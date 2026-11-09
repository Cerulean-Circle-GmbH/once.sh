# Design: `lamp` — a two-variant web stack over Docker

**Date:** 2026-11-09 · **Branch:** `dev` · **Status:** approved design, not yet implemented

## Context

`ossh` wraps SSH; `odocker` wraps Docker. Nothing in the tree sets up a web stack: a search for
`apache|mysql|mariadb|php` finds only nginx/certbot fragments in `DockerWorkspaces/WODA` and the
legacy `once.docker.scenario.*` compose runner in `init/once`.

The request: one command that installs **Apache or Nginx + MariaDB + PHP + Let's Encrypt**, with the
web server chosen during setup.

Two stacks must be first-class, not a flag on one image:

| | Web server | PHP SAPI | Database | TLS |
|---|---|---|---|---|
| A | `nginx:1.27-alpine` | `php:8.5-fpm` | `mariadb:latest` | `certbot/certbot` |
| B | `php:8.5-apache` | `mod_php` | `mariadb:latest` | `certbot/certbot` |

The official PHP images already contain **mbstring, curl, json, simplexml** and **not** intl, gd,
imagick, pdo_mysql, mysqli. A thin Dockerfile per variant adds what is missing and enables
`mod_rewrite`; nginx gets the equivalent `try_files`.

## Non-goals (v1)

Remote install over `ossh`, phpMyAdmin, several stacks side by side, backup/restore, DNS-01
challenge, PHP versions other than 8.5 in the default path (the argument exists, but only 8.5 is
tested), Windows/macOS-specific paths.

## Naming and placement

- New component `lamp` in the `once.sh` tree: `./lamp`, `test/test.lamp`, `docs/lamp.md`.
- Method names follow `script.object.verb`: `lamp.stack.install`, `lamp.site.add`, `lamp.db.create`,
  `lamp.cert.issue`.
- It never re-implements Docker: building, running, exec and logs go through `odocker.*` where a
  matching method exists; `docker compose` is used for the multi-container unit because `odocker`
  has no compose lifecycle command.
- Images and compose templates live in `DockerWorkspaces/LAMP/1.0.0/` (EAMD convention: Dockerfiles
  belong to `DockerWorkspaces`). Runtime state lives under `$CONFIG_PATH/lamp` and is never
  committed.

## Command surface

```
lamp stack.install <nginx|apache> <?php:8.5> <?mariadb:latest>
lamp stack.up
lamp stack.down
lamp stack.status
lamp stack.log       <?lines:50>
lamp stack.remove    <?purge:no>
lamp site.add        <domain> <docroot>
lamp db.create       <name> <?user>
lamp cert.issue      <domain> <email>
lamp cert.renew
lamp cert.status
```

Behaviour shared by every method:

- one-line docstring in the `# <params> # description #` form;
- `create.result <rc> "<message>"` and `error.log`/`success.log` on every exit path;
- `return $(result)`; no `exit`;
- idempotent where the operation is a state, not an event.

### `stack.install`

| Input | Behaviour |
|---|---|
| `<nginx\|apache>` present | use it |
| missing, stdin is a TTY | ask `web server [nginx]: ` once, save the answer |
| missing, non-TTY | rc 1 `no web server was specified (nginx or apache)` |
| anything else | rc 1 naming the two valid values |

Steps, in order, each failing loud:

1. `odocker.support.check` — rc 1 with `run: odocker prereqs.install` when Docker cannot work.
2. Resolve `$ODOCKER_WORKSPACES/LAMP/1.0.0/<variant>`; rc 1 if the template is absent.
3. Create `$CONFIG_PATH/lamp/{www,conf.d,certs/{conf,www},db,logs}` (700).
4. Write `$CONFIG_PATH/lamp/stack.env` (600) — see *State*.
5. Detect host ports 80/443; if taken by a foreign container, rc 1 naming it.
6. `docker compose --env-file stack.env -f <template>/docker-compose.yml -p lamp build`
7. `docker compose … up -d --wait`
8. `php -m` check against `common/php/required-extensions`; rc 1 naming every missing extension.
9. Record the resolved image ids in `stack.env`.

Re-running on an installed stack with the **same** variant is a no-op: rc 0 `already installed
(nginx)`. With a **different** variant it stops the project, rewrites `stack.env`, re-renders every site in
`$CONFIG_PATH/lamp/sites` for the new server, rebuilds and starts — data directories are kept, and
RESULT says `switched nginx → apache`.

Sites are recorded in `$CONFIG_PATH/lamp/sites` (one `domain<TAB>docroot` per line) so a switch can
rebuild `conf.d/` without guessing from the old vhost syntax.

### `stack.up / down / status / log / remove`

- `up` waits for health (`--wait`, 60 s); `down` keeps volumes; `remove` also removes the compose
  project; `remove purge` additionally deletes `$CONFIG_PATH/lamp`.
- `status` prints, in this order: web server, PHP and MariaDB requested/resolved versions, container
  states, host ports, required extensions with ✔/✗, certificate expiry per domain.
