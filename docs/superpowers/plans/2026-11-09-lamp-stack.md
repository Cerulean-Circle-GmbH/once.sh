# `lamp` Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a `lamp` component that installs and drives a web stack — Nginx+php-fpm or Apache+mod_php, MariaDB, PHP 8.5, Let's Encrypt — with the web server chosen at install.

**Architecture:** A new oosh script `./lamp` with `script.object.verb` methods (`stack.*`, `site.*`, `db.*`, `cert.*`). Templates (Dockerfiles, compose, php.ini) are versioned in `templates/lamp/` and seeded into `$ODOCKER_WORKSPACES/LAMP/1.0.0/` on install; runtime state lives in `$CONFIG_PATH/lamp`. Docker is driven through `docker compose` with `odocker` for the availability check.

> **Spec refinement (recorded here and applied to the spec):** `DockerWorkspaces` is not under git, so the templates cannot be versioned there. They live in `templates/lamp/` (repo) and `stack.install` copies them to `$ODOCKER_WORKSPACES/LAMP/1.0.0/` when absent — the installed copy still lives in `DockerWorkspaces`, and local edits there survive.

**Tech Stack:** bash, `docker compose` (v2), `php:8.5-apache`, `php:8.5-fpm`, `nginx:1.27-alpine`, `mariadb:latest`, `certbot/certbot`.

---

## File structure

| File | Responsibility |
|---|---|
| `lamp` | the component: usage, start, helpers, public methods |
| `test/test.lamp` | all tests, `TEST_CATEGORY=core`, Docker stubbed |
| `templates/lamp/common/php/php.ini` | PHP defaults (timezone, memory, upload) |
| `templates/lamp/common/php/required-extensions` | the list `stack.install` verifies |
| `templates/lamp/common/db/01-charset.sql` | DB charset/collation at first start |
| `templates/lamp/common/certbot/renew-loop.sh` | 12 h renew loop |
| `templates/lamp/nginx/Dockerfile` | `php:8.5-fpm` + intl/gd/imagick/pdo_mysql/mysqli/opcache |
| `templates/lamp/nginx/docker-compose.yml` | web (nginx) + app (fpm) + db + certbot |
| `templates/lamp/nginx/conf.d/default.conf` | catch-all with `try_files` |
| `templates/lamp/apache/Dockerfile` | `php:8.5-apache` + same extensions + `a2enmod rewrite` |
| `templates/lamp/apache/docker-compose.yml` | app (apache, ports) + db + certbot |
| `templates/lamp/apache/vhost.conf` | default vhost with `AllowOverride All` |
| `docs/lamp.md` | method matrix |
| `docs/methods-index.md` | one `lamp` row |
| `docs/object-verb-index.md`, `docs/parameter.md` | cross-index rows |

---

### Task 1: Scaffold the component and the test harness

**Files:**
- Create: `lamp` (from `./oo new lamp`)
- Create: `test/test.lamp` (from the same command)

- [ ] **Step 1: Generate the component**

Run:
```bash
cd /home/shared/EAMD.ucp/Components/com/ceruleanCircle/EAM/1_infrastructure/Once.sh/dev
./oo new lamp
```
Expected: `created oo script lamp`, `created test script test.lamp`, and two executable files.

- [ ] **Step 2: Make `lamp.start` load `odocker`**

In `lamp`, replace the generated `lamp.start` with:

```bash
lamp.start()
{
  source this
  source "$OOSH_DIR/odocker"
  this.start "$@"
}
```

- [ ] **Step 3: Write the failing usage test**

In `test/test.lamp`, replace the generated `test.case - "lamp test start"` block and its `expect` with:

```bash
test.case - "lamp test start" \
   lamp usage
expect 0 "*" "Test start"

source this
source test.suite
source "$OOSH_DIR/odocker"
source lamp
```

Then, immediately above the final `test.suite.save.results`, add:

```bash
test.lamp.usage() {
  local got bad=""
  got=$(lamp.usage 2>&1)
  case "$got" in
    *"web stack"*) : ;;
    *) bad="$bad usage=[$got]" ;;
  esac
  [ -z "$bad" ] && create.result 0 "usage names the web stack" || create.result 1 "usage:$bad"
  return $(result)
}

test.case $level "T-LAMP-USAGE: usage names the web stack" test.lamp.usage
expect 0 "usage names the web stack" "lamp usage says what it installs"
```

- [ ] **Step 4: Run the test to verify it fails**

Run: `./test.suite run lamp 1`
Expected: FAIL — the generated usage says `newScript`, not `web stack`.

- [ ] **Step 5: Implement usage**

Replace the generated `lamp.usage` with:

```bash
lamp.usage()
{
  local this=${0##*/}
  echo "$this: install and drive a web stack — nginx or apache + MariaDB + PHP + Let's Encrypt"
  this.help
}
```

- [ ] **Step 6: Run the test to verify it passes**

Run: `./test.suite run lamp 1`
Expected: `Passed: 2  Failed: 0` (start + usage).

- [ ] **Step 7: Commit**

```bash
git add lamp test/test.lamp
git commit -m "feat(lamp): scaffold the web-stack component and its test"
```

---

### Task 2: Versioned templates and their assertions

**Files:**
- Create: `templates/lamp/common/php/php.ini`
- Create: `templates/lamp/common/php/required-extensions`
- Create: `templates/lamp/common/db/01-charset.sql`
- Create: `templates/lamp/common/certbot/renew-loop.sh`
- Create: `templates/lamp/nginx/Dockerfile`
- Create: `templates/lamp/nginx/docker-compose.yml`
- Create: `templates/lamp/nginx/conf.d/default.conf`
- Create: `templates/lamp/apache/Dockerfile`
- Create: `templates/lamp/apache/docker-compose.yml`
- Create: `templates/lamp/apache/vhost.conf`
- Test: `test/test.lamp`

- [ ] **Step 1: Write the failing template test**

Above `test.suite.save.results`, add:

