#!/usr/bin/with-contenv bashio
# shellcheck shell=bash
# =============================================================================
# ChirpStack LoRaWAN add-on
#
# Starts three processes:
#   redis-server              - session/queue state (required by ChirpStack)
#   chirpstack-gateway-bridge - Basic Station endpoint on :3001, speaks MQTT
#   chirpstack                - the network server itself, web UI on :8080
#
# The SQLite database and the generated API secret live in /data, which the
# Supervisor persists across restarts and upgrades.
# =============================================================================
set -e

# Options are read straight from the file the Supervisor writes. bashio::config
# would fetch the same data over the Supervisor API, which makes the add-on
# impossible to boot anywhere else (the CI smoke test runs it under plain docker).
opt() { jq -r --arg k "$1" '.[$k] // empty' /data/options.json; }

REGION=$(opt region)
LOG_LEVEL=$(opt log_level)

# --- MQTT credentials -------------------------------------------------------
# Preferred source is the Supervisor's mqtt service (declared as "mqtt:want" in
# config.json), which hands us credentials for the Mosquitto add-on without
# anyone creating an account or typing a password into the add-on options.
# Setting mqtt_host explicitly overrides that, for an external broker.
MQTT_HOST=$(opt mqtt_host)
if [ -n "${MQTT_HOST}" ]; then
    MQTT_PORT=$(opt mqtt_port)
    MQTT_USER=$(opt mqtt_username)
    MQTT_PASS=$(opt mqtt_password)
    bashio::log.info "MQTT: using broker from add-on options"
elif bashio::services.available "mqtt"; then
    MQTT_HOST=$(bashio::services 'mqtt' 'host')
    MQTT_PORT=$(bashio::services 'mqtt' 'port')
    MQTT_USER=$(bashio::services 'mqtt' 'username')
    MQTT_PASS=$(bashio::services 'mqtt' 'password')
    bashio::log.info "MQTT: using Supervisor-provided service"
else
    bashio::exit.nok \
        "No MQTT broker available. Either install the Mosquitto add-on, or set mqtt_host in this add-on's options."
fi

CONF_DIR=/etc/chirpstack           # ChirpStack reads EVERY .toml in this dir,
GB_CONF=/etc/gateway-bridge.toml   # so the bridge config must live outside it.
REGION_SRC="/opt/chirpstack-regions/region_${REGION}.toml"
MQTT_URI="tcp://${MQTT_HOST}:${MQTT_PORT}"

mkdir -p "${CONF_DIR}" /data/redis

if [ ! -f "${REGION_SRC}" ]; then
    bashio::exit.nok "Region '${REGION}' has no region_${REGION}.toml upstream."
fi

# --- Persisted API secret (JWT signing key) ---------------------------------
# Regenerating this on every boot would invalidate every logged-in session and
# every issued API token, so it is generated once and kept.
if [ ! -s /data/api_secret ]; then
    head -c 32 /dev/urandom | od -An -tx1 | tr -d ' \n' > /data/api_secret
    bashio::log.info "Generated a new ChirpStack API secret"
fi
API_SECRET=$(cat /data/api_secret)

# --- Region-specific radio parameters for the Basic Station backend ---------
#
# The concentrator block below is NOT optional. It is commented out in the
# upstream gateway-bridge sample config, and leaving it out produces a
# router-config with no channel plan: the gateway connects, receives it,
# silently drops the connection and retries forever. Nothing in the
# gateway-bridge log says why.
#
# US915/AU915 channel plans are formulaic:
#   uplink ch i      = BASE + 0.2 MHz * i        (sub-band n => channels 8n..8n+7)
#   500 kHz uplink   = STD_BASE + 1.6 MHz * n
case "${REGION}" in
    us915_*)
        GB_REGION="US915"; FREQ_MIN=902000000; FREQ_MAX=928000000
        SB="${REGION#us915_}"
        CH0=$(( 902300000 + SB * 1600000 ))
        STD_FREQ=$(( 903000000 + SB * 1600000 ))
        STD_BW=500000; STD_SF=8; FSK_FREQ=0
        ;;
    au915_*)
        GB_REGION="AU915"; FREQ_MIN=915000000; FREQ_MAX=928000000
        SB="${REGION#au915_}"
        CH0=$(( 915200000 + SB * 1600000 ))
        STD_FREQ=$(( 915900000 + SB * 1600000 ))
        STD_BW=500000; STD_SF=8; FSK_FREQ=0
        ;;
    eu868)
        GB_REGION="EU868"; FREQ_MIN=863000000; FREQ_MAX=870000000
        CH0=""   # EU868 channels are not a uniform ladder; listed explicitly
        EU_FREQS="868100000 868300000 868500000 867100000 867300000 867500000 867700000 867900000"
        STD_FREQ=868300000; STD_BW=250000; STD_SF=7; FSK_FREQ=868800000
        ;;
    *)
        bashio::exit.nok \
            "Region '${REGION}' has no verified concentrator channel plan in this add-on. Supported: us915_0..7, au915_0..1, eu868."
        ;;
esac

# Build the multi-SF frequency list
if [ -n "${CH0}" ]; then
    MULTI_SF=""
    for i in 0 1 2 3 4 5 6 7; do
        MULTI_SF="${MULTI_SF}      $(( CH0 + i * 200000 )),
"
    done
