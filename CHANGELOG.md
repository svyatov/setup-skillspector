# Changelog

All notable changes to this project are documented in this file.

The format is based on [Keep a Changelog 2.0.0](https://keepachangelog.com/en/2.0.0/), and this project follows [Semantic Versioning](https://semver.org/spec/v2.0.0.html) over the inputs and outputs declared in `action.yml`.

## [Unreleased]

### Added

- The action installs SkillSpector 2.12.0 from a hash-locked lockfile and scans each skill under `path`, with `baseline`, `llm`, `fail-on-findings`, `fail-on-incomplete`, and `scan` inputs and `version` and `report-dir` outputs.