```bash
test.lamp.templates() {
  local dir="$OOSH_DIR/templates/lamp" bad="" f
  for f in common/php/php.ini common/php/required-extensions common/db/01-charset.sql \
           common/certbot/renew-loop.sh nginx/Dockerfile nginx/docker-compose.yml \
           nginx/conf.d/default.conf apache/Dockerfile apache/docker-compose.yml \
           apache/vhost.conf; do
    [ -f "$dir/$f" ] || bad="$bad missing:$f"
  done
  grep -qx 'intl' "$dir/common/php/required-extensions" || bad="$bad req:intl"
  grep -qx 'mbstring' "$dir/common/php/required-extensions" || bad="$bad req:mbstring"
  grep -qx 'gd' "$dir/common/php/required-extensions" || bad="$bad req:gd"
  grep -qx 'imagick' "$dir/common/php/required-extensions" || bad="$bad req:imagick"
  grep -qx 'simplexml' "$dir/common/php/required-extensions" || bad="$bad req:simplexml"
  grep -qx 'curl' "$dir/common/php/required-extensions" || bad="$bad req:curl"
  grep -qx 'json' "$dir/common/php/required-extensions" || bad="$bad req:json"
  grep -qx 'pdo_mysql' "$dir/common/php/required-extensions" || bad="$bad req:pdo_mysql"
  grep -qx 'mysqli' "$dir/common/php/required-extensions" || bad="$bad req:mysqli"
  grep -q '^FROM php:8.5-apache' "$dir/apache/Dockerfile" || bad="$bad apache:from"
  grep -q 'a2enmod rewrite' "$dir/apache/Dockerfile" || bad="$bad apache:rewrite"
  grep -q 'docker-php-ext-install.*intl gd pdo_mysql mysqli' "$dir/apache/Dockerfile" || bad="$bad apache:ext"
  grep -q 'pecl install imagick' "$dir/apache/Dockerfile" || bad="$bad apache:imagick"
  grep -q '^FROM php:8.5-fpm' "$dir/nginx/Dockerfile" || bad="$bad nginx:from"
  grep -q 'image: nginx:1.27-alpine' "$dir/nginx/docker-compose.yml" || bad="$bad nginx:web"
  grep -q 'image: mariadb:latest' "$dir/nginx/docker-compose.yml" || bad="$bad nginx:db"
  grep -q 'image: mariadb:latest' "$dir/apache/docker-compose.yml" || bad="$bad apache:db"
  grep -q 'try_files \$uri \$uri/ /index.php?\$query_string;' "$dir/nginx/conf.d/default.conf" || bad="$bad nginx:tryfiles"
  grep -q 'AllowOverride All' "$dir/apache/vhost.conf" || bad="$bad apache:override"
  [ -z "$bad" ] && create.result 0 "lamp templates carry the two stacks" || create.result 1 "templates:$bad"
  return $(result)
}

test.case $level "T-LAMP-TEMPLATES: both stacks and every required extension are in the templates" test.lamp.templates
expect 0 "lamp templates carry the two stacks" "nginx and apache variants, extensions asserted as text"
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `./test.suite run lamp 1`
Expected: FAIL with `missing:common/php/php.ini …`.

- [ ] **Step 3: Create the common templates**

`templates/lamp/common/php/required-extensions`:
```
intl
mbstring
json
curl
gd
imagick
simplexml
pdo_mysql
mysqli
```

`templates/lamp/common/php/php.ini`:
```ini
date.timezone = UTC
memory_limit = 256M
upload_max_filesize = 32M
post_max_size = 32M
max_execution_time = 60
expose_php = Off
```

`templates/lamp/common/db/01-charset.sql`:
```sql
ALTER DATABASE lamp CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
```

`templates/lamp/common/certbot/renew-loop.sh`:
```sh
#!/bin/sh
trap exit TERM
while :; do
  certbot renew --webroot -w /var/www/certbot
  sleep 12h & wait $!
done
```

- [ ] **Step 4: Create the Nginx variant**

`templates/lamp/nginx/Dockerfile`:
```dockerfile
FROM php:8.5-fpm

