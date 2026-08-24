# Home Assistant Add-ons

[![License][license-shield]](LICENSE)

## Installation

Settings > Add-ons > Add-on Store > three-dot menu > Repositories, and add:

```txt
https://github.com/dancwilliams/hassio-addons
```

## Add-ons

### [ChirpStack LoRaWAN](chirpstack-addon/)

![amd64][amd64-shield] ![aarch64][aarch64-shield]

Self-hosted LoRaWAN Network Server: ChirpStack (SQLite build) plus Gateway
Bridge with a Basic Station endpoint, publishing to your own MQTT broker.
No cloud, no privileges, no device mappings.

[Documentation](chirpstack-addon/DOCS.md) · [Changelog](chirpstack-addon/CHANGELOG.md)

### [AWNET to HASS](awnet/) - deprecated

Pushed Ambient Weather console data into a Home Assistant sensor. Superseded
by [awnet_local](https://github.com/tlskinneriv/awnet_local) and the core
Ecowitt integration; kept for reference only.

[license-shield]: https://img.shields.io/github/license/dancwilliams/hassio-addons.svg?style=flat
[amd64-shield]: https://img.shields.io/badge/amd64-yes-green.svg?style=flat
[aarch64-shield]: https://img.shields.io/badge/aarch64-yes-green.svg?style=flat
