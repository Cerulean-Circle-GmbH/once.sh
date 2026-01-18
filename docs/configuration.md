# Configuration Management

## Overview
Configuration in oosh/once.sh is managed through environment variables, config files, and dynamic sourcing. This ensures flexibility and portability across environments.

## Environment Variables
- Key variables: OOSH_DIR, LOG_LEVEL, CONFIG, etc.
- How to set and override variables for different environments.

## Config Files
- Location and structure of config files (e.g., ~/config/user.env).
- How scripts load and use configuration.
- Best practices for managing user and project configs.

## Dynamic Sourcing
- How configuration is sourced at runtime.
- Using `this` and other utilities to ensure correct config loading.

## See Also
- [first-principles.md](first-principles.md)
- [advanced-usage.md](advanced-usage.md)
- [test-suite.md](test-suite.md)