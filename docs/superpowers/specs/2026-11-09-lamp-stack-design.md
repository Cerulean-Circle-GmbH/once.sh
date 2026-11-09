# Design: `lamp` — web stack with Docker or a native install

**Date:** 2026-11-09 · **Branch:** `dev` · **Status:** approved design (replaces the Docker-only version)

## Context

The first design made `lamp` Docker-only and local-only. The requirement is now: **identify the
operating system and install the stack there, with or without Docker**, keeping one API.

The stack is the same in both cases: nginx + php-fpm or apache + mod_php, MariaDB, PHP 8.5,
Let's Encrypt. What differs is how packages arrive, how services are managed and where vhosts live.

## Goals

- One command surface: `stack.*`, `site.*`, `db.*`, `cert.*` work on either backend.
- Detect the OS family, init system and package manager; refuse unsupported hosts clearly.
- Prefer Docker when it is usable, but never require it.
- Native installs get PHP 8.5 everywhere (Sury, Remi, Alpine community/edge, Homebrew).
- `stack.status` is the runtime truth: family, init, backend, versions, extensions, services.

## Non-goals (v1)

Remote install over `ossh`, Windows, multiple stacks side by side, DNS-01, PHP versions other than
8.5 on the default path, backup/restore.

## 1. Detection

```
uname -s = Darwin                      → macos   / launchd / brew
/etc/os-release ID=debian|ubuntu       → debian  / systemd / apt-get
ID=almalinux|rocky|rhel|fedora|centos  → rhel    / systemd / dnf
ID=alpine                              → alpine  / openrc  / apk
```

`private.lamp.os.family` is a pure function: it reads `uname -s` and an `/etc/os-release` path
(overridable for tests) and echoes `family<TAB>init<TAB>pkg`. Unsupported → rc 1 listing the four.

## 2. Backend choice

```
lamp stack.install <webserver> <?php:8.5> <?mariadb:latest> <?backend:prompt>
```

| Situation | Result |
|---|---|
| `<?backend>` = `docker` or `native` | use it, no prompt |
| `<?backend>` absent, stdin is a TTY | ask `backend [docker\|native]: `, default = docker if usable else native |
| `<?backend>` absent, non-TTY | default as above, no prompt |
| `LAMP_BACKEND=docker\|native` in env | overrides the default (tests use this) |
| chosen backend unusable | rc 1 naming what is missing |

"Docker usable" = `odocker.support.check` passes **and** `docker compose version` succeeds.
"Native usable" = the family was detected and the package manager exists.

## 3. Native package plan

| | debian/ubuntu | rhel family | alpine | macos |
|---|---|---|---|---|
| PHP repo | Sury (`packages.sury.org/php`) | Remi (`remirepo.net`) | community/edge | Homebrew |
| PHP packages | `php8.5-{cli,fpm,intl,gd,imagick,mbstring,curl,xml,mysql,opcache}` | `php85-php-{cli,fpm,intl,gd,pecl-imagick,mbstring,curl,xml,mysqlnd,opcache}` | `php83`/`php84` + `php-{fpm,intl,gd,pecl-imagick,mbstring,curl,xml,mysqli,pdo_mysql,opcache}` | `php` (brew) + `pecl install imagick` |
| Apache | `apache2` + `libapache2-mod-php8.5` | `httpd` + `php85-php` | `apache2` + `php` | `httpd` |
| Nginx | `nginx` + `php8.5-fpm` | `nginx` + `php85-php-fpm` | `nginx` + `php-fpm` | `nginx` + `php` |
| MariaDB | mariadb.org repo → `mariadb-server` | mariadb.org repo → `mariadb-server` | `mariadb` | `mariadb` |
| Certbot | `certbot` + `python3-certbot-{nginx,apache}` | `certbot` + `python3-certbot-{nginx,apache}` | `certbot` | `certbot` |
| Enable | `systemctl enable --now` | `systemctl enable --now` | `rc-update add` + `rc-service start` | `brew services start` |
| Reload | `systemctl reload` | `systemctl reload` | `rc-service … reload` | `brew services restart` |

Alpine ships PHP 8.3/8.4 depending on release; `stack.install` records the resolved version and
`<?php>` is honoured only where the repository has it. The extension contract below is checked
either way, so a host that cannot provide `intl` fails at install, not at the first request.

## 4. Extension contract

Same list in both backends: `intl mbstring json curl gd imagick simplexml pdo_mysql mysqli`.
`stack.install` runs `php -m` (container or host) and fails naming every missing extension.
`opcache` is installed but not asserted (reported as `Zend OPcache`).

## 5. State

`$CONFIG_PATH/lamp/` is identical for both backends, plus new fields:

