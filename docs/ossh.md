# ossh — SSH Management for oosh

The `ossh` script wraps SSH operations following oosh conventions: key management, config generation, remote installation, and multi-hop connections.

## Overview

- Manages SSH keys, configs, and connections via oosh methods
- Installs oosh on remote hosts over SSH
- Supports multi-hop connections via ProxyJump keyword
- Naming: `tmux→otmux, ssh→ossh, docker→odocker`

## Quick Start

```bash
# Create SSH config for a host
ossh config.create myhost user@hostname:port
ossh config.show.last
ossh config.save.last

# Push your SSH key (for password-less login)
ossh key.push myhost

# Install oosh on the remote host
ossh install myhost username
```

## SSH Config Management

### Creating Configs

```bash
# Two-argument form: alias + URL
ossh config.create myserver admin@192.168.1.100:22

# Single-argument form: auto-derives alias from URL
ossh config.create admin@192.168.1.100

# With specific identity file
ossh config.create myserver admin@192.168.1.100 ~/.ssh/id_ed25519

# With ProxyJump for multi-hop connections (key auto-detected)
ossh config.create myvm admin@192.168.64.5 proxyJump macstudio

# With both explicit key and ProxyJump
ossh config.create myvm admin@192.168.64.5 ~/.ssh/id_ed25519 proxyJump macstudio
```

### Preview, Save, and List

```bash
# Show the last generated config block
ossh config.show.last

# Save it to ~/.ssh/config
ossh config.save.last

# List all configured hosts
ossh list
```

`config.create` writes its block to its own file (`private.ossh.config.last.file.get`,
`$CONFIG_PATH/ssh.config.last`) and, as before, a copy to `$CONFIG_PATH/result.txt` for
`config.show.last`. `config.save.last` appends **only** that block:

- it checks it is one Host block (the first line `Host <name>`, no second `Host`, every other
  line an indented `<Keyword> <value>`), else rc 1 "… is no single Host block — not appended"
- a Host the file already has: rc 1 "already exists — not appending duplicate", as before
- no last block: rc 1 "ossh config.create first"
- an existing file is written in place after the checks (owner and mode stay); a new file is made 600
- rc 0 + RESULT `appended <name> to <file>` (T-OSSH-CONFIG-SAVE-LAST)

Until 2026-10-19 it appended the whole `result.txt`, a scratch file: with live logging
(`LOG_LIVE`, on by default) `console.log`, `success.log` and `error.log` tee into it, and
`ossh config.get` overwrites it. A log line between create and save landed in `~/.ssh/config`, ssh
then refused the whole file ("Bad configuration option") and every login of that user failed
(review meeting 2026-10-15).

### Deleting a Config

```bash
# Remove the Host block of myvm from ~/.ssh/config (or from <file>)
ossh config.delete myvm
ossh config.delete myvm ~/some/other/ssh.config
```

The block is what `ossh config.get` shows: from `Host <name>` to the next empty
line. The other blocks, the file's mode and its empty lines stay, so a later
`ossh config.save.last` still appends a separate block. A host that is not
there answers rc 2 "not found" (T-OSSH-CONFIG-DELETE).

### Pulling a Config from another Host

```bash
# Copy the Host block demo of myhost's ~/.ssh/config into ~/.ssh/config (or into <file>)
ossh config.pull myhost demo
ossh config.pull myhost demo ~/some/other/ssh.config

# Without a name: the Host names myhost has
ossh config.pull myhost
```

`config.push` the other way around. The block is what `ossh config.get` shows
on `myhost`: from `Host <name>` to the next empty line; it is added after an
empty line, and the file is written whole (atomic, its mode kept, a new one
600). A Host the file already has stays as it is — rc 0 "already in <file>";
`ossh config.delete <name>` first to replace it. rc 1 + RESULT when the name
is no Host name (only letters, digits, `.`, `_`, `@`, `-`; checked before the
host is asked), when `myhost` has no such block, or when the file cannot be
written (T-OSSH-CONFIG-PULL). `<remoteConfigName>` has no Tab completion: the
names are on the other host (T-OSSH-CONFIG-PULL-COMPLETION).

The block is `myhost`'s: an `IdentityFile` or `ProxyJump` in it names a key
file or a Host of that computer — check them here (`ossh config.get <name>`).

Until 2026-10-19 it asked the host for a command that no longer exists
and appended the answer, nothing or an error line,
with rc 0.

### Changing one Field of a Host

```bash
ossh config.set myhost port 2222          # replace the Port line of Host myhost
ossh config.set myhost proxyJump bastion  # no ProxyJump yet: added below the Host line
ossh config.field.get myhost port         # 2222
```

Marcel's design (test/mcdonges.latest, March 2026), rebuilt on dev on 2026-10-19. Seven fields;
Tab completes the Host, the field and then what that field takes:

