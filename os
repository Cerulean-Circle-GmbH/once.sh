#!/usr/bin/env bash
#clear
#export PS4='\e[90m+${LINENO} in ${#BASH_SOURCE[@]}>${FUNCNAME[0]}:${BASH_SOURCE[@]##*/} \e[0m'
#set -x

#echo "starting: $0 <LOG_LEVEL=$1>"

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

private.os.platform.cleanup() { # <port> # stops and removes Docker container on given port
  local port="$1"
  local containerId
  containerId=$(docker ps -q --filter "publish=$port" 2>/dev/null)
  if [ -n "$containerId" ]; then
    docker stop "$containerId" 2>/dev/null
    docker rm "$containerId" 2>/dev/null
  fi
  containerId=$(docker ps -aq --filter "publish=$port" 2>/dev/null)
  if [ -n "$containerId" ]; then
    docker rm "$containerId" 2>/dev/null
  fi
}

private.os.platform.test.ci() # <platform> <?terminal> <?notests> # triggers CI workflow for native platform testing
{
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
  branch=$(git -C "$OOSH_DIR" rev-parse --abbrev-ref HEAD 2>/dev/null)
  if [ -z "$branch" ]; then
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

os.platform.list() # # lists all platforms with tier info
{
  private.os.platform.load
  printf "%-20s %-25s %-10s %s\n" "PLATFORM" "WORKSPACE" "PM" "TIER"
  printf "%-20s %-25s %-10s %s\n" "--------" "---------" "--" "----"
  local name
  for name in $(private.os.platform.names); do
    private.os.platform.parse "$name"
    printf "%-20s %-25s %-10s %s\n" "$name" "$PLATFORM_WORKSPACE" "$PLATFORM_PM" "$PLATFORM_TIER"
  done
}

os.platform.test() # <platform> <?terminal> <?notests> # tests oosh installation on a single platform
{
  local platform="$1"
  if [ -z "$platform" ]; then
    error.log "Usage: os platform.test <platform> <?terminal> <?notests>"
    return 1
  fi
  shift
  local terminal="$1"
  if [ -n "$1" ]; then shift; fi
  local notests="$1"
  if [ -n "$1" ]; then shift; fi

  private.os.platform.parse "$platform" || return 1

  if [ "$PLATFORM_WORKSPACE" = "native" ]; then
    if [ "$platform" = "macos" ]; then
      private.os.platform.test.ci "$platform" "$terminal" "$notests"
      return $?
    fi
    console.log "SKIP: $platform is a native platform (no Docker test)"
    create.result 1 "SKIP"
    return 1
  fi

  local imageTag sshPort rc
  imageTag=$(private.os.platform.image.from.workspace "$PLATFORM_WORKSPACE")
  sshPort=8022

  # Ensure sshpass is available for automated first-connection password
  if ! command -v sshpass >/dev/null 2>&1; then
    console.log "Installing sshpass for automated platform testing..."
    oo cmd sshpass
  fi

  # Set control path so sshpass and ossh subprocesses share the same socket
  : ${OSSH_CONTROL_PATH:="/tmp/ossh-%r@%h:%p"}
  export OSSH_CONTROL_PATH

  console.log "Testing platform: $platform (image: $imageTag)"

  # Auto-build if image doesn't exist
  if ! docker image inspect "$imageTag" &>/dev/null; then
    console.log "Image $imageTag not found — building from $PLATFORM_WORKSPACE..."
    if ! odocker build "$PLATFORM_WORKSPACE"; then
      error.log "Failed to build image for $platform"
      create.result 1 "FAIL"
      return 1
    fi
  fi

  # Fresh container
  odocker reset "$imageTag" "$sshPort"
  sleep 2

  # SSH setup
  ossh config.create "$platform" "test@localhost:$sshPort"
  ossh config.save.last
  # Clean up any stale ControlMaster socket from a previous test run
  ssh -O exit -o ControlPath="$OSSH_CONTROL_PATH" "$platform" 2>/dev/null
  rm -f "/tmp/ossh-test@localhost:$sshPort" 2>/dev/null

  # Open ControlMaster with sshpass (first connection, no keys yet)
  # Run 'true' instead of -N -f to avoid sshpass/ssh background fork race condition
  SSHPASS=test sshpass -e ssh \
    -o ControlMaster=yes \
    -o ControlPath="$OSSH_CONTROL_PATH" \
    -o ControlPersist=600 \
    -o StrictHostKeyChecking=accept-new \
    "$platform" true

  # Push key — reuses ControlMaster socket, no password prompt
  ossh key.push "$platform"

  # Configure passwordless sudo for automated testing (container is ephemeral)
  # Append to /etc/sudoers (must be last rule to override %wheel on Alpine)
  ossh exec "$platform" "echo 'test' | sudo -S sh -c 'echo \"test ALL=(ALL) NOPASSWD: ALL\" >> /etc/sudoers'"

  # Install oosh. init/oosh's POSIX prelude handles its own prereqs
  # (git via the detected PM, bash 4+ on macOS, /etc/paths.d wiring) —
  # no separate `ossh prereqs.install <host>` pre-step is needed. See
  # `private.push.init.oosh` (ossh:433) which SCPs init/oosh and runs
  # its self-install, and init/oosh:188 (git install) + 192-232
  # (bash install).
  ossh install "$platform" test

  # Refresh ControlMaster so new sessions pick up dev group membership
  # (usermod -aG dev runs during install, but ControlMaster keeps old groups)
  ossh connection.close "$platform" 2>/dev/null
  rm -f "/tmp/ossh-test@localhost:$sshPort" 2>/dev/null
  SSHPASS=test sshpass -e ssh \
    -o ControlMaster=yes \
    -o ControlPath="$OSSH_CONTROL_PATH" \
    -o ControlPersist=600 \
    -o StrictHostKeyChecking=accept-new \
    "$platform" true

  # ─── PHASE A: install all 4 users (no tests yet) ────────────────────────
  # Covers every install path we support in one run:
  #   test      — initial `ossh install <platform> test` (caller-side + user.oosh.install)
  #   root      — sudo re-exec during the above state-machine install
  #   oosh-user — `user create oosh-user password oosh-user` from test session
  #               (oosh-native user creation; user.create calls user.oosh.install internally)
  #   bash-user — raw `useradd` on remote, then `ossh install <platform> bash-user`
  #               (caller-initiated install for a pre-existing account)

  console.log "Phase A.2: creating oosh-user via 'user create' from test session..."
  ossh exec.tty "$platform" "user create oosh-user password oosh-user" || {
    error.log "Failed to create oosh-user on $platform"
  }
  # Give oosh-user NOPASSWD sudo. Append to /etc/sudoers directly (not
  # sudoers.d) — matches the existing pattern at os:217 for the test
  # user; sudoers.d isn't always included on minimal images (alma's
  # default /etc/sudoers may lack `#includedir /etc/sudoers.d`).
  ossh exec "$platform" "sudo sh -c 'echo \"oosh-user ALL=(ALL) NOPASSWD: ALL\" >> /etc/sudoers'"

  console.log "Phase A.3: creating bash-user via raw useradd/adduser..."
  # Note: no `-G sudo` — that group only exists on Debian/Ubuntu (RHEL/Alma use
  # `wheel`, Alpine has neither by default). The NOPASSWD sudoers entry below
  # grants sudo access without group membership, so portability beats group hygiene.
  # Try useradd first (Debian/RHEL/Alma), fall back to adduser -D (Alpine/busybox);
  # without this fallback, Alpine fails with `sudo: useradd: command not found`.
  #
  # Each step is independently idempotent — earlier versions chained
  # everything with `&&`, which short-circuits if any step returns
  # non-zero. Important quirk: `command -v useradd` runs in the SSH
  # session's PATH, which on non-interactive ssh excludes /usr/sbin
  # — so the existence check ALWAYS failed on Debian, even though
  # /usr/sbin/useradd is there. We probe via `sudo command -v`
  # instead so sudo's `secure_path` (which DOES include /usr/sbin)
  # resolves the binary. No `||` between the user-create branches and
  # the chpasswd/sudoers grant — those run unconditionally afterwards
  # so a user-already-exists path doesn't skip them.
  ossh exec.tty "$platform" "
    if id bash-user >/dev/null 2>&1; then
      echo 'bash-user already exists — skipping useradd'
    elif sudo sh -c 'command -v useradd' >/dev/null 2>&1; then
      sudo useradd -m -s /bin/bash bash-user
    elif sudo sh -c 'command -v adduser' >/dev/null 2>&1; then
      sudo adduser -D -s /bin/bash bash-user
    else
      echo 'no useradd/adduser available' >&2; exit 127
    fi
    echo bash-user:bash-user | sudo chpasswd
    sudo grep -qE '^bash-user[[:space:]]+ALL=' /etc/sudoers \
      || sudo sh -c 'echo \"bash-user ALL=(ALL) NOPASSWD: ALL\" >> /etc/sudoers'
  " || {
    error.log "Failed to create bash-user on $platform"
  }

  console.log "Phase A.4: installing oosh for bash-user from caller..."
  ossh install "$platform" bash-user || {
    error.log "Failed to install oosh for bash-user on $platform"
  }

  # ─── PHASE B: run test.suite core 1 on all 4 users ─────────────────────
  local rcTest=0 rcRoot=0 rcOoshUser=0 rcBashUser=0
  local testLog="" rootLog="" ooshUserLog="" bashUserLog=""

  if [ -z "$notests" ]; then
    # B.1 — test
    console.log "Running core tests as user test..."
    testLog="/tmp/oosh-platform-test-test-$platform.log"
    ossh exec "$platform" "test.suite core 1" 2>&1 | tee "$testLog"
    rcTest=${PIPESTATUS[0]}

    # B.2 — root (via test+sudo, needs -tt for TTY)
    console.log "Running core tests as root..."
    # `cd ~` (root) first: ssh starts bash with cwd=/home/test (the ssh
    # user's home). Same find-chdir-back hazard the runuser cases below
    # describe — except for root, the direct `find` calls work because
    # root reads anything; the failure mode is subprocesses (e.g. man-db's
    # postinst, which drops to user `man`) inheriting /home/test as cwd.
    rootLog="/tmp/oosh-platform-test-root-$platform.log"
    ossh exec.tty "$platform" "sudo bash -lc 'cd /root 2>/dev/null || cd /tmp; source /root/config/user.env 2>/dev/null; export PATH=/root/oosh:\$PATH; test.suite core 1'" 2>&1 | tee "$rootLog"
    rcRoot=${PIPESTATUS[0]}

    # Root's test.suite writes into sharedConfig (via /root/config symlink)
    # with root:root ownership, blocking the unprivileged users that come
    # next. Repair group+perms + setgid so B.3 and B.4 can write.
    private.os.platform.shared.config.repair "$platform"

    # B.3 — oosh-user (via test+sudo+runuser; login-shell equivalent of `user login oosh-user`).
    # Explicit source + PATH export mirrors the root case above: bashrcTemplate's
    # early-exit for non-interactive shells would otherwise skip the PATH / user.env
    # setup and `test.suite: command not found` fires.
    # `cd ~` first: ssh starts the bash with cwd=/home/test (the ssh user's
    # home, mode 700 owned by test). After `runuser -u oosh-user`, the new
    # user can't read /home/test, so any `find` invocation in test.suite
    # (e.g. state.machine.exists at state:865) emits hundreds of
    # `find: Failed to restore initial working directory: /home/test:
    # Permission denied` lines on stderr. cd'ing to the new user's own
    # home keeps find happy.
    console.log "Running core tests as oosh-user..."
    ooshUserLog="/tmp/oosh-platform-test-oosh-user-$platform.log"
    # `runuser` is shadow-utils on Debian/RHEL/Alma but missing on Alpine
    # (busybox doesn't ship it). Use a runtime detector that prefers
    # runuser (less PAM friction) and falls back to `sudo -H -u`. Both
    # give us "switch to <user>, reset HOME" semantics under the
    # NOPASSWD sudoers entry installed in Phase A.
    ossh exec.tty "$platform" "
      if command -v runuser >/dev/null 2>&1; then
        sudo runuser -u oosh-user -- bash -c 'cd ~ 2>/dev/null || cd /tmp; source ~/config/user.env 2>/dev/null; export PATH=~/oosh:\$PATH; test.suite core 1'
      else
        sudo -H -u oosh-user bash -c 'cd ~ 2>/dev/null || cd /tmp; source ~/config/user.env 2>/dev/null; export PATH=~/oosh:\$PATH; test.suite core 1'
      fi
    " 2>&1 | tee "$ooshUserLog"
    rcOoshUser=${PIPESTATUS[0]}

    # B.4 — bash-user (same pattern; same cwd fix)
    console.log "Running core tests as bash-user..."
    bashUserLog="/tmp/oosh-platform-test-bash-user-$platform.log"
    ossh exec.tty "$platform" "
      if command -v runuser >/dev/null 2>&1; then
        sudo runuser -u bash-user -- bash -c 'cd ~ 2>/dev/null || cd /tmp; source ~/config/user.env 2>/dev/null; export PATH=~/oosh:\$PATH; test.suite core 1'
      else
        sudo -H -u bash-user bash -c 'cd ~ 2>/dev/null || cd /tmp; source ~/config/user.env 2>/dev/null; export PATH=~/oosh:\$PATH; test.suite core 1'
      fi
    " 2>&1 | tee "$bashUserLog"
    rcBashUser=${PIPESTATUS[0]}
  else
    console.log "Skipping tests (notests)"
  fi

  # Interactive terminal — drop into bash-user shell (last-user-created convention)
  if [ -n "$terminal" ]; then
    console.log "Opening interactive terminal as bash-user on $platform..."
    console.log "Type 'exit' to end the session and clean up."
    # Same runuser-vs-sudo portability dance as the test invocations above.
    ossh exec.tty "$platform" "
      if command -v runuser >/dev/null 2>&1; then
        sudo runuser -u bash-user -- bash -l
      else
        sudo -H -u bash-user bash -l
      fi
    "
  fi

  # Cleanup
  ossh connection.close "$platform" 2>/dev/null
  private.os.platform.cleanup "$sshPort"

  if [ -n "$notests" ]; then
    printf "PASS: %s (tests=skipped)\n" "$platform"
    important.log "PASS: $platform (tests=skipped)"
    create.result 0 "PASS"
    rc=0
  elif [ $rcTest -eq 0 ] && [ $rcRoot -eq 0 ] && [ $rcOoshUser -eq 0 ] && [ $rcBashUser -eq 0 ]; then
    printf "PASS: %s (test=%d root=%d oosh-user=%d bash-user=%d)\n" "$platform" "$rcTest" "$rcRoot" "$rcOoshUser" "$rcBashUser"
    important.log "PASS: $platform (test=$rcTest root=$rcRoot oosh-user=$rcOoshUser bash-user=$rcBashUser)"
    create.result 0 "PASS"
    rm -f "$testLog" "$rootLog" "$ooshUserLog" "$bashUserLog"
    rc=0
  else
    printf "FAIL: %s (test=%d root=%d oosh-user=%d bash-user=%d)\n" "$platform" "$rcTest" "$rcRoot" "$rcOoshUser" "$rcBashUser"
    error.log "FAIL: $platform (test=$rcTest root=$rcRoot oosh-user=$rcOoshUser bash-user=$rcBashUser)"
    local _u _l
    for pair in "test:$testLog" "root:$rootLog" "oosh-user:$ooshUserLog" "bash-user:$bashUserLog"; do
      _u="${pair%%:*}"; _l="${pair#*:}"
      case "$_u" in
        test)      [ $rcTest -eq 0 ]     && continue ;;
        root)      [ $rcRoot -eq 0 ]     && continue ;;
        oosh-user) [ $rcOoshUser -eq 0 ] && continue ;;
        bash-user) [ $rcBashUser -eq 0 ] && continue ;;
      esac
      error.log "--- $_u test failures (grep FAIL) ---"
      grep -i "FAIL\|✗" "$_l" 2>/dev/null
      error.log "--- Full $_u log: $_l ---"
    done
    create.result 1 "FAIL"
    rc=1
  fi
  return $rc
}
os.platform.test.completion.platform() {
  private.os.platform.names
}

