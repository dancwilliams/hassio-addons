# Changelog

## 4.19.1

Initial release.

- ChirpStack 4.19.1 (SQLite build — no PostgreSQL dependency)
- ChirpStack Gateway Bridge 4.1.2, Basic Station backend on port 3001
- MQTT credentials taken from the Supervisor mqtt service (no dedicated broker account needed); overridable for an external broker
- Bundled Redis, bound to loopback only
- Region definitions pulled from the matching upstream git tag at build time
- Requests no privileges, no host networking, and no device mappings
- Ships build.yaml pinning the Home Assistant Alpine 3.21 base images
