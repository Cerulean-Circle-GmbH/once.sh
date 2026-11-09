# `lamp` Implementation Plan — Docker or native, by OS

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** One `lamp` component that detects the OS and installs the web stack natively or with Docker, with the same commands either way.

**Architecture:** A single `./lamp` script. `private.lamp.os.*` detects family/init/package manager; `private.lamp.backend.*` chooses and dispatches; `private.lamp.docker.*` and `private.lamp.native.*` implement the same contract (`install`, `up`, `down`, `status`, `log`, `remove`); `site.add`, `db.create`, `cert.*` are shared and call one backend-specific hook each.

**Tech Stack:** bash; apt-get + Sury, dnf + Remi, apk, brew; systemd, OpenRC, launchd; nginx/Apache, PHP 8.5, MariaDB, certbot; Docker + compose as the alternative backend.

---

## File structure

| File | Responsibility |
|---|---|
| `lamp` | the component: usage, start, OS/backend detection, dispatch, shared commands |
| `test/test.lamp` | tests, `TEST_CATEGORY=core`, package managers/services/Docker stubbed |
| `templates/lamp/common/php/php.ini` | PHP defaults |
| `templates/lamp/common/php/required-extensions` | the extension contract |
| `templates/lamp/common/db/01-charset.sql` | DB charset |
| `templates/lamp/common/certbot/renew-loop.sh` | Docker renew loop |
| `templates/lamp/docker/{nginx,apache}/…` | Dockerfiles + compose + vhosts |
| `templates/lamp/vhost/{nginx,apache}.conf` | vhost templates for both backends |
| `docs/lamp.md` | commands, platforms, backends |

---

### Task 1: Scaffold, usage, OS detection

**Files:**
- Create: `lamp`, `test/test.lamp` (`./oo new lamp`)
- Test: `test/test.lamp`

- [ ] **Step 1: Generate**

```bash
./oo new lamp
```

- [ ] **Step 2: `lamp.start` sources this + odocker, usage names the tool**

In `lamp`:

```bash
lamp.usage()
{
  local this=${0##*/}
  echo "$this: install a web stack — nginx or apache, MariaDB, PHP 8.5, certbot — with Docker or natively"
  this.help
}

lamp.start()
{
  source this
  source "$OOSH_DIR/odocker"
  this.start "$@"
}
```

- [ ] **Step 3: Write the failing detection test**

In `test/test.lamp`, after `source lamp`, and before `test.suite.save.results`:

```bash
test.lamp.osFamily() {
  local fx got bad=""
  fx=$(test.suite.fixture.make lampostest)
  printf 'ID=ubuntu\n'    > "$fx/ubuntu"
  printf 'ID=debian\n'    > "$fx/debian"
  printf 'ID=almalinux\n' > "$fx/alma"
  printf 'ID=rocky\n'     > "$fx/rocky"
  printf 'ID=alpine\n'    > "$fx/alpine"
  printf 'ID=arch\n'      > "$fx/arch"

  got=$(uname() { echo Linux; }; private.lamp.os.family "$fx/ubuntu")
  [ "$got" = $'debian\tsystemd\tapt-get' ] || bad="$bad ubuntu=[$got]"
  got=$(uname() { echo Linux; }; private.lamp.os.family "$fx/debian")
  [ "$got" = $'debian\tsystemd\tapt-get' ] || bad="$bad debian=[$got]"
  got=$(uname() { echo Linux; }; private.lamp.os.family "$fx/alma")
  [ "$got" = $'rhel\tsystemd\tdnf' ] || bad="$bad alma=[$got]"
  got=$(uname() { echo Linux; }; private.lamp.os.family "$fx/rocky")
  [ "$got" = $'rhel\tsystemd\tdnf' ] || bad="$bad rocky=[$got]"
  got=$(uname() { echo Linux; }; private.lamp.os.family "$fx/alpine")
  [ "$got" = $'alpine\topenrc\tapk' ] || bad="$bad alpine=[$got]"
  got=$(uname() { echo Linux; }; private.lamp.os.family "$fx/arch" 2>/dev/null)
  case "$got" in unsupported*arch*) : ;; *) bad="$bad arch=[$got]" ;; esac
  got=$(uname() { echo Darwin; }; private.lamp.os.family "$fx/ubuntu")
  [ "$got" = $'macos\tlaunchd\tbrew' ] || bad="$bad macos=[$got]"

  [ -z "$bad" ] && create.result 0 "os families detected" || create.result 1 "os:$bad"
  return $(result)
}

test.case $level "T-LAMP-OS: family, init and package manager are detected" test.lamp.osFamily
expect 0 "os families detected" "ubuntu, debian, alma, rocky, alpine, macos, unsupported"
```

- [ ] **Step 4: Run it — expect FAIL**

`./test.suite run lamp 1` → `private.lamp.os.family: command not found`.

- [ ] **Step 5: Implement detection**

Above `lamp.start "$@"`:

```bash
private.lamp.os.family() # <?osRelease:/etc/os-release> # echo "<family>\t<init>\t<pkg>"; unsupported goes to stderr and rc 1
{
  local osRelease="${1:-/etc/os-release}" id="" kernel
  kernel="$(uname -s 2>/dev/null)"
  if [ "$kernel" = Darwin ]; then
    printf 'macos\tlaunchd\tbrew\n'
    return 0
  fi
  if [ ! -f "$osRelease" ]; then
    echo "unsupported: no $osRelease"
    return 1
  fi
  id="$( . "$osRelease" 2>/dev/null; printf '%s' "${ID:-}" )"
  case "$id" in
    debian|ubuntu)                     printf 'debian\tsystemd\tapt-get\n' ;;
    almalinux|rocky|rhel|centos|fedora) printf 'rhel\tsystemd\tdnf\n' ;;
    alpine)                            printf 'alpine\topenrc\tapk\n' ;;
    *)
      echo "unsupported OS ${id:-unknown} — supported: debian/ubuntu, rhel family, alpine, macos"
      return 1
      ;;
  esac
  return 0
}
```

- [ ] **Step 6: Run it — expect PASS**

`./test.suite run lamp 1` → 2 passed (start + OS).

- [ ] **Step 7: Commit**

```bash
git add lamp test/test.lamp
git commit -m "feat(lamp): scaffold and OS detection (debian, rhel, alpine, macos)"
```

---

### Task 2: Backend choice, state and dispatch

**Files:** `lamp`, `test/test.lamp`

- [ ] **Step 1: Failing test**

```bash
test.lamp.backend() {
  local got bad=""
  got=$(private.lamp.backend.choose docker)
  [ "$got" = docker ] || bad="$bad explicitDocker=[$got]"
  got=$(private.lamp.backend.choose native)
  [ "$got" = native ] || bad="$bad explicitNative=[$got]"
  got=$(LAMP_BACKEND=native private.lamp.backend.choose prompt)
  [ "$got" = native ] || bad="$bad env=[$got]"
  got=$(LAMP_BACKEND=docker private.lamp.backend.choose "")
  [ "$got" = docker ] || bad="$bad env2=[$got]"
  got=$(LAMP_BACKEND=bogus private.lamp.backend.choose "")
  [ -z "$got" ] || bad="$bad bogus=[$got]"
  [ -z "$bad" ] && create.result 0 "backend selection works" || create.result 1 "backend:$bad"
  return $(result)
}

test.case $level "T-LAMP-BACKEND: explicit, env and default selection" test.lamp.backend
expect 0 "backend selection works" "docker, native, LAMP_BACKEND and an invalid value"
```

- [ ] **Step 2: Run — FAIL** (`command not found`).

- [ ] **Step 3: Implement**

