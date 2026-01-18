# Completion System

## Overview
The oosh/once.sh project features a dynamic Bash completion system, primarily implemented in the `c2` script. This system provides context-aware completions for commands, methods, parameters, and integrates standard Bash completions.

## Main Features
- Reads available scripts and their functions for completion.
- Parses method parameters and default values directly from code.
- Integrates standard file, directory, user, group, alias, and environment variable completions.
- Supports custom completions for specific parameters and methods.
- Designed for extensibility and DRY (Don't Repeat Yourself) principles.

## How It Works
- The `c2` script scans scripts for function signatures and documentation.
- Completion logic is modular and can be extended for new scripts and methods.
- Parameter and default value parsing is automatic, reducing duplication.

## Advanced Usage
- Custom completions for advanced scenarios.
- Debugging and troubleshooting completion issues.

## See Also
- [test-suite.md](test-suite.md) (for completion/parameter test cases)
- [command-creation.md](command-creation.md)
- [first-principles.md](first-principles.md)