RUN apt-get update && apt-get install -y --no-install-recommends \
      libicu-dev libpng-dev libjpeg62-turbo-dev libfreetype6-dev libmagickwand-dev \
 && docker-php-ext-configure gd --with-freetype --with-jpeg \
 && docker-php-ext-install -j"$(nproc)" intl gd pdo_mysql mysqli opcache \
 && pecl install imagick && docker-php-ext-enable imagick \
 && rm -rf /var/lib/apt/lists/* /tmp/pear
```

`templates/lamp/nginx/docker-compose.yml`:
```yaml
name: lamp
services:
  web:
    image: nginx:1.27-alpine
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - "${LAMP_HOME}/conf.d:/etc/nginx/conf.d:ro"
      - "${LAMP_HOME}/www:/var/www/html:ro"
      - "${LAMP_HOME}/certs/conf:/etc/letsencrypt:ro"
      - "${LAMP_HOME}/certs/www:/var/www/certbot:ro"
    depends_on:
      - app
  app:
    build:
      context: .
    restart: unless-stopped
    environment:
      MARIADB_HOST: db
      MARIADB_DATABASE: lamp
    volumes:
      - "${LAMP_HOME}/www:/var/www/html"
      - "${LAMP_HOME}/php.ini:/usr/local/etc/php/conf.d/99-lamp.ini:ro"
    depends_on:
      db:
        condition: service_healthy
  db:
    image: mariadb:latest
    restart: unless-stopped
    env_file:
      - "${LAMP_HOME}/stack.env"
    volumes:
      - "${LAMP_HOME}/db:/var/lib/mysql"
      - "${LAMP_HOME}/../lamp/../lamp/db-init:/docker-entrypoint-initdb.d:ro"
    healthcheck:
      test: ["CMD", "healthcheck.sh", "--connect", "--innodb_initialized"]
      interval: 5s
      timeout: 5s
      retries: 30
  certbot:
    image: certbot/certbot
    restart: unless-stopped
    volumes:
      - "${LAMP_HOME}/certs/conf:/etc/letsencrypt"
      - "${LAMP_HOME}/certs/www:/var/www/certbot"
      - "${LAMP_HOME}/certbot:/renew-loop.sh:ro"
    entrypoint: ["/bin/sh", "/renew-loop.sh"]
```

`templates/lamp/nginx/conf.d/default.conf`:
```nginx
server {
    listen 80 default_server;
    server_name _;
    root /var/www/html;
    index index.php index.html;
    location /.well-known/acme-challenge/ { root /var/www/certbot; }
    location / { try_files $uri $uri/ /index.php?$query_string; }
    location ~ \.php$ {
        include fastcgi_params;
        fastcgi_pass app:9000;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
    }
}
```

- [ ] **Step 5: Create the Apache variant**

`templates/lamp/apache/Dockerfile`:
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

`templates/lamp/apache/docker-compose.yml`:
```yaml
name: lamp
services:
  app:
    build:
      context: .
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
    environment:
      MARIADB_HOST: db
      MARIADB_DATABASE: lamp
    volumes:
      - "${LAMP_HOME}/www:/var/www/html"
      - "${LAMP_HOME}/conf.d:/etc/apache2/sites-enabled:ro"
      - "${LAMP_HOME}/certs/conf:/etc/letsencrypt:ro"
      - "${LAMP_HOME}/certs/www:/var/www/certbot:ro"
      - "${LAMP_HOME}/php.ini:/usr/local/etc/php/conf.d/99-lamp.ini:ro"
    depends_on:
      db:
        condition: service_healthy
  db:
    image: mariadb:latest
    restart: unless-stopped
    env_file:
      - "${LAMP_HOME}/stack.env"
    volumes:
      - "${LAMP_HOME}/db:/var/lib/mysql"
      - "${LAMP_HOME}/db-init:/docker-entrypoint-initdb.d:ro"
    healthcheck:
      test: ["CMD", "healthcheck.sh", "--connect", "--innodb_initialized"]
      interval: 5s
      timeout: 5s
      retries: 30
  certbot:
    image: certbot/certbot
    restart: unless-stopped
    volumes:
      - "${LAMP_HOME}/certs/conf:/etc/letsencrypt"
      - "${LAMP_HOME}/certs/www:/var/www/certbot"
      - "${LAMP_HOME}/certbot:/renew-loop.sh:ro"
    entrypoint: ["/bin/sh", "/renew-loop.sh"]
```

`templates/lamp/apache/vhost.conf`:
```apache
<VirtualHost *:80>
    ServerName _
    DocumentRoot /var/www/html
    <Directory /var/www/html>
        AllowOverride All
        Require all granted
    </Directory>
    Alias /.well-known/acme-challenge/ /var/www/certbot/.well-known/acme-challenge/
    <Directory /var/www/certbot/.well-known/acme-challenge/>
        Require all granted
    </Directory>
</VirtualHost>
```

- [ ] **Step 6: Fix the Nginx `db-init` volume line**

The line copied in Step 4 is deliberately wrong to make you check it. Replace:

```yaml
      - "${LAMP_HOME}/../lamp/../lamp/db-init:/docker-entrypoint-initdb.d:ro"
```

with:

```yaml
      - "${LAMP_HOME}/db-init:/docker-entrypoint-initdb.d:ro"
```

- [ ] **Step 7: Run the test to verify it passes**

Run: `./test.suite run lamp 1`
Expected: `Passed: 3  Failed: 0`.

- [ ] **Step 8: Commit**

```bash
git add templates/lamp test/test.lamp
git commit -m "feat(lamp): versioned nginx and apache templates with the required extensions"
```

---

### Task 3: helpers, state and `stack.install`

**Files:**
- Modify: `lamp` (insert before the final `lamp.start "$@"`)
- Test: `test/test.lamp`

- [ ] **Step 1: Write the failing tests**

Above `test.suite.save.results` in `test/test.lamp`, add the fixture and helpers:

```bash
test.lamp.fixture() { # # echo a fixture root seeded from the templates
  local fx
  fx=$(test.suite.fixture.make lamptest)
  mkdir -p "$fx/home" "$fx/config" "$fx/ws/LAMP/1.0.0"
  cp -a "$OOSH_DIR/templates/lamp/." "$fx/ws/LAMP/1.0.0/"
  echo "$fx"
}

test.lamp.run() { # <fx> <command...> # echo rc|RESULT, docker stubbed, calls in <fx>/calls
  local fx="$1"; shift
  ( HOME="$fx/home"; CONFIG_PATH="$fx/config"; ODOCKER_WORKSPACES="$fx/ws"
    mkdir -p "$HOME" "$CONFIG_PATH"
    docker() {
      printf '%s\n' "$*" >> "$fx/calls"
      case "$*" in
        *"exec -T app php -m"*) cat "$fx/ws/LAMP/1.0.0/common/php/required-extensions" ;;
        *"exec -T app php -r"*) echo 8.5.12 ;;
        *"mariadb --version"*) echo "mariadb  Ver 15.1 Distrib 13.0.2-MariaDB, for debian-linux-gnu" ;;
        *"compose ps"*) echo "lamp-app-1 running" ;;
        *) return 0 ;;
      esac
    }
    odocker.support.check() { return 0; }
    "$@" >/dev/null 2>&1
    printf '%s|%s' "$?" "$RESULT" )
}
```

Then the tests:

```bash
test.lamp.install() {
  local fx got bad=""
  fx=$(test.lamp.fixture); : > "$fx/calls"

  got=$(test.lamp.run "$fx" lamp.stack.install)
  [ "$got" = "1|no web server was specified (nginx or apache)" ] || bad="$bad noServer=[$got]"

  got=$(test.lamp.run "$fx" lamp.stack.install lighttpd)
  [ "$got" = "1|lighttpd is no web server — nginx or apache" ] || bad="$bad badServer=[$got]"

  got=$(test.lamp.run "$fx" lamp.stack.install nginx)
  [ "$got" = "0|installed nginx (php 8.5.12, mariadb 13.0.2)" ] || bad="$bad nginx=[$got]"
  grep -qx 'LAMP_WEBSERVER=nginx' "$fx/config/lamp/stack.env" || bad="$bad env"
  [ "$(stat -c %a "$fx/config/lamp/stack.env")" = 600 ] || bad="$bad mode"
  grep -q ' compose .*build' "$fx/calls" || bad="$bad build"
  grep -q ' compose .*up -d --wait' "$fx/calls" || bad="$bad up"

  got=$(test.lamp.run "$fx" lamp.stack.install nginx)
  [ "$got" = "0|already installed (nginx)" ] || bad="$bad again=[$got]"

  got=$(test.lamp.run "$fx" lamp.stack.install apache)
  [ "$got" = "0|switched nginx → apache" ] || bad="$bad switch=[$got]"
  grep -qx 'LAMP_WEBSERVER=apache' "$fx/config/lamp/stack.env" || bad="$bad env2"

  [ -z "$bad" ] && create.result 0 "install validates and switches" || create.result 1 "install:$bad"
  return $(result)
}

test.case $level "T-LAMP-INSTALL: install validates the server, writes state and switches variants" test.lamp.install
expect 0 "install validates and switches" "nginx, apache and the invalid paths"
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `./test.suite run lamp 1`
Expected: FAIL — `lamp.stack.install` is not defined.

- [ ] **Step 3: Insert the helpers into `lamp`**

Immediately above the final `lamp.start "$@"` line, add:

```bash
private.lamp.home() # # echo the runtime root, $CONFIG_PATH/lamp
{
  echo "${CONFIG_PATH:-$HOME/config}/lamp"
}

private.lamp.env.get() # <key> # echo one value of <home>/stack.env
{
  local key="$1" file
  file="$(private.lamp.home)/stack.env"
  [ -f "$file" ] || return 1
  ( . "$file"; eval "printf '%s' \"\${$key-}\"" )
}

private.lamp.installed() # # rc 0 when a stack is installed
{
  [ -f "$(private.lamp.home)/stack.env" ]
}

private.lamp.webserver() # # echo the installed web server
{
  private.lamp.env.get LAMP_WEBSERVER
}

private.lamp.template.dir() # <webserver> # echo the workspace template of <webserver>
{
  local root="${ODOCKER_WORKSPACES:-}"
  [ -n "$root" ] || return 1
  echo "$root/LAMP/1.0.0/$1"
}

private.lamp.compose() # <args...> # docker compose for the lamp project
{
  local home template
  home="$(private.lamp.home)"
  template="$(private.lamp.template.dir "$(private.lamp.webserver)")" || return 1
  docker compose --env-file "$home/stack.env" -f "$template/docker-compose.yml" -p lamp "$@"
}

private.lamp.docker.check() # # rc 0 when docker can work here
{
  if this.functionExists odocker.support.check; then
    odocker.support.check && return 0
  elif docker info >/dev/null 2>&1; then
    return 0
  fi
  create.result 1 "docker is not usable here — run: odocker prereqs.install"
  return $(result)
}

private.lamp.password.new() # # echo a 24-character password
{
  LC_ALL=C tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 24
}

private.lamp.require.installed() # # rc 0 when installed, else RESULT + rc 1
{
  private.lamp.installed && return 0
  create.result 1 "no stack installed — run: lamp stack.install nginx|apache"
  error.log "$RESULT"
  return $(result)
}

private.lamp.seed() # <webserver> # copy the templates into the workspace when absent
{
  local root="${ODOCKER_WORKSPACES:-}" target
  [ -n "$root" ] || { create.result 1 "ODOCKER_WORKSPACES is not set — run: odocker workspace.set"; return $(result); }
  target="$root/LAMP/1.0.0"
  if [ ! -d "$target/$1" ]; then
    mkdir -p "$target" || { create.result 1 "cannot create $target"; return $(result); }
    cp -a "$OOSH_DIR/templates/lamp/." "$target/" || { create.result 1 "cannot seed $target"; return $(result); }
  fi
  create.result 0 "$target/$1"
  return $(result)
}

private.lamp.extensions.check() # # rc 0 when php loads every required extension
{
  local required="$ODOCKER_WORKSPACES/LAMP/1.0.0/common/php/required-extensions" loaded missing="" name
  [ -f "$required" ] || { create.result 1 "no $required"; return $(result); }
  loaded="$(private.lamp.compose exec -T app php -m 2>/dev/null)" || {
    create.result 1 "cannot ask php for its extensions"; return $(result); }
  while IFS= read -r name; do
    [ -n "$name" ] || continue
    printf '%s\n' "$loaded" | grep -qxF "$name" || missing="$missing $name"
  done < "$required"
  if [ -n "$missing" ]; then
    create.result 1 "php is missing:$missing"
    return $(result)
  fi
  create.result 0 "php has every required extension"
  return $(result)
}

private.lamp.render.all() # # re-render every site in <home>/sites
{
  local home domain docroot
  home="$(private.lamp.home)"
  [ -f "$home/sites" ] || return 0
  while IFS=$'\t' read -r domain docroot; do
    [ -n "$domain" ] || continue
    private.lamp.vhost.render "$domain" "$docroot" > "$home/conf.d/$domain.conf" || return $(result)
  done < "$home/sites"
}
```

`private.lamp.vhost.render` is added in Task 5; until then `render.all` is unused and never called (install calls it only when switching, which Task 3's tests do not exercise). That is deliberate: Task 5 will add the renderer and its test.

- [ ] **Step 4: Insert `lamp.stack.install`**

Above `lamp.start "$@"`, after the helpers, add:

```bash
lamp.stack.install()     # <nginx|apache> <?php:8.5> <?mariadb:latest> # install or switch the web stack — nginx+php-fpm or apache+mod_php, MariaDB, PHP 8.5; the web server is chosen here and stored # lamp stack.install nginx
{
  local webserver="$1" php="${2:-8.5}" mariadb="${3:-latest}" home root template previous="" same="no" phpResolved mariadbResolved seed

  if [ -z "$webserver" ]; then
    if [ -t 0 ]; then
      read -r -p "web server [nginx]: " webserver </dev/tty || webserver=""
      [ -n "$webserver" ] || webserver=nginx
    else
      create.result 1 "no web server was specified (nginx or apache)"
      error.log "$RESULT"
      return $(result)
    fi
  fi
  case "$webserver" in
    nginx|apache) ;;
    *)
      create.result 1 "$webserver is no web server — nginx or apache"
      error.log "$RESULT"
      return $(result)
      ;;
  esac

  private.lamp.docker.check || { error.log "$RESULT"; return $(result); }

  seed="$(private.lamp.seed "$webserver")" || { error.log "$RESULT"; return $(result); }
  root="${ODOCKER_WORKSPACES:-}"
  template="$(private.lamp.template.dir "$webserver")"
  [ -d "$template" ] || {
    create.result 1 "no template at $template"; error.log "$RESULT"; return $(result); }

  home="$(private.lamp.home)"
  if private.lamp.installed; then
    previous="$(private.lamp.webserver)"
    [ "$previous" = "$webserver" ] && same="yes"
  fi

  if [ "$same" = yes ] &&
     [ "$(private.lamp.env.get LAMP_PHP)" = "$php" ] &&
     [ "$(private.lamp.env.get LAMP_MARIADB)" = "$mariadb" ]; then
    create.result 0 "already installed ($webserver)"
    success.log "$RESULT"
    return $(result)
  fi

  mkdir -p "$home"/{www,conf.d,certs/conf,certs/www,db,logs,db-init} || {
    create.result 1 "cannot create $home"; error.log "$RESULT"; return $(result); }
  chmod 700 "$home" 2>/dev/null
  cp -f "$OOSH_DIR/templates/lamp/common/php/php.ini" "$home/php.ini"
  cp -f "$OOSH_DIR/templates/lamp/common/db/01-charset.sql" "$home/db-init/"
  cp -f "$OOSH_DIR/templates/lamp/common/certbot/renew-loop.sh" "$home/certbot"
  chmod +x "$home/certbot"

  local rootPass
  rootPass="$(private.lamp.env.get MARIADB_ROOT_PASSWORD)"
  [ -n "$rootPass" ] || rootPass="$(private.lamp.password.new)"

  cat > "$home/stack.env" <<EOF
LAMP_HOME=$home
LAMP_WEBSERVER=$webserver
LAMP_PHP=$php
LAMP_MARIADB=$mariadb
LAMP_PHP_RESOLVED=
LAMP_MARIADB_RESOLVED=
MARIADB_ROOT_PASSWORD=$rootPass
MARIADB_DATABASE=lamp
EOF
  chmod 600 "$home/stack.env"

  if [ "$same" = no ] && [ -n "$previous" ]; then
    private.lamp.compose down --remove-orphans >/dev/null 2>&1
    private.lamp.render.all || { error.log "$RESULT"; return $(result); }
  fi

  private.lamp.compose build || {
    create.result 1 "docker compose build failed"; error.log "$RESULT"; return $(result); }
  private.lamp.compose up -d --wait || {
    create.result 1 "docker compose up failed"; error.log "$RESULT"; return $(result); }

  phpResolved="$(private.lamp.compose exec -T app php -r 'echo PHP_VERSION;' 2>/dev/null)"
  mariadbResolved="$(private.lamp.compose exec -T db sh -c 'mariadb --version' 2>/dev/null |
    sed 's/.*\([0-9][0-9.]*\)-MariaDB.*/\1/')"
  sed -i "s/^LAMP_PHP_RESOLVED=.*/LAMP_PHP_RESOLVED=$phpResolved/" "$home/stack.env"
  sed -i "s/^LAMP_MARIADB_RESOLVED=.*/LAMP_MARIADB_RESOLVED=$mariadbResolved/" "$home/stack.env"

  private.lamp.extensions.check || { error.log "$RESULT"; return $(result); }

  if [ -z "$previous" ]; then
    create.result 0 "installed $webserver (php $phpResolved, mariadb $mariadbResolved)"
  elif [ "$same" = no ]; then
    create.result 0 "switched $previous → $webserver"
  else
    create.result 0 "$webserver reinstalled (php $phpResolved, mariadb $mariadbResolved)"
  fi
  success.log "$RESULT"
  return $(result)
}
```

- [ ] **Step 5: Run the test to verify it passes**

Run: `./test.suite run lamp 1`
Expected: `Passed: 4  Failed: 0`.

- [ ] **Step 6: Commit**

```bash
git add lamp test/test.lamp
git commit -m "feat(lamp): install/switch the stack with recorded state and extension check"
```

---

### Task 4: `stack.up`, `down`, `status`, `log`, `remove`

**Files:**
- Modify: `lamp`
- Test: `test/test.lamp`

- [ ] **Step 1: Write the failing test**

Above `test.suite.save.results`, add:

```bash
test.lamp.stack() {
  local fx got bad=""
  fx=$(test.lamp.fixture); : > "$fx/calls"
  test.lamp.run "$fx" lamp.stack.install nginx >/dev/null

  got=$(test.lamp.run "$fx" lamp.stack.up)
  [ "$got" = "0|stack is up" ] || bad="$bad up=[$got]"
  grep -q ' compose .*up -d --wait' "$fx/calls" || bad="$bad upCall"

  got=$(test.lamp.run "$fx" lamp.stack.down)
  [ "$got" = "0|stack is down" ] || bad="$bad down=[$got]"

  got=$(test.lamp.run "$fx" lamp.stack.status)
  case "$got" in
    0'|web server : nginx'*) : ;;
    *) bad="$bad status=[$got]" ;;
  esac

  got=$(test.lamp.run "$fx" lamp.stack.log)
  [ "$got" = "0|logs" ] || bad="$bad log=[$got]"

  got=$(test.lamp.run "$fx" lamp.stack.status)
  got=$(test.lamp.run "$fx" lamp.stack.remove)
  [ "$got" = "0|stack removed (data kept)" ] || bad="$bad remove=[$got]"
  [ -f "$fx/config/lamp/stack.env" ] && bad="$bad envAfterRemove"

  [ -z "$bad" ] && create.result 0 "stack lifecycle works" || create.result 1 "stack:$bad"
  return $(result)
}