| `<field>` | ssh keyword | `<value>` checked | Tab offers |
|---|---|---|---|
| `identityFile` | IdentityFile | one line | `~/.ssh/ids/*/id_*` and `~/.ssh/id_*` (no `.pub`) |
| `user` | User | one line | git root deploy ubuntu |
| `port` | Port | 1 to 65535 | 22 443 2222 8022 |
| `hostName` | HostName | one line | — |
| `proxyJump` | ProxyJump | one line | the Hosts |
| `forwardAgent` | ForwardAgent | yes or no | yes no |
| `identitiesOnly` | IdentitiesOnly | yes or no | yes no |

The block is what `ossh config.get` shows: from `Host <name>` to the empty line or the next
`Host`; the Host is compared as a string (`s.cond` is not `second`). An existing line of the
keyword — whatever its case in the file — is replaced and keeps its indent (RESULT
`<Keyword> <value> set in Host <name> (replaced)`); without one the line goes right below the
Host line (`(added)`). The file is written whole with `private.this.file.write`: atomic, its
mode and group kept, a trailing empty line kept. An unknown Host or field, a missing argument or
a value the field does not take is rc 1 + RESULT, and the file stays byte for byte
(T-OSSH-CONFIG-SET). `config.field.get` echoes only the value; rc 1 when the Host, the field or
its line is not there (T-OSSH-CONFIG-FIELD-GET).

Each field has its own `private.ossh.config.<field>.get|set` (the setter carries the value
completion); `ossh config.set` dispatches to them. Changed against Marcel's version: the
`.tmp` + `mv` write (it gave a new `~/.ssh/config` the umask mode — 664 under umask 002, which
ssh refuses), the unchecked values, the Host used as a pattern, and the value completion, which
read the field from `$2` (the class name; it is `$PARAM_field` —
[completion-system.md](completion-system.md)) (T-OSSH-CONFIG-SET-COMPLETION).

### Generated Config Format

```
Host myserver
 User admin
 Port 22
 HostName 192.168.1.100
 IdentityFile ~/.ssh/id_ed25519
```

With ProxyJump:

```
Host myvm
 User admin
 Port 22
 HostName 192.168.64.5
 IdentityFile ~/.ssh/id_ed25519
 ProxyJump macstudio
```

## ProxyJump — Multi-Hop SSH

ProxyJump connects to a final destination through an intermediate "jump host". Use this when the target machine is on a private network only reachable from the jump host.

### How It Works

```
Your machine  ──SSH──>  Jump host  ──tunnel──>  Target machine
(Ubuntu VM)             (Mac Studio)             (tart VM)
                        public IP                private IP
                        home.donges.it:9922      192.168.64.5
```

Without ProxyJump, `192.168.64.5` is unreachable — it is on the Mac Studio's internal network. ProxyJump automates the connection:

1. SSH connects to the jump host
2. From there, opens a tunnel to the target
3. Your session flows through the tunnel transparently

### Setup

Create the jump host config first (it must exist before you reference it):

```bash
ossh config.create macstudio donges@home.donges.it:9922
ossh config.show.last
ossh config.save.last
```

Then create the target config with the `proxyJump` keyword:

```bash
ossh config.create tart_sequoia admin@192.168.64.5 proxyJump macstudio
ossh config.show.last
ossh config.save.last
```

The `proxyJump` keyword tells ossh to add a `ProxyJump macstudio` line to the SSH config. SSH resolves `macstudio` by looking up `Host macstudio` in the same `~/.ssh/config` file — that is why the jump host config must be created and saved first.

Now all ossh commands reach the target through the jump host:

```bash
ossh key.push tart_sequoia      # pushes key through macstudio
ossh install tart_sequoia admin  # installs oosh through macstudio
ossh login tart_sequoia          # interactive login through macstudio
```

### When to Use ProxyJump

- VMs behind a host (tart/UTM VMs on a Mac Studio)
- Docker containers accessed through a remote host
- Servers on private networks reachable only from a bastion/gateway
- Any target where you need to hop through an intermediate machine

## Key Management

```bash
# Create a new SSH key pair
ossh id.create mykey

# List available keys
ossh list.ids

# Push a key to a remote host
ossh key.push myhost

# Pull a remote host's key here and let it log in to this computer
ossh key.pull myhost

# Put the Host block demo into a remote host's SSH config (replaced there, or added)
ossh config.push myhost demo

# Pull a Host block from a remote host's SSH config
ossh config.pull myhost demo

# Change one field of a Host block
ossh config.set myhost port 2222
```

### Who may log in: `public_keys/` and `authorized_keys`

`~/.ssh/public_keys/` is the list; `~/.ssh/authorized_keys` is built from it
by `user authorized.keys.update` — the one rebuild, which `ossh key.push` runs
on the target. Revoking a key moves its file to `~/.ssh/deactive.public_keys/`
and rebuilds.

