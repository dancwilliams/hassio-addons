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

## 4.19.1-2

- Fix: the MQTT integration used `servers=[...]`, but ChirpStack expects
  `server="..."` (singular). Unknown TOML keys are ignored silently, so the
  integration fell back to `tcp://localhost:1883` and could not publish
  uplinks. Added a startup assertion so this can't regress quietly.
- Default web UI host port moved 8080 -> 8090; 8080 collides with the UniFi
  Network Application's device-inform port.

## 4.19.1-3

- Removed `build.yaml`; the Supervisor now reports it as deprecated. The base
  image is hardcoded in the Dockerfile as the multi-arch manifest list
  `ghcr.io/home-assistant/base:3.21`, which buildx resolves per target
  platform — so multi-arch support is retained, not traded away.
- Architecture for the upstream artifact download now falls back to the build
  platform if the Supervisor does not supply `BUILD_ARCH`.

## 4.19.1-4

- Added a `webui` link so the add-on page gets an "Open Web UI" button.
  Ingress is deliberately not used: the ChirpStack UI references its assets
  with absolute paths and offers no base-path option, so it cannot be served
  under the ingress sub-path. Port 3001 could not use ingress in any case,
  since the gateway is an external client rather than a browser session.
