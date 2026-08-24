#!/usr/bin/env bash
# Smoke test for the ChirpStack add-on image. Boots it the way the Supervisor
# would (fake /data/options.json, manual-broker path so no Supervisor API is
# needed) against a throwaway Mosquitto, then checks that the web UI answers,
# the Basic Station port listens, and both MQTT clients reached the broker.
# Usage: ./smoke-test.sh <image>
set -euo pipefail
IMG=${1:?usage: smoke-test.sh <image>}
NET=cs-smoke
TMP=$(mktemp -d)
cleanup() {
    docker rm -f cs-smoke cs-mqtt >/dev/null 2>&1 || true
    docker network rm "$NET" >/dev/null 2>&1 || true
    rm -rf "$TMP"
}
trap cleanup EXIT
fail() { echo "FAIL: $*"; echo "--- add-on log"; docker logs cs-smoke 2>&1 | tail -50; echo "--- mosquitto log"; docker logs cs-mqtt 2>&1 | tail -20; exit 1; }

printf 'listener 1883\nallow_anonymous true\n' > "$TMP/mosquitto.conf"
echo '{"region":"us915_1","mqtt_host":"cs-mqtt","mqtt_port":1883,"mqtt_username":"","mqtt_password":"","log_level":"info"}' > "$TMP/options.json"

docker network create "$NET" >/dev/null
docker run -d --name cs-mqtt --network "$NET" \
    -v "$TMP/mosquitto.conf:/mosquitto/config/mosquitto.conf:ro" eclipse-mosquitto:2 >/dev/null
docker run -d --name cs-smoke --network "$NET" -p 18080:8080 -p 13001:3001 \
    -v "$TMP/options.json:/data/options.json:ro" "$IMG" >/dev/null

for _ in $(seq 1 30); do
    [ "$(docker inspect -f '{{.State.Running}}' cs-smoke)" = true ] || fail "add-on container exited"
    curl -sf --max-time 2 -o /dev/null http://127.0.0.1:18080/ && break
    sleep 2
done
curl -sf --max-time 2 -o /dev/null http://127.0.0.1:18080/ || fail "web UI never answered on 8080"
timeout 3 bash -c 'exec 3<>/dev/tcp/127.0.0.1/13001' || fail "Basic Station port 3001 not listening"
docker logs cs-smoke 2>&1 | grep -q 'using broker from add-on options' || fail "did not take the manual-broker path"
sleep 3
n=$(docker logs cs-mqtt 2>&1 | grep -c 'New client connected' || true)
[ "$n" -ge 2 ] || fail "expected ChirpStack + Gateway Bridge on the broker, saw $n client(s)"
docker logs cs-smoke 2>&1 | grep -qi 'process exited' && fail "a process exited"
echo "smoke OK ($n MQTT clients)"
