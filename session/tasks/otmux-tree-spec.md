# Task: otmux.tree - Session/Pane Tree Overview

## User Directive
Add a tree overview command to otmux that shows all tmux sessions, panes, titles and addresses in a formatted tree. Make it the default output when starting otmux or running `otmux status`.

## Expected Output Format

```
tmux sessions
│
├── cursorOrchestrator (attached, Jan 29)
│   ├── 0.0  orchestrator              [claude 2.1.29]
│   ├── 0.1  product-owner             [claude 2.1.29]
│   ├── 0.2  agent-trainer             [claude 2.1.29]
│   ├── 0.3  task-agent                [claude 2.1.29]
│   ├── 0.4  oosh-expert               [claude 2.1.29]
│   ├── 0.5  oosh-tester               [claude 2.1.25]
│   └── 0.6  scrum-master              [claude 2.1.29]
│
├── claudeWoda (Feb 2)
│   ├── 0.0  OOSH Best Practices       [bash]
│   ├── 0.1  Monitor Design Issues     [claude 2.1.29]
│   ├── 0.2  zsh.commands              [zsh]
│   ├── 0.3  zsh.split                 [zsh]
│   └── 0.4  Claude Code               [bash]
│
├── agent (Feb 3)
│   ├── 0.0  Greeting Bot              [script]
│   ├── 0.1  MacStudio.default.shell   [zsh]
│   └── 0.2  MacStudio.oosh.shell      [bash]
│
└── test_yourself (attached, Jan 30)
    ├── 0.0  MacStudio.fritz.box        [bash]
    └── 0.1  MacStudio.fritz.box        [bash]
```

## Requirements
- Method name: `otmux.tree`
- Shows ALL tmux sessions with creation date
- Marks attached sessions
- Groups panes by window (if multiple windows, show window headers)
- Each pane shows: address (session:window.pane), title, running process in [brackets]
- Tree drawing with proper UTF-8 box characters (├── └── │)
- Aligned columns for readability
- Should be the default output for `otmux status` or bare `otmux`

## Plan
| Step | Agent | Action |
|------|-------|--------|
| 1 | Expert | Implement `otmux.tree` method with proper OOSH patterns |
| 2 | Expert | Wire it as default for `otmux status` |
| 3 | Tester | Validate output format matches spec |
| 4 | Tester | Verify Tab completion includes `tree` method |

## Status
- [ ] Step 1
- [ ] Step 2
- [ ] Step 3
- [ ] Step 4
