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

# ─────────────────────────────────────────────────────────────────────────────
# PLATFORM TESTING
# ─────────────────────────────────────────────────────────────────────────────

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

os.platform.test() # <platform> <?terminal> <?notests> # (moved to platform, 2026-10-22) — runs platform test
{ platform test "$@"; }
os.platform.test.completion.platform() { platform test.completion.platform; }
os.platform.test.completion.terminal() { platform test.completion.terminal; }
os.platform.test.completion.notests()  { platform test.completion.notests; }

os.platform.test.all() # # (moved to platform, 2026-10-22) — runs platform test.all
{ platform test.all "$@"; }

os.platform.list() # # (moved to platform, 2026-10-22) — runs platform list
{ platform list "$@"; }

os.platform.parse.check() # <?platform:almalinux_9> <?dir:$OOSH_DIR> # (moved to platform, 2026-10-22) — runs platform parse.check
{ platform parse.check "$@"; }
os.platform.parse.check.completion.platform() { platform test.completion.platform; }

os.info()  # <verbose:> # shows info abut the running os. add v to get more details
{
  local prettyName
  prettyName=$(private.os.release.get PRETTY_NAME)
  echo "
          shell level: $SHLVL

                script: $0
                args  : $*
                dir   : $(pwd)

              hostname: $HOSTNAME
                type  : $HOSTTYPE
                OS    : $OSTYPE

                Name  : ${GREEN}$prettyName${NORMAL}

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

os.check.env() # # set OOSH_OS (the OS family) when it is empty — from the kernel getter private.this.os.family.get #
{
  # The $OSTYPE mapping moved down into the base (this), where config needs it
  # without loading os (the blueprint oosh.drawio, 2026-10-23).
  if [ -z "$OOSH_OS" ]; then
    local family
    if ! family=$(private.this.os.family.get); then
      important.log "  could not determine OS... please contribute to private.this.os.family.get"
      return 1
    fi
    info.log "      $family detected"
    export OOSH_OS="$family"
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
    $this platform.list          (→ platform list)
    $this platform.test ubuntu_24_04  (→ platform test)

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
  # ogit sourced once here, not loaded per method (the boss, 2026-10-22)
  source ogit

  # if [ -z "$1" ]; then
  #   status.discover "$@"
  #   return 0
  # fi

  this.start "$@"
}

os.start "$@"

