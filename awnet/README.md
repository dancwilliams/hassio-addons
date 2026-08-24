# Home Assistant Add-on: AWNET

> **Deprecated (2026-08).** This add-on is no longer maintained; the code stays for reference only. Use one of these instead:
>
> - [awnet_local](https://github.com/tlskinneriv/awnet_local) (HACS) - the direct replacement. Same "Custom Server" setup on the console, proper devices and entities.
> - The core [Ecowitt](https://www.home-assistant.io/integrations/ecowitt) integration, if your console can send the Ecowitt protocol. Consoles that only speak the Ambient Weather protocol need the [GSzabados/ecowitt](https://github.com/GSzabados/ecowitt) HACS fork until [aioecowitt#174](https://github.com/home-assistant-libs/aioecowitt/pull/174) is merged.

Local access between Ambient Weather weatherstation and Home Assistant.

## About

You can use this add-on to take advantage of the new "Custom Server" feature in AWNET available in Firware [4.2.8](https://ambientweather.com/support) on the WS-2902A, WS-2902B, WS-2902C, WS-2000 And WS-5000.  I have tested this using my WS-2902B.  It presents a webserver that will accept the polling from the WS device.  It then creates a entity in Home Assistant.

I will be working on a cleaner integration...but it works.