- `log <?lines:50>` is `docker compose logs --tail`.

### `site.add <domain> <docroot>`

- `<docroot>` absolute, or relative to `$CONFIG_PATH/lamp/www/`; created when missing.
- appends `domain<TAB>docroot` to `$LAMP_HOME/sites` (idempotent);
- writes `conf.d/<domain>.conf` for the **installed** variant:
  - nginx: `server` on 80, `root`, `try_files $uri $uri/ /index.php?$query_string`, PHP via
    `fastcgi_pass app:9000`, ACME location from `certs/www`;
  - apache: `VirtualHost *:80`, `DocumentRoot`, `<Directory>` with `AllowOverride All`,
    `DirectoryIndex index.php`, ACME alias.
- adds a 443 `server`/`VirtualHost` block only when `certs/conf/live/<domain>/fullchain.pem` exists.
- reloads (`nginx -s reload` / `apachectl -k graceful`).
- refuses (rc 1, nothing written) when the file exists with different content; rc 0 `unchanged`
  when identical.
- validates `<domain>` against `[A-Za-z0-9.-]`, refuses empty labels and `..`.

### `db.create <name> <?user>`

- validates the name (`[A-Za-z0-9_]+`), user defaults to the name;
- accepts only the local socket via `docker compose exec -T db`;
- generates a 24-char password, creates DB + user + `GRANT ALL ON <name>.*`;
- prints the password **once** to stdout and appends `name user password` to
  `$CONFIG_PATH/lamp/db.credentials` (600);
- existing DB or user → rc 1, nothing changed.

### `cert.issue <domain> <email>`

- requires the domain to exist in `conf.d/` (a stack with no vhost gets no certificate);
- runs the `certbot` service: `certonly --webroot -w /var/www/certbot -d <domain> --email <email>
  --agree-tos --no-eff-email`;
- rc 1 with certbot's last error line when the challenge fails; existing certificates untouched;
- on success, rewrites the vhost with the 443 block and reloads;
- `cert.renew` is one-shot `certbot renew`; the compose also runs a 12 h loop.

## Images

```
DockerWorkspaces/LAMP/1.0.0/
├── common/
│   ├── php/php.ini
│   ├── php/required-extensions      # one per line
│   ├── db/01-charset.sql
│   └── certbot/renew-loop.sh
├── nginx/
│   ├── Dockerfile
│   ├── docker-compose.yml
│   └── conf.d/default.conf
└── apache/
    ├── Dockerfile
    ├── docker-compose.yml
    └── vhost.conf
```

`apache/Dockerfile`:

```dockerfile
FROM php:8.5-apache

RUN apt-get update && apt-get install -y --no-install-recommends \
      libicu-dev libpng-dev libjpeg62-turbo-dev libfreetype6-dev libmagickwand-dev \
 && docker-php-ext-configure gd --with-freetype --with-jpeg \
 && docker-php-ext-install -j"$(nproc)" intl gd pdo_mysql mysqli opcache \
 && pecl install imagick && docker-php-ext-enable imagick \
 && a2enmod rewrite \
 && rm -rf /var/lib/apt/lists/* /tmp/pear
```

`nginx/Dockerfile`: same from `php:8.5-fpm`, no `a2enmod`.

| Extension | Comes from |
|---|---|
| mbstring, json, curl, simplexml | official image |
| intl, gd, imagick | our Dockerfile |
| pdo_mysql, mysqli | our Dockerfile — without them PHP cannot reach MariaDB |
| opcache | our Dockerfile |
| mod_rewrite | `a2enmod rewrite` (Apache); nginx uses `try_files` |

`php.ini` is seeded to `$CONFIG_PATH/lamp/php.ini` and mounted read-only over
`conf.d/99-lamp.ini`, so tuning it does not need a rebuild.

## Compose unit (both variants)

```yaml
name: lamp
services:
  app:            # build: .  (php-fpm or php-apache)
    volumes: [ "${LAMP_HOME}/www:/var/www/html" ]
    environment: { MARIADB_HOST: db, MARIADB_DATABASE: lamp }
    depends_on: { db: { condition: service_healthy } }
  web:            # nginx variant only
    image: nginx:1.27-alpine
    ports: [ "80:80", "443:443" ]
    volumes:
      - "${LAMP_HOME}/conf.d:/etc/nginx/conf.d:ro"
      - "${LAMP_HOME}/www:/var/www/html:ro"
      - "${LAMP_HOME}/certs/conf:/etc/letsencrypt:ro"
      - "${LAMP_HOME}/certs/www:/var/www/certbot:ro"
  db:
    image: mariadb:latest
    volumes: [ "${LAMP_HOME}/db:/var/lib/mysql" ]
    healthcheck: { test: ["CMD", "healthcheck.sh", "--connect", "--innodb_initialized"], interval: 5s, retries: 30 }
    env_file: "${LAMP_HOME}/stack.env"
  certbot:
    image: certbot/certbot
    volumes:
      - "${LAMP_HOME}/certs/conf:/etc/letsencrypt"
      - "${LAMP_HOME}/certs/www:/var/www/certbot"
    entrypoint: ["/bin/sh", "/renew-loop.sh"]
```