```
LAMP_BACKEND=native|docker
LAMP_OS_FAMILY=debian|rhel|alpine|macos
LAMP_INIT=systemd|openrc|launchd
LAMP_PKG=apt-get|dnf|apk|brew
LAMP_WEBSERVER=nginx|apache
LAMP_PHP=8.5
LAMP_PHP_RESOLVED=8.5.12
LAMP_MARIADB=latest
LAMP_MARIADB_RESOLVED=13.0.2
LAMP_WEB_ROOT=/etc/nginx/sites-available        (per family; see §6)
LAMP_SERVICE_WEB=nginx|apache2|httpd
LAMP_SERVICE_PHP=php8.5-fpm|php-fpm|none
```

The runtime tree is unchanged: `www/`, `conf.d/`, `sites`, `certs/{conf,www}`, `db/`,
`db.credentials`, `php.ini`, `db-init/`.

## 6. Where vhosts and unit files live

| family | nginx | apache |
|---|---|---|
| debian | `/etc/nginx/sites-available` + `sites-enabled` symlink | `/etc/apache2/sites-available` + `a2ensite` |
| rhel | `/etc/nginx/conf.d` | `/etc/httpd/conf.d` |
| alpine | `/etc/nginx/http.d` | `/etc/apache2/conf.d` |
| macos | `$(brew --prefix)/etc/nginx/servers` | `$(brew --prefix)/etc/httpd/extra` |

`site.add` renders into `conf.d/` as the source of truth, then installs the file (or symlink) into
the family path with `sudo` and reloads. `stack.install` re-renders every recorded site.

## 7. Command behaviour

| command | docker | native |
|---|---|---|
| `stack.install` | pull/build, compose up -d --wait | add repo, install packages, write PHP ini, enable/start services |
| `stack.up/down` | compose up/down | start/stop the two services |
| `stack.status` | compose ps + `php -m` in container | service state + host `php -m` |
| `stack.log` | compose logs --tail | journalctl -u <svc> -n / rc-service log / brew log |
| `stack.remove` | compose down | stop + disable; `purge` removes packages and state |
| `site.add` | writes `$LAMP_HOME/conf.d` | same, then installs into §6 and reloads |
| `db.create` | `compose exec -T db mariadb` | `sudo mariadb` (socket auth) |
| `cert.issue` | certbot container | host certbot with `--nginx`/`--apache` or `--webroot` |

## 8. Privileges

Run as the caller. `sudo` per privileged step: package installs, service enable/start, writes
outside `$HOME`, `a2ensite`, certbot. `$CONFIG_PATH/lamp` stays caller-owned; the only root-owned
things are the installed packages and vhosts. Missing sudo → rc 1 with the exact command.

## 9. macOS

Ports below 1024 need root. The native backend binds **8080/8443** by default and prints the URLs;
`stack.install function … port 80` would require running the listener as root, which v1 does not do.
Linux backends use 80/443.

## 10. Errors

| situation | rc | RESULT |
|---|---|---|
| unsupported OS | 1 | `unsupported OS <id> — supported: debian/ubuntu, rhel family, alpine, macos` |
| package manager missing | 1 | `no <pkg> on this host` |
| PHP repo install fails | 1 | the package manager's last line |
| extension missing after install | 1 | `php is missing: intl imagick` |
| service fails to start | 1 | service name + last 20 log lines |
| sudo refused | 1 | `sudo is required for <step> — run: sudo <command>` |
| Docker chosen but unusable | 1 | `docker is not usable here — run: odocker prereqs.install` |

## 11. Testing

- `private.lamp.os.family` with fixture `/etc/os-release` files: debian, ubuntu, almalinux, rocky,
  fedora, alpine, plus `uname -s` = Darwin.
- Package plan: `apt-get`, `dnf`, `apk`, `brew`, `systemctl`, `rc-service`, `rc-update`, `sudo`
  replaced by functions that record argv; assert the exact install/start/reload calls per family.
- Backend selection: explicit arg, env override, non-TTY default, TTY prompt via here-string.
- Docker backend keeps the compose tests from the first design.
- Vhost content shared; only the destination path differs per family.
- `core` must pass without Docker, without network and without installing anything.

## 12. Decisions log

| question | decision |
|---|---|
| OS families | debian/ubuntu, rhel family, alpine, macos |
| backend choice | ask when interactive, default docker-if-usable, `<?backend>`/`LAMP_BACKEND` override |
| PHP 8.5 | Sury / Remi / community / brew |
| parity | full: stack, site, db, cert on both |
| privileges | sudo per privileged step |
| macOS ports | 8080/8443 |
