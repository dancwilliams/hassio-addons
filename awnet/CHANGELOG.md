# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.48] - 2026-08-23
- Deprecated. Superseded by [awnet_local](https://github.com/tlskinneriv/awnet_local) (HACS) and the core Ecowitt integration; see README. The add-on is flagged `stage: deprecated` in the store and will not receive further updates.
- Dockerfile: base image pinned to `ghcr.io/home-assistant/base:3.21` (build.yaml/BUILD_FROM is deprecated) and `requests` installed from apk, because `pip install` into the system Python is refused on current base images. Without this the add-on no longer built.

## [0.1.47] - 2021-07-16
- Removing modification of the datetime within the python script.  This is better handled within the teamplate sensor in Home Assistant.

## [0.1.46] - 2021-07-15
- Added icon.png

## [0.1.45] - 2021-07-15
- Dressing up this so people can follow.  This is the initial "public" posting on my GitHub.
- Will update Changelog with all work moving forward.