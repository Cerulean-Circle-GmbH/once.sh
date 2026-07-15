#!/usr/bin/env bash
# opy — OOP-OOSH Python version & venv manager (pyenv-backed, self-healing).
#
# One tool to install/select Python versions and manage venvs. NEVER trusts
# `python3` on PATH (it is the system interpreter here); every interpreter is
# resolved through pyenv. pyenv is NOT shell-integrated on this host, so we
# export PYENV_ROOT and resolve the binary + version paths explicitly.
#
# Author: oosh-expert (OOSH idiom) · Spec: sprint-1/task-1.opy.md · PO: opy1

# ── Resolution chokepoint (private) ──────────────────────────────────────────
# All pyenv access funnels through private.opy.pyenv so PYENV_ROOT is always set
# and the binary is resolved by path, never assumed on PATH.

private.opy.pyenvRoot() # # echo the resolved PYENV_ROOT (default ~/.pyenv)
{
  echo "${PYENV_ROOT:-$HOME/.pyenv}"
}

private.opy.pyenvBin() # # echo path to the pyenv binary (root/bin first, then PATH), or empty
{
  local root; root=$(private.opy.pyenvRoot)
  if [ -x "$root/bin/pyenv" ]; then
    echo "$root/bin/pyenv"
  else
    command -v pyenv 2>/dev/null
  fi
}

private.opy.pyenv() # <args...> # pyenv chokepoint — PYENV_ROOT exported + resolved binary
{
  local bin; bin=$(private.opy.pyenvBin)
  [ -z "$bin" ] && { error.log "pyenv not found (looked in $(private.opy.pyenvRoot)/bin and PATH)"; return 1; }
  PYENV_ROOT="$(private.opy.pyenvRoot)" "$bin" "$@"
}

private.opy.python() # <version> # absolute interpreter path for a pyenv version (measured, not assumed)
{
  local version="$1"
  [ -z "$version" ] && { error.log "private.opy.python: version required"; return 1; }
  echo "$(private.opy.pyenvRoot)/versions/$version/bin/python"
}

private.opy.venvHome() # # echo the managed-venv root (deterministic; state measured from FS)
{
  echo "${OPY_VENVS:-$HOME/.opy/venvs}"
}

private.opy.isInstalled() # <version> # 0 if version is a bare pyenv install
{
  local version="$1"
  [ -z "$version" ] && return 1
  private.opy.pyenv versions --bare 2>/dev/null | grep -qx "$version"
}

private.opy.ensurePyenv() # # self-heal: pyenv present + actually runnable, else fail loud
{
  local bin; bin=$(private.opy.pyenvBin)
  if [ -z "$bin" ]; then
    error.log "pyenv is not installed/resolvable under $(private.opy.pyenvRoot). Install pyenv (https://github.com/pyenv/pyenv), then re-run."
    return 1
  fi
  if ! PYENV_ROOT="$(private.opy.pyenvRoot)" "$bin" --version >/dev/null 2>&1; then
    error.log "pyenv found at $bin but not runnable — broken install."
    return 1
  fi
  debug.log "pyenv OK: $bin (root=$(private.opy.pyenvRoot))"
  return 0
}

private.opy.pkgInstall() # <pkg...> # non-interactive build-header install via apt-get/dnf/yum fan-out
{
  [ -z "$1" ] && return 0
  local sudo=""
  [ "$(id -u)" -ne 0 ] && sudo="sudo"
  if command -v apt-get >/dev/null 2>&1; then
    $sudo apt-get update -y >/dev/null 2>&1
    $sudo DEBIAN_FRONTEND=noninteractive apt-get install -y "$@"
  elif command -v dnf >/dev/null 2>&1; then
    $sudo dnf install -y "$@"
  elif command -v yum >/dev/null 2>&1; then
    $sudo yum install -y "$@"
  else
    error.log "opy.deps: no supported package manager (apt-get/dnf/yum) found"
    return 1
  fi
}