os.platform.test.completion.terminal() {
  echo "terminal"
}

os.platform.test.completion.notests() {
  echo "notests"
}

private.os.platform.shared.config.repair() # <platform> # reset sharedConfig group+perms in <platform>'s container so subsequent unprivileged users can write after root's test.suite left root-owned files there
{
  local platform=$1
  if [ -z "$platform" ]; then
    create.result 1 "private.os.platform.shared.config.repair requires <platform>"
    error.log "$RESULT"
    return $(result)
  fi

  # Resolve the sharedConfig path inside the container via root's
  # ~/config symlink (set up by user.oosh.install per user:821).
  # chgrp+chmod+setgid recover the dev-group-writable invariant; setgid
  # on dirs causes new files to inherit the dev group ownership, so
  # this doesn't have to run between every step — once after root is
  # enough.
  ossh exec.tty "$platform" "sudo bash -c '
    shared=\$(readlink -f /root/config 2>/dev/null)
    if [ -n \"\$shared\" ] && [ -d \"\$shared\" ]; then
      chgrp -R dev \"\$shared\" 2>/dev/null
      chmod -R g+rw \"\$shared\" 2>/dev/null
      find \"\$shared\" -type d -exec chmod g+s {} + 2>/dev/null
    fi
  '"
}

os.platform.test.all() # # tests all must-pass platforms, reports summary
{
  private.os.platform.load
  local name pass=0 fail=0 skip=0
  local platformNames=() platformResults=() platformDetails=()

  for name in $(private.os.platform.names); do
    private.os.platform.parse "$name"
    if [ "$PLATFORM_WORKSPACE" = "native" ]; then
      if [ "$name" != "macos" ]; then
        platformNames+=("$name")
        platformResults+=("SKIP")
        platformDetails+=("native — no Docker test")
        skip=$((skip + 1))
        continue
      fi
    fi

    local testLog="/tmp/oosh-platform-test-all-$name.log"
    os.platform.test "$name" 2>&1 | tee "$testLog"
    local testRc=${PIPESTATUS[0]}

    # Extract GHA URL if present (macos CI tests print "Job Summary: <url>")
    local ghaUrl=""
    ghaUrl=$(grep "^Job Summary:" "$testLog" 2>/dev/null | sed 's/Job Summary: //')
    rm -f "$testLog"

    platformNames+=("$name")
    if [ $testRc -eq 0 ]; then
      platformResults+=("PASS")
      platformDetails+=("$ghaUrl")
      pass=$((pass + 1))
    else
      platformResults+=("FAIL")
      platformDetails+=("$PLATFORM_TIER")
      if [ "$PLATFORM_TIER" = "must-pass" ]; then
        fail=$((fail + 1))
      fi
    fi
  done

  # Summary table
  echo ""
  echo -e "\e[1;35m╔════════════════════════════════════════════════════════════════════╗\e[0m"
  echo -e "\e[1;35m║                    PLATFORM TEST SUMMARY\e[0m"
  echo -e "\e[1;35m╚════════════════════════════════════════════════════════════════════╝\e[0m"
  echo ""
  printf "  %-20s %s\n" "PLATFORM" "RESULT"
  printf "  %-20s %s\n" "────────────────────" "──────"

  local i
  for i in "${!platformNames[@]}"; do
    local color="\e[1;32m"
    if [ "${platformResults[$i]}" = "FAIL" ]; then
      color="\e[1;31m"
    elif [ "${platformResults[$i]}" = "SKIP" ]; then
      color="\e[1;33m"
    fi
    printf "  %-20s " "${platformNames[$i]}"
    echo -e "${color}${platformResults[$i]}\e[0m"
    if [ -n "${platformDetails[$i]}" ]; then
      echo -e "                       \e[0;90m${platformDetails[$i]}\e[0m"
    fi
  done

  echo ""
  if [ $fail -eq 0 ] && [ $skip -eq 0 ]; then
    echo -e "  Passed:  \e[1;32m$pass\e[0m"
  else
    echo -e "  Passed: \e[1;32m$pass\e[0m  Failed: \e[1;31m$fail\e[0m  Skipped: \e[1;33m$skip\e[0m"
  fi

  if [ $fail -eq 0 ]; then
    echo ""
    echo -e "  \e[1;32m╔══════════════════════════════════════════════════════════════════╗\e[0m"
    echo -e "  \e[1;32m║  ✓ ALL PLATFORMS PASSED\e[0m"
    echo -e "  \e[1;32m╚══════════════════════════════════════════════════════════════════╝\e[0m"
  else
    echo ""
    echo -e "  \e[1;31m✗ $fail PLATFORM(S) FAILED\e[0m"
  fi

  [ $fail -eq 0 ]
}

os.info()  # <verbose:> # shows info abut the running os. add v to get more details
{
  if [ -f /etc/os-release ]; then
    source /etc/os-release
  fi
  echo "              
          shell level: $SHLVL

                script: $0
                args  : $*
                dir   : $(pwd)

              hostname: $HOSTNAME
                type  : $HOSTTYPE
                OS    : $OSTYPE

                Name  : ${GREEN}$PRETTY_NAME${NORMAL}

       package manager: $OOSH_PM
    "
  if [ -n "$1" ]; then
    cat /etc/os-release
  fi
}

os.check() { # <method> # is true if an OS was detected. LOG LEVEL 4 to see output. 
  info.log "detecting OS:  $OSTYPE" 
  local method="$1"
  if [ -n "$1" ]; then
    shift
  fi
  case "$OSTYPE" in
    darwin*)
      info.log "      Mac OS detected"
      method="$method.darwin"
      ;;
    linux*)
      info.log "      Linux detected"
      method="$method.linux"
      ;;
    *)
      important.log "  could not determine OS... please contribute to os.check"
    ;;
  esac
  
  if this.functionExists "$method"; then
    create.result 0 "$method" "$1"
  else
    create.result 1 "$method.unknown" "$1"
  fi
  return $(result)
}