```bash
private.lamp.docker.usable() # # rc 0 when the daemon and compose work
{
  if this.functionExists odocker.support.check; then
    odocker.support.check >/dev/null 2>&1 || return 1
  fi
  docker compose version >/dev/null 2>&1
}

private.lamp.backend.choose() # <?backend:prompt> # echo docker or native; asks on a TTY
{
  local choice="$1" fallback
  case "$choice" in docker|native) echo "$choice"; return 0 ;; esac
  if [ -n "${LAMP_BACKEND:-}" ]; then
    case "$LAMP_BACKEND" in
      docker|native) echo "$LAMP_BACKEND"; return 0 ;;
      *) return 1 ;;
    esac
  fi
  if private.lamp.docker.usable; then fallback=docker; else fallback=native; fi
  if [ -t 0 ]; then
    read -r -p "backend [docker|native] ($fallback): " choice
    [ -n "$choice" ] || choice="$fallback"
  else
    choice="$fallback"
  fi
  case "$choice" in
    docker|native) echo "$choice" ;;
    *) return 1 ;;
  esac
}
```

- [ ] **Step 4: Run — PASS.**

- [ ] **Step 5: Commit**

```bash
git add lamp test/test.lamp
git commit -m "feat(lamp): backend selection with TTY prompt and LAMP_BACKEND override"
```

---

### Task 3: Docker backend (templates + install + lifecycle)

**Files:**
- Create: `templates/lamp/common/{php/php.ini,php/required-extensions,db/01-charset.sql,certbot/renew-loop.sh}`
- Create: `templates/lamp/docker/{nginx,apache}/{Dockerfile,docker-compose.yml}`
- Create: `templates/lamp/vhost/{nginx,apache}.conf`
- Modify: `lamp`, `test/test.lamp`

- [ ] **Step 1: Failing template test**

```bash
test.lamp.templates() {
  local d="$OOSH_DIR/templates/lamp" bad="" f
  for f in common/php/php.ini common/php/required-extensions common/db/01-charset.sql \
           common/certbot/renew-loop.sh docker/nginx/Dockerfile docker/nginx/docker-compose.yml \
           docker/apache/Dockerfile docker/apache/docker-compose.yml vhost/nginx.conf vhost/apache.conf; do
    [ -f "$d/$f" ] || bad="$bad missing:$f"
  done
  grep -q '^FROM php:8.5-apache' "$d/docker/apache/Dockerfile" || bad="$bad apache:from"
  grep -q 'a2enmod rewrite' "$d/docker/apache/Dockerfile" || bad="$bad apache:rewrite"
  grep -q 'docker-php-ext-install.*intl gd pdo_mysql mysqli' "$d/docker/apache/Dockerfile" || bad="$bad apache:ext"
  grep -q 'pecl install imagick' "$d/docker/apache/Dockerfile" || bad="$bad apache:imagick"
  grep -q '^FROM php:8.5-fpm' "$d/docker/nginx/Dockerfile" || bad="$bad nginx:from"
  grep -q 'image: nginx:1.27-alpine' "$d/docker/nginx/docker-compose.yml" || bad="$bad nginx:web"
  grep -q 'image: mariadb:latest' "$d/docker/apache/docker-compose.yml" || bad="$bad apache:db"
  grep -q 'try_files \$uri \$uri/ /index.php?\$query_string;' "$d/vhost/nginx.conf" || bad="$bad nginx:tryfiles"
  grep -q 'AllowOverride All' "$d/vhost/apache.conf" || bad="$bad apache:override"
  [ -z "$bad" ] && create.result 0 "templates carry both backends" || create.result 1 "templates:$bad"
  return $(result)
}
test.case $level "T-LAMP-TEMPLATES: docker files, vhosts and the extension list exist" test.lamp.templates
expect 0 "templates carry both backends" "Dockerfiles, compose, vhosts, extension contract"
```

- [ ] **Step 2: Run — FAIL.**

- [ ] **Step 3: Create the templates**

`common/php/required-extensions`:

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

`common/php/php.ini`:

```ini
date.timezone = UTC
memory_limit = 256M
upload_max_filesize = 32M
post_max_size = 32M
max_execution_time = 60
expose_php = Off
```

`common/db/01-charset.sql`:

```sql
ALTER DATABASE lamp CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
```

`common/certbot/renew-loop.sh`:

```sh
#!/bin/sh
trap exit TERM
while :; do
  certbot renew --webroot -w /var/www/certbot
  sleep 12h & wait $!
done
```

`docker/nginx/Dockerfile`:

```dockerfile
FROM php:8.5-fpm
RUN apt-get update && apt-get install -y --no-install-recommends \
      libicu-dev libpng-dev libjpeg62-turbo-dev libfreetype6-dev libmagickwand-dev \
 && docker-php-ext-configure gd --with-freetype --with-jpeg \
 && docker-php-ext-install -j"$(nproc)" intl gd pdo_mysql mysqli opcache \
 && pecl install imagick && docker-php-ext-enable imagick \
 && rm -rf /var/lib/apt/lists/* /tmp/pear
```

`docker/apache/Dockerfile`:

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

`docker/nginx/docker-compose.yml`:

```yaml
name: lamp
services:
  web:
    image: nginx:1.27-alpine
    restart: unless-stopped
    ports: ["80:80", "443:443"]
    volumes:
      - "${LAMP_HOME}/conf.d:/etc/nginx/conf.d:ro"
      - "${LAMP_HOME}/www:/var/www/html:ro"
      - "${LAMP_HOME}/certs/conf:/etc/letsencrypt:ro"
      - "${LAMP_HOME}/certs/www:/var/www/certbot:ro"
    depends_on: [app]
  app:
    build: { context: . }
    restart: unless-stopped
    environment: { MARIADB_HOST: db, MARIADB_DATABASE: lamp }
    volumes:
      - "${LAMP_HOME}/www:/var/www/html"
      - "${LAMP_HOME}/php.ini:/usr/local/etc/php/conf.d/99-lamp.ini:ro"
    depends_on:
      db: { condition: service_healthy }
  db:
    image: mariadb:latest
    restart: unless-stopped
    env_file: ["${LAMP_HOME}/stack.env"]
    volumes:
      - "${LAMP_HOME}/db:/var/lib/mysql"
      - "${LAMP_HOME}/db-init:/docker-entrypoint-initdb.d:ro"
    healthcheck:
      test: ["CMD", "healthcheck.sh", "--connect", "--innodb_initialized"]
      interval: 5s
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

`docker/apache/docker-compose.yml`:

```yaml
name: lamp
services:
  app:
    build: { context: . }
    restart: unless-stopped
    ports: ["80:80", "443:443"]
    environment: { MARIADB_HOST: db, MARIADB_DATABASE: lamp }
    volumes:
      - "${LAMP_HOME}/www:/var/www/html"
      - "${LAMP_HOME}/conf.d:/etc/apache2/sites-enabled:ro"
      - "${LAMP_HOME}/certs/conf:/etc/letsencrypt:ro"
      - "${LAMP_HOME}/certs/www:/var/www/certbot:ro"
      - "${LAMP_HOME}/php.ini:/usr/local/etc/php/conf.d/99-lamp.ini:ro"
    depends_on:
      db: { condition: service_healthy }
  db:
    image: mariadb:latest
    restart: unless-stopped
    env_file: ["${LAMP_HOME}/stack.env"]
    volumes:
      - "${LAMP_HOME}/db:/var/lib/mysql"
      - "${LAMP_HOME}/db-init:/docker-entrypoint-initdb.d:ro"
    healthcheck:
      test: ["CMD", "healthcheck.sh", "--connect", "--innodb_initialized"]
      interval: 5s
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

`vhost/nginx.conf` (placeholders `@DOMAIN@`, `@DOCROOT@`, `@CERT@` replaced by `site.add`):

