# Command Creation System

## Overview
The oosh/once.sh project uses a modular, template-driven approach for creating new commands and methods. This ensures consistency, maintainability, and adherence to DRY principles.

## Creating New Commands
- Use `oo.new <name>` to generate a new script from a template.
- Scripts are placed in the project root and follow a standard structure.
- Completion and usage documentation are set up automatically.

## Adding Methods
- Use `oo.new.method <script.method>` to interactively add new methods to scripts.
- Methods are inserted using templates, ensuring consistent documentation and structure.

## Templates
- All new scripts and methods are based on templates in `templates/code/`.
- Templates enforce best practices and modular design.

## Best Practices
- Keep commands focused and modular.
- Document each method and parameter.
- Use the test suite to validate new commands and methods.

## See Also
- [test-suite.md](test-suite.md)
- [completion-system.md](completion-system.md)
- [first-principles.md](first-principles.md)