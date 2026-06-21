# otmux Clipboard — Copy/Paste in Local and Remote (SSH) Sessions

Copy/paste in tmux has a subtle problem over SSH: the default `pbcopy` / `xclip`
bindings write to the **remote** machine's clipboard, which is useless when you
are sitting at a different machine.

otmux handles both cases automatically.

## Quick Summary

| Scenario | Mode | How copy works |
|----------|------|---------------|
| Local tmux on macOS | `pbcopy` | tmux pipes selection to local `pbcopy` |
| Local tmux on Linux | `xclip`/`xsel` | tmux pipes selection to local clipboard helper |
| **SSH → remote tmux** | **OSC 52** | **tmux emits an escape sequence, your local terminal writes to local clipboard** |

otmux auto-detects SSH sessions via `SSH_CONNECTION` / `SSH_TTY` and picks OSC 52.

## Starting With The Right Mode

`otmux setup.default` runs on the first session creation and calls
`private.otmux.setup.clipboard`, which auto-detects:

```bash
otmux setup.default                # auto-detects SSH vs local
otmux setup.clipboard.remote       # force OSC 52 (remote-aware)
otmux setup.clipboard.local        # force pbcopy / xclip (local)
```

## How OSC 52 Works

1. You select text in a tmux pane with the mouse (or `v` in copy-mode).
2. tmux emits an OSC 52 escape sequence: `\e]52;c;<base64>\a`
3. Your SSH client's terminal (on the LOCAL machine) reads the stream,
   recognizes OSC 52, decodes the base64, and writes to your local clipboard.
4. `Cmd+V` in any local app pastes the text.

No remote agent, no X forwarding, no clipboard daemon. Just a terminal escape.

## Terminal Support — What You Need On Your Local Machine

OSC 52 is a terminal feature, not a tmux feature. Your local terminal must
accept it:

| Terminal | OSC 52 support | Setup |
|----------|---------------|-------|
| **iTerm2** | Yes | Preferences → General → Selection → **"Applications in terminal may access clipboard"** ON |
| **WezTerm** | Yes | On by default |
| **kitty** | Yes | `clipboard_control write-clipboard write-primary` (default) |
| **Alacritty** | Yes | Add `mouse.bindings = [...]`, or enable via terminal OSC |
| **Terminal.app (macOS 13+)** | Partial | Limited — prefer iTerm2 |
| **Windows Terminal** | Yes (recent) | On by default |
| **xterm** | Yes (opt-in) | `XTerm*disallowedWindowOps: 20,21,SetXprop` remove `52` |

If you can copy but nothing lands in the local clipboard, **check this setting first.**

## Using Copy/Paste

### Copy (from tmux pane → local clipboard)

**Mouse method (easiest):**
1. Click and drag to select text in a pane
2. On release, tmux copies — your local clipboard now has the text
3. `Cmd+V` anywhere on your local Mac

**Keyboard (copy-mode):**
1. `Ctrl+b [` → enters copy-mode
2. `v` → start selection, arrow keys / vim motions to extend
3. `y` or `Enter` → copy + exit copy-mode
4. `Cmd+V` locally

### Paste (local clipboard → tmux pane)

Just press `Cmd+V` in your terminal. The terminal types the characters into
the SSH stream; tmux treats them as regular input.

tmux's own paste buffer (prefix `]`) pastes from tmux's internal buffer (last
thing copied *inside* tmux) — different from your local clipboard and not
usually what you want.

## Troubleshooting

### Copy appears to work but local clipboard is empty

Your local terminal is discarding OSC 52. Check:

```bash
echo $TERM                         # should be screen-*, tmux-*, or xterm-256color
tmux show-options -g set-clipboard # should be 'on'
```

Then enable the "allow clipboard access" setting in your local terminal.

### Mouse select doesn't copy

```bash
tmux show-options -g mouse         # should be 'on'
otmux setup.default                # re-applies mouse + clipboard
```

### Nested tmux (tmux inside tmux over SSH)

Set `allow-passthrough on` (already done by `setup.clipboard.remote` on
tmux 3.3+) so the inner tmux can forward OSC 52 through the outer one.

### Paste dumps garbage with quotes/newlines

Enable bracketed paste:

```bash
tmux set -g set-clipboard on
# Modern tmux + terminal combinations do this automatically.
```

### Very long selections get truncated

Some terminals cap OSC 52 payload size (iTerm2: ~unbounded; xterm: usually
at ~74KB by default). For huge copies, use `tmux save-buffer` to write to a
file instead, then `scp` it.

## What Changed in otmux

Before: macOS `darwin` branch used `pbcopy` — which on a remote MacStudio
copies to MacStudio's clipboard, not the laptop's. Users over SSH saw nothing
in their local clipboard.

After: `private.otmux.setup.clipboard` checks `$SSH_CONNECTION` / `$SSH_TTY`
first and switches to OSC 52 mode (`copy-selection-and-cancel` + `set-clipboard
on`). Local sessions still get `pbcopy`/`xclip` behavior.

## Related

- `otmux setup.default` — applies all defaults including clipboard
- `otmux reload` — reloads `~/.tmux.conf` + re-applies clipboard
- [docs/tmux.claude.code.color.issue.md](tmux.claude.code.color.issue.md) — a different tmux-over-SSH color quirk