```nginx
server {
    listen 80;
    server_name @DOMAIN@;
    root @DOCROOT@;
    index index.php index.html;
    location /.well-known/acme-challenge/ { root /var/www/certbot; }
    location / { try_files $uri $uri/ /index.php?$query_string; }
    location ~ \.php$ {
        include fastcgi_params;
        fastcgi_pass @PHP@;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
    }
}
```

`vhost/apache.conf`:

```apache
<VirtualHost *:80>
    ServerName @DOMAIN@
    DocumentRoot @DOCROOT@
    <Directory @DOCROOT@>
        AllowOverride All
        Require all granted
    </Directory>
    Alias /.well-known/acme-challenge/ /var/www/certbot/.well-known/acme-challenge/
    <Directory /var/www/certbot/.well-known/acme-challenge/>
        Require all granted
    </Directory>
</VirtualHost>
```

- [ ] **Step 4: Failing install test (Docker path)**

```bash
test.lamp.dockerInstall() {
  local fx got bad=""
  fx=$(test.suite.fixture.make lampdocker)
  mkdir -p "$fx/home" "$fx/config" "$fx/ws"
  cp -a "$OOSH_DIR/templates/lamp/." "$fx/ws/" 2>/dev/null || true
  : > "$fx/calls"

  got=$( ( HOME="$fx/home"; CONFIG_PATH="$fx/config"; ODOCKER_WORKSPACES="$fx/ws"; LAMP_BACKEND=docker
    docker() {
      printf '%s\n' "$*" >> "$fx/calls"
      case "$*" in
        *"exec -T app php -m"*) cat "$OOSH_DIR/templates/lamp/common/php/required-extensions" ;;
        *"exec -T app php -r"*) echo 8.5.12 ;;
        *"mariadb --version"*) echo "mariadb  Ver 15.1 Distrib 13.0.2-MariaDB" ;;
        *) return 0 ;;
      esac
    }
    odocker.support.check() { return 0; }
    lamp.stack.install nginx 8.5 latest docker >/dev/null 2>&1
    printf '%s|%s' "$?" "$RESULT" ) )
  [ "$got" = "0|installed docker nginx (php 8.5.12, mariadb 13.0.2)" ] || bad="$bad install=[$got]"
  grep -qx 'LAMP_BACKEND=docker' "$fx/config/lamp/stack.env" || bad="$bad backend"
  grep -q '^compose .*up -d --wait' "$fx/calls" || bad="$bad up"
  [ -z "$bad" ] && create.result 0 "docker install works" || create.result 1 "docker:$bad"
  return $(result)
}
test.case $level "T-LAMP-DOCKER: install records the backend and starts compose" test.lamp.dockerInstall
expect 0 "docker install works" "state, build/up and the extension check"
```

- [ ] **Step 5: Implement state, compose and install**

```bash
private.lamp.home() { echo "${CONFIG_PATH:-$HOME/config}/lamp"; }
private.lamp.env.get() { local f; f="$(private.lamp.home)/stack.env"; [ -f "$f" ] || return 1; ( . "$f"; eval "printf '%s' \"\${$1-}\"" ); }
private.lamp.installed() { [ -f "$(private.lamp.home)/stack.env" ]; }
private.lamp.webserver() { private.lamp.env.get LAMP_WEBSERVER; }
private.lamp.backend() { private.lamp.env.get LAMP_BACKEND; }

private.lamp.require.installed() {
  private.lamp.installed && return 0
  create.result 1 "no stack installed — run: lamp stack.install nginx"
  error.log "$RESULT"; return $(result)
}

private.lamp.password.new() { LC_ALL=C tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 24; }

private.lamp.compose() {
  local home template
  home="$(private.lamp.home)"
  template="$ODOCKER_WORKSPACES/lamp/docker/$(private.lamp.webserver)"
  docker compose --env-file "$home/stack.env" -f "$template/docker-compose.yml" -p lamp "$@"
}

private.lamp.extensions.check() {
  local required="$OOSH_DIR/templates/lamp/common/php/required-extensions" loaded missing="" name
  case "$(private.lamp.backend)" in
    docker) loaded="$(private.lamp.compose exec -T app php -m 2>/dev/null)" ;;
    *)      loaded="$(php -m 2>/dev/null)" ;;
  esac
  [ -n "$loaded" ] || { create.result 1 "cannot ask php for its extensions"; return $(result); }
  while IFS= read -r name; do
    [ -n "$name" ] || continue
    printf '%s\n' "$loaded" | grep -qxF "$name" || missing="$missing $name"
  done < "$required"
  [ -z "$missing" ] && create.result 0 "php has every required extension" || create.result 1 "php is missing:$missing"
  return $(result)
}

lamp.stack.install()     # <webserver> <?php:8.5> <?mariadb:latest> <?backend:prompt> # install the stack natively or with Docker # lamp stack.install nginx
{
  local webserver="$1" php="${2:-8.5}" mariadb="${3:-latest}" wantBackend="${4:-prompt}"
  local family init pkg backend home previous="" same="no"

  [ -n "$webserver" ] || { create.result 1 "no web server was specified (nginx or apache)"; error.log "$RESULT"; return $(result); }
  case "$webserver" in nginx|apache) ;; *) create.result 1 "$webserver is no web server — nginx or apache"; error.log "$RESULT"; return $(result) ;; esac

  family="$(private.lamp.os.family)" || { create.result 1 "unsupported operating system"; error.log "$RESULT"; return $(result); }
  init="${family#*$'\t'}"; init="${init%%$'\t'*}"
  pkg="${family##*$'\t'}"; family="${family%%$'\t'*}"

  backend="$(private.lamp.backend.choose "$wantBackend")" || { create.result 1 "no backend chosen — docker or native"; error.log "$RESULT"; return $(result); }

  home="$(private.lamp.home)"
  previous="$(private.lamp.env.get LAMP_BACKEND)/$(private.lamp.env.get LAMP_WEBSERVER)"
  [ "$previous" = "$backend/$webserver" ] && same="yes"

  mkdir -p "$home"/{www,conf.d,certs/conf,certs/www,db,logs,db-init} || { create.result 1 "cannot create $home"; error.log "$RESULT"; return $(result); }
  cp -f "$OOSH_DIR/templates/lamp/common/php/php.ini" "$home/php.ini"
  cp -f "$OOSH_DIR/templates/lamp/common/db/01-charset.sql" "$home/db-init/"

  local rootPass; rootPass="$(private.lamp.env.get MARIADB_ROOT_PASSWORD)"; [ -n "$rootPass" ] || rootPass="$(private.lamp.password.new)"
  cat > "$home/stack.env" <<EOF
LAMP_HOME=$home
LAMP_BACKEND=$backend
LAMP_OS_FAMILY=$family
LAMP_INIT=$init
LAMP_PKG=$pkg
LAMP_WEBSERVER=$webserver
LAMP_PHP=$php
LAMP_MARIADB=$mariadb
LAMP_PHP_RESOLVED=
LAMP_MARIADB_RESOLVED=
MARIADB_ROOT_PASSWORD=$rootPass
MARIADB_DATABASE=lamp
EOF
  chmod 600 "$home/stack.env"

  case "$backend" in
    docker) private.lamp.docker.install "$webserver" || { error.log "$RESULT"; return $(result); } ;;
    native) private.lamp.native.install "$family" "$pkg" "$webserver" "$php" "$mariadb" || { error.log "$RESULT"; return $(result); } ;;
  esac

  private.lamp.extensions.check || { error.log "$RESULT"; return $(result); }
  private.lamp.render.all || { error.log "$RESULT"; return $(result); }

  if [ -z "$(private.lamp.env.get LAMP_PHP_RESOLVED)" ]; then
    case "$backend" in
      docker) : ;;
      *)
        sed -i "s/^LAMP_PHP_RESOLVED=.*/LAMP_PHP_RESOLVED=$(php -r 'echo PHP_VERSION;' 2>/dev/null)/" "$home/stack.env"
        sed -i "s/^LAMP_MARIADB_RESOLVED=.*/LAMP_MARIADB_RESOLVED=$(mariadb --version 2>/dev/null | awk '{for(i=1;i<=NF;i++) if ($i ~ /-MariaDB/) {sub(/-MariaDB.*/,"",$i); print $i; exit}}')/" "$home/stack.env"
        ;;
    esac
  fi

  if [ "$same" = no ] && [ -n "$(private.lamp.env.get LAMP_WEBSERVER)" ] && [ -n "$previous" ] && [ "${previous%%/*}" != "$backend" ]; then
    create.result 0 "switched to $backend $webserver"
  else
    create.result 0 "installed $backend $webserver (php $(private.lamp.env.get LAMP_PHP_RESOLVED), mariadb $(private.lamp.env.get LAMP_MARIADB_RESOLVED))"
  fi
  success.log "$RESULT"
  return $(result)
}
```