# ── Constructor ──────────────────────────────────────────────────────────────

# ── Shell-function UX (activate/deactivate need the CURRENT shell) ────────────
# A subprocess can't mutate its parent shell, so venv activate/deactivate are
# driven by a thin opy shell function like pyenv/nvm: the function evals what
# the script EMITS for those two verbs and passes every other verb through. The
# function is installed by an EXPLICIT, user-invoked `opy shell.install` — consent
# required to touch a shell profile — never silently on every call.

private.opy.bashrcBlock() # # emit the canonical opy() shell-function block (marker-delimited)
{
  cat <<'EOF'
# >>> opy shell function >>>
function opy {
  case "$1" in
    venv.activate|venv.deactivate) eval "$(command opy "$@")" ;;
    *) command opy "$@" ;;
  esac
}
# <<< opy shell function <<<
EOF
}

private.opy.installBashrc() # <rcfile> # idempotently install/self-heal the opy() function into <rcfile>
{
  local rc="$1"
  [ -z "$rc" ] && { error.log "installBashrc: rcfile required"; return 1; }
  local begin="# >>> opy shell function >>>"
  local end="# <<< opy shell function <<<"
  local canonical; canonical="$(private.opy.bashrcBlock)"
  [ -f "$rc" ] || touch "$rc" 2>/dev/null || { error.log "opy: cannot create $rc"; return 1; }
  local existing
  existing=$(awk -v b="$begin" -v e="$end" 'index($0,b){f=1} f{print} index($0,e){f=0}' "$rc" 2>/dev/null)
  [ "$existing" = "$canonical" ] && { console.log "opy.shell.install: already current in $rc"; return 0; }
  local tmp; tmp="${rc}.opy.$$"
  awk -v b="$begin" -v e="$end" 'index($0,b){f=1} !f{print} index($0,e){f=0}' "$rc" 2>/dev/null > "$tmp" \
    || { error.log "opy: bashrc rewrite failed"; rm -f "$tmp"; return 1; }
  printf '%s\n' "$canonical" >> "$tmp"
  mv "$tmp" "$rc" || { error.log "opy: cannot update $rc"; rm -f "$tmp"; return 1; }
  console.log "opy.shell.install: installed opy shell function in $rc — run 'source $rc' or open a new shell"
  return 0
}

opy.shell.install() # <?rcfile:~/.bashrc> # EXPLICIT opt-in: install the opy() shell function enabling venv.activate/deactivate
{
  local rc="${1:-$HOME/.bashrc}"
  private.opy.installBashrc "$rc"
}
opy.shell.install.completion.rcfile() { compgen -f -- "$1"; }

opy.start() # # constructor: source kernel + self-heal pyenv (never on source), then dispatch
{
  source this
  # Self-heal on real construction only (init yields a valid object or fails loud).
  # Skipped when sourced (completion) and for introspection verbs so the tool
  # stays usable even when pyenv is broken. NOTE: the opy shell function is NOT
  # auto-installed here — a shell profile is only modified via explicit
  # `opy shell.install` (consent). If venv.activate is used without it, activate
  # emits a hint.
  if ! this.isSourced; then
    case "$1" in
      ''|help|help*|usage) : ;;
      *) private.opy.ensurePyenv || return $? ;;
    esac
  fi
  this.start "$@"
}

# ── Build dependencies ───────────────────────────────────────────────────────

