#!/usr/bin/env bash
#clear
#export PS4='\e[90m+${LINENO} in ${#BASH_SOURCE[@]}>${FUNCNAME[0]}:${BASH_SOURCE[@]##*/} \e[0m'
#set -x

#echo "starting: $0 <LOG_LEVEL=$1>"

private.os.release.get()     # <key> <?file:/etc/os-release> # echo one value of the os-release <file> (ID, VERSION_CODENAME, PRETTY_NAME …) with its quotes removed, without running the file; rc 1 and nothing when the key or the file is missing #
{
 # NO create.result — a getter consumed as $(...): SILENT BY CONTRACT. Read
 # line by line, never sourced: the file is data, and the caller's shell keeps
 # its variables. Moved from odocker (T-OS-RELEASE-GET).
 local key="$1" file="${2:-/etc/os-release}" name value
 case "$key" in ""|*[!A-Za-z0-9_]*) return 1 ;; esac
 [ -r "$file" ] || return 1
 while IFS='=' read -r name value || [ -n "$name" ]; do
   [ "$name" = "$key" ] || continue
   case "$value" in
     \"*\") value="${value#\"}"; value="${value%\"}"
            value="${value//\\\"/\"}"; value="${value//\\\$/\$}"; value="${value//\\\`/\`}"; value="${value//\\\\/\\}" ;;
     \'*\') value="${value#\'}"; value="${value%\'}" ;;
   esac
   printf '%s\n' "$value"
   return 0
 done < "$file"
 return 1
}


private.os.systemd.is()     # <?root:/> # rc 0 when systemd runs this computer: its run directory <root>/run/systemd/system is there and systemctl is on PATH; a container has none #
{
 # A predicate (rc only, no create.result), like private.this.container.is.
 # Moved from su/setup, which needs it before it installs a service
 # (T-OS-SYSTEMD-IS). <root> lets a test use a fixture.
 local root="${1:-/}"
 root="${root%/}"
 [ -d "$root/run/systemd/system" ] && command -v systemctl >/dev/null 2>&1
}


os.service.on()     # <service> # switch the system service <service> on, now and at boot: systemd, else OpenRC, else SysV service on Linux; on macOS the system launch daemon <service> (a label like com.apple.smbd); rc 1 naming it when it cannot #
{
 # The one service switch (T-OS-SERVICE). su/setup called systemctl and
 # launchctl raw; odocker's engine start and ossh's fail2ban carry the same
 # Linux fallback chain inline.
 local service="$1"
 if [ -z "$service" ]; then
   create.result 1 "os.service.on: <service> required"; error.log "$RESULT"; return $(result)
 fi
 if os.check private.os.service.on && $RESULT "$service"; then
   create.result 0 "$service is on"
 else
   create.result 1 "$service could not be switched on"; error.log "$RESULT"
 fi
 return $(result)
}

private.os.service.on.linux()     # <service> # systemctl enable --now, else rc-update add + rc-service start, else service start #
{
 $SUDO systemctl enable --now "$1" >/dev/null 2>&1 \
   || { $SUDO rc-update add "$1" default >/dev/null 2>&1 && $SUDO rc-service "$1" start >/dev/null 2>&1; } \
   || $SUDO service "$1" start >/dev/null 2>&1
}

private.os.service.on.darwin()     # <label> # launchctl enable system/<label>, then bootstrap its LaunchDaemons plist; a daemon already loaded is on #
{
 $SUDO launchctl enable "system/$1" >/dev/null 2>&1
 # bootstrap refuses a daemon that is already loaded: then it is on.
 $SUDO launchctl bootstrap system "/System/Library/LaunchDaemons/$1.plist" >/dev/null 2>&1 \
   || $SUDO launchctl print "system/$1" >/dev/null 2>&1
}


os.service.off()     # <service> # switch the system service <service> off, now and at boot: systemd, else OpenRC, else SysV service on Linux; the system launch daemon <service> on macOS; rc 1 naming it when it cannot #
{
 local service="$1"
 if [ -z "$service" ]; then
   create.result 1 "os.service.off: <service> required"; error.log "$RESULT"; return $(result)
 fi
 if os.check private.os.service.off && $RESULT "$service"; then
   create.result 0 "$service is off"
 else
   create.result 1 "$service could not be switched off"; error.log "$RESULT"
 fi
 return $(result)
}

private.os.service.off.linux()     # <service> # systemctl disable --now, else rc-service stop + rc-update del, else service stop #
{
 $SUDO systemctl disable --now "$1" >/dev/null 2>&1 \
   || { $SUDO rc-service "$1" stop >/dev/null 2>&1 && $SUDO rc-update del "$1" default >/dev/null 2>&1; } \
   || $SUDO service "$1" stop >/dev/null 2>&1
}

private.os.service.off.darwin()     # <label> # launchctl bootout system/<label>, then disable it; a daemon not loaded is off #
{
 $SUDO launchctl bootout "system/$1" >/dev/null 2>&1
 $SUDO launchctl disable "system/$1" >/dev/null 2>&1
}


### new.method

