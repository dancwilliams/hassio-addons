# ChirpStack LoRaWAN add-on

Self-hosted LoRaWAN Network Server for Home Assistant — ChirpStack 4.19.1 plus
Gateway Bridge 4.1.2, backed by SQLite.

Point a Basic Station gateway at `ws://<ha-ip>:3001`, and decoded uplinks land
on your own MQTT broker. No cloud service involved.

See [DOCS.md](DOCS.md) for configuration, and read the US915 region-numbering
note before first boot — the zero-indexed region IDs are off by one from the
sub-band numbers everyone quotes.
