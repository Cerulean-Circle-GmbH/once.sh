# setup — the headless set (install state 50)

`su/setup` is what install state 50 (`headless.setup.started`) runs on every
computer: Docker, Node.js + npm through nvm, a remote desktop and file sharing.
`su/` is on root's PATH only. Anyone else calls it by path, and the steps that
change the system need root:

```bash
sudo -i ~root/oosh/su/setup all            # what state 50 runs
sudo -i ~root/oosh/su/setup vnc.password alice
sudo -i ~root/oosh/su/setup samba.password alice
```

## Decisions (2026-10-14)

1. State 50 **always** runs every step. A step that cannot work here is
   *skipped* with an info line: VNC and Samba in a container, or without
   systemd. A failing step is a **warning, never a stop**. The install goes on,
   and the summary names the step.
2. **macOS** uses its built-in services: `setup headless` switches on Screen
   Sharing and `setup samba.support` switches on File Sharing (SMB). What Apple
   only allows by hand is printed as the next step (remote control,
   which folders to share, SMB for the user).
3. **Linux VNC** is TigerVNC plus a small Xfce, from the package manager
   through `oo cmd`. No downloaded script, no RealVNC.
4. **No password during the install.** VNC and Samba are installed and
   prepared but stay **off**. `setup vnc.password <user>` /
   `setup samba.password <user>` ask for the password and switch them on.
5. **Node.js through nvm.** The official installer is pinned to
   `SETUP_NVM_VERSION`, Node is the current LTS by default, and it goes to the
   one who ran sudo, to root and to every member of group `dev`, each in its own
   home. **Every user who gets oosh later gets it too**: `user oosh.install`
   (used by `user create` and `ossh install <host> <user>`) runs `setup nodejs`
   and `setup npm` for that user (`private.user.oosh.install.node`). A failure
   there is a warning, never a failed install. npm comes with it.
   `.bashrc` loads nvm and then puts `~/oosh` back in front of nvm's node on PATH
   (`this.path.add`, T-BASHRC-NVM-NOT-FIRST): oosh stays first, node is there.
   Every nvm step runs with the **user's own** nvm (`private.setup.nvm.run`
   drops the caller's `NVM_DIR`): from root's login shell, which exports
   `NVM_DIR=/root/.nvm`, `user create bob` aimed bob's nvm at `/root/.nvm` and
   failed (T-SETUP-NVM-OWN-DIR).
6. netatalk (AFP) is gone: macOS speaks SMB. Avahi stays, so the Finder sees
   the Samba share.
7. **Samba shares each user's own home folder, and only that** (`[homes]`,
   `valid users = %S`, new files 0700), from `templates/setup/samba.homes.conf`
   — copied to `/etc/samba/oosh.homes.conf` and included by one line in
   `smb.conf`, which otherwise stays as the distribution ships it.
