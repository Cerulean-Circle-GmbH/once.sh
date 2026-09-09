# First Principles: oosh / once.sh

## Philosophy
- **Portability:** Designed to work across multiple Unix-like environments (Mac OS, Ubuntu, Android Termux, iOS iSH, Raspberry Pi OS).
- **Object-Oriented Shell (OOSH):** Brings object-oriented paradigms to shell scripting for better modularity, reusability, and maintainability.
- **Unified Management:** ONCE provides a single entry point to manage installation and configuration of the environment.
- **Transparency:** Emphasis on logging, debugging, and state management for traceability and troubleshooting.
- **Interactivity:** Advanced usage (ONCE server) is highly interactive, guiding the user through a state machine.

## Self-Healing Objects (CMM4 — MANDATORY)
- **Every OOSH object MUST self-heal to a valid state from nothing.** A broken or missing config is not an error to report — it is a state to recover from. `config init` regenerates `user.env` from scratch; the bootstrap (`source this`) re-derives `OOSH_DIR`, `CONFIG_PATH`, `PATH`, and the source chain (`log.env`, `oosh.env`) from whatever the environment provides. The result is a working object, not an error message.
- **Why:** A machine restart, a corrupted env file, or a fresh install all produce the same condition: missing or broken state. If the framework requires manual repair, it is not CMM3. If it self-heals, it is.
- **Proven pattern (WODA.prod, 2026-07-07):** config was broken after a restart (corrupted `current.method.env`, completion dead). Running `config init` triggered `config.save` which regenerated the full env chain — `user.env` → `oosh.env` → `log.env` — from live environment variables. Completion recovered. No manual file editing. The object healed itself.
- **The rule:** `init` always yields a valid object. A constructor that can fail is not a constructor — it is a function. Every OOSH entry point (`this.start`, `config.init`, `oo.start`) must leave the system in a usable state or explain exactly why it cannot (never silently broken).

## Core Mechanisms
- **State Machine:** ONCE uses a state-driven approach for installation and configuration, allowing stepwise progression and troubleshooting.
- **Domain Management:** Supports domain configuration and discovery, including integration with external services (e.g., Keycloak).
- **Script Modularity:** Codebase is split into focused scripts (e.g., oo, ossh, log, config, user) and directories (init, ng, su, etc.) for separation of concerns.
- **Extensibility:** Designed to be extended for new environments, features, and integrations.

## What We Learn from the Codebase
- **Comprehensive Bash Usage:** Heavy use of advanced bash scripting, including completion, logging, and debugging utilities.
- **Support for Multiple Install Methods:** Flexibility in installation (curl, wget, fetch, manual) to maximize accessibility.
- **Testing and Documentation:** Presence of test scripts and a docs directory indicates a focus on reliability and maintainability.
- **Legacy and Experimental Code:** The presence of 'old' and 'external' directories suggests ongoing evolution and experimentation.

## To Be Expanded
- Detailed breakdown of each core script/module
- Design patterns and anti-patterns observed
- Security and permission handling
- User experience and onboarding flow

## DRY Principle & Modularization
- **DRY (Don't Repeat Yourself):** The system is designed so that information about available commands, parameters, and defaults is defined only once—in the code itself. The completion engine reads this directly, eliminating duplication between documentation, code, and completion logic.
- **Modularization:** The original 'once' script became too large and unwieldy. The project is being refactored into a consistent set of small, focused scripts. The 'this' script acts as the bootloader, and 'oo' manages script installation and project state.

## Bash Completion (c2)
- **Dynamic Completion:** The `ng/c2` script implements a dynamic Bash completion system that:
  - Reads available scripts and their functions.
  - Parses method parameters and default values for accurate, context-aware completion.
  - Integrates standard Bash completions (files, users, groups, etc.) with project-specific logic.
  - Supports custom completions for advanced use cases.
- **Extensibility:** New scripts and methods are automatically included in the completion system, supporting rapid evolution and experimentation.

## The "this" Script
- **Bootstrapping:** Initializes the environment, sets up logging, and manages configuration.
- **Utility Functions:** Provides core utilities for checking function existence, dynamic loading, and calling methods across scripts.
- **Central Entry Point:** Ensures all scripts are loaded and available, acting as the foundation for the modular system.
- **State Management:** Handles environment variables, PATH, and configuration sourcing, supporting both interactive and scripted use.

## Command Creation System
- **Automated Command Generation:** New commands/scripts are created using `oo.new`, which copies a template and sets up completion and usage documentation automatically.
- **Method Addition:** `oo.new.method` interactively adds new methods to scripts, ensuring consistent structure and documentation.
- **Templates:** All new scripts and methods are based on templates in `templates/code/`, enforcing best practices and DRY principles.
- **Modularity:** Each command is a self-contained script, easily extended and tested.

## Test System
- **Test Suite Automation:** The `test.suite` system manages test discovery, execution, and result aggregation.
- **Test Templates:** New test scripts are generated from templates, ensuring consistency and ease of use.
- **Test Cases and Expectations:** Tests are defined using `test.case` (to run a function and capture results) and `expect` (to assert correctness).
- **Integration:** Tests source the command under test and the test suite, running in a controlled environment with logging and result tracking.
- **Feedback:** Results are summarized for each test and the overall suite, supporting rapid development and refactoring.