A key that is only in `authorized_keys` — put there by the hoster, by hand, or
before oosh was installed — gets a file `public_keys/adopted.<comment>.public_key`
first, so the rebuild keeps it. A revoked key (file in `deactive.public_keys/`)
stays out. Keys are compared by the key itself, not by file name. Before
2026-10-15 the rebuild deleted such keys: on POL.dev the first `ossh key.push`
after the install removed the Mac Studio's RSA key, and root's login asked for
a password again (T-USER-AUTHORIZED-KEYS-ADOPT). The adopt's writes are
checked (`private.this.folder.ensure`, `private.this.file.write`): when
`public_keys/` or a key file in it cannot be written, the rebuild stops with
rc 1 and `authorized_keys` stays byte for byte — until 2026-10-16 the key was
dropped in silence and the rebuild swapped in an `authorized_keys` without it,
the same lockout. An adopted file, like every new file the kernel's write
makes, is 600.

The rebuild writes the new `authorized_keys` completely first and then swaps
it in (`authorized_keys.new`, then a rename — `private.this.file.write`); each
key file ends its own line. Until 2026-10-16 it deleted the file and then
appended `public_keys/*`: in between, and for good when a step failed, the user
had no `authorized_keys` at all (T-USER-AUTHORIZED-KEYS-REBUILD-ATOMIC). No
`.bak` is left in `~/.ssh`; a failed write leaves the old file and no `.new`.
`~/.ssh` stays 700, `authorized_keys` 600.

`ossh authorized.keys.update <?sshDir>`
is the same rebuild through ossh. Both return:

| rc | RESULT | authorized_keys |
|----|--------|-----------------|
| 0 | `authorized_keys of <sshDir> rebuilt from public_keys/` | the new one |
| 1 | `no ssh set up in <sshDir> — authorized_keys left as it is` (no private key there) | untouched |
| 1 | `cannot read <file> …` / `cannot write …` — `… left as it is` | untouched |

Where ossh writes a target's `authorized_keys` itself — `ossh install <host> <user>`,
and `key.push` to an oosh without `authorized.keys.update` — it only adds the
pushed key (`private.ossh.authorized.key.append.get`, T-OSSH-AUTHORIZED-KEY-APPEND).

`key.push <toHost> <?keyName> <?sshDir>` without a key name pushes the own key
of `<sshDir>` (the one in its `private_key/`); an empty `""` key name keeps its
place, so `ossh key.push <host> "" <sshDir>` pushes that sshDir's key — before
2026-10-16 the `""` swallowed the `<sshDir>` and the key was named from the
default sshDir. The Host entry must log in with that key —
`ossh config.create` writes `IdentityFile ~/.ssh/id_ed25519`; an older
hand-written entry may name another key (`id_rsa`), and then needs
`ossh key.push <host> <file in public_keys/>`. key.push says how it ended:

| rc | RESULT |
|----|--------|
| 0 | `<keyName> authorized on <toHost> (rebuild)` — the host's oosh rebuilt its `authorized_keys` |
| 0 | `<keyName> added to <toHost>'s authorized_keys` — no oosh there (or no ssh set up), the key was only added |
| 1 | `could not authorize <keyName> on <toHost>` — both ways failed (error.log) |
| 1 | the RESULT of `connection.open` or of the key copy, when that fails first |

(T-OSSH-REMOTE-PUBLIC-KEY-PUT; before 2026-10-16 the push ended with the rc of
the fallback pipeline, no RESULT, and a failed fallback said nothing.)

`key.pull <fromHost> <?remoteKeyName> <?sshDir>` is `key.push` the other way around:
it gets `<fromHost>:~/.ssh/public_keys/<remoteKeyName>` (by default the host's own
key file) into `<sshDir>/public_keys/<remoteKeyName>` and runs the local
rebuild. The host's own key is the `~/.ssh/private_key/<name>.private_key`
there that has its `public_keys/<name>.public_key`, read with a POSIX listing
(`private.ossh.remote.key.file.name.get`) that writes nothing and needs no oosh
on the host. Until 2026-10-16 it asked the host `ossh file.get.name` (on an
older oosh `ossh id.file.get`), which on a host without `private_key/` made a
key name and ran `config save ssh.info` THERE (T-OSSH-REMOTE-KEY-FILE-NAME-GET).
A host without oosh keys (Termux) gives its
`~/.ssh/id_*.pub`, kept as `<fromHost>.<type>.public_key`. Before 2026-10-16 it
asked for a method dev had renamed, pulled `~/.ssh/<name>.pub` as
`<name>.public_key.pulled` and never ran the rebuild (T-OSSH-KEY-PULL).
Names stay in `public_keys/`: a `'` in `<remoteKeyName>` is dropped (as
key.push does), a name with a `/` (or `.`/`..`) is refused with rc 1 before
the host is asked, and a remote answer with a `/`, a space or a `'` is no name
— a name like `../x` would have read and written outside `public_keys/`.
`..` inside a name (`user..public_key`, a key from before the hostname fix)
stays allowed: without a `/` it cannot leave the folder.
`<sshDir>` is the LOCAL folder the key lands in; on `<fromHost>` it is always
`~/.ssh/public_keys/`. key.pull is rc 1 when it finds no key (what
`private.user.authorized.key.get` reads as one) or cannot save it; a key saved
while this computer has no ssh set up is rc 0 with a warning — the rebuild
said no, the next one authorizes it.