else
    MULTI_SF=""
    for f in ${EU_FREQS}; do
        MULTI_SF="${MULTI_SF}      ${f},
"
    done
fi

# --- Region file ------------------------------------------------------------
# Rewrite ONLY the keys inside [regions.gateway.backend.mqtt]. A blanket sed
# would also clobber the identically-named keys in other sections.
rm -f "${CONF_DIR}"/*.toml
awk -v srv="${MQTT_URI}" -v usr="${MQTT_USER}" -v pw="${MQTT_PASS}" '
    /^[[:space:]]*\[/ {
        section=$0
        gsub(/^[[:space:]]+|[[:space:]]+$/, "", section)
    }
    section=="[regions.gateway.backend.mqtt]" && /^[[:space:]]*server[[:space:]]*=/ {
        print "        server=\"" srv "\""; next
    }
    section=="[regions.gateway.backend.mqtt]" && /^[[:space:]]*username[[:space:]]*=/ {
        print "        username=\"" usr "\""; next
    }
    section=="[regions.gateway.backend.mqtt]" && /^[[:space:]]*password[[:space:]]*=/ {
        print "        password=\"" pw "\""; next
    }
    { print }
' "${REGION_SRC}" > "${CONF_DIR}/region_${REGION}.toml"

# --- ChirpStack -------------------------------------------------------------
cat > "${CONF_DIR}/chirpstack.toml" <<EOF
[logging]
  level="${LOG_LEVEL}"

[sqlite]
  path="/data/chirpstack.sqlite"

[redis]
  servers=["redis://127.0.0.1:6379"]

[network]
  net_id="000000"
  enabled_regions=["${REGION}"]

[api]
  bind="0.0.0.0:8080"
  secret="${API_SECRET}"

[integration]
  enabled=["mqtt"]

  [integration.mqtt]
    server="${MQTT_URI}"
    username="${MQTT_USER}"
    password="${MQTT_PASS}"
    json=true
EOF

# Guard: ChirpStack silently ignores unknown TOML keys and falls back to its
# built-in default of tcp://localhost:1883. That failure mode looks like a
# broker outage in the log, so assert the key we just wrote is the real one.
if ! grep -qE '^\s*server="' "${CONF_DIR}/chirpstack.toml"; then
    bashio::exit.nok "chirpstack.toml is missing the integration MQTT 'server' key"
fi

# --- Gateway Bridge ---------------------------------------------------------
# The topic templates MUST carry the region as a prefix, because ChirpStack
# subscribes under the region file's topic_prefix ("${REGION}"). Without the
# prefix the bridge publishes into a namespace nobody is listening on, and
# uplinks vanish silently.
cat > "${GB_CONF}" <<EOF
[backend]
  type="basic_station"

  [backend.basic_station]
    bind=":3001"
    region="${GB_REGION}"
    frequency_min=${FREQ_MIN}
    frequency_max=${FREQ_MAX}

  [[backend.basic_station.concentrators]]

    [backend.basic_station.concentrators.multi_sf]
    frequencies=[
${MULTI_SF}    ]

    [backend.basic_station.concentrators.lora_std]
    frequency=${STD_FREQ}
    bandwidth=${STD_BW}
    spreading_factor=${STD_SF}

    [backend.basic_station.concentrators.fsk]
    frequency=${FSK_FREQ}

[integration]
  marshaler="protobuf"

  [integration.mqtt]
    event_topic_template="${REGION}/gateway/{{ .GatewayID }}/event/{{ .EventType }}"
    command_topic_template="${REGION}/gateway/{{ .GatewayID }}/command/#"

    [integration.mqtt.auth]
      type="generic"

      [integration.mqtt.auth.generic]
        servers=["${MQTT_URI}"]
        username="${MQTT_USER}"
        password="${MQTT_PASS}"
EOF

# Guard: without a concentrator block the gateway receives a router-config with
# no channel plan, then connects/disconnects in a loop with no stated reason.
if ! grep -q '\[\[backend.basic_station.concentrators\]\]' "${GB_CONF}"; then
    bashio::exit.nok "gateway-bridge config has no concentrator channel plan"
fi

bashio::log.info "Region ${REGION} (${GB_REGION}), broker ${MQTT_URI} as '${MQTT_USER}'"
bashio::log.info "Radio plan: 8x multi-SF from $(( CH0 ? CH0 : 0 ))Hz, LoRa-STD ${STD_FREQ}Hz BW${STD_BW} SF${STD_SF}"
bashio::log.info "Basic Station endpoint: ws://<this-host>:3001"

# --- Launch -----------------------------------------------------------------
redis-server --daemonize yes --port 6379 --bind 127.0.0.1 --dir /data/redis --save '900 1'
sleep 1
redis-cli ping > /dev/null || bashio::exit.nok "Redis failed to start"

chirpstack-gateway-bridge -c "${GB_CONF}" &
GB_PID=$!
chirpstack -c "${CONF_DIR}" &
CS_PID=$!

# If either dies, stop the add-on so the Supervisor restarts it cleanly rather
# than leaving a half-running stack that looks healthy from the outside.
trap 'kill ${GB_PID} ${CS_PID} 2>/dev/null || true' TERM INT
wait -n ${GB_PID} ${CS_PID}
bashio::log.error "A ChirpStack process exited - shutting down"
kill ${GB_PID} ${CS_PID} 2>/dev/null || true
exit 1
