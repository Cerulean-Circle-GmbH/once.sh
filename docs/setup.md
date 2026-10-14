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
   home (bash-user had none in the first container run). npm comes with it.
6. netatalk (AFP) is gone: macOS speaks SMB. Avahi stays, so the Finder sees
   the Samba share.

## Methods

| Method | Parameters | What it does |
|--------|------------|--------------|
| `all` | `<?user:$SUDO_USER>` | docker, nodejs + npm for `<user>`, the caller and every member of `dev` (`private.this.group.members.get`), headless, samba.support. Prints a summary; RESULT `headless setup: N ok, M skipped, K failed (names)`; always rc 0 |
| `docker` | `<?user>` | `odocker prereqs.install <user>`: the engine on a computer, the client in a container, `<user>` in the socket's group |
| `nvm` | `<?user> <?version:v0.40.3>` | nvm's official installer, downloaded to `/tmp`, run as `<user>` with `PROFILE=/dev/null` (the login already loads nvm); nothing when `~<user>/.nvm/nvm.sh` is there |
| `nodejs` | `<?version:--lts> <?user>` | `setup nvm`, then `nvm install <version>` as `<user>`; rc 1 when `node -v` does not answer |
| `npm` | `<?user>` | npm of nvm's node, else `oo cmd npm` (`oo cmd npm node` with Homebrew) |
| `headless` | `<?user>` | Linux: `vncserver`, `startxfce4`, `xfwm4`, `xfce4-panel`, `xfce4-terminal`, `dbus-launch` through `oo cmd`; the service stays off. macOS: Screen Sharing on |
| `vnc.password` | `<user>` | `vncpasswd` as `<user>`, `session=xfce` in `~/.vnc/config`, the first free display in `/etc/tigervnc/vncserver.users`, `systemctl enable --now vncserver@:<n>` (port 5900+n). macOS: nothing to set |
| `samba.support` | `<?user>` | Linux: `smbd`, `smbclient`, `avahi-daemon` through `oo cmd`, smbd/nmbd switched off again (Debian starts them), `/etc/avahi/services/smb.service`. macOS: File Sharing (SMB) on |
| `samba.password` | `<user>` | `smbpasswd -a <user>`, `systemctl enable --now smbd avahi-daemon`. macOS: the System Settings step |

Package names per package manager come from `private.setup.package.get`, the
one table (apt `tigervnc-standalone-server`, dnf `tigervnc-server`,
`samba-client`, `avahi`, …). `share samba.install` and
`disk install.samba.support` call `setup samba.support`.

## In the install

`private.check.headless.setup.started` (oo) loads `su/setup` and runs
`setup all` without arguments. It returns 0 with the RESULT `state 50: …`,
which is never a bare number (a numeric RESULT would make `state.next` jump to
that state). State 51 (`headless.setup.finished`) does nothing. Each state check
runs in its own `state` process, so the summary and the next steps are printed
by `setup all` itself.

## Tests

`test/test.setup` (core) runs every method in a child with stand-ins for
`oo.cmd`, `odocker.prereqs.install`, `curl`, `sudo`, `systemctl`, `launchctl`,
`vncpasswd` and `smbpasswd`, which log their arguments. Under
`OOSH_NO_INSTALL` (every test run) each method answers rc 0 and touches
nothing. `T-OO-STATE-50` in `test/test.oo` pins the state hook.