A key without an oosh key file is named `<owner>.<type>.public_key` both ways:
key.pull uses the Host name (`phone.id_ed25519.public_key`), `ossh install`
this computer's oosh key name `<user>.<host>` (`hannesn.mybox.id_ed25519.public_key`;
before 2026-10-16 `<user>.<type>.public_key`, so a key installed earlier may
have a second file, and the key stands twice in `authorized_keys` — sshd takes that).

Tab on `key.push` / `key.pull` completes per parameter: hosts, and for
`key.push` this computer's `public_keys/` (`<keyName>`); `key.pull`'s
`<remoteKeyName>` is a file on the other host and offers nothing — a listing
would ask the password on Tab. It was `<keyName>` with an empty
`ossh.key.pull.completion.keyName`: c2 takes an empty answer as "no
completion" and asks `ossh.parameter.completion.keyName` next, so Tab listed
this computer's keys after all (T-OSSH-KEY-COMPLETION). `remoteKeyName` is
on the free-text list of `test/test.completion.audit`.

### First contact with only a password

`ossh connection.open` opens one shared connection; the password is asked
once. Its socket path (`private.ossh.control.path.get`) is
`${TMPDIR:-/tmp}/ossh-%C` only when that fits a Unix socket, else
`/tmp/ossh-%C`, else `~/.ssh/ossh-%C`. Before 2026-10-16 the long TMPDIR of
macOS (49 characters) made it too long: `connection.open` always failed,
`ossh key.push` asked the password five times and said "Failed to connect",
and the key still landed (T-OSSH-CONTROL-PATH-SHORT).

The socket a host's master really uses is `$OSSH_CONTROL_PATH` with `%C`
expanded — a hash only ssh knows. `private.ossh.control.path.resolved.get
<host>` asks `ssh -G` (which prints the configuration and connects to
nothing) and echoes it; nothing and rc 1 without a host, or when ssh answers
`none` or a path that still has a `%`. `os platform.test` closes a stale
master with `ossh connection.close` and then removes that socket; until
2026-10-16 it removed `/tmp/ossh-test@localhost:<port>`, a name from before
`%C` that never existed (T-OSSH-CONTROL-PATH-RESOLVED-GET).

A failed connection now says ssh's reason (e.g. `Permission denied`) and stops
`key.push` / `key.pull` / `config.push` / `dir.push` / `dir.pull` / `id.push`
and `ossh install`; `-4` is retried only after a
network error (T-OSSH-CONNECTION-OPEN-FAIL). The reason is
`private.ossh.connection.error.get` (the last line of ssh's stderr that is no
"Warning: Permanently added"); which reasons count as a network error is
`private.ossh.connection.error.network.is`; both attempts are
`private.ossh.master.start`. ssh's stderr lives in a private temp dir
(`private.this.temp.dir.get`) that is removed on every way out.

