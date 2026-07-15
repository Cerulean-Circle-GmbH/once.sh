#!/usr/bin/env bash
# Tests for the opy script — pyenv-backed Python version & venv manager.
# Env-dependent cases (need a resolvable pyenv) are skip-guarded so the suite
# stays green on hosts without pyenv. Destructive state is isolated to a temp
# OPY_VENVS so real ~/.opy is never touched.

level=$1
if [ -z "$level" ]; then
  level=1
else
  shift
fi
echo "starting: ${BASH_SOURCE[@]##*/} <LOG_LEVEL=$level>"

source this
source test.suite
source opy

log.level $level

# ── Isolation ────────────────────────────────────────────────────────────────
ORIGINAL_OPY_VENVS="$OPY_VENVS"
export OPY_VENVS="/tmp/test.opy.$$/venvs"
mkdir -p "$OPY_VENVS"
cleanup_test_opy() {
  rm -rf "/tmp/test.opy.$$" 2>/dev/null
  export OPY_VENVS="$ORIGINAL_OPY_VENVS"
}

# Is pyenv resolvable on this host? Guards env-dependent cases.
PYENV_OK=1
if private.opy.ensurePyenv >/dev/null 2>&1; then PYENV_OK=0; fi

# ============================================================================
# T1: venvHome honors OPY_VENVS override (pure, no pyenv)
# ============================================================================
test.case - "T1: private.opy.venvHome reflects OPY_VENVS" \
  echo "checking"
if [ "$(private.opy.venvHome)" = "$OPY_VENVS" ]; then
  create.result 0 "venvHome overridden"
else
  create.result 1 "got: $(private.opy.venvHome)"
fi
expect 0 "venvHome overridden" "venvHome is deterministic + overridable"

# ============================================================================
# T2: pyenvRoot defaults sanely (pure, no pyenv)
# ============================================================================
test.case - "T2: private.opy.pyenvRoot non-empty" \
  echo "checking"
if [ -n "$(private.opy.pyenvRoot)" ]; then
  create.result 0 "pyenvRoot resolved"
else
  create.result 1 "empty pyenvRoot"
fi
expect 0 "pyenvRoot resolved" "pyenvRoot always resolves"

# ============================================================================
# T3: missing required param → usage + non-zero (venv.create)
# ============================================================================
test.case - "T3: venv.create without name errors" \
  opy.venv.create
if [ "$RETURN_VALUE" -ne 0 ]; then
  create.result 0 "usage shown"
else
  create.result 1 "should have failed"
fi
expect 0 "usage shown" "venv.create requires <name>"

# ============================================================================
# T4: missing required param → non-zero (version.set, install, remove)
# ============================================================================
test.case - "T4a: version.set without version errors" \
  opy.version.set
[ "$RETURN_VALUE" -ne 0 ] && create.result 0 "usage" || create.result 1 "should fail"
expect 0 "usage" "version.set requires <version>"

test.case - "T4b: install without version errors" \
  opy.install
[ "$RETURN_VALUE" -ne 0 ] && create.result 0 "usage" || create.result 1 "should fail"
expect 0 "usage" "install requires <version>"

test.case - "T4c: remove without version errors" \
  opy.remove
[ "$RETURN_VALUE" -ne 0 ] && create.result 0 "usage" || create.result 1 "should fail"
expect 0 "usage" "remove requires <version>"

# ============================================================================
# T5: venv.remove safety — refuses a dir that is not a venv
# ============================================================================
mkdir -p "$OPY_VENVS/notavenv"
test.case - "T5: venv.remove refuses non-venv dir" \
  opy.venv.remove notavenv
if [ "$RETURN_VALUE" -ne 0 ] && [ -d "$OPY_VENVS/notavenv" ]; then
  create.result 0 "refused"
else
  create.result 1 "should refuse + preserve"
fi
expect 0 "refused" "venv.remove will not delete a non-venv"
rmdir "$OPY_VENVS/notavenv" 2>/dev/null

# ============================================================================
# T6: venv.remove of missing name → non-zero, human error
# ============================================================================
test.case - "T6: venv.remove missing name errors" \
  opy.venv.remove nope
[ "$RETURN_VALUE" -ne 0 ] && create.result 0 "no such" || create.result 1 "should fail"
expect 0 "no such" "venv.remove reports missing venv"

