# ChirpStack LoRaWAN

A self-hosted LoRaWAN Network Server. Your gateway talks to this add-on over your
own LAN, this add-on publishes decoded uplinks to your own MQTT broker, and
Home Assistant reads them from there. Nothing leaves the building.

Bundles ChirpStack 4.19.1 (SQLite build) and ChirpStack Gateway Bridge 4.1.2.

## Before you start

Nothing, if you run the Mosquitto add-on. This add-on declares `mqtt:want`, so
the Supervisor hands it broker credentials automatically — no account to create
and no password to type in.

## Configuration

| Option | Default | Notes |
|---|---|---|
| `region` | `us915_1` | See the region note below — the numbering is easy to get wrong. |
| `mqtt_host` | *(empty)* | Leave empty to use the Supervisor's MQTT service. Set it only to point at an external broker. |
| `mqtt_port` | `1883` | Only used when `mqtt_host` is set. |
| `mqtt_username` | *(empty)* | Only used when `mqtt_host` is set. |
| `mqtt_password` | *(empty)* | Only used when `mqtt_host` is set. |
| `log_level` | `info` | Use `debug` when a gateway won't connect. |

The startup log states which source was used — `using Supervisor-provided
service` or `using broker from add-on options` — so it is never ambiguous which
credentials are in play.

### A word on US915 region numbering

ChirpStack's region IDs are **zero-indexed**, while the LoRaWAN world usually
talks about sub-bands **one-indexed**. They are off by one:

| ChirpStack region | Channels | Commonly called |
|---|---|---|
| `us915_0` | 0–7 + 64 | sub-band 1 |
| `us915_1` | 8–15 + 65 | **sub-band 2** ← what TTN and most US deployments use |

Pick the wrong one and the server starts perfectly, the gateway connects
perfectly, and no device is ever heard. There is no error message for this.
`us915_1` is almost certainly what you want in North America.

## Pointing a gateway at it

The add-on exposes a **Basic Station** endpoint on port `3001`. On the gateway,
set the LNS URI to:

```
ws://<home-assistant-ip>:3001
```

Plain `ws://`, not `wss://` — this is an unencrypted LAN link. If you need TLS,
put a reverse proxy in front of it.

Semtech UDP packet forwarders are not exposed by default. If you need one,
add `1700/udp` to `ports` in `config.json` and switch `[backend] type` in
`run.sh` to `semtech_udp`.

## Web UI

Reachable at `http://<home-assistant-ip>:8080`. Default login is
`admin` / `admin` — change it immediately, since this port is open on your LAN.

## Data and backups

The SQLite database and the generated API secret live in `/data`, so the
Supervisor persists them across restarts and add-on updates, and includes them
in add-on backups. The database holds your device registrations, keys, and
gateway list — it is small, but losing it means re-provisioning every device.

The API secret is generated once on first boot and reused. Deleting it logs
out every session and invalidates every issued API token.

## Updating

Bump `CHIRPSTACK_VERSION` / `GATEWAY_BRIDGE_VERSION` in the `Dockerfile` and
`version` in `config.json`, then rebuild. The region definitions are pulled
from the matching upstream git tag automatically, so they can never drift out
of sync with the binary that reads them.

## Troubleshooting

**Gateway connects then immediately drops.** Almost always a region mismatch
between the gateway's radio config and `region`.

**Server is up, gateway is up, no uplinks.** Check the region numbering table
above first. After that, confirm the gateway is actually in Basic Station mode
rather than packet-forwarder mode.

**`MQTT error: Connection refused` in the log.** The broker is unreachable or
the credentials are wrong. The add-on retries forever and recovers on its own
once the broker returns.