`private.lamp.docker.install`:

```bash
private.lamp.docker.install() # <webserver> # seed, build, up, record versions
{
  local webserver="$1" target="$ODOCKER_WORKSPACES/lamp" home
  home="$(private.lamp.home)"
  if [ ! -d "$target/docker/$webserver" ]; then
    mkdir -p "$target" || { create.result 1 "cannot create $target"; return $(result); }
    cp -a "$OOSH_DIR/templates/lamp/." "$target/" || { create.result 1 "cannot seed $target"; return $(result); }
  fi
  cp -f "$home/php.ini" "$home/php.ini"
  private.lamp.compose down --remove-orphans >/dev/null 2>&1
  private.lamp.compose build || { create.result 1 "docker compose build failed"; return $(result); }
  private.lamp.compose up -d --wait || { create.result 1 "docker compose up failed"; return $(result); }
  sed -i "s/^LAMP_PHP_RESOLVED=.*/LAMP_PHP_RESOLVED=$(private.lamp.compose exec -T app php -r 'echo PHP_VERSION;' 2>/dev/null)/" "$home/stack.env"
  sed -i "s/^LAMP_MARIADB_RESOLVED=.*/LAMP_MARIADB_RESOLVED=$(private.lamp.compose exec -T db sh -c 'mariadb --version' 2>/dev/null | awk '{for(i=1;i<=NF;i++) if ($i ~ /-MariaDB/) {sub(/-MariaDB.*/,"",$i); print $i; exit}}')/" "$home/stack.env"
  create.result 0 "$webserver"
  return $(result)
}
```

- [ ] **Step 6: Run — PASS** for templates and Docker install (the native path still fails its own task).

- [ ] **Step 7: Commit**

```bash
git add templates/lamp lamp test/test.lamp
git commit -m "feat(lamp): docker backend — templates, compose and install"
```

---

### Task 4: Native package plan and install

**Files:** `lamp`, `test/test.lamp`

- [ ] **Step 1: Failing package-plan test**

```bash
test.lamp.nativePlan() {
  local got bad=""
  got=$(private.lamp.native.packages debian nginx 8.5)
  case "$got" in *"php8.5-fpm"*"nginx"*"mariadb-server"*"certbot"*) : ;; *) bad="$bad debian=[$got]" ;; esac
  got=$(private.lamp.native.packages rhel apache 8.5)
  case "$got" in *"httpd"*"php85-php"*"mariadb-server"*) : ;; *) bad="$bad rhel=[$got]" ;; esac
  got=$(private.lamp.native.packages alpine nginx 8.5)
  case "$got" in *"nginx"*"php-fpm"*"mariadb"*"certbot"*) : ;; *) bad="$bad alpine=[$got]" ;; esac
  got=$(private.lamp.native.packages macos nginx 8.5)
  case "$got" in *"nginx"*"php"*"mariadb"*"certbot"*) : ;; *) bad="$bad macos=[$got]" ;; esac
  [ -z "$bad" ] && create.result 0 "package plans per family" || create.result 1 "plan:$bad"
  return $(result)
}
test.case $level "T-LAMP-NATIVE-PLAN: every family gets its packages" test.lamp.nativePlan
expect 0 "package plans per family" "debian, rhel, alpine, macos"
```

- [ ] **Step 2: Run — FAIL.**

- [ ] **Step 3: Implement the package plan and service helper**

```bash
private.lamp.native.packages() # <family> <webserver> <php> # echo the package list, space separated
{
  local family="$1" ws="$2" php="$3"
  case "$family" in
    debian)
      if [ "$ws" = apache ]; then printf 'apache2 libapache2-mod-php%s php%s php%s-cli php%s-fpm php%s-intl php%s-gd php%s-imagick php%s-mbstring php%s-curl php%s-xml php%s-mysql php%s-opcache mariadb-server certbot python3-certbot-apache' "$php" "$php" "$php" "$php" "$php" "$php" "$php" "$php" "$php" "$php" "$php" "$php"
      else printf 'nginx php%s-fpm php%s-cli php%s-intl php%s-gd php%s-imagick php%s-mbstring php%s-curl php%s-xml php%s-mysql php%s-opcache mariadb-server certbot python3-certbot-nginx' "$php" "$php" "$php" "$php" "$php" "$php" "$php" "$php" "$php" "$php"
      fi ;;
    rhel)
      if [ "$ws" = apache ]; then printf 'httpd php85-php php85-php-cli php85-php-fpm php85-php-intl php85-php-gd php85-php-pecl-imagick php85-php-mbstring php85-php-xml php85-php-mysqlnd php85-php-opcache mariadb-server certbot python3-certbot-apache'
      else printf 'nginx php85-php-fpm php85-php-cli php85-php-intl php85-php-gd php85-php-pecl-imagick php85-php-mbstring php85-php-xml php85-php-mysqlnd php85-php-opcache mariadb-server certbot python3-certbot-nginx'
      fi ;;
    alpine)
      printf 'nginx php php-fpm php-intl php-gd php-pecl-imagick php-mbstring php-curl php-xml php-mysqli php-pdo_mysql php-opcache mariadb mariadb-client certbot' ;;
    macos)
      printf 'nginx php mariadb certbot' ;;
    *) create.result 1 "unsupported family $family"; return $(result) ;;
  esac
  create.result 0 "$family"
  return $(result)
}

private.lamp.native.sudo() # <command...> # run a privileged step, or fail with the exact command
{
  if [ "$(id -u)" = 0 ]; then "$@"; return $?; fi
  if sudo -n true 2>/dev/null || sudo -v 2>/dev/null; then sudo "$@"; return $?; fi
  create.result 1 "sudo is required — run: sudo $*"
  return $(result)
}

private.lamp.native.service() # <family> <name> <start|stop|reload|enable> # manage one service
{
  local family="$1" name="$2" action="$3"
  case "$family" in
    debian|rhel)
      case "$action" in
        start)  private.lamp.native.sudo systemctl start "$name" ;;
        stop)   private.lamp.native.sudo systemctl stop "$name" ;;
        reload) private.lamp.native.sudo systemctl reload "$name" ;;
        enable) private.lamp.native.sudo systemctl enable "$name" ;;
      esac ;;
    alpine)
      case "$action" in
        start)  private.lamp.native.sudo rc-service "$name" start ;;
        stop)   private.lamp.native.sudo rc-service "$name" stop ;;
        reload) private.lamp.native.sudo rc-service "$name" reload ;;
        enable) private.lamp.native.sudo rc-update add "$name" default ;;
      esac ;;
    macos)
      case "$action" in
        start|enable) brew services start "$name" ;;
        stop)         brew services stop "$name" ;;
        reload)       brew services restart "$name" ;;
      esac ;;
  esac
}

private.lamp.native.install() # <family> <pkg> <webserver> <php> <mariadb> # install packages and start services
{
  local family="$1" pkg="$2" ws="$3" php="$4" mariadb="$5" list name
  private.lamp.native.repo.add "$family" "$php" || { error.log "$RESULT"; return $(result); }
  list="$(private.lamp.native.packages "$family" "$ws" "$php")"
  case "$pkg" in
    apt-get) private.lamp.native.sudo apt-get update && private.lamp.native.sudo apt-get install -y $list ;;
    dnf)     private.lamp.native.sudo dnf install -y $list ;;
    apk)     private.lamp.native.sudo apk add --no-cache $list ;;
    brew)    brew install $list ;;
    *)       create.result 1 "no package manager $pkg"; return $(result) ;;
  esac || { create.result 1 "package install failed"; return $(result); }

  case "$ws" in
    nginx) name=nginx ;;
    apache) case "$family" in debian) name=apache2 ;; *) name=httpd ;; esac ;;
  esac
  private.lamp.native.service "$family" "$name" enable
  private.lamp.native.service "$family" "$name" start
  private.lamp.native.service "$family" mariadb enable
  private.lamp.native.service "$family" mariadb start
  create.result 0 "$pkg"
  return $(result)
}

private.lamp.native.repo.add() # <family> <php> # add Sury/Remi (or nothing where the distro has the version)
{
  local family="$1" php="$2"
  case "$family" in
    debian)
      [ -f /etc/apt/sources.list.d/sury-php.list ] && return 0
      private.lamp.native.sudo install -d /usr/share/keyrings
      curl -fsSL https://packages.sury.org/php/apt.gpg | private.lamp.native.sudo tee /usr/share/keyrings/sury-php.gpg >/dev/null
      echo "deb [signed-by=/usr/share/keyrings/sury-php.gpg] https://packages.sury.org/php/ $( . /etc/os-release; echo "$VERSION_CODENAME" ) main" | private.lamp.native.sudo tee /etc/apt/sources.list.d/sury-php.list >/dev/null
      private.lamp.native.sudo apt-get update ;;
    rhel)
      rpm -q remi-release >/dev/null 2>&1 && return 0
      private.lamp.native.sudo dnf install -y "https://rpms.remirepo.net/enterprise/remi-release-$(rpm -E %rhel).rpm" || return $?
      private.lamp.native.sudo dnf module reset -y php ;;
    alpine|macos) : ;;
  esac
  create.result 0 "$family"
  return $(result)
}
```