os.check.env() # #
{

  if [ -z "$OOSH_OS" ]; then

    case "$OSTYPE" in
      darwin*)
        info.log "      Mac OS detected"
        export OOSH_OS="darwin"
        ;;
      linux*)
        # Match linux-gnu (glibc), linux-musl (Alpine), and any future
        # variants. Tag as "linux-gnu" — the historical value, kept for
        # downstream consumers; mirrors the broader pattern in oo:1504.
        info.log "      Linux detected"
        export OOSH_OS="linux-gnu"
        ;;
      cygwin)
        info.log "      cygwin detected"
        export OOSH_OS="cygwin"
        ;;
      msys)
        info.log "      msys detected"
        export OOSH_OS="msys"
        ;;
      win32)
        info.log "      win32 detected"
        export OOSH_OS="win32"
        ;;
      freebsd)
        info.log "      freebsd detected"
        export OOSH_OS="freebsd"
        ;;
      *)
        important.log "  could not determine OS... please contribute to os.check"
        return 1
      ;;
    esac
  fi
  return 0

}


os.usage()
{
  local this=${0##*/}
  echo "You started" 
  echo "$0

  Usage:
  $this: command   description and Parameter

      usage     prints this dialog while it will print the status when there are no parameters          
      v         print version information
      init      initializes ...nothing yet
      ----      --------------------------"
  this.help
  echo "
  ${NO_COLOR}
  Examples
    $this v
    $this init
    $this platform.list
    $this platform.test ubuntu_24_04
    $this platform.test.all

    code:${GREEN}
    source os

    if os.check ossh.service.status; then
      echo Will call ossh.service.status.detectedOS
      $RESULT "$@"
    else
      important.log "$RESULT is not supported"
    fi  


  "
}

os.start()
{
  #echo "sourcing init"
  source this

  # if [ -z "$1" ]; then
  #   status.discover "$@"
  #   return 0
  # fi

  this.start "$@"
}

os.start "$@"

