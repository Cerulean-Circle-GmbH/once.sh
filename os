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

private.os.platform.test.ci() # <platform> # triggers CI workflow for native platform testing
{
  local platform="$1"

  if ! command -v gh >/dev/null 2>&1; then
    error.log "gh CLI not found — install with: oo cmd gh"
    create.result 1 "FAIL"
    return 1
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
  if ! gh workflow run macos-test.yml -R "$repo" -r "$branch" -f branch="$branch"; then
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

os.platform.test() # <platform> # tests oosh installation on a single platform
{
  local platform="$1"
  if [ -z "$platform" ]; then
    error.log "Usage: os platform.test <platform>"
    return 1
  fi

  private.os.platform.parse "$platform" || return 1

  if [ "$PLATFORM_WORKSPACE" = "native" ]; then
    if [ "$platform" = "macos" ]; then
      private.os.platform.test.ci "$platform"
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

  # Install oosh
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

  # Verify group membership before tests
  ossh exec "$platform" "id; ls -la ~/config/ | head -3"

  # Run user tests first (clean shared config state)
  console.log "Running core tests as user test..."
  local userLog="/tmp/oosh-platform-test-user-$platform.log"
  ossh exec "$platform" "test.suite core 1" 2>&1 | tee "$userLog"
  local rcUser=${PIPESTATUS[0]}

  # Run tests as root (needs -tt for sudo TTY)
  console.log "Running core tests as root..."
  local rootLog="/tmp/oosh-platform-test-root-$platform.log"
  ossh exec.tty "$platform" "sudo bash -lc 'source /root/config/user.env 2>/dev/null; export PATH=/root/oosh:\$PATH; test.suite core 1'" 2>&1 | tee "$rootLog"
  local rcRoot=${PIPESTATUS[0]}

  # Cleanup
  ossh connection.close "$platform" 2>/dev/null
  private.os.platform.cleanup "$sshPort"

  if [ $rcRoot -eq 0 ] && [ $rcUser -eq 0 ]; then
    printf "PASS: %s (root=%d, user=%d)\n" "$platform" "$rcRoot" "$rcUser"
    important.log "PASS: $platform (root=$rcRoot, user=$rcUser)"
    create.result 0 "PASS"
    rm -f "$userLog" "$rootLog"
    rc=0
  else
    printf "FAIL: %s (root=%d, user=%d)\n" "$platform" "$rcRoot" "$rcUser"
    error.log "FAIL: $platform (root=$rcRoot, user=$rcUser)"
    if [ $rcUser -ne 0 ]; then
      error.log "--- USER test failures (grep FAIL) ---"
      grep -i "FAIL\|✗" "$userLog" 2>/dev/null
      error.log "--- Full user log: $userLog ---"
    fi
    if [ $rcRoot -ne 0 ]; then
      error.log "--- ROOT test failures (grep FAIL) ---"
      grep -i "FAIL\|✗" "$rootLog" 2>/dev/null
      error.log "--- Full root log: $rootLog ---"
    fi
    create.result 1 "FAIL"
    rc=1
  fi
  return $rc
}
os.platform.test.completion.platform() {
  private.os.platform.names
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
      linux-gnu*)
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

