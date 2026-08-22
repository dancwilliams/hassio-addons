ARG BUILD_FROM
FROM ${BUILD_FROM}

# Upstream versions. Bumping these two lines (plus "version" in config.json)
# is the entire update procedure.
ARG CHIRPSTACK_VERSION=4.19.1
ARG GATEWAY_BRIDGE_VERSION=4.1.2
ARG BUILD_ARCH=amd64

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN apk add --no-cache redis curl tar

# ---------------------------------------------------------------------------
# ChirpStack (SQLite build - no PostgreSQL needed) + Gateway Bridge.
# Both are statically-linked and run directly on the Alpine base.
# ---------------------------------------------------------------------------
RUN set -eux; \
    case "${BUILD_ARCH}" in \
      amd64)   CS_ARCH=amd64; GB_ARCH=amd64 ;; \
      aarch64) CS_ARCH=arm64; GB_ARCH=arm64 ;; \
      *) echo "Unsupported architecture: ${BUILD_ARCH}" >&2; exit 1 ;; \
    esac; \
    curl -fsSL -o /tmp/cs.tar.gz \
      "https://artifacts.chirpstack.io/downloads/chirpstack/chirpstack_${CHIRPSTACK_VERSION}_sqlite_linux_${CS_ARCH}.tar.gz"; \
    tar -xzf /tmp/cs.tar.gz -C /usr/bin chirpstack; \
    curl -fsSL -o /tmp/gb.tar.gz \
      "https://artifacts.chirpstack.io/downloads/chirpstack-gateway-bridge/chirpstack-gateway-bridge_${GATEWAY_BRIDGE_VERSION}_linux_${GB_ARCH}.tar.gz"; \
    tar -xzf /tmp/gb.tar.gz -C /usr/bin chirpstack-gateway-bridge; \
    rm -f /tmp/cs.tar.gz /tmp/gb.tar.gz; \
    chmod +x /usr/bin/chirpstack /usr/bin/chirpstack-gateway-bridge; \
    chirpstack --version; \
    chirpstack-gateway-bridge version

# ---------------------------------------------------------------------------
# Region definitions, pinned to the SAME upstream tag as the binary so the
# region schema can never drift out of sync with the server that reads it.
# ---------------------------------------------------------------------------
RUN set -eux; \
    mkdir -p /opt/chirpstack-regions; \
    curl -fsSL "https://codeload.github.com/chirpstack/chirpstack/tar.gz/refs/tags/v${CHIRPSTACK_VERSION}" \
      | tar -xz --strip-components=3 -C /opt/chirpstack-regions \
          "chirpstack-${CHIRPSTACK_VERSION}/chirpstack/configuration"; \
    rm -f /opt/chirpstack-regions/chirpstack.toml; \
    ls /opt/chirpstack-regions/region_us915_1.toml

COPY run.sh /
RUN chmod a+x /run.sh

CMD [ "/run.sh" ]