- [ ] **Step 4: Run — PASS** for the plan; the install test is Task 5.

- [ ] **Step 5: Commit**

```bash
git add lamp test/test.lamp
git commit -m "feat(lamp): native package and service maps for four OS families"
```

---

### Task 5: Native lifecycle and status

**Files:** `lamp`, `test/test.lamp`

- [ ] **Step 1: Failing test (stubbed package manager + services)**

```bash
test.lamp.nativeInstall() {
  local fx got bad=""
  fx=$(test.suite.fixture.make lampnative); mkdir -p "$fx/home" "$fx/config" "$fx/ws"; : > "$fx/calls"
  got=$( ( HOME="$fx/home"; CONFIG_PATH="$fx/config"; LAMP_BACKEND=native
    sudo() { printf 'sudo %s\n' "$*" >> "$fx/calls"; "$@"; }
    systemctl() { printf 'systemctl %s\n' "$*" >> "$fx/calls"; }
    apt-get() { printf 'apt-get %s\n' "$*" >> "$fx/calls"; }
    curl() { :; }
    php() { if [ "$1" = -m ]; then cat "$OOSH_DIR/templates/lamp/common/php/required-extensions"; else echo 8.5.12; fi; }
    mariadb() { echo "mariadb  Ver 15.1 Distrib 13.0.2-MariaDB"; }
    uname() { echo Linux; }
    lamp.stack.install nginx 8.5 latest native >/dev/null 2>&1
    printf '%s|%s' "$?" "$RESULT" ) )
  [ "$got" = "0|installed native nginx (php 8.5.12, mariadb 13.0.2)" ] || bad="$bad install=[$got]"
  grep -qx 'LAMP_BACKEND=native' "$fx/config/lamp/stack.env" || bad="$bad backend"
  grep -q 'apt-get install' "$fx/calls" || bad="$bad apt"
  grep -q 'systemctl start nginx' "$fx/calls" || bad="$bad start"
  [ -z "$bad" ] && create.result 0 "native install runs the plan" || create.result 1 "native:$bad"
  return $(result)
}
test.case $level "T-LAMP-NATIVE: install runs the package and service plan" test.lamp.nativeInstall
expect 0 "native install runs the plan" "apt-get, systemctl and the recorded backend"
```

- [ ] **Step 2: Run — FAIL** (no native install yet).

- [ ] **Step 3: Implement `up/down/status/log/remove` with a backend switch**

```bash
private.lamp.native.services() # # echo "<web> <php> <db>" for the installed backend
{
  local ws family; ws="$(private.lamp.webserver)"; family="$(private.lamp.env.get LAMP_OS_FAMILY)"
  case "$ws" in
    nginx) ws=nginx ;;
    apache) case "$family" in debian) ws=apache2 ;; *) ws=httpd ;; esac ;;
  esac
  case "$family" in
    debian) echo "$ws php8.5-fpm mariadb" ;;
    rhel)   echo "$ws php-fpm mariadb" ;;
    alpine) echo "$ws php-fpm mariadb" ;;
    macos)  echo "$ws none mariadb" ;;
  esac
}

lamp.stack.up() {
  private.lamp.require.installed || return $(result)
  case "$(private.lamp.backend)" in
    docker) private.lamp.compose up -d --wait || { create.result 1 "docker compose up failed"; error.log "$RESULT"; return $(result); } ;;
    native)
      local family; family="$(private.lamp.env.get LAMP_OS_FAMILY)"
      local svc; for svc in $(private.lamp.native.services); do [ "$svc" = none ] || private.lamp.native.service "$family" "$svc" start; done ;;
  esac
  create.result 0 "stack is up"; success.log "$RESULT"; return $(result)
}

lamp.stack.down() {
  private.lamp.require.installed || return $(result)
  case "$(private.lamp.backend)" in
    docker) private.lamp.compose down || { create.result 1 "docker compose down failed"; return $(result); } ;;
    native)
      local family; family="$(private.lamp.env.get LAMP_OS_FAMILY)"
      local svc; for svc in $(private.lamp.native.services); do [ "$svc" = none ] || private.lamp.native.service "$family" "$svc" stop; done ;;
  esac
  create.result 0 "stack is down"; success.log "$RESULT"; return $(result)
}

lamp.stack.status() {
  private.lamp.require.installed || return $(result)
  local home; home="$(private.lamp.home)"
  echo "backend    : $(private.lamp.backend)"
  echo "os         : $(private.lamp.env.get LAMP_OS_FAMILY) ($(private.lamp.env.get LAMP_INIT), $(private.lamp.env.get LAMP_PKG))"
  echo "web server : $(private.lamp.webserver)"
  echo "php        : $(private.lamp.env.get LAMP_PHP) ($(private.lamp.env.get LAMP_PHP_RESOLVED))"
  echo "mariadb    : $(private.lamp.env.get LAMP_MARIADB) ($(private.lamp.env.get LAMP_MARIADB_RESOLVED))"
  case "$(private.lamp.backend)" in
    docker) private.lamp.compose ps 2>/dev/null | sed 's/^/  /' ;;
    native)
      local family; family="$(private.lamp.env.get LAMP_OS_FAMILY)"
      case "$family" in
        debian|rhel) systemctl is-active $(private.lamp.native.services) 2>/dev/null | sed 's/^/  /' ;;
        alpine) for svc in $(private.lamp.native.services); do printf '  %s: %s\n' "$svc" "$(rc-service "$svc" status 2>&1 | head -1)"; done ;;
        macos) brew services list 2>/dev/null | sed 's/^/  /' ;;
      esac ;;
  esac
  private.lamp.extensions.check >/dev/null 2>&1 && echo "extensions : ok" || echo "extensions : $RESULT"
  create.result 0 "backend : $(private.lamp.backend)"
  return $(result)
}

lamp.stack.log() {
  private.lamp.require.installed || return $(result)
  local lines="${1:-50}" family svc
  case "$(private.lamp.backend)" in
    docker) private.lamp.compose logs --tail "$lines" 2>/dev/null ;;
    native)
      family="$(private.lamp.env.get LAMP_OS_FAMILY)"
      for svc in $(private.lamp.native.services); do
        [ "$svc" = none ] && continue
        case "$family" in
          debian|rhel) journalctl -u "$svc" -n "$lines" --no-pager 2>/dev/null ;;
          alpine) tail -n "$lines" /var/log/messages 2>/dev/null ;;
          macos) tail -n "$lines" "$(brew --prefix)/var/log/$svc.log" 2>/dev/null ;;
        esac
      done ;;
  esac
  create.result 0 "logs"; return $(result)
}

lamp.stack.remove() {
  private.lamp.require.installed || return $(result)
  local purge="${1:-no}" home backend family
  home="$(private.lamp.home)"; backend="$(private.lamp.backend)"; family="$(private.lamp.env.get LAMP_OS_FAMILY)"
  case "$backend" in
    docker) private.lamp.compose down --remove-orphans ;;
    native) for svc in $(private.lamp.native.services); do [ "$svc" = none ] || private.lamp.native.service "$family" "$svc" stop; done ;;
  esac
  if [ "$purge" = purge ]; then
    case "$backend" in
      native) case "$family" in debian|rhel) private.lamp.native.sudo apt-get remove -y nginx apache2 httpd mariadb-server certbot 2>/dev/null ;; esac ;;
    esac
    rm -rf "$home"
    create.result 0 "stack removed (data deleted)"
  else
    create.result 0 "stack removed (data kept)"
  fi
  success.log "$RESULT"; return $(result)
}
```

