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
. **Samba shares each user's own home folder, and only that** (`[homes]`,
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
| `nvm` | `<?user> <?version:v0.40.3>` | nvm's official installer, downloaded to `/tmp`, run as `<user>` with `PROFILE=/dev/null` (the login already loads nvm); nothing when `~<user>/.nvm/nvm.sh` is there — asked as `<user>`, since the caller may not see into that home |
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