# ─────────────────────────────────────────────────────────────────────────────
# PLATFORM CONFIG HELPERS
# ─────────────────────────────────────────────────────────────────────────────

private.os.platform.load() { # # loads platform config from defaults and user overrides
  source "$OOSH_DIR/defaults/platforms.env"
  [ -f "$HOME/config/platforms.env" ] && source "$HOME/config/platforms.env"
}

private.os.platform.names() { # # returns sorted list of platform names
  private.os.platform.load
  env | grep '^PLATFORM_' | sed 's/^PLATFORM_//' | cut -d= -f1 | sort
}

private.os.platform.parse() { # <platform> # parses platform config into PLATFORM_* variables
  local platform="$1"
  local varname="PLATFORM_${platform}"
  private.os.platform.load
  local value="${!varname}"
  if [ -z "$value" ]; then
    error.log "Unknown platform: $platform"
    return 1
  fi
  # Parse from edges inward: workspace:...:pm:tier
  PLATFORM_TIER="${value##*:}"
  local withoutTier="${value%:*}"
  PLATFORM_PM="${withoutTier##*:}"
  local withoutPm="${withoutTier%:*}"
  PLATFORM_WORKSPACE="${withoutPm%%:*}"
  PLATFORM_BASE_IMAGE="${withoutPm#*:}"
}

private.os.platform.image.from.workspace() { # <workspace> # converts workspace path to Docker image tag
  echo "$1" | sed 's/\([a-z]\)\([A-Z]\)/\1_\2/g' | tr '[:upper:]/' '[:lower:]_' | tr '.' '_'
}

private.os.platform.container.id() { # <port> # id of the running platform-test container publishing <port> (empty if none)
  docker ps -q --filter "publish=$1" 2>/dev/null | head -1
}

private.os.platform.cleanup() { # <port> # stops and removes Docker container on given port
  local port="$1"
  local containerId
  containerId=$(private.os.platform.container.id "$port")
  if [ -n "$containerId" ]; then
    docker stop "$containerId" 2>/dev/null
    docker rm "$containerId" 2>/dev/null
  fi
  containerId=$(docker ps -aq --filter "publish=$port" 2>/dev/null)
  if [ -n "$containerId" ]; then
    docker rm "$containerId" 2>/dev/null
  fi
}

private.os.platform.sshd.reload() { # <port> # re-exec the container's sshd after an in-place openssh upgrade during install
  # The in-container git install (init/oosh's prereq step, `dnf -y install git`)
  # can upgrade openssh-server *in place*: AlmaLinux 9.8 shipped openssh
  # 9.9p1-7.el9_8, while the test image still bakes in 8.7p1, so dnf swaps
  # /usr/sbin/sshd out from under the running daemon. AlmaLinux sshd re-execs
  # /usr/sbin/sshd for every new connection, so once the on-disk binary no
  # longer matches the running master, every FRESH connection dies pre-banner
  # ("kex_exchange_identification: Connection closed by remote host"). Already
  # established connections survive — which is why the install itself finishes
  # but Phase B (fresh connections, after the ControlMaster is dropped) fails on
  # all users. We own the container and SSH itself is what's broken, so re-exec
  # sshd via odocker (docker), not ssh. SIGHUP makes sshd re-exec the (new)
  # binary while keeping the listener up. No-op when no container publishes the
  # port (e.g. native runs).
  local containerId
  containerId=$(private.os.platform.container.id "$1")
  [ -z "$containerId" ] && return 0
  console.log "Re-exec sshd on $containerId (pick up any in-place openssh upgrade)"
  odocker exec.command "$containerId" '
    pid=$(cat /run/sshd.pid 2>/dev/null || cat /var/run/sshd.pid 2>/dev/null)
    [ -z "$pid" ] && pid=$(pidof sshd 2>/dev/null)
    [ -n "$pid" ] && kill -HUP $pid
  ' 2>/dev/null
  sleep 1
}

private.os.platform.test.ci() # <platform> <?terminal> <?notests> # triggers CI workflow for native platform testing
{
  private.this.script.load ogit ogit.branch.get
  local platform="$1"
  local terminal="$2"
  local notests="$3"

  if ! command -v gh >/dev/null 2>&1; then
    console.log "Installing gh CLI for CI platform testing..."
    oo cmd gh
  fi

  if ! gh auth status >/dev/null 2>&1; then
    console.log "gh CLI is not authenticated — starting login..."
    gh auth login
  fi

  local branch
  branch=$(ogit.branch.get "$OOSH_DIR")
  if [ -z "$branch" ]; then
    # ogit-exception: printed text, not an invocation
    error.log "Could not determine current git branch"
    create.result 1 "FAIL"
    return 1
  fi

  console.log "Triggering macOS CI test on branch: $branch"

  # Trigger the workflow and capture the run
  local repo="Cerulean-Circle-GmbH/once.sh"
  if ! gh workflow run macos-test.yml -R "$repo" -r "$branch" -f branch="$branch" -f terminal="${terminal:-}" -f notests="${notests:-}"; then
    error.log "Failed to trigger macOS CI workflow"
    create.result 1 "FAIL"
    return 1
  fi

  # Wait for the run to appear (GHA has a brief delay)
  sleep 5

  # Find the run we just triggered
  local runId
  runId=$(gh run list -R "$repo" -w "macos-test.yml" --branch "$branch" -L 1 --json databaseId -q '.[0].databaseId' 2>/dev/null)
  if [ -z "$runId" ]; then
    error.log "Could not find triggered workflow run"
    create.result 1 "FAIL"
    return 1
  fi

  console.log "Watching CI run $runId..."
  gh run watch "$runId" -R "$repo" --exit-status 2>&1
  local rc=$?

  if [ $rc -eq 0 ]; then
    printf "PASS: %s (ci=%d)\n" "$platform" "$rc"
    important.log "PASS: $platform (ci=$rc)"
    create.result 0 "PASS"
  else
    printf "FAIL: %s (ci=%d)\n" "$platform" "$rc"
    error.log "FAIL: $platform (ci=$rc)"
    error.log "View details: gh run view $runId -R $repo --log"
    create.result 1 "FAIL"
  fi
  printf "\nJob Summary: https://github.com/%s/actions/runs/%s\n" "$repo" "$runId"
  printf "Open in browser: gh run view %s -R %s --web\n" "$runId" "$repo"
  return $rc
}

