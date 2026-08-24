# AWNET to HASS

> **Deprecated (2026-08).** This add-on is no longer maintained; the code stays for reference only. Use one of these instead:
>
> - [awnet_local](https://github.com/tlskinneriv/awnet_local) (HACS) - the direct replacement. Same "Custom Server" setup on the console, proper devices and entities.
> - The core [Ecowitt](https://www.home-assistant.io/integrations/ecowitt) integration, if your console can send the Ecowitt protocol. Consoles that only speak the Ambient Weather protocol need the [GSzabados/ecowitt](https://github.com/GSzabados/ecowitt) HACS fork until [aioecowitt#174](https://github.com/home-assistant-libs/aioecowitt/pull/174) is merged.

## How it worked

The add-on listens on host port 7080 for the "Custom Server" push from an
Ambient Weather console (firmware 4.2.8+ on WS-2902A/B/C, WS-2000, WS-5000).
In the awnet app: Custom > Protocol "Ambient Weather", server = your HA IP,
port 7080, path `/`. Every report is written as a single `sensor.<entity_id>`
whose attributes carry the raw station fields.

| Option | Default | Notes |
|---|---|---|
| `entity_id` | `WS2902B` | Name of the sensor created in Home Assistant. |