**A client that cannot multiplex stops here too.** These steps need the
ControlMaster; until 471b0e01 (2026-10-16) a failed `connection.open` was ignored and
every step opened its own connection. On a client without ControlMaster
support — native Win32 OpenSSH (Windows' `ssh.exe`) has none — that "worked"
with one password prompt per step; now the step stops after the failed
`connection.open` with its RESULT. Use an ssh that multiplexes (WSL, Git for
Windows' / MSYS2's OpenSSH, Cygwin) or push the key once by hand
(`ssh-copy-id`), so the master is not needed for a password.

`key.push` and `ossh install` copy the key file with
`private.ossh.remote.public.key.put`; when that copy fails, `key.push` stops
with rc 1 instead of rebuilding the target's `authorized_keys` without it
(T-OSSH-REMOTE-PUBLIC-KEY-PUT). The copy runs `umask 077`, makes
`~/.ssh/public_keys` and sets `~/.ssh` to 700 on the target: under the
target's own umask (pam_umask 002) a new `~/.ssh` was 775, and sshd's
StrictModes then ignores every key in it — the push "worked" and the login
still asked the password (T-OSSH-REMOTE-PUBLIC-KEY-PUT-MODES). A new key file
there is 600.

`ossh install <host>` adds the installer's key to the host's `public_keys/` and
`authorized_keys` right after the connection opens — only added — and checks a
key login; when that fails, a warning names the Host entry's IdentityFile
(T-OSSH-INSTALL-PUSHES-KEY). Its remote half, `private.ossh.oosh.init.push`,
says its result on every
path (T-OSSH-OOSH-INIT-PUSH-RESULT):

| rc | RESULT |
|----|--------|
| 0 | `oosh installed on <host> and finished here` |
| 0 | `oosh already on <host> (state [99] \| ~/oosh exists) and finished here` — the bootstrap is skipped |
| 1 | `could not transfer init/oosh to <host>` |
| 1 | `the oosh installer on <host> failed (rc <n>)` |
| 1 | `oosh installed on <host>, but ossh.install.finish.local failed` (or `oosh already on …, but …`) |
| 1 | the RESULT of `connection.open` or of the installer's key, when that fails first |

The copy helpers say theirs too (T-OSSH-PUSH-PULL-RESULT), each rc 1 + RESULT
+ error.log for a missing argument, a failed connection or a failed copy:
`private.ossh.config.push <toHost> <?sshConfigName>` (`<name> added to` /
`<name> replaced in <toHost>:~/.ssh/config`; without a name nothing is pushed, rc 0 —
see "Pushing a Config" below),
`private.ossh.dir.push <toHost> <dir>` (`<dir> copied to <toHost>`),
`private.ossh.dir.pull <fromHost> <dir>` (`<fromHost>:<dir> copied here`) and
`private.ossh.id.push <toHost> <id> <?sshDir>` (`<id> copied to
<toHost>:~/.ssh/ids/`; a missing `<sshDir>/ids/<id>` is rc 1 before any
copy). Until 2026-10-16 they had verb-first names
(T-OSSH-RENAMES-OBJECT-VERB) and ended with a bare `return 1` or the copy's
rc; the public `ossh config.push` / `dir.push` / `dir.pull` / `id.push` keep
their names.

### Pushing a Config

`ossh config.push <toHost> <sshConfigName>` puts the local Host block into `~/.ssh/config` on
`<toHost>` in one ssh call, the block on stdin; the host runs POSIX commands from
`private.ossh.config.block.put.get` — no rsync and no oosh needed there:

| On the host | Then | RESULT |
|---|---|---|
| no block of that name | appended after an empty line (a new `~/.ssh` 700, a new config 600) | `<name> added to <host>:~/.ssh/config` |
| one or more blocks of that name | the first replaced **in place** (a `Host *` before it keeps deciding), the others dropped | `<name> replaced in <host>:~/.ssh/config` |

The file is written back with `>`, so its owner and mode stay. Refused with rc 1 before the
host is asked: a name that is no Host name (only letters, digits, `.`, `_`, `@`, `-`) and a
name that is not in the local config. A failed host is rc 1 `could not put <name> into …`
(T-OSSH-CONFIG-BLOCK-PUT, T-OSSH-CONFIG-PUSH).

Until 2026-10-19 it copied a temp file with rsync into the host's `~/config` (after a
`sudo chown -h` there) and appended it with `>>`: a second push gave a second block, ssh reads
only the first, so a block changed with `config.set` had no effect there; an unknown name
answered rc 0 "appended" and added an empty line; a bare host without rsync failed (lab cplab).

`user authorized.keys.update` returns 1 when the user has no ssh set up (no
private key in the sshDir), so `key.push`'s add-only fallback takes over
(T-USER-AUTHORIZED-KEYS-UPDATE-RC). On a host without oosh, `key.push` asks
for `user` first and goes straight to that fallback — no "user: command not
found" any more (T-OSSH-KEY-PUSH-BARE-QUIET).

## Repairing a Broken `~/.ssh`

A fresh OOSH install lays down a canonical `~/.ssh` tree via `osshLayout build` (idempotent roles for owner, developking, installer, outeruser, closed by `private.osshLayout.perms.tighten`). On older machines that were installed before the Phase 2 layout work, the tree may have drifted — forbidden symlinks where real files are required, wrong perms (775/777 on private keys), legacy artifacts from earlier OOSH versions.

Three commands handle this:

```bash
# Diagnose drift (read-only, returns 0 even with findings)
ossh folder.fix.check

# Repair: converge ~/.ssh to canonical state (conservative — never deletes)
ossh folder.fix

# Repair + also prune known-stale legacy artifacts (.bak.*, .previous, 2cuGitHub, no_deploy_keys, ssh-copy-id.*)
ossh folder.fix strict

# Re-assert canonical perms only (700 dirs, 600 privkeys, 644 pubkeys)
ossh rights.fix
```

`ossh folder.fix` is idempotent and uses three-tier identity resolution. If the installer email is already known from existing `~/.ssh/ids/ssh.*/` directories, no args are needed — discovery happens automatically. Otherwise, pass the email explicitly:

```bash
ossh folder.fix me@example.com
ossh folder.fix me@example.com ~/.ssh strict
```