# ============================================================================
# T7: venv.list on empty home → success, empty (pure FS)
# ============================================================================
test.case - "T7: venv.list empty home" \
  opy.venv.list
create.result "$RETURN_VALUE" "listed"
expect 0 "listed" "venv.list succeeds on empty home"

# ============================================================================
# ── pyenv-dependent (skip-guarded) ──────────────────────────────────────────
# ============================================================================
if [ "$PYENV_OK" -eq 0 ]; then

  # T8: version.list returns installed versions
  test.case - "T8: version.list runs" \
    opy.version.list
  VLIST_RC="$RETURN_VALUE"
  create.result "$VLIST_RC" "ran"
  expect 0 "ran" "version.list succeeds when pyenv present"

  # T9: version resolves an active interpreter (measured)
  test.case - "T9: version measured" \
    opy.version
  create.result "$RETURN_VALUE" "measured"
  expect 0 "measured" "version resolves active interpreter"

  # T10: install completion yields candidates
  CAND=$(opy.install.completion.version 2>/dev/null | head -1)
  test.case - "T10: install completion non-empty" \
    echo "checking"
  [ -n "$CAND" ] && create.result 0 "have candidates" || create.result 1 "no candidates"
  expect 0 "have candidates" "install.completion lists pyenv versions"

  # T11: full venv lifecycle on the ACTIVE interpreter (create → list → remove)
  ACTIVE=$(private.opy.pyenv version-name 2>/dev/null)
  test.case - "T11a: venv.create from active" \
    opy.venv.create suitevenv
  if [ -x "$OPY_VENVS/suitevenv/bin/python" ]; then
    create.result 0 "created"
  else
    create.result 1 "no interpreter in venv"
  fi
  expect 0 "created" "venv.create builds a usable venv"

  test.case - "T11b: venv.list shows the new venv" \
    echo "checking"
  if opy.venv.list 2>/dev/null | grep -qx "suitevenv"; then
    create.result 0 "listed"
  else
    create.result 1 "not listed"
  fi
  expect 0 "listed" "venv.list finds the created venv"

  test.case - "T11c: venv.remove deletes it" \
    opy.venv.remove suitevenv
  if [ ! -d "$OPY_VENVS/suitevenv" ]; then
    create.result 0 "removed"
  else
    create.result 1 "still present"
  fi
  expect 0 "removed" "venv.remove deletes the venv"

else
  important.log "SKIP T8-T11 — pyenv not resolvable on this host"
fi

# ============================================================================
# ── logic / dry-path cases (NEVER apt-install, NEVER recompile CPython) ──────
# ============================================================================

# ----------------------------------------------------------------------------
# T12: opy.deps module-probe branch — all importable → return 0, NO install.
# Double-guarded: only runs when the active interpreter imports every probed
# module, so the test can never fall into the pkgInstall (apt) path.
# ----------------------------------------------------------------------------
if [ "$PYENV_OK" -eq 0 ]; then
  PYX=$(private.opy.pyenv which python 2>/dev/null)
  ALLIMP=1
  if [ -x "$PYX" ]; then
    for m in _sqlite3 bz2 readline ctypes lzma _ssl zlib; do
      "$PYX" -c "import $m" >/dev/null 2>&1 || ALLIMP=0
    done
  else
    ALLIMP=0
  fi

  if [ "$ALLIMP" -eq 1 ]; then
    # Capture console.log output via a LOG_DEVICE file (console.log writes to
    # LOG_DEVICE, not stdout — /dev/null would swallow the 'nothing to install' line).
    DEPS_LOG="/tmp/test.opy.$$.deps"
    LOG_DEVICE="$DEPS_LOG" opy deps >/dev/null 2>&1; DEPS_RC=$?
    DEPS_OUT=$(cat "$DEPS_LOG" 2>/dev/null); rm -f "$DEPS_LOG"
    test.case - "T12: deps all-importable dry path (no install)" \
      echo "checking"
    if [ "$DEPS_RC" -eq 0 ] && echo "$DEPS_OUT" | grep -q "nothing to install"; then
      create.result 0 "nothing to install"
    else
      create.result 1 "rc=$DEPS_RC :: $DEPS_OUT"
    fi
    expect 0 "nothing to install" "deps probes modules + installs nothing when all importable"
  else
    test.case - "T12: deps dry path (skipped)" echo "skip"
    expect.pass "T12 skipped — active interpreter misses a probed module (would apt)"
  fi
