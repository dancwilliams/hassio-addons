#!/usr/bin/with-contenv bashio
# shellcheck shell=bash

ENTITY_ID="$(bashio::config 'entity_id')"
export ENTITY_ID
# export PUBLISH_ALL="$(bashio::config 'publish_all_sensors')"

python3 awnet.py