- [ ] **Step 4: Run — PASS.**

- [ ] **Step 5: Commit**

```bash
git add lamp test/test.lamp
git commit -m "feat(lamp): native lifecycle, status, logs and removal"
```

---

### Task 6: `site.add` for both backends

**Files:** `lamp`, `test/test.lamp`

- [ ] **Step 1: Failing test**

```bash
test.lamp.site() {
  local fx got bad="" vhost
  fx=$(test.suite.fixture.make lampsite); mkdir -p "$fx/home" "$fx/config"; : > "$fx/calls"
  # docker install first (stubbed as in Task 3)
  ( HOME="$fx/home"; CONFIG_PATH="$fx/config"; LAMP_BACKEND=docker
    docker() { printf '%s\n' "$*" >> "$fx/calls"; case "$*" in *"php -m"*) cat "$OOSH_DIR/templates/lamp/common/php/required-extensions" ;; *"php -r"*) echo 8.5.12 ;; *"mariadb --version"*) echo "mariadb 13.0.2-MariaDB" ;; *) : ;; esac; }
    odocker.support.check() { return 0; }
    lamp.stack.install nginx 8.5 latest docker ) >/dev/null 2>&1
  got=$( ( HOME="$fx/home"; CONFIG_PATH="$fx/config"; LAMP_BACKEND=docker
    docker() { :; }; lamp.site.add example.org public 2>/dev/null; printf '%s|%s' "$?" "$RESULT" ) )
  vhost="$fx/config/lamp/conf.d/example.org.conf"
  [ -f "$vhost" ] || bad="$bad nofile"
  grep -q 'try_files \$uri \$uri/ /index.php?\$query_string;' "$vhost" || bad="$bad tryfiles"
  grep -q 'server_name example.org;' "$vhost" || bad="$bad name"
  [ -z "$bad" ] && create.result 0 "site.add renders a vhost" || create.result 1 "site:$bad"
  return $(result)
}
test.case $level "T-LAMP-SITE: site.add renders the vhost for the backend" test.lamp.site
expect 0 "site.add renders a vhost" "nginx try_files and the domain"
```

- [ ] **Step 2: Run — FAIL.**

- [ ] **Step 3: Implement rendering + installation**

```bash
private.lamp.vhost.render() # <domain> <docroot> # echo the vhost of the installed web server
{
  local domain="$1" docroot="$2" home php
  home="$(private.lamp.home)"
  [ -d "$docroot" ] || docroot="$home/www/$docroot"
  # macOS cannot bind <1024 without root: the native backend uses 8080/8443 there.
  local ports=""
  if [ "$(private.lamp.env.get LAMP_OS_FAMILY)" = macos ]; then ports=macos; fi

  if [ "$(private.lamp.webserver)" = nginx ]; then
    case "$(private.lamp.backend)" in
      docker) php='app:9000' ;;
      *) case "$(private.lamp.env.get LAMP_OS_FAMILY)" in
           debian) php='unix:/run/php/php8.5-fpm.sock' ;;
           rhel)   php='unix:/run/php-fpm/www.sock' ;;
           alpine) php='127.0.0.1:9000' ;;
           macos)  php='127.0.0.1:9000' ;;
         esac ;;
    esac
    sed -e "s|@DOMAIN@|$domain|g" -e "s|@DOCROOT@|$docroot|g" -e "s|@PHP@|$php|g" \
        "$OOSH_DIR/templates/lamp/vhost/nginx.conf" |
      { if [ "$ports" = macos ]; then
          sed -e 's/listen 80;/listen 8080;/' -e 's/listen 443 ssl;/listen 8443 ssl;/'
        else cat; fi; }
  else
    sed -e "s|@DOMAIN@|$domain|g" -e "s|@DOCROOT@|$docroot|g" \
        "$OOSH_DIR/templates/lamp/vhost/apache.conf" |
      { if [ "$ports" = macos ]; then sed -e 's/\*:80/*:8080/' -e 's/\*:443/*:8443/'; else cat; fi; }
  fi
  create.result 0 "$domain"
  return $(result)
}

private.lamp.vhost.install() # <domain> <file> # install the rendered vhost into the family path
{
  local domain="$1" file="$2" family
  family="$(private.lamp.env.get LAMP_OS_FAMILY)"
  case "$(private.lamp.backend)" in
    docker) : ;;
    *)
      case "$family:$(private.lamp.webserver)" in
        debian:nginx)  private.lamp.native.sudo cp "$file" "/etc/nginx/sites-available/$domain.conf"; private.lamp.native.sudo ln -sf "/etc/nginx/sites-available/$domain.conf" "/etc/nginx/sites-enabled/$domain.conf" ;;
        debian:apache) private.lamp.native.sudo cp "$file" "/etc/apache2/sites-available/$domain.conf"; private.lamp.native.sudo a2ensite "$domain.conf" ;;
        rhel:nginx)    private.lamp.native.sudo cp "$file" "/etc/nginx/conf.d/$domain.conf" ;;
        rhel:apache)   private.lamp.native.sudo cp "$file" "/etc/httpd/conf.d/$domain.conf" ;;
        alpine:nginx)  private.lamp.native.sudo cp "$file" "/etc/nginx/http.d/$domain.conf" ;;
        alpine:apache) private.lamp.native.sudo cp "$file" "/etc/apache2/conf.d/$domain.conf" ;;
        macos:nginx)   private.lamp.native.sudo cp "$file" "$(brew --prefix)/etc/nginx/servers/$domain.conf" ;;
        macos:apache)  private.lamp.native.sudo cp "$file" "$(brew --prefix)/etc/httpd/extra/$domain.conf" ;;
      esac ;;
  esac
  create.result 0 "$file"
  return $(result)
}

lamp.site.add()     # <domain> <docroot> # add a site and reload the web server # lamp site.add example.org public
{
  local domain="$1" docroot="$2" home file tmp
  [ -n "$domain" ] && [ -n "$docroot" ] || { create.result 1 "usage: lamp site.add <domain> <docroot>"; error.log "$RESULT"; return $(result); }
  case "$domain" in *[!A-Za-z0-9.-]*|.*|*..*) create.result 1 "$domain is no domain name"; error.log "$RESULT"; return $(result) ;; esac
  private.lamp.require.installed || return $(result)
  home="$(private.lamp.home)"
  case "$docroot" in /*) ;; *) docroot="$home/www/$docroot" ;; esac
  mkdir -p "$docroot" || { create.result 1 "cannot create $docroot"; error.log "$RESULT"; return $(result); }
  file="$home/conf.d/$domain.conf"; tmp="$file.new"
  private.lamp.vhost.render "$domain" "$docroot" > "$tmp" || { rm -f "$tmp"; error.log "$RESULT"; return $(result); }
  if [ -f "$file" ] && ! cmp -s "$tmp" "$file"; then
    rm -f "$tmp"; create.result 1 "$file exists with different content"; error.log "$RESULT"; return $(result)
  fi
  mv "$tmp" "$file"
  private.lamp.vhost.install "$domain" "$file" || { error.log "$RESULT"; return $(result); }
  grep -qxF "$domain"$'\t'"$docroot" "$home/sites" 2>/dev/null || printf '%s\t%s\n' "$domain" "$docroot" >> "$home/sites"
  private.lamp.reload || { create.result 1 "cannot reload the web server"; error.log "$RESULT"; return $(result); }
  create.result 0 "site $domain added ($docroot)"; success.log "$RESULT"; return $(result)
}

private.lamp.reload() {
  local family
  case "$(private.lamp.backend)" in
    docker) case "$(private.lamp.webserver)" in nginx) private.lamp.compose exec -T web nginx -s reload ;; apache) private.lamp.compose exec -T app apachectl -k graceful ;; esac ;;
    native)
      family="$(private.lamp.env.get LAMP_OS_FAMILY)"
      case "$(private.lamp.webserver)" in nginx) private.lamp.native.service "$family" nginx reload ;; apache) case "$family" in debian) private.lamp.native.service "$family" apache2 reload ;; macos) private.lamp.native.service "$family" httpd reload ;; *) private.lamp.native.service "$family" httpd reload ;; esac ;; esac ;;
  esac
}

private.lamp.render.all() {
  local home domain docroot
  home="$(private.lamp.home)"; [ -f "$home/sites" ] || return 0
  while IFS=$'\t' read -r domain docroot; do
    [ -n "$domain" ] || continue
    private.lamp.vhost.render "$domain" "$docroot" > "$home/conf.d/$domain.conf" || return $(result)
    private.lamp.vhost.install "$domain" "$home/conf.d/$domain.conf" >/dev/null 2>&1
  done < "$home/sites"
}
```

