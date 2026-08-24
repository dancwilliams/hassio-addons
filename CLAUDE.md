# hassio-addons

Home Assistant add-on repository. Each top-level directory is one add-on; the
Supervisor builds the image on the user's machine from `Dockerfile` +
`config.json` (no registry, no `image:` key). Users see `README.md` and
`DOCS.md` in the add-on store and `CHANGELOG.md` on update, so they are user
docs, not dev notes.

## Add-ons

- `chirpstack-addon/` - ChirpStack LoRaWAN server + Gateway Bridge. Active.
  Every known trap is documented where it bites: `run.sh` comments, the
  "region numbering" section of `DOCS.md`, and `CHANGELOG.md`. Read those
  before touching config generation.
- `awnet/` - `stage: deprecated`. Docs-only changes; do not extend the code.

## Conventions

- `config.json` is the source of truth (version, ports, options, schema).
  `build.yaml`/`BUILD_FROM` is deprecated; base images are hardcoded as the
  multi-arch `ghcr.io/home-assistant/base:<alpine>` manifest list.
- ChirpStack add-on version = ChirpStack version, with `-N` appended for
  add-on-only changes (including Gateway Bridge bumps). CI fails if
  `config.json` version, the `CHIRPSTACK_VERSION` ARG and the top `CHANGELOG.md`
  entry disagree.
- `CHANGELOG.md` is newest-first (`update-check.py` prepends).
- Base image is Alpine: install Python libs via `apk add py3-*`, never pip.

## Updating ChirpStack

`update-check.py` runs daily via `.github/workflows/update-check.yaml` and
opens a `bump/<version>` PR when ChirpStack or the Gateway Bridge releases
(only once the binaries exist on artifacts.chirpstack.io). It edits the
Dockerfile ARGs, the version strings in `config.json`/`README.md`/`DOCS.md`,
and prepends a CHANGELOG entry. Manual equivalent: same edits by hand.

Before merging a bump, read the upstream release notes for changes to
`chirpstack.toml` keys or the region files - `run.sh` generates both.

## Testing

```sh
docker buildx build --load --build-arg BUILD_ARCH=amd64 -t chirpstack:amd64 chirpstack-addon
./smoke-test.sh chirpstack:amd64      # boots against a throwaway Mosquitto
python3 update-check.py true          # dry run, no push
```

CI (`.github/workflows/ci.yaml`): frenck/action-addon-linter on both add-ons,
version-consistency check, shellcheck, hadolint (config in `.hadolint.yaml`),
amd64 + aarch64 builds, smoke test, Trivy.