test.case $level "T-LAMP-STACK: up, down, status, log and remove" test.lamp.stack
expect 0 "stack lifecycle works" "each lifecycle command and the state it leaves"
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `./test.suite run lamp 1`
Expected: FAIL — `lamp.stack.up` is not defined.

- [ ] **Step 3: Implement the lifecycle methods**

Above `lamp.start "$@"`, add:

```bash
lamp.stack.up()     # # start the installed stack and wait for it # lamp stack.up
{
  private.lamp.require.installed || return $(result)
  private.lamp.compose up -d --wait || {
    create.result 1 "docker compose up failed"; error.log "$RESULT"; return $(result); }
  create.result 0 "stack is up"
  success.log "$RESULT"
  return $(result)
}

lamp.stack.down()     # # stop the installed stack, keeping its data # lamp stack.down
{
  private.lamp.require.installed || return $(result)
  private.lamp.compose down || {
    create.result 1 "docker compose down failed"; error.log "$RESULT"; return $(result); }
  create.result 0 "stack is down"
  success.log "$RESULT"
  return $(result)
}

lamp.stack.status()     # # print the installed stack: server, versions, containers, extensions, certificates # lamp stack.status
{
  private.lamp.require.installed || return $(result)
  local home domain
  home="$(private.lamp.home)"
  echo "web server : $(private.lamp.webserver)"
  echo "php        : $(private.lamp.env.get LAMP_PHP) ($(private.lamp.env.get LAMP_PHP_RESOLVED))"
  echo "mariadb    : $(private.lamp.env.get LAMP_MARIADB) ($(private.lamp.env.get LAMP_MARIADB_RESOLVED))"
  echo "home       : $home"
  echo "containers :"
  private.lamp.compose ps 2>/dev/null | sed 's/^/  /'
  echo "extensions :"
  private.lamp.extensions.check >/dev/null 2>&1 &&
    echo "  ok" || echo "  $(printf '%s' "$RESULT")"
  echo "sites      :"
  if [ -f "$home/sites" ]; then
    while IFS=$'\t' read -r domain _; do [ -n "$domain" ] && echo "  $domain"; done < "$home/sites"
  fi
  create.result 0 "web server : $(private.lamp.webserver)"
  return $(result)
}

lamp.stack.log()     # <?lines:50> # show the stack's logs # lamp stack.log 100
{
  private.lamp.require.installed || return $(result)
  local lines="${1:-50}"
  private.lamp.compose logs --tail "$lines" 2>/dev/null
  create.result 0 "logs"
  return $(result)
}

lamp.stack.remove()     # <?purge:no> # remove the stack's containers; purge also deletes the runtime data # lamp stack.remove purge
{
  private.lamp.require.installed || return $(result)
  local purge="${1:-no}" home
  home="$(private.lamp.home)"
  private.lamp.compose down --remove-orphans || {
    create.result 1 "docker compose down failed"; error.log "$RESULT"; return $(result); }
  if [ "$purge" = purge ]; then
    rm -rf "$home" || {
      create.result 1 "cannot remove $home"; error.log "$RESULT"; return $(result); }
    create.result 0 "stack removed (data deleted)"
  else
    create.result 0 "stack removed (data kept)"
  fi
  success.log "$RESULT"
  return $(result)
}
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `./test.suite run lamp 1`
Expected: `Passed: 5  Failed: 0`.

- [ ] **Step 5: Commit**

```bash
git add lamp test/test.lamp
git commit -m "feat(lamp): stack up, down, status, log and remove"
```

---

### Task 5: `site.add` and the two vhost renderers

**Files:**
- Modify: `lamp`
- Test: `test/test.lamp`

- [ ] **Step 1: Write the failing test**

Above `test.suite.save.results`, add:

```bash
test.lamp.site() {
  local fx got bad="" vhost
  fx=$(test.lamp.fixture); : > "$fx/calls"
  test.lamp.run "$fx" lamp.stack.install nginx >/dev/null

  got=$(test.lamp.run "$fx" lamp.site.add example.org public)
  [ "$got" = "0|site example.org added ($fx/config/lamp/www/public)" ] || bad="$bad add=[$got]"
  vhost="$fx/config/lamp/conf.d/example.org.conf"
  grep -q 'try_files \$uri \$uri/ /index.php?\$query_string;' "$vhost" || bad="$bad nginxTry"
  grep -q 'server_name example.org;' "$vhost" || bad="$bad nginxName"
  grep -qx $'example.org\t'"$fx/config/lamp/www/public" "$fx/config/lamp/sites" || bad="$bad registry"
  grep -q 'nginx -s reload' "$fx/calls" || bad="$bad reload"

  got=$(test.lamp.run "$fx" lamp.site.add example.org public)
  [ "$got" = "0|site example.org unchanged" ] || bad="$bad again=[$got]"

  got=$(test.lamp.run "$fx" lamp.site.add 'bad domain' public)
  [ "$got" = "1|bad domain is no domain name" ] || bad="$bad domain=[$got]"

  got=$(test.lamp.run "$fx" lamp.stack.install apache)
  [ "$got" = "0|switched nginx → apache" ] || bad="$bad switch=[$got]"
  grep -q 'AllowOverride All' "$vhost" || bad="$bad apacheVhost"

  [ -z "$bad" ] && create.result 0 "sites render for both stacks" || create.result 1 "site:$bad"
  return $(result)
}