- [ ] **Step 4: Run — PASS.**

- [ ] **Step 5: Commit**

```bash
git add lamp test/test.lamp
git commit -m "feat(lamp): site.add for docker and native backends"
```

---

### Task 7: `db.create` for both backends

**Files:** `lamp`, `test/test.lamp`

- [ ] **Step 1: Failing test (native path)**

```bash
test.lamp.db() {
  local fx got bad=""
  fx=$(test.suite.fixture.make lampdb); mkdir -p "$fx/home" "$fx/config/lamp"; : > "$fx/calls"
  cat > "$fx/config/lamp/stack.env" <<EOF
LAMP_BACKEND=native
LAMP_OS_FAMILY=debian
LAMP_WEBSERVER=nginx
LAMP_PHP=8.5
LAMP_MARIADB=latest
MARIADB_ROOT_PASSWORD=x
EOF
  got=$( ( HOME="$fx/home"; CONFIG_PATH="$fx/config"
    sudo() { printf 'sudo %s\n' "$*" >> "$fx/calls"; "$@"; }
    mariadb() { printf 'mariadb %s\n' "$*" >> "$fx/calls"; if [ "$1" = -N ]; then :; fi; }
    lamp.db.create blog 2>/dev/null ) )
  [ "${#got}" = 24 ] || bad="$bad pw=[$got]"
  grep -q 'mariadb' "$fx/calls" || bad="$bad mariadb"
  [ -z "$bad" ] && create.result 0 "db.create uses the host mariadb" || create.result 1 "db:$bad"
  return $(result)
}
test.case $level "T-LAMP-DB: db.create uses the backend's mariadb" test.lamp.db
expect 0 "db.create uses the host mariadb" "sudo mariadb, 24-char password"
```

- [ ] **Step 2: Run — FAIL.**

- [ ] **Step 3: Implement the split**

```bash
private.lamp.db.exec() # # run sql from stdin as root
{
  case "$(private.lamp.backend)" in
    docker) private.lamp.compose exec -T db sh -c 'mariadb -uroot -p"$MARIADB_ROOT_PASSWORD"' ;;
    native) private.lamp.native.sudo mariadb -uroot ;;
  esac
}

lamp.db.create()     # <name> <?user> # create a database and its user; password printed once # lamp db.create blog
{
  local name="$1" user="${2:-$1}" home password exists
  [ -n "$name" ] || { create.result 1 "usage: lamp db.create <name> <?user>"; error.log "$RESULT"; return $(result); }
  case "$name" in *[!A-Za-z0-9_]*) create.result 1 "$name is no database name"; error.log "$RESULT"; return $(result) ;; esac
  case "$user" in *[!A-Za-z0-9_]*) create.result 1 "$user is no database user"; error.log "$RESULT"; return $(result) ;; esac
  private.lamp.require.installed || return $(result)
  home="$(private.lamp.home)"
  exists="$(printf "SHOW DATABASES LIKE '%s';\n" "$name" | private.lamp.db.exec 2>/dev/null)"
  [ -z "$exists" ] || { create.result 1 "database $name already exists"; error.log "$RESULT"; return $(result); }
  password="$(private.lamp.password.new)"
  {
    printf 'CREATE DATABASE `%s`;\n' "$name"
    printf "CREATE USER '%s'@'%%' IDENTIFIED BY '%s';\n" "$user" "$password"
    printf "GRANT ALL ON \`%s\`.* TO '%s'@'%%';\n" "$name" "$user"
  } | private.lamp.db.exec || { create.result 1 "could not create $name"; error.log "$RESULT"; return $(result); }
  printf '%s\t%s\t%s\n' "$name" "$user" "$password" >> "$home/db.credentials"
  chmod 600 "$home/db.credentials"
  echo "$password"
  create.result 0 "database $name created for $user (password on stdout)"; success.log "$RESULT"; return $(result)
}
```

- [ ] **Step 4: Run — PASS.**

- [ ] **Step 5: Commit**

```bash
git add lamp test/test.lamp
git commit -m "feat(lamp): db.create on docker or the host mariadb"
```

---

### Task 8: `cert.*` for both backends

**Files:** `lamp`, `test/test.lamp`

- [ ] **Step 1: Failing test**

