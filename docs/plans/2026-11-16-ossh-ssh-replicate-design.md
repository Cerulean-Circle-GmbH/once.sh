# ossh ssh.replicate — replicate /root/.ssh to every user

**Date:** 2026-11-16
**Status:** approved design, not implemented

## Goal

One command copies the whole `/root/.ssh/` directory into the `~/.ssh` of every
normal user — on this machine or on a remote Host entry.

```bash
ossh ssh.replicate            # this machine
ossh ssh.replicate myhost     # that host, through the Host block
```

The source is always `/root/.ssh` on the machine doing the work. There is no
user list and no source argument.

## Non-goals

- No public-key-only mode: `ossh key.push` already does that.
- No exact mirror: user files that are not in `/root/.ssh` stay.
- No user creation, no oosh install, no password changes.

## Accounts

A "normal user" is a real home directory under `/home` on Linux or `/Users` on
macOS, skipping `shared` and `Shared`, verified with `id`. Root is skipped
because it is the source. This mirrors `private.ossh.user.homes.get`.

## Behaviour

1. **Privilege.** The command needs root or working sudo. Locally the normal
   `$SUDO` may prompt. On a remote host the ssh command has no tty, so it needs
   root or passwordless sudo; otherwise rc 1 with a clear RESULT before any
   account is touched.
2. **One ssh call for remote mode.** After `ossh.connection.open`, a single
   remote POSIX shell script enumerates accounts, copies, fixes ownership and
   prints one line per account. Local mode runs the same script under `$SUDO`.
3. **Per account:**
   - `mkdir -p ~/.ssh`
   - copy every entry from `/root/.ssh/` into `~/.ssh/`, overwriting same names
     and keeping the user's other files
   - `chown -R <user>` the result (primary group)
   - modes: `~/.ssh` 700; private keys, `config` and `authorized_keys` 600;
     `*.pub`, `known_hosts` and `known_hosts.old` 644
4. **Continue on failure.** One unwritable home does not stop the rest. Each
   account produces `ok <user>` or `FAILED <user>: <reason>`.
5. **Result.**
   - rc 0: `replicated /root/.ssh to <n> users on <machine> (including private keys)`
   - rc 1: the same summary naming the failed accounts, or the
     connection/privilege/source error
6. **Source missing.** No `/root/.ssh` means rc 1 with a RESULT; nothing is
   written.

## Safety

The command copies private keys, not just `authorized_keys`. Every normal user
can afterwards authenticate as root to everything root's keys reach. The method
logs a warning that says so. There is no prompt: running the command is the
intent.

`~/.ssh` that is a symlink is written through, as other oosh methods do.

## Files

| File | Change |
|------|--------|
| `ossh` | `ossh.ssh.replicate()` plus a private remote-script builder |
| `docs/ossh.md` | method table row and a short Key Management section |
| `test/test.ossh` | `T-OSSH-SSH-REPLICATE` with a fake home tree |

Generated indexes (`docs/methods-index.md`, `docs/object-verb-index.md`,
`docs/parameter.md`) are produced by `oosh-architect`; update them only if the
generator is available.

## Tests

One test case with a fixture home tree:

- copies over same-named files and keeps extras
- sets `~/.ssh` 700, private keys 600, `.pub`/`known_hosts` 644
- skips `shared`
- skips a directory whose basename is not a user
- one failing account does not stop the others; rc 1 and the failure is named
- no `/root/.ssh` → rc 1, nothing written
- no root/sudo → rc 1 before any write