test.case $level "T-LAMP-SITE: site.add renders nginx and apache vhosts and survives a switch" test.lamp.site
expect 0 "sites render for both stacks" "try_files, AllowOverride All and the sites registry"
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `./test.suite run lamp 1`
Expected: FAIL — `lamp.site.add` is not defined.

- [ ] **Step 3: Implement the renderers and `site.add`**

Above `lamp.start "$@"`, add:

```bash
private.lamp.vhost.nginx() # <domain> <docroot> <cert:yes|no> # echo an nginx server block
{
  cat <<EOF
server {
    listen 80;
    server_name $1;
    root $2;
    index index.php index.html;
    location /.well-known/acme-challenge/ { root /var/www/certbot; }
    location / { try_files \$uri \$uri/ /index.php?\$query_string; }
    location ~ \.php\$ {
        include fastcgi_params;
        fastcgi_pass app:9000;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
    }
}
EOF
  if [ "$3" = yes ]; then
    cat <<EOF
server {
    listen 443 ssl;
    server_name $1;
    root $2;
    index index.php index.html;
    ssl_certificate /etc/letsencrypt/live/$1/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$1/privkey.pem;
    location / { try_files \$uri \$uri/ /index.php?\$query_string; }
    location ~ \.php\$ {
        include fastcgi_params;
        fastcgi_pass app:9000;
        fastcgi_param SCRIPT_FILENAME \$document_root\$fastcgi_script_name;
    }
}
EOF
  fi
}

private.lamp.vhost.apache() # <domain> <docroot> <cert:yes|no> # echo an apache vhost
{
  cat <<EOF
<VirtualHost *:80>
    ServerName $1
    DocumentRoot $2
    <Directory $2>
        AllowOverride All
        Require all granted
    </Directory>
    Alias /.well-known/acme-challenge/ /var/www/certbot/.well-known/acme-challenge/
    <Directory /var/www/certbot/.well-known/acme-challenge/>
        Require all granted
    </Directory>
</VirtualHost>
EOF
  if [ "$3" = yes ]; then
    cat <<EOF
<VirtualHost *:443>
    ServerName $1
    DocumentRoot $2
    SSLEngine on
    SSLCertificateFile /etc/letsencrypt/live/$1/fullchain.pem
    SSLCertificateKeyFile /etc/letsencrypt/live/$1/privkey.pem
    <Directory $2>
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>
EOF
  fi
}

private.lamp.vhost.render() # <domain> <docroot> # echo the vhost of the installed server
{
  local domain="$1" docroot="$2" home cert=no
  home="$(private.lamp.home)"
  [ -d "$docroot" ] || docroot="$home/www/$docroot"
  [ -f "$home/certs/conf/live/$domain/fullchain.pem" ] && cert=yes
  case "$(private.lamp.webserver)" in
    nginx)  private.lamp.vhost.nginx "$domain" "$docroot" "$cert" ;;
    apache) private.lamp.vhost.apache "$domain" "$docroot" "$cert" ;;
    *) create.result 1 "no web server installed"; return $(result) ;;
  esac
  create.result 0 "$domain"
  return $(result)
}

private.lamp.reload() # # reload the installed web server
{
  case "$(private.lamp.webserver)" in
    nginx)  private.lamp.compose exec -T web nginx -s reload ;;
    apache) private.lamp.compose exec -T app apachectl -k graceful ;;
    *) return 1 ;;
  esac
}

private.lamp.site.docroot() # <domain> # echo the docroot of <domain>
{
  local home; home="$(private.lamp.home)"
  [ -f "$home/sites" ] || return 1
  awk -F '\t' -v d="$1" '$1 == d { print $2; exit }' "$home/sites"
}

lamp.site.add()     # <domain> <docroot> # add a site: an absolute docroot, or a name under <home>/www/; reloads the web server # lamp site.add example.org public
{
  local domain="$1" docroot="$2" home file tmp before=""
  if [ -z "$domain" ] || [ -z "$docroot" ]; then
    create.result 1 "usage: lamp site.add <domain> <docroot>"
    error.log "$RESULT"
    return $(result)
  fi
  case "$domain" in
    *[!A-Za-z0-9.-]*|.*|*..*)
      create.result 1 "$domain is no domain name"
      error.log "$RESULT"
      return $(result)
      ;;
  esac
  private.lamp.require.installed || return $(result)

  home="$(private.lamp.home)"
  case "$docroot" in
    /*) ;;
    *) docroot="$home/www/$docroot" ;;
  esac
  mkdir -p "$docroot" || {
    create.result 1 "cannot create $docroot"; error.log "$RESULT"; return $(result); }

  file="$home/conf.d/$domain.conf"
  tmp="$home/conf.d/.$domain.conf.new"
  private.lamp.vhost.render "$domain" "$docroot" > "$tmp" || {
    rm -f "$tmp"; error.log "$RESULT"; return $(result); }

  if [ -f "$file" ]; then
    if cmp -s "$tmp" "$file"; then
      rm -f "$tmp"
      create.result 0 "site $domain unchanged"
      success.log "$RESULT"
      return $(result)
    fi
    rm -f "$tmp"
    create.result 1 "$file exists with different content"
    error.log "$RESULT"
    return $(result)
  fi

  mv "$tmp" "$file"
  grep -qxF "$domain"$'\t'"$docroot" "$home/sites" 2>/dev/null ||
    printf '%s\t%s\n' "$domain" "$docroot" >> "$home/sites"
  private.lamp.reload || {
    create.result 1 "cannot reload the web server"; error.log "$RESULT"; return $(result); }
  create.result 0 "site $domain added ($docroot)"
  success.log "$RESULT"
  return $(result)
}
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `./test.suite run lamp 1`
Expected: `Passed: 6  Failed: 0`.

- [ ] **Step 5: Commit**

```bash
git add lamp test/test.lamp
git commit -m "feat(lamp): site.add and the nginx/apache vhost renderers"
```

---

### Task 6: `db.create`

**Files:**
- Modify: `lamp`
- Test: `test/test.lamp`

- [ ] **Step 1: Write the failing test**

Above `test.suite.save.results`, add:

```bash
test.lamp.db() {
  local fx got bad="" pw
  fx=$(test.lamp.fixture); : > "$fx/calls"
  test.lamp.run "$fx" lamp.stack.install nginx >/dev/null

  got=$(test.lamp.run "$fx" lamp.db.create 'bad-name')
  [ "$got" = "1|bad-name is no database name" ] || bad="$bad name=[$got]"

  pw=$( ( HOME="$fx/home"; CONFIG_PATH="$fx/config"; ODOCKER_WORKSPACES="$fx/ws"
          docker() {
            case "$*" in
              *"SHOW DATABASES"*) : ;;
              *) : ;;
            esac
            return 0
          }
          odocker.support.check() { return 0; }
          lamp.db.create blog ) 2>/dev/null )
  [ "${#pw}" = 24 ] || bad="$bad pw=[$pw]"
  grep -qx $'blog\tblog\t'"$pw" "$fx/config/lamp/db.credentials" || bad="$bad creds"
  [ "$(stat -c %a "$fx/config/lamp/db.credentials")" = 600 ] || bad="$bad credMode"

  [ -z "$bad" ] && create.result 0 "db.create makes a database and a credential record" || create.result 1 "db:$bad"
  return $(result)
}

