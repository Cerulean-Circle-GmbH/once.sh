# oosh / once.sh Wiki

Welcome to the documentation wiki for the oosh / once.sh project. This wiki provides a structured overview, foundational principles, and detailed documentation for users and developers.

## Entry Points

- [README.md](../README.md): Quickstart, installation, and high-level overview.
- [Outline](outline.md): Project structure, supported environments, installation methods, and directory map.
- [First Principles](first-principles.md): Philosophy, design choices, and foundational concepts.

## Getting Started
- See the [README.md](../README.md) for fast install instructions and supported environments.
- Explore the [Outline](outline.md) for a map of the project and its components.
- Read [First Principles](first-principles.md) to understand the core ideas and design philosophy.

## Next Steps
- Detailed module and script documentation (coming soon)
- Advanced usage and troubleshooting guides
- Contribution and extension guidelines

## Core Tools

- [OOSH Quick Reference](oosh.md) - Framework basics and quick start guide
- [OOSH Architecture](oosh-architecture.md) - Complete technical reference
- [Log System Documentation](log.md) - Logging levels, live logging, debug breakpoints, and capture modes
- [Log Levels and Testing](log-levels-and-testing.md) - Diagnostic reference: log level 0-7 details, config.save pollution bug, set +x bug, debugging guide, and proposed fixes
- [Config System Documentation](config.md) - Environment configuration persistence and management
- [Debug System Documentation](debug.md) - Interactive step debugger, stack traces, and trap handlers
- [OO Framework Documentation](oo.md) - Script creation, version control, package management
- [State Machine Documentation](state.md) - Creating and managing state machines for multi-step workflows

## Infrastructure Tools

- [SSH Management (ossh)](ossh.md) - SSH keys, configs, remote installation, ProxyJump multi-hop
- [Docker Wrapper (odocker)](odocker.md) - Docker image/container management, workspace builds, container reset
- [Promotion Pipeline (promote)](promote.md) - Code promotion with gated tests (dev → testing → prod)
- [OS & Platform Testing (os)](os.md) - OS detection, platform install tests
- [Supported Platforms](supported-platforms.md) - Platform matrix, tiers, and install requirements
- [Branching Strategy](branching.md) - Branch naming, promotion flow, feature/hotfix conventions

## Agent Orchestration

- [HiveMind](hivemind.md) - Multi-agent orchestrator for distributed task execution
- `claudeFlow` - Claude Flow wrapper with hive-mind commands
- `claudeCode` - Claude Code session management and agent support
- `otmux` - Tmux wrapper for pane management

### Agent Roles (`.claude/agents/`)

All agent role definitions live in `.claude/agents/<role>/SKILL.md`:

| Role | Purpose |
|------|---------|
| `agent-teacher` | Train agents, delegate tasks, improve tools |
| `oosh-expert` | Framework architecture & development |
| `oosh-tester` | Testing & quality assurance |
| `scrum-master` | Continuous monitoring, permission approval |
| `product-owner` | OOSH principles quality guardian |
| `script-product-owner` | Per-script lifecycle guardian (template) |
| `developer` | Implementation capacity (template) |

Cursor reads these via symlinks at `.cursor/skills/` (DRY — single source of truth).

## Core Concepts

### Bash Completion System (c2)
The heart of the oosh/once.sh system is an advanced Bash completion engine, implemented in the `ng/c2` script. This system:
- Dynamically reads available scripts and their functions to provide context-aware completion.
- Parses method names, parameters, and default values directly from the code, ensuring completions are always up-to-date (DRY principle).
- Integrates standard file, directory, user, group, alias, and environment variable completions for a seamless shell experience.
- Supports custom completions for specific parameters and methods, and can fall back to standard Bash completions.
- Is designed to be modular and extensible, allowing new scripts and methods to be added without duplicating completion logic.

### The "this" Boot Script
The `this` script is the bootstrapper and foundation of the environment:
- Sets up environment variables, logging, and debugging.
- Provides core utility functions for function existence checks, dynamic loading, and calling of script methods.
- Ensures that scripts and functions are loaded only once and are available for completion and execution.
- Manages the PATH and configuration sourcing, acting as the entry point for the modular script system.
- Embodies the DRY principle by centralizing logic for loading, calling, and managing scripts and their state.

For more details, see:
- [Outline](outline.md)
- [First Principles](first-principles.md)

## Command Creation System

Commands in oosh/once.sh are created using the `oo` script, which provides utilities for generating new scripts and methods:
- `oo.new <name>`: Creates a new script (command) from a template, with completion support.
- `oo.new.method <script.method>`: Adds a new method to an existing script, interactively updating the script with a method template.
- Templates for new scripts and methods are found in `templates/code/` (e.g., `newScript`, `newMethod`).
- Each new command is structured to support modular loading, completion, and usage documentation.

## Test System

Testing is managed by the `test.suite` system:
- Test scripts are generated using templates (e.g., `newScriptTest`) and placed in the `test/` directory.
- Each test script sources the command under test, the test suite, and sets up logging and environment.
- Tests are defined using `test.case` (to run a function and capture results) and `expect` (to assert return values and outputs).
- The test suite can run individual tests (`test.suite run <command>`) or all tests (`test.suite all`).
- Results are summarized, and success/failure is reported for each test case and the overall suite.

### Example: Creating and Testing a Command
1. `oo new mycmd` — creates `mycmd` script from template.
2. `oo new.method mycmd.hello` — adds a `hello` method to `mycmd`.
3. `oo.new.test mycmd` — creates `test/test.mycmd` from template.
4. Edit `test/test.mycmd` to add test cases for `mycmd` methods.
5. Run `test.suite run mycmd` or `test.suite all` to execute tests and see results.

For more details, see:
- [First Principles](first-principles.md)
- [Outline](outline.md)

## Test Suite Usage

The test suite is a core part of the oosh/once.sh development process. It ensures reliability, correctness, and safe refactoring. Here’s how it works:

### Structure
- All test scripts are located in the `test/` directory and named `test.<command>` (e.g., `test.mycmd`, `test.oosh`, `test.c2`).
- Each test script:
  - Sources `test.suite` for test utilities and result tracking.
  - Sets up the environment and logging level.
  - Defines test cases using `test.case` (to run a function/command) and `expect` (to assert results).
  - May use `expect.error` to check for expected failures.
  - Can source the command under test and other dependencies as needed.

### Running Tests
- To run a single test: `test.suite run <command>` (e.g., `test.suite run mycmd`)
- To run all tests: `test.suite all`
- Test results are summarized, showing the number of successful and expected cases, and reporting any failures.

### Example Test Script
```bash
source test.suite $*
log.init.colors
log.level $level

test.case - "direct call with parameter" \
  mycmd 3 f g 1 a b c
expect 0 "result not loaded" "$RESULT after a direct call"

# More test cases ...
```

### Best Practices
- Use `test.case` for each logical test scenario.
- Use `expect` to assert both return values and output.
- Use `expect.error` for negative tests (expected failures).
- Source the command under test and any required dependencies.
- Keep tests isolated and repeatable.

### Test Coverage
- The test suite covers a wide range of commands and scenarios, including core utilities, completion, file operations, and error handling.
- Example test scripts: `test.mycmd`, `test.check`, `test.c2`, `test.oosh`, `test.loop`, and many more.

For more details, see:
- [First Principles](first-principles.md)
- [Outline](outline.md)