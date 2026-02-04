# Project Outline: oosh / once.sh

## Overview
- Unified shell environment for UCP components and ONCE (Object Network Communication Environment)
- Two main topics:
  1. OOSH: Object Oriented Shell environment (completion, logging, debugging)
  2. ONCE: Bash script to manage ONCE installation in any environment

## Supported Environments
- Mac OS
- Ubuntu
- Android (Termux)
- iOS (iSH)
- Raspberry Pi OS

## Installation Methods
- Fast install (curl, wget, fetch)
- Manual install
- Debugging/logging install
- Installation without curl/wget

## Advanced Usage
- ONCE Server setup
- State machine for ONCE configuration
- Domain management
- State management and troubleshooting
- Integration with Keycloak

## Directory Structure (High-level)
- `init/` : Installation and bootstrap scripts (once, oosh, deinstall.oosh)
- `docs/` : Documentation (this outline, diagrams)
- `test/` : Test scripts and scenarios
- `ng/`, `su/`, `os.specific/`, `templates/`, `external/`, `old/` : Modules, OS-specific, templates, external, and legacy code
- Root scripts: Core logic (oo, ossh, log, config, user, etc.)

## Entry Points
- [README.md](../README.md): Main entry and quickstart
- [first-principles.md](first-principles.md): Foundational concepts and design principles
- [wiki-index.md](wiki-index.md): Wiki home and navigation