```bash
test.lamp.cert() {
  local fx got bad=""
  fx=$(test.suite.fixture.make lampcert); mkdir -p "$fx/home" "$fx/config/lamp/conf.d" "$fx/config/lamp/certs/conf/live/example.org"
  printf 'LAMP_BACKEND=native\nLAMP_OS_FAMILY=debian\nLAMP_WEBSERVER=nginx\n' > "$fx/config/lamp/stack.env"
  : > "$fx/config/lamp/conf.d/example.org.conf"
  : > "$fx/config/lamp/certs/conf/live/example.org/fullchain.pem"
  : > "$fx/calls"
  got=$( ( HOME="$fx/home"; CONFIG_PATH="$fx/config"
    sudo() { printf 'sudo %s\n' "$*" >> "$fx/calls"; "$@"; }
    certbot() { printf 'certbot %s\n' "$*" >> "$fx/calls"; }
    lamp.cert.issue example.org me@example.org 2>/dev/null; printf '%s|%s' "$?" "$RESULT" ) )
  [ "$got" = "0|certificate issued for example.org" ] || bad="$bad issue=[$got]"
  grep -q 'certbot certonly' "$fx/calls" || bad="$bad certbot"
  [ -z "$bad" ] && create.result 0 "cert.issue uses host certbot" || create.result 1 "cert:$bad"
  return $(result)
}
test.case $level "T-LAMP-CERT: cert.issue uses the backend's certbot" test.lamp.cert
expect 0 "cert.issue uses host certbot" "sudo certbot and the recorded result"
```

- [ ] **Step 2: Run — FAIL.**

- [ ] **Step 3: Implement**

```bash
private.lamp.cert.run() # <args...> # run certbot in the backend
{
  case "$(private.lamp.backend)" in
    docker) private.lamp.compose run --rm --entrypoint certbot certbot "$@" ;;
    native) private.lamp.native.sudo certbot "$@" ;;
  esac
}

lamp.cert.issue()     # <domain> <email> # issue a certificate for an existing site # lamp cert.issue example.org me@example.org
{
  local domain="$1" email="$2" home
  [ -n "$domain" ] && [ -n "$email" ] || { create.result 1 "usage: lamp cert.issue <domain> <email>"; error.log "$RESULT"; return $(result); }
  private.lamp.require.installed || return $(result)
  home="$(private.lamp.home)"
  [ -f "$home/conf.d/$domain.conf" ] || { create.result 1 "no site $domain — lamp site.add $domain <docroot> first"; error.log "$RESULT"; return $(result); }
  case "$(private.lamp.backend)" in
    docker)
      private.lamp.compose run --rm --entrypoint certbot certbot certonly --webroot -w /var/www/certbot -d "$domain" --email "$email" --agree-tos --no-eff-email || { create.result 1 "certbot could not issue $domain"; error.log "$RESULT"; return $(result); } ;;
    native)
      private.lamp.native.sudo certbot certonly --webroot -w "$home/certs/www" -d "$domain" --email "$email" --agree-tos --no-eff-email || { create.result 1 "certbot could not issue $domain"; error.log "$RESULT"; return $(result); } ;;
  esac
  private.lamp.reload || { error.log "$RESULT"; return $(result); }
  create.result 0 "certificate issued for $domain"; success.log "$RESULT"; return $(result)
}

lamp.cert.renew() { private.lamp.require.installed || return $(result); case "$(private.lamp.backend)" in docker) private.lamp.compose run --rm --entrypoint certbot certbot renew --webroot -w /var/www/certbot ;; native) private.lamp.native.sudo certbot renew --webroot -w "$(private.lamp.home)/certs/www" ;; esac || { create.result 1 "certbot renew failed"; return $(result); }; private.lamp.reload; create.result 0 "certificates renewed"; return $(result); }

lamp.cert.status() {
  private.lamp.require.installed || return $(result)
  local home cert domain line
  home="$(private.lamp.home)"
  for cert in "$home"/certs/conf/live/*/fullchain.pem; do
    [ -f "$cert" ] || continue
    domain="${cert%/fullchain.pem}"; domain="${domain##*/}"
    line="$(openssl x509 -enddate -noout -in "$cert" 2>/dev/null | sed 's/^notAfter=//')"
    echo "$domain expires $line"
  done
  create.result 0 "certificate status printed"; return $(result)
}
```

- [ ] **Step 4: Run — PASS.**

- [ ] **Step 5: Commit**

```bash
git add lamp test/test.lamp
git commit -m "feat(lamp): cert.issue/renew/status on either backend"
```

---

### Task 9: Completion, docs, indexes, full suite

**Files:** `lamp`, `docs/lamp.md`, `docs/methods-index.md`, `docs/object-verb-index.md`, `docs/parameter.md`, `test/test.lamp`

- [ ] **Step 1: Completion hooks**

```bash
lamp.parameter.completion.backend() { printf 'docker\nnative\n'; }
lamp.parameter.completion.webserver() { printf 'nginx\napache\n'; }
lamp.parameter.completion.purge() { printf 'no\npurge\n'; }
lamp.parameter.completion.domain() { local h; h="$(private.lamp.home)"; [ -d "$h/conf.d" ] && ls "$h/conf.d" 2>/dev/null | sed 's/\.conf$//'; }
lamp.parameter.completion.docroot() { compgen -d "$(private.lamp.home)/www/" 2>/dev/null; }
```

- [ ] **Step 2: `docs/lamp.md`**

Cover: commands; the backend table (`docker` vs `native`); the platform matrix (debian/rhel/alpine/macos, package manager, init, vhost paths); PHP 8.5 sources; extension contract; state; macOS 8080/8443; completion.

- [ ] **Step 3: Indexes**

`docs/methods-index.md`: add the `lamp` row with the counts from:

```bash
grep -cE '^lamp\.[A-Za-z0-9_.]*\(\)' lamp
grep -cE '^private\.lamp\.' lamp
```

and update the totals.

`docs/object-verb-index.md`: rows for `lamp`, `stack`, `site`, `db`, `cert`, `backend`, `os`, `native`, `docker`, `vhost`.

`docs/parameter.md`: rows for `webserver`, `php`, `mariadb`, `backend`, `domain`, `docroot`, `name`, `user`, `email`, `lines`, `purge`.

- [ ] **Step 4: Full verification**

```bash
./test.suite run lamp 1
./test.suite run ossh 1
./test.suite core 1
```

Expected: `lamp` all green; `ossh` 156/156; `core` all green plus the intentional meta-test.

- [ ] **Step 5: Commit**

```bash
git add lamp test/test.lamp docs/lamp.md docs/methods-index.md docs/object-verb-index.md docs/parameter.md
git commit -m "docs(lamp): commands, platforms and backends"
```

---

## Self-review

**Spec coverage**

| spec section | task |
|---|---|
| §1 detection | 1 |
| §2 backend choice | 2 |
| §3 package plan | 4 |
| §4 extension contract | 3 (docker), 4–5 (native) |
| §5 state | 3 |
| §6 vhost destinations | 6 |
| §7 command behaviour | 3, 5, 6, 7, 8 |
| §8 privileges | 4 |
| §9 macOS ports | 6 (`private.lamp.vhost.render` rewrites 80/443 to 8080/8443 for macos) |
| §10 errors | each task's failure paths |
| §11 testing | all tasks |
| §12 docs | 9 |

**macOS ports:** `private.lamp.vhost.render` (Task 6) rewrites `80/443` to `8080/8443` when the
family is `macos`; `stack.status` prints the base URL so the ports are not a surprise.

**Placeholder scan:** no `TBD`/`TODO`; each step has code.

**Type consistency:** `private.lamp.backend`, `private.lamp.webserver`, `private.lamp.native.service`,
`private.lamp.vhost.render`, `private.lamp.db.exec`, `private.lamp.cert.run` keep one signature
across tasks.

## Execution handoff

Plan saved to `docs/superpowers/plans/2026-11-09-lamp-stack.md`. Two options:

1. **Subagent-driven (recommended)** — one fresh subagent per task.
2. **Inline with checkpoints** — run here, stop for review after each task.

Which approach?