Strict mode **never** deletes `authorized_keys`, `id_rsa`, or `config`. It only removes documented legacy patterns. User-authored content is always preserved.

## Remote Installation

```bash
# Install oosh on a remote host
ossh install myhost

# Install and set up a specific user
ossh install myhost username
```

What happens during install:

1. Opens persistent SSH connection (password entered once)
2. Transfers `init/oosh` bootstrap script
3. Runs remote installer (installs bash 4+, git, etc.)
4. Sets up the clone for the current branch
5. Copies deploy key for GitHub access (if available)
6. Creates user account and symlinks
7. Sets login shell to bash 4+

### Prereqs (`ossh prereqs.install`)

If the remote is missing oosh's install-time tools, run `ossh prereqs.install <host>` first. It installs the package list appropriate to the remote's package manager (detected via `ossh pm.discover`):

| PM | Packages installed | Post-install |
|---|---|---|
| `apt-get`, `dnf`, `pacman`, `pkg` | `curl`, `git` | — |
| `apk` (Alpine) | `curl`, `git`, **`bash`**, **`shadow`**, **`util-linux`** | `chmod u+s /bin/busybox` |
| `brew` (macOS) | `curl`, `git`, **`bash`** | write `/etc/paths.d/oosh-homebrew` |

The Alpine extras are required because alpine's base image ships only busybox + ash:
- `bash` — oosh's `#!/usr/bin/env bash` shebangs
- `shadow` — `useradd`/`chpasswd` (busybox `adduser` differs in flags)
- `util-linux` — `runuser`, used by `os platform.test` for user-switching
- `chmod u+s /bin/busybox` — naked alpine ships busybox at mode 0755; the suid bit is needed for non-root `su -` (so `user login <user>` works from a regular user's shell). Real alpine deployments typically ship busybox suid by default. The same chmod also fires from `init/oosh` after its sudo re-exec, so curl/drag-and-drop install paths get the heal too.

The macOS extras are required because Apple's `/bin/bash` is 3.2 (their last GPLv2 release) but oosh requires bash 4+:
- `bash` — installs `/opt/homebrew/bin/bash` (5.x).
- `/etc/paths.d/oosh-homebrew` — macOS sshd builds non-interactive PATH via `path_helper`, which reads `/etc/paths` + `/etc/paths.d/*`. `/opt/homebrew/bin` is NOT in either by default, so even with brew bash on disk, ssh-exec'd shebangs (`#!/usr/bin/env bash`) resolve to `/bin/bash` 3.2. Wiring the entry once via paths.d benefits every non-interactive ssh session on the host.

The remote install runs over ssh+sh (no bash on remote required), so this works on a fresh naked alpine box where bash doesn't yet exist, and on a stock macOS where only the system 3.2 bash is present.

### GitHub access

`ossh install` gives every user on the target a working `github.com` SSH alias for cloning from `Cerulean-Circle-GmbH` (`git clone git@github.com:…`, `oo update`, `oo checkout`). Two pieces:

1. **The key.** `~/.ssh/ids/ssh.developking/id_rsa`, which `osshLayout.role.developking` places for every user. It was downloaded during state 31 from the oosh templates server (`test.wo-da.de`) or the local `templates/user/developking.ssh/` fallback. `developking` is an ordinary user (it owns none of the shared folders) and is also the remote account in `Host WODA.dev`; nothing reads the key from `~developking/.ssh` any more.
2. **The alias and GitHub's host key**, once for the whole host — see [GitHub for every user](#github-for-every-user). State 31 sets them up before its first clone; `ossh install` runs the same on the target (`ossh config.shared.seed.github`).

If the key could not be downloaded (test.wo-da.de unreachable AND no local templates), install still succeeds — only the GitHub access is missing. A `warn.log` line flags this.

## Hardening

`ossh.harden` is invoked **after** `ossh install` finishes, on Debian/Ubuntu
remotes only. It applies a standard baseline: unattended-upgrades,
fail2ban, UFW, and an opinionated sshd_config. User creation and SSH-key
distribution are deliberately **not** repeated here — `ossh install` did
that already; `ossh.harden` only adds the security layers.

```bash
ossh install myhost admin        # sets up users, keys, shared-oosh infrastructure
ossh harden  myhost              # locks the box down (no AllowUsers yet — safe default)
```

Each concern is also callable standalone:

| Method | What it does |
|---|---|
| `ossh.harden <host>` | Orchestrator: packages → unattended-upgrades → fail2ban → firewall → sshd. Does **not** touch `AllowUsers`. |
| `ossh.harden.packages <host>` | `apt update && apt dist-upgrade -y && apt install unattended-upgrades fail2ban ufw htop nano bzip2` |
| `ossh.harden.unattended.upgrades <host>` | Writes `/etc/apt/apt.conf.d/20auto-upgrades` + `/etc/apt/apt.conf.d/51-oosh-unattended-upgrades` (auto-remove kernels/deps, reboot at 02:30) |
| `ossh.harden.fail2ban <host>` | Writes `/etc/fail2ban/jail.local` with `[sshd]` block, enables + restarts |
| `ossh.harden.firewall <host> <?extraPorts>` | UFW default deny-in/allow-out + OpenSSH + any optional extras (e.g. `"8080/tcp 8443/tcp"`) |
| `ossh.harden.sshd <host>` | sshd_config hardening toggles. Reloads sshd (existing sessions survive). |
| `ossh.harden.sshd.allowusers <host> <users>` | **Opt-in only.** Appends `AllowUsers`. Include every user who needs SSH access — unlisted users will be locked out. |

### Preflight safety gate

Every `ossh.harden.*` method runs `private.ossh.harden.preflight` first,
which refuses to proceed if:
- The caller cannot SSH in `BatchMode` (only password auth works — hardening would lock them out).
- The remote isn't Linux, or its `/etc/os-release` ID isn't `debian`/`ubuntu`.

### Intentional non-goals

- **No user creation.** `ossh install`'s `user.create` + `install.user.remote` covered this.
- **No NOPASSWD sudoers drop-in.** One-liner if you need it: `echo "<user> ALL=(ALL) NOPASSWD:ALL" | ssh <host> sudo tee /etc/sudoers.d/<user>-nopasswd`.
- **No `AllowUsers` in the orchestrator.** Dangerous default; opt-in via `.sshd.allowusers`.

## GitHub for every user

```bash
sudo ossh config.shared.github.create     # as root; idempotent
```

OpenSSH reads two system files for **every** user, so oosh writes GitHub there once instead of into each home:

| File | Content | Mode |
|---|---|---|
| `/etc/ssh/ssh_config.d/oosh-github.conf` | `Host github.com` — `User git`, `Port 22`, `HostName github.com`, `IdentityFile ~/.ssh/ids/ssh.developking/id_rsa`, `IdentitiesOnly yes` | 644 |
| `/etc/ssh/ssh_known_hosts` | GitHub's host key lines from `ssh-keyscan github.com` (missing lines added) | 644 |

- `~` in `IdentityFile` is expanded by ssh for the user who runs it, so each user uses their own copy of the developking key.
- The `.conf` ending is needed on Linux (`Include /etc/ssh/ssh_config.d/*.conf`); macOS reads every file there (`Include /etc/ssh/ssh_config.d/*`). Checked 2026-10-19 on Debian 12, Alma 9.8, Alpine 3.19 and 3.23, Ubuntu 24.04, macOS 15 and 26.
- The host key is public. Having it system-wide means no user is ever asked "Are you sure you want to continue connecting?" for github.com, so a fake GitHub is refused straight away. Access needs the private key, which stays in each user's own `~/.ssh`.
- `ossh config.get github.com` and `ssh -G github.com` show the result; the invariant tests (`ssh.config.invariant`, `ssh.config.woda`, `platform.ssh.layout.invariant`) check `ssh -G`.

**Clean-up of the old layout.** From 2026-04-01 (1b5c427e) to 2026-10-19, oosh kept a root-only template in `<basehome>/shared/.ssh` (`/home/shared/.ssh`, `/Users/shared/.ssh`) and copied its block and host key into every user's `~/.ssh/config` and `known_hosts`. `config.shared.github.create` now removes:

- `<basehome>/shared/.ssh`, but only when it holds nothing but `config` and `known_hosts`. Anything else (e.g. an old `2cuGitHub` deploy key, there until 2026-05-11) keeps the folder as it is, with a warning — a human decides.
- in every home (the users base without `shared`, plus root's home): the `Host github.com` block when it has only the fields oosh writes (`private.ossh.github.block.is.oosh`), and the `known_hosts` lines that are also in `/etc/ssh/ssh_known_hosts`. Files are written in place, owner and mode stay. A block or key the user wrote stays. Reason: a user's own config wins over the system file, and an old host key there would block ssh after a GitHub key rotation.

`RESULT` names the two files and what was removed. `ossh folder.fix` (runs as the user) no longer adds the block to `~/.ssh/config`; it warns when the system file lacks it.

## Method Reference

| Method | Description |
|--------|-------------|
| `ossh config.create` | Create SSH config entry |
| `ossh config.show.last` | Show last generated config |
| `ossh config.save.last` | Append the block of the last config.create to ~/.ssh/config (checked) |
| `ossh config.push` | Put a Host block into a remote host's ~/.ssh/config (replaced or added) |
| `ossh config.pull` | Copy a Host block from a remote host's ~/.ssh/config here |
| `ossh config.delete` | Remove a Host block from ~/.ssh/config |
| `ossh config.set` | Set one of seven fields (port, user, …) of a Host block |
| `ossh config.field.get` | Echo one field of a Host block |
| `ossh config.shared.github.create` | GitHub for every user: `/etc/ssh/ssh_config.d/oosh-github.conf` + `/etc/ssh/ssh_known_hosts`; removes the old `<basehome>/shared/.ssh` and its copies |
| `ossh install` | Install oosh on remote host |
| `ossh login` | Interactive SSH login |
| `ossh key.push` | Push SSH key to remote host |
| `ossh key.pull` | Pull a remote host's SSH key here and authorize it (`<fromHost> <?remoteKeyName> <?sshDir>`) |
| `ossh authorized.keys.update` | Rebuild authorized_keys from public_keys/ (atomic; rc 1 when no ssh is set up) |
| `ossh id.create` | Create new SSH key pair |
| `ossh list` | List configured hosts |
| `ossh list.ids` | List available key identities |
| `ossh harden` | Harden Debian/Ubuntu remote (orchestrator; no AllowUsers) |
| `ossh harden.packages` | Install the hardening package set |
| `ossh harden.unattended.upgrades` | Enable + configure unattended-upgrades |
| `ossh harden.fail2ban` | Enable fail2ban with [sshd] jail |
| `ossh harden.firewall` | Configure UFW (default deny in / allow out + OpenSSH + optional extra ports) |
| `ossh harden.sshd` | Harden sshd_config (no AllowUsers) |
| `ossh harden.sshd.allowusers` | **Opt-in** AllowUsers restriction |
| `ossh certificates.update` | Rotate TLS cert + restore workspace on a remote host (state-machine backed) |
| `ossh certificates.status` | Show current state of the CERT_UPDATE machine for a host |

## certificates.update — TLS cert rotation

`ossh certificates.update <host>` refreshes the TLS certificate for the
application running on `<host>` and restores its data workspace afterwards.
Backed by a 9-state machine (`CERT_UPDATE_<sanitized-host>`); a failure
stops *at* the failing state, and re-running the same command resumes from
there.

### Usage

```bash
ossh certificates.update WODA.test            # interactive: prints plan, asks Proceed?
ossh certificates.update WODA.test yes        # skip the confirmation prompt
ossh certificates.update WODA.test dryRun     # print every SSH call, execute none
ossh certificates.update WODA.test reset      # discard any in-flight state, start over

ossh certificates.status WODA.test            # show current state + persisted config
```

`reset` / `yes` / `dryRun` can each be passed bare or `--`-prefixed.
`dryRun` also accepts `dry-run` and `--dry-run` for ergonomics
(`dryRun` is the canonical OOSH-camelCase name).

### Per-host config

Config for `<host>` lives at
`$OOSH_DIR/etc/ossh/hosts/<host>/certificates.update.conf`, a `source`-able
key=value file:

```bash
domain=test.wo-da.de
workspace=/var/dev/.../Workspaces/structrAppWorkspace
certScenario=certbot
appScenario=structr
dataDir=WODA-current

# optional — defaults shown:
backupBase=/var/backups
verifyMinDaysLeft=30
```

Required keys: `domain`, `workspace`, `certScenario`, `appScenario`, `dataDir`.

### State flow

```
[11] stop.certbot          ssh: once docker.scenario.stop $certScenario
[12] stop.structr          ssh: once docker.scenario.stop $appScenario
[13] archive.workspace     ssh: mv $workspace/$dataDir -> $backupBase/$dataDir.<stamp>.bak
[14] create.certbot        ssh: once docker.scenario.create $certScenario $domain   (TLS renewed here)
[15] create.structr        ssh: once docker.scenario.create $appScenario $domain
[16] rotate.empty          ssh: rm -rf $workspace/WODA-empty ; mv $dataDir WODA-empty
[17] restore.workspace     ssh: mv $backupBase/$dataDir.<stamp>.bak -> $workspace/$dataDir
[18] start.structr         ssh: once docker.scenario.start $appScenario $domain
[19] verify.https          local: curl + openssl s_client check expiry >= $verifyMinDaysLeft days
```

The dated backup in `$backupBase` is the safety net: if anything fails
between [13] and [17], the data is recoverable and the state machine
remembers where it stopped. No in-script `EXIT`-trap auto-restore — the
state machine + dated backup *is* the recovery mechanism.

### Caveats

- **`WODA-empty` is treated as disposable** by state [16] (`rm -rf`). If
  that directory ever holds data you care about, do not run this command
  without first renaming it aside.
- The remote host must have `once docker.scenario.{stop,create,start}`
  available.
- Catastrophic abort (laptop disconnects mid-state) may leave the host in
  a partial state. `ossh certificates.status <host>` and the dated
  backup name in `$backupBase` give you everything needed to resume or
  recover manually.

## See Also

- [odocker](odocker.md) — Docker container management
- [Architecture](oosh-architecture.md) — OOSH framework overview
- [Branching](branching.md) — Branch and clone management