8. **VNC listens on this computer only** (TigerVNC's default). From another
   computer through an SSH tunnel: `ssh -L 5901:localhost:5901 <host>`, then a
   VNC viewer on `localhost:5901` — the VNC password is weak (8 characters
   count) and the connection is not encrypted. `setup vnc.password` prints the
   line.

## Methods

| Method | Parameters | What it does |
|--------|------------|--------------|
| `all` | `<?user:$SUDO_USER>` | docker, nodejs + npm for `<user>`, the caller and every member of `dev` (`private.this.group.members.get`), headless, samba.support. Prints a summary; RESULT `headless setup: N ok, M skipped, K failed (names)`; always rc 0 |
| `docker` | `<?user>` | `odocker prereqs.install <user>`: the engine on a computer, the client in a container, `<user>` in the socket's group. *Skipped* where no Docker can run: no socket and no engine possible (a Mac VM without virtualization, a container started without the socket) |
| `nvm` | `<?user> <?version:v0.40.3>` | nvm's official installer, downloaded to `/tmp`, run as `<user>` with `PROFILE=/dev/null` (the login already loads nvm) and without the caller's `NVM_DIR`; nothing when `~<user>/.nvm/nvm.sh` is there — asked as `<user>`, since the caller may not see into that home |
| `nodejs` | `<?version:--lts> <?user>` | `setup nvm`, then `nvm install <version>` as `<user>`; rc 1 when `node -v` does not answer |
| `npm` | `<?user>` | npm of nvm's node only; rc 1 "no npm for <user> — run: setup nodejs" when it is missing. Never the package manager (on Ubuntu that pulls in the system nodejs 18) |
| `headless` | `<?user>` | Linux: `vncserver`, `startxfce4`, `xfwm4`, `xfce4-panel`, `xfce4-terminal`, `dbus-launch` through `oo cmd`; the service stays off. macOS: Screen Sharing on |
| `vnc.password` | `<user>` | `vncpasswd` as `<user>`, `session=xfce` in `~/.vnc/config`, the first free display in `/etc/tigervnc/vncserver.users`, `os service.on <unit>@:<n>` (port 5900+n), local only — RESULT names the `ssh -L` tunnel (decision 8); the unit is the package's: `tigervncserver` on Debian/Ubuntu, `vncserver` on Fedora/RHEL (`private.setup.vnc.unit.get`). macOS: nothing to set |
| `samba.support` | `<?user>` | Linux: `smbd`, `smbclient`, `avahi-daemon` through `oo cmd`, smbd/nmbd switched off again (Debian starts them) as long as Samba has no user (`private.setup.samba.users.any`: `pdbedit -L`), so a rerun never locks a user out, `/etc/avahi/services/smb.service` from `templates/setup/avahi.smb.service`, and `[homes]` (decision 7) via `/etc/samba/oosh.homes.conf` + one `include` line in `smb.conf`. macOS: File Sharing (SMB) on |
| `samba.password` | `<user>` | `smbpasswd -a <user>`, `systemctl enable --now smbd avahi-daemon`. macOS: the System Settings step |

Package names per package manager come from `private.setup.package.get`, the
one table (apt `tigervnc-standalone-server`, dnf `tigervnc-server`,
`samba-client`, `avahi`, …). `share samba.install` and
`disk install.samba.support` call `setup samba.support`.

## The oosh methods it stands on

`su/setup` calls no system tool raw that oosh has a method for
(T-SETUP-OOSH-ONLY pins it):

| Need | oosh method |
|------|-------------|
| install a package | `oo cmd <cmd> <package>` (`private.setup.package.get` names the package) |
| Docker | `odocker prereqs.install`, `private.odocker.engine.supported` |
| run something as a user | `private.as.user` (user) |
| a user's home | `user get home <user>` |
| macOS or Linux | `os check private.setup.<method>` → `.darwin` / `.linux` |
| a service on or off | `os service.on` / `os service.off` (os) |
| systemd or not, a container or not | `private.os.systemd.is`, `private.this.container.is` |
| a temp folder, a download | `private.this.temp.dir.get`, `private.this.url.download` |
| a line in a file, once | `private.this.file.line.ensure` |
| a file owner | `private.this.path.owner.set` |
| the Avahi SMB announcement, the `[homes]` share | the templates `templates/setup/avahi.smb.service` and `samba.homes.conf`, copied by `private.setup.template.install` when `private.this.file.same` says they differ |
| the members of dev | `private.this.group.members.get` |

Every `<user>` parameter completes from `user list`
(`setup.<method>.completion.user`), the nvm version from `SETUP_NVM_VERSION`.

## In the install

`private.check.headless.setup.started` (oo) loads `su/setup` and runs
`setup all` without arguments. It returns 0 with the RESULT `state 50: …`,
which is never a bare number (a numeric RESULT would make `state.next` jump to
that state). State 51 (`headless.setup.finished`) does nothing. Each state check
runs in its own `state` process, so the summary and the next steps are printed
by `setup all` itself.

A user added after the install gets the per-user part through
`user oosh.install`. Docker: its groups step puts the user in the docker group.
Node + npm: `private.user.oosh.install.node`. VNC and Samba stay on demand
(`vnc.password` / `samba.password`).

## Tests

`test/test.setup` (core) runs every method in a child with stand-ins for
`oo.cmd`, `odocker.prereqs.install`, `private.as.user`, `curl`, `systemctl`,
`launchctl`, `vncpasswd` and `smbpasswd`, which log their arguments; `user` and
`os` are sourced first so the stand-ins replace their methods, and `os.check`
reads the pinned `OSTYPE`. Under
`OOSH_NO_INSTALL` (every test run) each method answers rc 0 and touches
nothing. `T-OO-STATE-50` in `test/test.oo` pins the state hook.

<!-- BEGIN generated: oosh method matrix (oosh-architect) -->
## `su/setup` — method matrix (origin/dev ↔ origin/test/mcdonges.latest)

Generated by oosh-architect from the branch sources (2026-10-20). Indexes: [methods-index.md](methods-index.md) · [object-verb-index.md](object-verb-index.md) · [parameter.md](parameter.md).

**Decomposition** — every method is `setup.<object>.<verb>[.<more.words>]`. One method = one row.
`object`/`verb` are left **blank when unchanged from the row above** (objects are never repeated).
The **script name is the root object** — `odocker` acts on `container`, `image`, `volume` … so a method is
an object CHAIN ending in a verb: **`object.object.verb`**. The object column shows the full chain.
The **verb is identified semantically** (a real action word), not by position; OOSH's normalized form puts
the **verb last** (e.g. `authorized.keys.update`), so segments before it are the object, after it `more.words`.
An **adverbial modifier** directly before the verb belongs to the verb, not the object —
`otmux.window.aggressive.resize` is object `otmux.window` + verb `aggressive.resize`.
An **empty verb** means the name carries **no action at all** — the chain never reaches a verb
(an `object.verb` naming gap, listed in [verb-audit.md](verb-audit.md)).

| object | verb | more.words | all parameter | origin/test/mcdonges.latest | origin/dev |
|---|---|---|---|---|---|
| **=== public ===** | | | | | |
| `setup` | `snapAppStore` |  | `# # sets up everything needed for headless operation` | `setup.snapAppStore` ✅ | `setup.snapAppStore` ✅ |
| `setup.all` |  |  | `# <?user:$SUDO_USER> # everything install state 50 runs: docker, nodejs + npm for <user> and this user, headless, samba support; a failing step is a warning, never a stop #` |  | `setup.all` |
| `setup.chromium` |  |  | `# # sets up everything needed for headless operation` | `setup.chromium` ✅ | `setup.chromium` ✅ |
| `setup.docker` |  |  | `# <?user:$SUDO_USER> # Docker here (engine on a computer, client in a container) and <user> in the group of its socket — odocker prereqs.install; skipped where no Docker can run #` | `setup.docker` | `setup.docker` |
| `setup.headless` |  |  | `# <?user:$SUDO_USER> # remote desktop: TigerVNC + a small Xfce on Linux (off until vnc.password), Screen Sharing on macOS; skipped in a container or without systemd #` | `setup.headless` | `setup.headless` |
|  | `enable` |  |  | `setup.headless.enable` |  |
| `setup.nodejs` |  |  | `# <?version:--lts> <?user:$SUDO_USER> # install node <version> through nvm for <user> and make sure it runs #` | `setup.nodejs` | `setup.nodejs` |
| `setup.npm` |  |  | `# <?user:$SUDO_USER> # make sure <user> has npm — only the npm of the nvm node; rc 1 naming setup nodejs when it is missing #` | `setup.npm` | `setup.npm` |
| `setup.nvm` |  |  | `# <?user:$SUDO_USER> <?version:v0.40.3> # install nvm for <user> from its official installer, pinned to <version>; nothing when it is there #` | `setup.nvm` | `setup.nvm` |
| `setup.pacstall` |  |  |  | `setup.pacstall` ✅ | `setup.pacstall` ✅ |
| `setup.samba.password` |  |  | `# <user> # ask the Samba password of <user> and switch Samba and Avahi on #` |  | `setup.samba.password` |
| `setup.samba.support` |  |  | `# <?user:$SUDO_USER> # file sharing: Samba + Avahi on Linux (off until samba.password), File Sharing (SMB) on macOS; skipped in a container or without systemd #` | `setup.samba.support` | `setup.samba.support` |
| `setup.status.headless` |  |  |  | `setup.status.headless` |  |
| `setup.vnc.password` |  |  | `# <user> # ask the VNC password of <user>, give <user> an Xfce session on a display of its own and switch the VNC service on #` |  | `setup.vnc.password` |
| **=== private ===** | | | | | |
| `setup` | `load` |  | `#  # load the oosh methods su/setup stands on: private.as.user and user.get (user), os.service.on / off and private.os.systemd.is (os); rc 1 naming what is missing #` |  | `private.setup.load` |
| `setup.all` | `step` |  | `# <name> <method> <?args…> # one step of setup.all: count it ok, skipped or failed and add its line to SETUP_SUMMARY; a failure is a warning, never a stop #` |  | `private.setup.all.step` |
| `setup.cmds` | `install` |  | `# <cmd> <?cmd…> # oo cmd every <cmd> with its package; rc 1 at the first that fails, naming it #` |  | `private.setup.cmds.install` |
| `setup.gate` |  |  | `#  # rc 0 with RESULT when OOSH_NO_INSTALL is set — a test run installs nothing; rc 1 otherwise #` |  | `private.setup.gate` |
| `setup.headless.darwin` |  |  | `# <?user> # macOS: switch the built-in Screen Sharing on #` |  | `private.setup.headless.darwin` |
| `setup.headless.linux` |  |  | `# <?user> # Linux: TigerVNC + a small Xfce through oo cmd; the service stays off until vnc.password #` |  | `private.setup.headless.linux` |
| `setup.linux` | `skip` |  | `# <what> # rc 0 with RESULT "skipped: …" when <what> (VNC, Samba) cannot run here: a container, or no systemd; rc 1 when it can #` |  | `private.setup.linux.skip` |
| `setup.nvm` | `is` |  | `# <user> # rc 0 when <user> has nvm — asked AS <user>: the caller may not see into that home #` |  | `private.setup.nvm.is` |
|  | `run` |  | `# <user> <command...> # run <command> as <user> with the user's own nvm — never the caller's NVM_DIR #` |  | `private.setup.nvm.run` |
| `setup.package` | `get` |  | `# <cmd> # echo the package that provides <cmd> for the package manager in OOSH_PM; <cmd> itself when it is the same #` |  | `private.setup.package.get` |
| `setup.pm` | `ensure` |  | `#  # load oo cmd and discover the package manager when OOSH_PM is still empty #` |  | `private.setup.pm.ensure` |
| `setup.samba.password.darwin` |  |  | `# <user> # macOS: SMB for <user> is turned on in System Settings, which asks for the password #` |  | `private.setup.samba.password.darwin` |
| `setup.samba.password.linux` |  |  | `# <user> # Linux: smbpasswd -a <user>, then smbd and avahi-daemon on #` |  | `private.setup.samba.password.linux` |
| `setup.samba.support.darwin` |  |  | `# <?user> # macOS: switch the built-in File Sharing (SMB) on #` |  | `private.setup.samba.support.darwin` |
| `setup.samba.support.linux` |  |  | `# <?user> # Linux: Samba + Avahi through oo cmd, smbd off until samba.password, the Avahi SMB announcement from templates/setup, each user's own home folder as [homes] #` |  | `private.setup.samba.support.linux` |
| `setup.samba.users.any` |  |  | `#  # rc 0 when Samba has at least one user (pdbedit -L lists one) — someone ran samba.password #` |  | `private.setup.samba.users.any` |
| `setup.services` | `switch` |  | `# <on\|off> <service> <?service…> # os service.on / service.off for every <service>; rc 1 at the first that fails, naming it #` |  | `private.setup.services.switch` |
| `setup.template` | `install` |  | `# <template> <target> # copy templates/setup/<template> to <target> when it differs (its folder made); rc 1 naming <target> when it cannot be written #` |  | `private.setup.template.install` |
| `setup.user` | `get` |  | `# <?user> # echo <user>, else the one who ran sudo (never root), else nothing #` |  | `private.setup.user.get` |
| `setup.vnc.password.darwin` |  |  | `# <user> # macOS: Screen Sharing uses the account password — nothing to set #` |  | `private.setup.vnc.password.darwin` |
| `setup.vnc.password.linux` |  |  | `# <user> # Linux: vncpasswd as <user>, session=xfce in ~<user>/.vnc/config, the first free display in vncserver.users, the TigerVNC unit @:<n> on #` |  | `private.setup.vnc.password.linux` |
| `setup.vnc.unit` | `get` |  | `#  # echo the systemd unit template of TigerVNC for the package manager in OOSH_PM, without @: tigervncserver (Debian, Ubuntu), vncserver (Fedora, RHEL) #` |  | `private.setup.vnc.unit.get` |
<!-- END generated: oosh method matrix -->