# ─────────────────────────────────────────────────────────────────────────────
# PLATFORM TESTING
# ─────────────────────────────────────────────────────────────────────────────

private.os.platform.image.exists() # <imageTag> # rc 0 when the image <imageTag> is on this host
{
  # A predicate (rc only, no create.result), like private.this.container.is.
  docker image inspect "$1" >/dev/null 2>&1
}

private.os.shell.files.list() # <dir> # echo the tracked files of <dir> whose first line is a #! naming sh or bash, one per line, relative to <dir>
{
  # NO create.result — a getter consumed as $(...).
  local f line
  while IFS= read -r f; do
    [ -f "$1/$f" ] || continue
    IFS= read -r line < "$1/$f" || continue
    case "$line" in ('#!'*sh*) printf '%s\n' "$f" ;; esac
  done < <(ogit.repo.files.list "$1")
}

os.platform.parse.check() # <?platform:almalinux_9> <?dir:$OOSH_DIR> # bash -n every tracked shell file of <dir> with the bash of the image of <platform> — almalinux_9 has the oldest bash oosh runs on (5.1); rc 1 naming each file that does not parse
{
  # test.oo did not even load on almalinux_9: bash 5.1 reads a case pattern
  # without its "(" inside $( ( … ) ) as a syntax error, Ubuntu's and macOS's
  # bash 5.2 do not — only a promotion's platform test found it (2026-10-14,
  # T-OS-PLATFORM-PARSE-CHECK). The tree goes into a throwaway container of
  # the image as a tar on stdin (odocker image.command); nothing is installed.
  local platform="${1:-almalinux_9}" dir="${2:-$OOSH_DIR}" imageTag files n out version failed
  if ! private.os.platform.parse "$platform"; then
    create.result 1 "unknown platform $platform — os platform.list names them"; error.log "$RESULT"; return $(result)
  fi
  if [ "$PLATFORM_WORKSPACE" = "native" ]; then
    create.result 1 "$platform is native — it has no image to check with"; error.log "$RESULT"; return $(result)
  fi
  imageTag=$(private.os.platform.image.from.workspace "$PLATFORM_WORKSPACE")
  if ! private.os.platform.image.exists "$imageTag"; then
    create.result 1 "no image $imageTag on this host — os platform.test $platform builds it"; error.log "$RESULT"; return $(result)
  fi
  private.this.script.load ogit ogit.repo.files.list || { create.result 1 "ogit not found in $OOSH_DIR"; error.log "$RESULT"; return $(result); }
  private.this.script.load odocker odocker.image.command || { create.result 1 "odocker not found in $OOSH_DIR"; error.log "$RESULT"; return $(result); }
  files=$(private.os.shell.files.list "$dir")
  n=$(printf '%s\n' "$files" | grep -c .)
  out=$( (cd "$dir" && printf '%s\n' "$files" | tar -cf - -T -) \
    | odocker.image.command "$imageTag" 'd=$(mktemp -d) && cd "$d" && tar -xf - && bash --version | head -1 && find . -type f | sort | while read -r f; do bash -n "$f" 2>&1 | head -1; done' )
  version=$(printf '%s\n' "$out" | head -1)
  failed=$(printf '%s\n' "$out" | tail -n +2 | sed -n 's|^\./\([^:]*\): line .*|\1|p' | sort -u)
  if [ -n "$failed" ]; then
    printf '%s\n' "$out" | tail -n +2 | while IFS= read -r line; do [ -n "$line" ] && error.log "$line"; done
    create.result 1 "$(printf '%s\n' "$failed" | grep -c .) of $n shell files do not parse with $version: $(echo $failed)"
  else
    create.result 0 "$n shell files parse with $version"
  fi
  return $(result)
}

# @TODO [ ] os.platform.parse.check.completion.platform() { private.os.platform.load; private.os.platform.names; }
os.parameter.completion.platform() { private.os.platform.load; private.os.platform.names; }