opy.deps() # <?version> # check/install build headers needed to compile CPython
{
  local version="$1"
  local modules="_sqlite3 bz2 readline ctypes lzma _ssl zlib"

  # Choose an interpreter to probe: the target version if present, else active.
  local py=""
  if [ -n "$version" ] && [ -x "$(private.opy.python "$version")" ]; then
    py="$(private.opy.python "$version")"
  else
    py="$(private.opy.pyenv which python 2>/dev/null)"
  fi

  local missing=""
  if [ -n "$py" ] && [ -x "$py" ]; then
    local m
    for m in $modules; do
      "$py" -c "import $m" >/dev/null 2>&1 || missing="$missing $m"
    done
  else
    # No interpreter to probe yet (fresh host) — install the full set so the
    # first compile has every header. Measure-don't-assume: say why.
    important.log "opy.deps: no interpreter to probe — installing full CPython build-dep set"
    missing="$modules"
  fi

  if [ -z "$missing" ]; then
    console.log "opy.deps: all build modules importable — nothing to install"
    return 0
  fi

  # Map probed modules → Debian/Ubuntu -dev packages.
  local pkgs="" mod
  for mod in $missing; do
    case "$mod" in
      _sqlite3) pkgs="$pkgs libsqlite3-dev" ;;
      bz2)      pkgs="$pkgs libbz2-dev" ;;
      readline) pkgs="$pkgs libreadline-dev" ;;
      ctypes)   pkgs="$pkgs libffi-dev" ;;
      lzma)     pkgs="$pkgs liblzma-dev" ;;
      _ssl)     pkgs="$pkgs libssl-dev" ;;
      zlib)     pkgs="$pkgs zlib1g-dev" ;;
    esac
  done
  pkgs=$(echo $pkgs | tr ' ' '\n' | grep -v '^$' | sort -u | tr '\n' ' ')
  console.log "opy.deps: installing build headers:$pkgs"
  private.opy.pkgInstall $pkgs
}

# ── Version management ───────────────────────────────────────────────────────

opy.install() # <version> # pyenv install <version> (idempotent; runs deps first)
{
  local version="$1"
  [ -z "$version" ] && { error.log "usage: opy install <version>"; return 1; }
  if private.opy.isInstalled "$version"; then
    console.log "opy.install: $version already installed"
    return 0
  fi
  opy.deps "$version" || { error.log "opy.install: build deps failed for $version"; return 1; }
  console.log "opy.install: building $version (this can take several minutes)…"
  private.opy.pyenv install -s "$version"
}
opy.install.completion.version() { private.opy.pyenv install --list 2>/dev/null | sed 's/^[[:space:]]*//' | grep -viE 'available versions|^$'; }

opy.version() # # show ACTIVE python version (measured, not assumed)
{
  local v; v=$(private.opy.pyenv version-name 2>/dev/null)
  [ -z "$v" ] && { error.log "opy.version: could not resolve active version"; return 1; }
  local py; py=$(private.opy.pyenv which python 2>/dev/null)
  console.log "$v${py:+  ($py)}"
  return 0    # success = version resolved, independent of log level
}

opy.version.set() # <version> # pyenv global <version>
{
  local version="$1"
  [ -z "$version" ] && { error.log "usage: opy version.set <version>"; return 1; }
  if ! private.opy.isInstalled "$version"; then
    error.log "opy.version.set: $version is not installed — run 'opy install $version' first"
    return 1
  fi
  private.opy.pyenv global "$version"
}
opy.version.set.completion.version() { private.opy.pyenv versions --bare 2>/dev/null; }

opy.version.list() # # list installed pyenv versions
{
  private.opy.pyenv versions --bare 2>/dev/null
}

# ── Virtual environments ─────────────────────────────────────────────────────

opy.venv.create() # <name> <?version> # venv from a pyenv interpreter (default: active)
{
  local name="$1"
  local version="$2"
  [ -z "$name" ] && { error.log "usage: opy venv.create <name> <?version>"; return 1; }

  local py=""
  if [ -n "$version" ]; then
    py="$(private.opy.python "$version")"
    [ -x "$py" ] || { error.log "opy.venv.create: interpreter for $version not found ($py) — 'opy install $version' first"; return 1; }
  else
    py="$(private.opy.pyenv which python 2>/dev/null)"
    [ -x "$py" ] || { error.log "opy.venv.create: no active interpreter resolvable"; return 1; }
  fi

  local home; home="$(private.opy.venvHome)"
  local dest="$home/$name"
  if [ -d "$dest" ]; then
    console.log "opy.venv.create: venv '$name' already exists at $dest"
    return 0
  fi
  mkdir -p "$home" || { error.log "opy.venv.create: cannot create venv home $home"; return 1; }
  console.log "opy.venv.create: creating '$name' from $py"
  "$py" -m venv "$dest" || { error.log "opy.venv.create: venv creation failed"; return 1; }
  console.log "opy.venv.create: $dest"
  return 0
}
opy.venv.create.completion.version() { private.opy.pyenv versions --bare 2>/dev/null; }