else
  test.case - "T12: deps dry path (skipped)" echo "skip"
  expect.pass "T12 skipped — pyenv not resolvable"
fi

# ----------------------------------------------------------------------------
# T13: opy.install isInstalled guard — re-installing a present version is a
# no-op (RC0) and must NOT recompile. Guarded on an already-installed version.
# ----------------------------------------------------------------------------
if [ "$PYENV_OK" -eq 0 ]; then
  EXISTING=$(private.opy.pyenv versions --bare 2>/dev/null | head -1)
else
  EXISTING=""
fi
if [ -n "$EXISTING" ]; then
  test.case - "T13: install already-installed is a no-op (guard)" \
    opy.install "$EXISTING"
  [ "$RETURN_VALUE" -eq 0 ] && create.result 0 "no-op" || create.result 1 "rc=$RETURN_VALUE"
  expect 0 "no-op" "install of a present version returns 0 without rebuild"
else
  test.case - "T13: install guard (skipped)" echo "skip"
  expect.pass "T13 skipped — no installed version to re-install"
fi

# ----------------------------------------------------------------------------
# T14: opy.update — required-param usage + STRUCTURAL delegation to install.
# We never run a real update (it uninstalls+recompiles); T14b asserts the DRY
# delegation by inspecting the source, so no heavy path executes.
# ----------------------------------------------------------------------------
test.case - "T14a: update without version errors" \
  opy.update
[ "$RETURN_VALUE" -ne 0 ] && create.result 0 "usage" || create.result 1 "should fail"
expect 0 "usage" "update requires <version>"

test.case - "T14b: update delegates to opy.install (DRY, structural)" \
  echo "checking"
OPY_SRC=$(command -v opy)
if grep -A7 '^opy.update()' "$OPY_SRC" | grep -q 'opy.install'; then
  create.result 0 "delegates"
else
  create.result 1 "no opy.install call in opy.update body"
fi
expect 0 "delegates" "update reuses install (which runs deps first) — no separate build path"

# ----------------------------------------------------------------------------
# T15: opy.start constructor self-heal contract. The constructor funnels self-
# heal through private.opy.ensurePyenv: RC0 + idempotent on a resolvable host,
# fail-loud (never RC0) when pyenv is broken. We assert the reachable branch.
# ----------------------------------------------------------------------------
if [ "$PYENV_OK" -eq 0 ]; then
  test.case - "T15a: constructor self-heal yields valid state (RC0)" \
    private.opy.ensurePyenv
  create.result "$RETURN_VALUE" "healed"
  expect 0 "healed" "opy.start self-heal resolves pyenv on a valid host"

  test.case - "T15b: constructor self-heal is idempotent (re-run RC0)" \
    private.opy.ensurePyenv
  create.result "$RETURN_VALUE" "healed"
  expect 0 "healed" "self-heal is safe to re-run (constructor == repair)"
else
  test.case - "T15: constructor fails loud on broken pyenv" \
    private.opy.ensurePyenv
  [ "$RETURN_VALUE" -ne 0 ] && create.result 0 "failed loud" || create.result 1 "must not RC0 when broken"
  expect 0 "failed loud" "constructor never returns 0 on an unresolvable pyenv"
fi

# ----------------------------------------------------------------------------
# T16: this.help lists EVERY public opy method (DoD: self-documenting surface).
# opy.usage -> this.help renders the METHOD table to stdout (pyenv-independent).
# ----------------------------------------------------------------------------
test.case - "T16: this.help lists all public methods" \
  echo "checking"
HELP=$(LOG_DEVICE=/dev/null opy usage 2>/dev/null | sed 's/\x1b\[[0-9;]*m//g')
MISS=""
for m in start deps install version version.set version.list venv.create venv.list venv.remove remove update usage; do
  echo "$HELP" | grep -qE "^[[:space:]]*${m//./\\.}[[:space:]]*\|" || MISS="$MISS $m"
done
[ -z "$MISS" ] && create.result 0 "all listed" || create.result 1 "missing:$MISS"
expect 0 "all listed" "this.help documents every public opy method"

# ── Teardown ─────────────────────────────────────────────────────────────────
cleanup_test_opy

test.suite.save.results