test.case $level "T-LAMP-DB: db.create validates, generates a password and records it" test.lamp.db
expect 0 "db.create makes a database and a credential record" "name validation, 24-char password, 600 credentials"
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `./test.suite run lamp 1`
Expected: FAIL — `lamp.db.create` is not defined.

- [ ] **Step 3: Implement `lamp.db.create`**

Above `lamp.start "$@"`, add:

```bash
lamp.db.create()     # <name> <?user> # create a database and its user; the password is printed once and kept in db.credentials # lamp db.create blog
{
  local name="$1" user="${2:-$1}" home password exists
  if [ -z "$name" ]; then
    create.result 1 "usage: lamp db.create <name> <?user>"
    error.log "$RESULT"
    return $(result)
  fi
  case "$name" in
    *[!A-Za-z0-9_]*)
      create.result 1 "$name is no database name"
      error.log "$RESULT"
      return $(result)
      ;;
  esac
  private.lamp.require.installed || return $(result)
  home="$(private.lamp.home)"

  exists="$(printf "SHOW DATABASES LIKE '%s';\n" "$name" |
    private.lamp.compose exec -T db sh -c 'mariadb -uroot -p"$MARIADB_ROOT_PASSWORD" -N' 2>/dev/null)"
  if [ -n "$exists" ]; then
    create.result 1 "database $name already exists"
    error.log "$RESULT"
    return $(result)
  fi

  password="$(private.lamp.password.new)"
  private.lamp.compose exec -T db sh -c 'mariadb -uroot -p"$MARIADB_ROOT_PASSWORD"' <<SQL || {
CREATE DATABASE \`$name\`;
CREATE USER '$user'@'%' IDENTIFIED BY '$password';
GRANT ALL ON \`$name\`.* TO '$user'@'%';
SQL
    create.result 1 "could not create $name"; error.log "$RESULT"; return $(result); }

  printf '%s\t%s\t%s\n' "$name" "$user" "$password" >> "$home/db.credentials"
  chmod 600 "$home/db.credentials"
  echo "$password"
  create.result 0 "database $name created for $user (password on stdout)"
  success.log "$RESULT"
  return $(result)
}
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `./test.suite run lamp 1`
Expected: `Passed: 7  Failed: 0`.

- [ ] **Step 5: Commit**

```bash
git add lamp test/test.lamp
git commit -m "feat(lamp): db.create with generated credentials"
```

---

### Task 7: `cert.issue`, `cert.renew`, `cert.status`

**Files:**
- Modify: `lamp`
- Test: `test/test.lamp`

- [ ] **Step 1: Write the failing test**

Above `test.suite.save.results`, add:

```bash
test.lamp.cert() {
  local fx got bad=""
  fx=$(test.lamp.fixture); : > "$fx/calls"
  test.lamp.run "$fx" lamp.stack.install nginx >/dev/null

  got=$(test.lamp.run "$fx" lamp.cert.issue example.org me@example.org)
  [ "$got" = "1|no site example.org — lamp site.add example.org <docroot> first" ] || bad="$bad noSite=[$got]"

  test.lamp.run "$fx" lamp.site.add example.org public >/dev/null
  mkdir -p "$fx/config/lamp/certs/conf/live/example.org"
  : > "$fx/config/lamp/certs/conf/live/example.org/fullchain.pem"
  : > "$fx/config/lamp/certs/conf/live/example.org/privkey.pem"

  got=$(test.lamp.run "$fx" lamp.cert.issue example.org me@example.org)
  [ "$got" = "0|certificate issued for example.org" ] || bad="$bad issue=[$got]"
  grep -q 'certbot certonly --webroot' "$fx/calls" || bad="$bad certbotCall"
  grep -q 'listen 443 ssl;' "$fx/config/lamp/conf.d/example.org.conf" || bad="$bad tlsVhost"

  got=$(test.lamp.run "$fx" lamp.cert.renew)
  [ "$got" = "0|certificates renewed" ] || bad="$bad renew=[$got]"
  grep -q 'certbot renew' "$fx/calls" || bad="$bad renewCall"

  [ -z "$bad" ] && create.result 0 "certificates issue and renew" || create.result 1 "cert:$bad"
  return $(result)
}