In the Apache variant `app` publishes 80/443 itself and there is no `web` service; the vhosts are
mounted at `/etc/apache2/sites-enabled/`.

The MariaDB root password reaches **only** the `db` service (`env_file`), never the app container.

Path substitution uses `--env-file $CONFIG_PATH/lamp/stack.env`, so the templates stay static and
readable.

## State

`$CONFIG_PATH/lamp/stack.env` (600), also the compose env file:

```
LAMP_HOME=/home/<user>/config/lamp
LAMP_WEBSERVER=nginx
LAMP_PHP=8.5
LAMP_PHP_RESOLVED=8.5.12
LAMP_MARIADB=latest
LAMP_MARIADB_RESOLVED=13.0.2
LAMP_MARIADB_DIGEST=sha256:…
LAMP_DOMAIN=
MARIADB_ROOT_PASSWORD=<generated>
MARIADB_DATABASE=lamp
```

`$CONFIG_PATH/lamp/sites` is the source of truth for `site.add` (domain and docroot per line);
`conf.d/*.conf` is rendered from it and from the installed variant.

`latest` moves, so the resolved version and digest are recorded at install time and shown by
`status`; `stack.up` never re-pulls. Upgrading is an explicit `stack.install`, which reports
`mariadb 13.0.2 → 13.1.0`.

## Error handling

| Situation | rc | RESULT |
|---|---|---|
| Docker unusable | 1 | `docker is not usable here — run: odocker prereqs.install` |
| Template missing | 1 | `no template at <path>` |
| Port 80/443 owned elsewhere | 1 | `port 80 is taken by <container>` |
| Missing PHP extension | 1 | `php is missing: intl imagick` |
| Unknown web server | 1 | `nginx or apache` |
| Install on another variant | 0 | `switched nginx → apache` |
| Same install again | 0 | `already installed (nginx)` |
| vhost differs | 1 | `<file> exists with different content` |
| DB exists | 1 | `database <name> already exists` |
| cert challenge fails | 1 | certbot's error line |
| no vhost for domain | 1 | `no site <domain> — lamp site.add <domain> <docroot> first` |

Every failure logs the same message to `error.log`; every success logs to `success.log`.

## Testing

`test/test.lamp` (`TEST_CATEGORY=core`), Docker not required:

1. `docker`/`docker compose` stubbed as shell functions that record argv.
2. Install with `nginx` writes `stack.env`, selects the nginx template, builds and ups.
3. Install with `apache` selects the apache template; no `web` service.
4. Install with no argument, non-TTY → rc 1; with a TTY → prompt (driven via a here-string).
5. Invalid variant → rc 1 listing both.
6. Same install again → rc 0 `already installed`; different → `switched`.
7. `site.add` writes `try_files` for nginx and `AllowOverride All` for apache; reload command
   asserted.
8. `db.create` generates a password, refuses a duplicate, records credentials 600.
9. `cert.issue` refuses a domain with no vhost; success path rewrites the vhost with 443.
10. Missing-extension path: stub `php -m` without `intl` → rc 1 names it.
11. Dockerfile text assertions: `intl gd imagick pdo_mysql mysqli` installed, `a2enmod rewrite`,
    `FROM php:8.5`.
12. One integration case, skipped unless `odocker.support.check` passes: install nginx on an unused
    port pair, curl `phpinfo`-less index for `intl` and `pdo_mysql`, then down.

Docs: `docs/lamp.md` added; `docs/methods-index.md`, `docs/object-verb-index.md`,
`docs/parameter.md` rows updated; completion hooks for `webserver`, `domain`, `docroot`, `name`.

## Acceptance criteria

- `./lamp stack.install nginx` and `./lamp stack.install apache` both produce a working stack with
  PHP 8.5, MariaDB, and all required extensions verified inside the container.
- The same command on an installed stack either says `already installed` or switches variant,
  never leaves half a stack.
- `site.add`, `db.create`, `cert.issue` each work on both variants and say what changed.
- `test.ossh`-style coverage: `./test.suite run lamp 1` is green without Docker present.
- `docs/lamp.md` documents every method and its rc/RESULT.

## Risks

- First build pulls ICU/ImageMagick dev packages; expect minutes on a slow link.
- `mariadb:latest` drift is recorded, not prevented.
- Certbot has rate limits; `cert.issue` surfaces them instead of retrying.
- Two stacks on one host need different ports, which v1 does not support (non-goal).

## Decisions log

| Question | Decision |
|---|---|
| Where does the command live? | new `lamp` component |
| How is the web server chosen? | argument, prompt fallback |
| Image strategy | official bases + thin Dockerfile for extensions |
| PHP / MariaDB | 8.5 / latest, resolved values recorded |
| TLS | Let's Encrypt on demand, 12 h renew loop |
| Scope | local machine only |
| Extensions | intl, mbstring, json, curl, gd, imagick, simplexml, pdo_mysql, mysqli, opcache, mod_rewrite |