opy.venv.list() # # list managed venvs
{
  local home; home="$(private.opy.venvHome)"
  [ -d "$home" ] || return 0
  local d
  for d in "$home"/*/; do
    [ -d "$d" ] || continue
    [ -x "${d}bin/python" ] || continue    # only real venvs count
    basename "$d"
  done
}

opy.venv.remove() # <name> # remove a venv
{
  local name="$1"
  [ -z "$name" ] && { error.log "usage: opy venv.remove <name>"; return 1; }
  local home; home="$(private.opy.venvHome)"
  local dest="$home/$name"
  if [ ! -d "$dest" ]; then
    error.log "opy.venv.remove: no such venv '$name' at $dest"
    return 1
  fi
  # Safety: only remove things that actually look like a venv.
  if [ ! -e "$dest/pyvenv.cfg" ] && [ ! -x "$dest/bin/python" ]; then
    error.log "opy.venv.remove: '$dest' does not look like a venv — refusing to remove"
    return 1
  fi
  rm -rf "$dest" || { error.log "opy.venv.remove: failed to remove $dest"; return 1; }
  console.log "opy.venv.remove: removed $dest"
  return 0
}
opy.venv.remove.completion.name() { opy.venv.list; }

opy.venv.activate() # <name> # emit the activation line for the opy() shell function to eval in the CURRENT shell
{
  local name="$1"
  [ -z "$name" ] && { error.log "usage: opy venv.activate <name>"; return 1; }
  local home; home="$(private.opy.venvHome)"
  local act="$home/$name/bin/activate"
  [ -f "$act" ] || { error.log "opy.venv.activate: no such venv '$name' (looked for $act) — 'opy venv.create $name' first"; return 1; }
  # RAW stdout bypasses logging: the opy shell function evals this in-place.
  # Run directly (no function) and you just SEE the line — install once with
  # 'opy shell.install' to make 'opy venv.activate' activate in your shell.
  echo "source '$act'"
}
opy.venv.activate.completion.name() { opy.venv.list; }

opy.venv.deactivate() # # emit the deactivation command for the opy() shell function to eval
{
  # Guarded so eval is a no-op when no venv is active.
  echo "deactivate 2>/dev/null || true"
}

# ── Lifecycle ────────────────────────────────────────────────────────────────

opy.remove() # <version> # uninstall a pyenv version
{
  local version="$1"
  [ -z "$version" ] && { error.log "usage: opy remove <version>"; return 1; }
  if ! private.opy.isInstalled "$version"; then
    console.log "opy.remove: $version not installed — nothing to do"
    return 0
  fi
  private.opy.pyenv uninstall -f "$version"
}
opy.remove.completion.version() { private.opy.pyenv versions --bare 2>/dev/null; }

opy.update() # <version> # rebuild a version (uninstall+install) to pick up new deps
{
  local version="$1"
  [ -z "$version" ] && { error.log "usage: opy update <version>"; return 1; }
  private.opy.pyenv uninstall -f "$version" 2>/dev/null
  opy.install "$version"    # DRY: install runs deps first, then builds
}
opy.update.completion.version() { private.opy.pyenv versions --bare 2>/dev/null; }

# ── Help ─────────────────────────────────────────────────────────────────────

opy.usage() # # help footer -> this.help
{
  console.log "opy — OOP-OOSH Python version & venv manager (pyenv-backed)"
  this.help
}

opy.start "$@"