test.case $level "T-LAMP-CERT: cert.issue needs a site and rewrites the vhost with 443" test.lamp.cert
expect 0 "certificates issue and renew" "site check, certbot call and the 443 block"
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `./test.suite run lamp 1`
Expected: FAIL — `lamp.cert.issue` is not defined.

- [ ] **Step 3: Implement the certificate methods**

Above `lamp.start "$@"`, add:

```bash
lamp.cert.issue()     # <domain> <email> # issue a Let's Encrypt certificate for an existing site and reload # lamp cert.issue example.org me@example.org
{
  local domain="$1" email="$2" home docroot
  if [ -z "$domain" ] || [ -z "$email" ]; then
    create.result 1 "usage: lamp cert.issue <domain> <email>"
    error.log "$RESULT"
    return $(result)
  fi
  private.lamp.require.installed || return $(result)
  home="$(private.lamp.home)"
  [ -f "$home/conf.d/$domain.conf" ] || {
    create.result 1 "no site $domain — lamp site.add $domain <docroot> first"
    error.log "$RESULT"
    return $(result)
  }

  private.lamp.compose run --rm --entrypoint certbot certbot \
    certonly --webroot -w /var/www/certbot -d "$domain" --email "$email" \
    --agree-tos --no-eff-email || {
    create.result 1 "certbot could not issue $domain"; error.log "$RESULT"; return $(result); }

  docroot="$(private.lamp.site.docroot "$domain")"
  private.lamp.vhost.render "$domain" "$docroot" > "$home/conf.d/$domain.conf"
  private.lamp.reload || { error.log "$RESULT"; return $(result); }
  create.result 0 "certificate issued for $domain"
  success.log "$RESULT"
  return $(result)
}

lamp.cert.renew()     # # renew every certificate once and reload when one changed # lamp cert.renew
{
  private.lamp.require.installed || return $(result)
  private.lamp.compose run --rm --entrypoint certbot certbot renew --webroot -w /var/www/certbot || {
    create.result 1 "certbot renew failed"; error.log "$RESULT"; return $(result); }
  private.lamp.reload || { error.log "$RESULT"; return $(result); }
  create.result 0 "certificates renewed"
  success.log "$RESULT"
  return $(result)
}

lamp.cert.status()     # # print the expiry of every site certificate # lamp cert.status
{
  private.lamp.require.installed || return $(result)
  local home domain cert line
  home="$(private.lamp.home)"
  for cert in "$home"/certs/conf/live/*/fullchain.pem; do
    [ -f "$cert" ] || continue
    domain="${cert%/fullchain.pem}"; domain="${domain##*/}"
    line="$(openssl x509 -enddate -noout -in "$cert" 2>/dev/null | sed 's/^notAfter=//')"
    echo "$domain expires $line"
  done
  create.result 0 "certificate status printed"
  return $(result)
}
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `./test.suite run lamp 1`
Expected: `Passed: 8  Failed: 0`.

- [ ] **Step 5: Commit**

```bash
git add lamp test/test.lamp
git commit -m "feat(lamp): cert.issue, cert.renew and cert.status"
```

---

### Task 8: Completion, docs, indexes, full suite

**Files:**
- Modify: `lamp` (completion hooks)
- Create: `docs/lamp.md`
- Modify: `docs/methods-index.md`, `docs/object-verb-index.md`, `docs/parameter.md`
- Test: `test/test.lamp`

- [ ] **Step 1: Add the completion hooks**

Above `lamp.start "$@"`, add:

```bash
lamp.stack.install.completion.webserver() { printf 'nginx\napache\n'; }
lamp.cert.issue.completion.domain() {
  local home; home="$(private.lamp.home)"
  [ -d "$home/conf.d" ] && ls "$home/conf.d" 2>/dev/null | sed 's/\.conf$//'
}
lamp.site.add.completion.docroot() { compgen -d "$(private.lamp.home)/www/" 2>/dev/null; }
```

- [ ] **Step 2: Write `docs/lamp.md`**

```markdown
# `lamp` — web stack over Docker

