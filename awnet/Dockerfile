# Multi-arch Home Assistant base image (Alpine + s6-overlay + bashio).
# Hardcoded because build.yaml is deprecated and the Supervisor no longer
# supplies BUILD_FROM. requests comes from apk: pip refuses to install into
# the system Python on current base images (PEP 668).
FROM ghcr.io/home-assistant/base:3.21

ENV LANG=C.UTF-8

COPY run.sh awnet.py /
RUN chmod a+x /run.sh && apk add --no-cache python3 py3-requests

CMD [ "/run.sh" ]
