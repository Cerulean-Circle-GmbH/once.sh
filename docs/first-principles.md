# First Principles: oosh / once.sh

## Philosophy
- **init() is the constructor — it ALWAYS yields a fully operational, consistent, and safe object.** OOSH is the Object-Oriented Shell: `scriptname.start()` / `this.init` / `config.init` are constructors. The constructor contract is absolute — after init runs, the object IS valid: fully operational, internally consistent, safe to use. There is no "loaded-but-broken" state.
  - **Always valid, every call.** init is idempotent and self-healing BY DESIGN. Run it on a fresh object or a born-broken one — it always ends in a valid object. "Repair" is not a separate command; it is simply init invoked again.
  - **Resolve fundamentals from the canonical source.** Identity/structure (e.g. OOSH_DIR, CONFIG_PATH, OOSH_MODE) is derived from where the script itself lives (`BASH_SOURCE`) — never guessed (`$HOME/oosh`), never trusted from a possibly-broken value, never conditionally skipped.
  - **No state loss.** Reinit preserves all existing user configuration; it restores the broken/missing fundamentals only. Reinit ≠ wipe.
  - **Pure-state persistence.** Config/env files hold STATE ONLY — `export`/`declare`, comments, blanks. No logic, and **no `source` lines: an env file never sources another env file.** The bootstrap (`this`) owns the source chain — it sources `user.env` and the env files that belong to the chain (`oosh.env`, `log.env`) in order. Env files are safe to source precisely because they are inert pure state; moving the chain into `this` keeps them that way (a stray `source` in an env file is the exact pollution `config.validate` rejects).
  - **Never silently broken.** A broken/polluted env is never run on blindly: init detects it (validates its own state) and heals it. It is never half-constructed and never returns RC=0 on an env it has not made valid.
- **Self-Care Across the Whole Lifecycle.** *Tron, verbatim:* "All programs self-care for their whole lifecycle. They init correct (env) states, and reinit to self-repair when something goes sideways." A program is responsible for its own correctness from birth to death:
  - **Init correct state.** On startup it establishes a known-good environment (correct env vars, pure-state config, resolved paths) — it never assumes the environment is already correct.
  - **Detect when it goes sideways.** It validates its own state (`config.validate`, `check`) and recognises a broken/polluted/stale env instead of running blindly on it.
  - **Reinit to self-repair.** When state is bad it heals itself — regenerates clean config, re-resolves fundamentals, reinits — via ONE easy, discoverable, idempotent entrypoint that is always available (repair IS init invoked again).
  - **Whole lifecycle.** install → boot → run → recover. Every phase can detect-and-heal; no phase silently ships or perpetuates a broken state.
  - Implemented by: `check … fix` (check-and-auto-fix idiom), `config.validate` / `config.save` (purity guard + self-healing reinit), `reconfigure` / `oo reconfigure` (re-exec with fresh config), and `this` bootstrap self-validate.
- **Clean perspective of truth — never trust an inherited environment.** *Tron, verbatim:* "you are now clean and can work from a clean perspective of truth." An inherited or stale shell environment *lies*: `$TMUX_PANE`, `LOG_DEVICE`, leaked session ids and the like survive a move/fork/rewind and keep pointing at a prior incarnation. Truth requires a clean vantage point.
  - **Start clean.** When environment-derived facts matter, establish a clean shell (`env -i sh` → a fresh `bash -l` that re-sources the profile) so PATH, identity, and location reflect *now* — not a previous incarnation. This is the constructor contract applied to your own shell: init a known-good environment; never assume the one you inherited is correct.
  - **Ground truth beats the env var.** When location or identity is in doubt, resolve from the canonical source — kernel/runtime values and the process-ancestry trace (your pid → the pane's shell pid) — never a possibly-stale inherited variable, never a pane title. (Mirrors "resolve fundamentals from `BASH_SOURCE`, never guessed.")
  - **The environmental form of "measure, never assume."** A measurement taken through a dirty environment is a guess wearing data's clothes.
- **Only env files are sourced; scripts are invoked.** Sourcing pulls a file's contents into the current shell. Only pure-state env files (`export`/`declare` only, no logic, no `source` lines) may be sourced — they are inert and safe. SCRIPTS are never sourced into a shell; they are invoked through their CLI / the `this` dispatch (`scriptname method args`), which runs them in their own process with proper method resolution. The ONE exception is the bootstrap itself: `.bashrc` → `this`, where `this` sources the env chain (`user.env` → `oosh.env` → `log.env`) — never another script. This keeps logic out of the env and keeps the shell uncontaminated by a script's internals.
- **Portability:** Designed to work across multiple Unix-like environments (Mac OS, Ubuntu, Android Termux, iOS iSH, Raspberry Pi OS).
- **Object-Oriented Shell (OOSH):** Brings object-oriented paradigms to shell scripting for better modularity, reusability, and maintainability.
- **Unified Management:** ONCE provides a single entry point to manage installation and configuration of the environment.
- **Transparency:** Emphasis on logging, debugging, and state management for traceability and troubleshooting.
- **Interactivity:** Advanced usage (ONCE server) is highly interactive, guiding the user through a state machine.

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
- **Completion Precedence (MANDATORY — 3-tier resolution):**
  1. **Method-specific parameter completion is a HARD OVERWRITE of the standard.** A method's own `<class>.<method>.completion.<paramName>` takes precedence over — and hard-overwrites — the standard class-level `<class>.parameter.completion.<paramName>`. *Method completion goes over (standard) parameter completion.*
  2. **Standard (class-level) parameter completion is the default fallback.** When a method defines no specific completion for a parameter, the shared `<class>.parameter.completion.<paramName>` is used.
  3. **Parameter completion (either tier) is USED over method / sub-command listing.** Once a complete method with parameters is on the line, complete the current PARAMETER — never fall back to listing sub-methods. *The usage of parameter completion goes over method-completion definition.*
  - Corollary: a parameter name MUST be a valid bash identifier (camelCase, no `...` / dashes / spaces). An invalid name (e.g. `<text...>`) breaks `declare PARAM_<name>` and kills parameter tracking — see [oosh-architecture.md](oosh-architecture.md) naming standard.

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