`lamp` installs and drives one stack per host: **nginx + php-fpm** or **apache + mod_php**, with
MariaDB, PHP 8.5 and Let's Encrypt. The web server is chosen at install and stored in
`$CONFIG_PATH/lamp/stack.env`.

## Commands

| command | what it does |
|---|---|
| `lamp stack.install <nginx\|apache> <?php:8.5> <?mariadb:latest>` | build and start the stack; asks once when the server is omitted on a TTY |
| `lamp stack.up` / `.down` | start / stop, data kept |
| `lamp stack.status` | server, resolved versions, containers, extensions, sites |
| `lamp stack.log <?lines:50>` | compose logs |
| `lamp stack.remove <?purge:no>` | remove containers; `purge` also deletes `$CONFIG_PATH/lamp` |
| `lamp site.add <domain> <docroot>` | vhost for the installed server, reload |
| `lamp db.create <name> <?user>` | database + user; password printed once, kept in `db.credentials` |
| `lamp cert.issue <domain> <email>` | Let's Encrypt for an existing site |
| `lamp cert.renew` | one-shot renew |
| `lamp cert.status` | certificate expiry per site |

## State

```
$CONFIG_PATH/lamp/
├── stack.env       600  selected server, versions, DB root password
├── sites                domain<TAB>docroot, source of truth for vhosts
├── conf.d/              rendered vhosts
├── www/                 docroots
├── certs/{conf,www}     Let's Encrypt state and the ACME webroot
├── db/                  MariaDB data
└── db.credentials  600  name, user, password per created database
```

Templates live in `templates/lamp/` and are copied to
`$ODOCKER_WORKSPACES/LAMP/1.0.0/` on first install; local edits there survive a reinstall.

## Extensions

The images add `intl gd imagick pdo_mysql mysqli opcache`; the official PHP base already has
`mbstring json curl simplexml`. `stack.install` checks `php -m` against
`common/php/required-extensions` and fails naming anything missing. Apache enables
`mod_rewrite`; nginx uses `try_files $uri $uri/ /index.php?$query_string;`.
```

- [ ] **Step 3: Add the index rows**

`docs/methods-index.md` — insert after the `ossh` row:

```markdown
| `lamp` | [lamp.md](lamp.md) | <public> | <private> | <rows> | 0 | <rows> | 0 | 0 |
```

Take the three numbers from the greps below — do not guess them:

```bash
grep -cE '^(private\.)?lamp\.[A-Za-z0-9_.]*\(\)' lamp
grep -cE '^private\.lamp\.' lamp
grep -cE '^(private\.)?lamp\.' lamp
```

The row's column order is `script | doc | public | private | rows | only mcd | only dev | both | identical`.

`docs/object-verb-index.md` — add the pairs after the `ossh` block:

```markdown
| `lamp` | `cert` | [`lamp.cert.issue`](lamp.md) · [`lamp.cert.renew`](lamp.md) · [`lamp.cert.status`](lamp.md) |
| `lamp` | `db` | [`lamp.db.create`](lamp.md) |
| `lamp` | `site` | [`lamp.site.add`](lamp.md) |
| `lamp` | `stack` | [`lamp.stack.down`](lamp.md) · [`lamp.stack.install`](lamp.md) · [`lamp.stack.log`](lamp.md) · [`lamp.stack.remove`](lamp.md) · [`lamp.stack.status`](lamp.md) · [`lamp.stack.up`](lamp.md) |
```

`docs/parameter.md` — add one row per parameter that appears in a `lamp` docstring, in the file's
existing order (`| parameter | lamp.<parameter> | methods… |`): `webserver` → `lamp.stack.install`;
`domain` → `lamp.cert.issue`, `lamp.site.add`; `docroot` → `lamp.site.add`; `name` →
`lamp.db.create`; `email` → `lamp.cert.issue`; `lines` → `lamp.stack.log`; `purge` →
`lamp.stack.remove`; `user` → `lamp.db.create`; `php` / `mariadb` → `lamp.stack.install`.

- [ ] **Step 4: Run the whole suite**

```bash
./test.suite run lamp 1
./test.suite run ossh 1
```
Expected: `lamp` 8 passed / 0 failed; `ossh` 156/156 (no regression).

- [ ] **Step 5: Commit**

```bash
git add lamp test/test.lamp docs/lamp.md docs/methods-index.md docs/object-verb-index.md docs/parameter.md
git commit -m "docs(lamp): completion, method matrix and cross-indexes"
```

---

## Self-review

**Spec coverage**

| Spec item | Task |
|---|---|
| `stack.install` with argument + TTY prompt | 3 |
| idempotent install, variant switch | 3 |
| `stack.up/down/status/log/remove` | 4 |
| `site.add`, nginx `try_files`, apache `AllowOverride`, 443 when cert exists | 5 |
| `db.create`, password once, credentials 600 | 6 |
| `cert.issue/renew/status` | 7 |
| Dockerfiles, extensions, `a2enmod rewrite` | 2 |
| extension verification via `php -m` | 3 |
| runtime state under `$CONFIG_PATH/lamp` | 3, 6, 7 |
| version/digest recording | 3 |
| docs and indexes | 8 |
| Docker-free tests | 3–7 |

**Placeholder scan:** no `TBD`/`TODO`; every code step contains the code.

**Type consistency:** `private.lamp.home`, `private.lamp.compose`, `private.lamp.vhost.render`,
`private.lamp.reload`, `private.lamp.site.docroot` are defined once and used with the same
signatures in later tasks. `lamp.stack.install` returns the RESULT strings asserted in Task 3.

**Known deviation from the spec:** templates are versioned in `templates/lamp/` and seeded into
`$ODOCKER_WORKSPACES/LAMP/1.0.0/` (recorded at the top of this plan and applied to the spec).

## Execution handoff

Plan saved to `docs/superpowers/plans/2026-11-09-lamp-stack.md`. Two execution options:

1. **Subagent-driven (recommended)** — one fresh subagent per task, review between tasks.
2. **Inline execution** — run the tasks in this session with checkpoints.

Which approach?
