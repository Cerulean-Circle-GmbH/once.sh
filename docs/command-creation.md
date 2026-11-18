# Command Creation System

## Overview
The oosh/once.sh project uses a modular, template-driven approach for creating new commands and methods. This ensures consistency, maintainability, and adherence to DRY principles.

## Creating New Commands
- Use `oo.new <name>` to generate a new script from a template.
- Scripts are placed in the project root and follow a standard structure.
- Completion and usage documentation are set up automatically.

## Adding Methods
- Use `oo.method.new <script.method>` to interactively add new methods to scripts.
- Methods are inserted using templates, ensuring consistent documentation and structure.

### Help metadata

An optional tag in the description field of the signature line controls the generated help:

- `# @group:<name>` — render the method under that section in `this.help`.
- `# @hidden` — omit the method from `this.help` and from `c2` completion; it stays callable.

A script that uses no tags keeps the old flat, alphabetical table. A script can fix section order by
defining `<script>.help.group.order`, one group per line.

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