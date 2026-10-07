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


private.os.platform.container.up()     # <platform> <image> <port> # start a fresh platform container from <image> on ssh <port>, open ssh to it, push the key, let test sudo, install oosh for the user test through ossh install (honours OSSH_INSTALL_BRANCH) and settle sshd and the ControlMaster; rc 1 (RESULT FAIL) when the image cannot be built #
{
 local platform="$1" imageTag="$2" sshPort="$3"
 if [ -z "$platform" ] || [ -z "$imageTag" ] || [ -z "$sshPort" ]; then
   create.result 1 "private.os.platform.container.up requires <platform> <image> <port>"
   error.log "$RESULT"
   return $(result)
 fi
 # PLATFORM_WORKSPACE comes from private.os.platform.parse, run by the caller
 # (os.platform.test) in the same shell.

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
   return $(result)
  fi
 fi

 # Fresh container
 # Docker's random name, as container and host name (odocker.run.sshd), so
 # the install inside names the computer by it, not by the container's ID.
 odocker reset "$imageTag" "$sshPort"
 sleep 2

 # SSH setup
 ossh config.create "$platform" "test@localhost:$sshPort"
 ossh config.save.last
 # Clean up any stale ControlMaster socket from a previous test run
 ssh -O exit -o ControlPath="$OSSH_CONTROL_PATH" "$platform" 2>/dev/null
 private.os.platform.socket.remove "$sshPort"

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
 # `private.push.init.oosh` in ossh which SCPs init/oosh and runs
 # its self-install, and the git install + the bash install steps of
 # Phase A in init/oosh.
 ossh install "$platform" test

 # The git install above may upgrade openssh-server in place (AlmaLinux 9.8
 # shipped 9.9p1). sshd re-execs per connection, so the running pre-upgrade
 # daemon refuses every FRESH connection until it re-execs the new binary.
 # Re-exec it now so the ControlMaster refresh below — and all of Phase B —
 # connect cleanly. See private.os.platform.sshd.reload.
 private.os.platform.sshd.reload "$sshPort"

 # Refresh ControlMaster so new sessions pick up dev group membership
 # (usermod -aG dev runs during install, but ControlMaster keeps old groups)
 ossh connection.close "$platform" 2>/dev/null
 private.os.platform.socket.remove "$sshPort"
 SSHPASS=test sshpass -e ssh \
  -o ControlMaster=yes \
  -o ControlPath="$OSSH_CONTROL_PATH" \
  -o ControlPersist=600 \
  -o StrictHostKeyChecking=accept-new \
  "$platform" true
 create.result 0 "container for $platform is up on port $sshPort, install of oosh for test attempted (see the log)"
 return $(result)
}


private.os.platform.users.install()     # <platform> # Phase A in the platform container: create oosh-user with user create, bash-user with useradd/adduser, give both NOPASSWD sudo and install oosh for bash-user from the caller (ossh install honours OSSH_INSTALL_BRANCH); failures are logged, not fatal #
{
 local platform="$1"
 if [ -z "$platform" ]; then
   create.result 1 "private.os.platform.users.install requires <platform>"
   error.log "$RESULT"
   return $(result)
 fi

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
 # sudoers.d) — matches the sudoers append for the test
 # user above; sudoers.d isn't always included on minimal images (alma's
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
 create.result 0 "creation of oosh-user and bash-user and the install for bash-user attempted on $platform (see the log)"
 return $(result)
}


private.os.platform.gate.log.get()     # <user> <platform> # echo the log file path of the platform gate of <user> in <platform> (/tmp/oosh-platform-test-<user>-<platform>.log); one place for gate.run and platform.test #
{
 # NO create.result — a getter consumed as $(...): SILENT BY CONTRACT.
 [ -n "$1" ] && [ -n "$2" ] || return 1
 echo "/tmp/oosh-platform-test-$1-$2.log"
}


private.os.platform.gate.run()     # <platform> <user> <?log> # Phase B for ONE user (test, root, oosh-user or bash-user) in the platform container: test.suite gate 1 through private.os.platform.user.run (the transport that fits the user), tee into <log> (default: private.os.platform.gate.log.get <user> <platform>); rc is the gate rc of that user #
{
 local platform="$1" user="$2" log="$3"
 if [ -z "$platform" ] || [ -z "$user" ]; then
   create.result 1 "private.os.platform.gate.run requires <platform> <user>"
   error.log "$RESULT"
   return $(result)
 fi
 case "$user" in test|root|oosh-user|bash-user) ;; *)
   create.result 1 "private.os.platform.gate.run: unknown <user> $user (test, root, oosh-user or bash-user)"
   error.log "$RESULT"
   return $(result) ;;
 esac
 [ -n "$log" ] || log=$(private.os.platform.gate.log.get "$user" "$platform")

 # Each user runs `test.suite gate 1`: core AND platform.shared.configLayout.invariant
 # (the config layout, no boot), one verdict. The transport per user, and why,
 # is private.os.platform.user.run's (os platform.heal.test runs other commands through it).
 console.log "Running the gate (core + platform invariant) as $([ "$user" = test ] && echo "user test" || echo "$user")..."
 private.os.platform.user.run "$platform" "$user" "test.suite gate 1" "$log"
 local rc=$?
 create.result "$rc" "the gate of $user on $platform ended with rc $rc (log: $log)"
 return $rc
}


private.os.platform.branch.gate()     # <branch> <?dir:$OOSH_DIR> # era gate for platform.test: rc 0 when the init/oosh of <branch> (a branch on origin of the repo in <dir>) carries the mode root installer contract, rc 1 and a message when the ref is missing or older than commit b8b90b82 #
{
 local branch="$1" dir="${2:-$OOSH_DIR}"
 if [ -z "$branch" ]; then
   create.result 1 "private.os.platform.branch.gate requires <branch>"
   error.log "$RESULT"
   return $(result)
 fi
 # Probe text: since b8b90b82 (23 Apr 2026) init/oosh answers any mode but root with
 # "only 'mode root' is supported"; the older refs (b492b2e, 9824746e, 0f63df38, 1604e3e,
 # 596ab0c) use `mode ssh` + rsync and do not contain that text. A ref beginning with
 # a dash is never a ref (it would be read as an option by git).
 private.this.script.load ogit ogit.file.show || return $(result)
 private.this.script.load ogit ogit.branch.check || return $(result)
 local contract="only 'mode root' is supported" content
 case "$branch" in
   -*) create.result 1 "<branch> $branch is not a branch name"
       error.log "$RESULT"
       return $(result) ;;
 esac
 # The container clones from origin, so only a branch that origin has is accepted
 # (ogit.branch.check "origin/<branch>", tried first and the only candidate: a stale
 # local branch of the same name must not win, and a sha is not cloneable). The
 # scenario test os platform.heal.test ships a sha as a temporary branch
 # platform-test/<sha>. The gate reads the remote-tracking ref in <dir>, which can be
 # stale until the next fetch. The old installer is read through ogit.file.show.
 local ref="origin/$branch"
 if ! ogit.branch.check "$ref" "$dir"; then
   create.result 1 "<branch> $branch is not a branch on origin (a sha or a local-only branch cannot be cloned by the container); the scenario test os platform.heal.test ships a sha as a temporary branch platform-test/<sha>"
   error.log "$RESULT"
   return $(result)
 fi
 if ! content=$(ogit.file.show "$ref" init/oosh "$dir" 2>/dev/null); then
   create.result 1 "ref $ref has no init/oosh in $dir"
   error.log "$RESULT"
   return $(result)
 fi
 case "$content" in
   *"$contract"*) create.result 0 "ref $branch carries the mode root installer contract"; return $(result) ;;
 esac
 create.result 1 "ref $branch is older than commit b8b90b82: its init/oosh uses the mode ssh contract, which the current ossh install cannot drive; such refs are reproduced by the eraB.* breakages of os platform.heal.test"
 error.log "$RESULT"
 return $(result)
}


private.os.platform.socket.remove()     # <port> # remove the stale ControlMaster socket /tmp/ossh-test@localhost:<port> of a platform test container; silent and idempotent #
{
 # NO create.result — silent by contract; a missing socket is no error.
 [ -n "$1" ] || return 1
 rm -f "/tmp/ossh-test@localhost:$1" 2>/dev/null
 return 0
}


private.os.platform.heal.breakage.names.get()     #  # echo the breakage names of os platform.heal.test one per line, in the order they are applied; silent getter #
{
 # NO create.result — a getter consumed as $(...) and by the completion of
 # os.platform.heal.test. The order is the order of application, whatever
 # order is typed (private.os.platform.heal.breakage.list.get keeps it): the
 # users' shapes, the system's, then the canonical folder <base>/<branch>.
 # The folder arms build on one another in this order: missing.branch clears
 # <base>/<branch>; diverged clones it again from the installed tree (an
 # install of another ref has no such folder) and commits on it;
 # markers.committed commits on it; merge.conflict leaves a merge in
 # progress, which refuses any further commit; dirty changes a file the merge
 # does not touch; detached comes last, through update-ref, because a merge
 # in progress refuses a checkout. worktree.layout breaks <base>/testing, a
 # folder of its own: one folder holds one shape of a worktree.
 printf '%s\n' eraB.config root.clone foreign.symlink devhome.missing boot.era no.bashrc \
   safe.directory.stale ssh.legacy state.30 launcher.missing worktree.layout \
   missing.branch diverged markers.committed merge.conflict dirty detached
}


private.os.platform.heal.breakage.list.get()     # <?names...:all> # RESULT = the breakages to apply, space-separated, in the order of private.os.platform.heal.breakage.names.get: all, or no name, is every one; rc 1 naming the first unknown name #
{
 local names word wanted=" " list=""
 names=$(private.os.platform.heal.breakage.names.get | tr '\n' ' ')
 [ $# -gt 0 ] || set -- all
 for word in "$@"; do
   if [ "$word" = all ]; then
     wanted=" $names"
     continue
   fi
   # A name is letters, digits and dots: a glob character never reaches the case pattern below.
   case "$word" in
     ""|*[!A-Za-z0-9.]*) ;;
     *) case " $names" in *" $word "*) wanted="$wanted$word "; continue ;; esac ;;
   esac
   create.result 1 "unknown breakage '$word' — one of: all ${names% }"
   error.log "$RESULT"
   return $(result)
 done
 for word in $names; do
   case "$wanted" in *" $word "*) list="$list $word" ;; esac
 done
 create.result 0 "${list# }"
 return $(result)
}


private.os.platform.heal.fixture.script.get()     # <fixture> <target> # echo POSIX sh that writes the file or folder test/fixtures/heal/<fixture> to <target> where it runs, each file as a quoted here-document (nothing in it expanded); <target> is shell text the remote shell expands, e.g. $h/config; silent getter, rc 1 when the fixture is missing #
{
 # NO create.result — a getter consumed as $(...); its text is part of a
 # breakage script (private.os.platform.heal.breakage.script.get). The files
 # travel as text inside the one script: the script is the only thing that
 # reaches the container (private.os.platform.root.script.run).
 local fixture="$1" target="$2" src file rel
 src="$OOSH_DIR/test/fixtures/heal/$fixture"
 [ -n "$fixture" ] && [ -n "$target" ] && [ -e "$src" ] || return 1
 if [ -f "$src" ]; then
   printf "cat > \"%s\" <<'OOSH_HEAL_FIXTURE_EOF'\n" "$target"
   # raw: the fixture's bytes, no method reads a file; a last line without a newline gets one
   cat "$src"
   [ -z "$(tail -c 1 "$src")" ] || echo
   echo OOSH_HEAL_FIXTURE_EOF
   return 0
 fi
 printf 'mkdir -p "%s"\n' "$target"
 while IFS= read -r file; do
   rel="${file#"$src"/}"
   case "$rel" in */*) printf 'mkdir -p "%s/%s"\n' "$target" "${rel%/*}" ;; esac
   printf "cat > \"%s/%s\" <<'OOSH_HEAL_FIXTURE_EOF'\n" "$target" "$rel"
   cat "$file"
   [ -z "$(tail -c 1 "$file")" ] || echo
   echo OOSH_HEAL_FIXTURE_EOF
 done < <(find "$src" -type f | LC_ALL=C sort)
}


private.os.platform.heal.remote.preamble.get()     # <branch> # echo the POSIX sh preamble of every script os platform.heal.test runs as root in a container: H=<branch>, home_of from /etc/passwd, the base B, the sharedConfig S, the canonical folder D=B/H, rgit, say and fail, the installed tree and a clone of it, the foreign sums; silent getter, rc 1 for a missing or bad <branch> #
{
 # NO create.result — a getter consumed as $(...). Raw POSIX sh ON PURPOSE:
 # these scripts reproduce and inspect what an OLD install left behind, and
 # must not depend on the oosh under test (an old ref, broken further by the
 # earlier breakages); /bin/sh may be dash or busybox ash. The base and the
 # sharedConfig are the paths of private.oo.heal.path.get under the parent of
 # developking's home from /etc/passwd (kept there when its home is removed),
 # else /home. N names the breakage in say and fail; the caller sets it.
 local branch="$1"
 case "$branch" in ""|-*|*[!A-Za-z0-9._/@+-]*) return 1 ;; esac
 printf "H='%s'\n" "$branch"
 cat <<'OOSH_HEAL_PREAMBLE'
set -u
N=${N:-heal}
say()  { echo "breakage $N: $*"; }
fail() { echo "breakage $N: FAILED — $*" >&2; exit 1; }
# ogit-exception: inside the platform container, as root — the oosh there is the old ref under test; safe.directory for this call only
rgit() { git -c safe.directory='*' -c user.email=heal-test@oosh.invalid -c user.name='oosh heal test' -c commit.gpgsign=false "$@"; }
home_of() { awk -F: -v u="$1" '$1 == u { print $6; exit }' /etc/passwd; }
dh=$(home_of developking)
bh=/home
[ -n "$dh" ] && bh=${dh%/*}
B="$bh/shared/EAMD.ucp/Components/com/ceruleanCircle/EAM/1_infrastructure/Once.sh"
S="$bh/shared/EAMD.ucp/Scenarios/localhost/EAM/1_infrastructure/Once.sh/sharedConfig"
D="$B/$H"
installed() { t=$(readlink -f "$(home_of test)/oosh" 2>/dev/null); [ -n "$t" ] && [ -e "$t/.git" ] && echo "$t"; }
clone_installed() {
  src=$(installed) || fail "the user test has no installed ~/oosh to clone"
  url=$(rgit -C "$src" remote get-url origin) || fail "$src has no origin"
  mkdir -p "${1%/*}"
  rgit clone -q "$src" "$1" || fail "clone of $src into $1"
  rgit -C "$1" checkout -q -B "$2" || fail "branch $2 in $1"
  rgit -C "$1" remote set-url origin "$url" || fail "origin of $1"
  }
branch_dir_ensure() {
  [ -e "$D/.git" ] && return 0
  [ -e "$D" ] && rm -rf "$D"
  clone_installed "$D" "$H"
  say "$D cloned from $(installed) on branch $H"
  }
foreign_sums() { ( cd /opt/foreign && find . -print | LC_ALL=C sort && find . -type f -exec cksum {} + | LC_ALL=C sort ); }
OOSH_HEAL_PREAMBLE
}


private.os.platform.heal.breakage.script.get()     # <name> <branch> # echo the POSIX sh that applies the breakage <name> as root in a platform container: the preamble of private.os.platform.heal.remote.preamble.get and the arm of <name>; each arm looks first, says already and changes nothing when its shape is there, else breaks and says what it did; silent getter, rc 1 for an unknown name or a bad <branch> #
{
 # NO create.result — a getter consumed as $(...); private.os.platform.heal.breakage.apply
 # runs the text. The container is disposable (os platform.heal.test removes
 # it), so an arm may delete; what the real machines must never lose is
 # oo heal's concern, and the scenario proves it on these copies.
 local name="$1" branch="$2" preamble
 [ -n "$name" ] || return 1
 private.os.platform.heal.breakage.names.get | grep -qxF -- "$name" || return 1
 preamble=$(private.os.platform.heal.remote.preamble.get "$branch") || return 1
 printf "N='%s'\n%s\n" "$name" "$preamble"
 case "$name" in
   eraB.config)
     # test's ~/config: the MacStudio's era-B folder (sanitised), /Users/donges -> test's home
     cat <<'OOSH_HEAL_ARM'
h=$(home_of test); [ -n "$h" ] || fail "no user test"
c="$h/config"
if [ -d "$c" ] && [ ! -L "$c" ] && grep -q 'OOSH_MODE="mcdonges.latest"' "$c/user.env" 2>/dev/null; then say "already: $c is the era-B config"; exit 0; fi
if [ -L "$c" ]; then rm -f "$c"; elif [ -e "$c" ]; then mv "$c" "$c.before-eraB"; fi
OOSH_HEAL_ARM
     private.os.platform.heal.fixture.script.get eraB.config '$c' || return 1
     cat <<'OOSH_HEAL_ARM'
sed -i "s#/Users/donges#$h#g" "$c/user.env" "$c/oosh.env"
chown -R test "$c" # recursive-exception: the era-B config this arm just wrote, in a disposable container
say "$c is a real folder with the era-B files of the MacStudio, /Users/donges rewritten to $h"
OOSH_HEAL_ARM
     ;;
   root.clone)
     # once_dev's root: ~/oosh a real clone (dev at the old ref) with an oosh.orig.<ts>, ~/config real with OOSH_MODE="oosh"
     cat <<'OOSH_HEAL_ARM'
r=$(home_of root); [ -n "$r" ] || fail "no root in /etc/passwd"
if [ -d "$r/oosh/.git" ] && [ ! -L "$r/oosh" ]; then
  say "already: $r/oosh is a real clone"
else
  if [ -L "$r/oosh" ]; then rm -f "$r/oosh"; elif [ -e "$r/oosh" ]; then mv "$r/oosh" "$r/oosh.before-private-clone"; fi
  clone_installed "$r/oosh" dev
  say "$r/oosh is a real clone of $(installed) on branch dev"
fi
o="$r/oosh.orig.20260910-093000"
if [ -e "$o" ]; then say "already: $o"; else cp -a "$r/oosh" "$o" || fail "copy to $o"; say "$o copied from $r/oosh"; fi
if [ -L "$r/config" ]; then
  t=$(readlink -f "$r/config"); rm -f "$r/config"
  cp -a "$t" "$r/config" || fail "copy of $t"
  say "$r/config is a real copy of $t"
elif [ -d "$r/config" ]; then
  say "already: $r/config is a real folder"
else
  mkdir -p "$r/config"; say "$r/config made"
fi
f="$r/config/oosh.session.env"
if grep -qx 'export OOSH_MODE="oosh"' "$f" 2>/dev/null; then say "already: OOSH_MODE=oosh in $f"
elif grep -q '^export OOSH_MODE=' "$f" 2>/dev/null; then sed -i 's/^export OOSH_MODE=.*/export OOSH_MODE="oosh"/' "$f"; say "OOSH_MODE=oosh in $f"
else echo 'export OOSH_MODE="oosh"' >> "$f"; say "OOSH_MODE=oosh added to $f"; fi
OOSH_HEAL_ARM
     ;;
   foreign.symlink)
     # bash-user's ~/oosh -> a clone outside the base; its sums and a marker are recorded for private.os.platform.heal.foreign.check
     cat <<'OOSH_HEAL_ARM'
u=$(home_of bash-user); [ -n "$u" ] || fail "no bash-user"
f=/opt/foreign/OOSH/x
if [ -e "$f/.git" ]; then say "already: $f is a clone"; else clone_installed "$f" dev; say "$f is a real clone of $(installed)"; fi
if [ "$(readlink "$u/oosh" 2>/dev/null)" = "$f" ]; then
  say "already: $u/oosh -> $f"
else
  if [ -L "$u/oosh" ]; then rm -f "$u/oosh"; elif [ -e "$u/oosh" ]; then mv "$u/oosh" "$u/oosh.before-foreign"; fi
  ln -s "$f" "$u/oosh" && chown -h bash-user "$u/oosh" || fail "link $u/oosh"
  say "$u/oosh -> $f"
fi
if [ -f /opt/foreign.heal.sums ]; then
  say "already: the sums of /opt/foreign are recorded"
else
  foreign_sums > /opt/foreign.heal.sums && touch /opt/foreign.heal.marker || fail "sums of /opt/foreign"
  say "the sums of /opt/foreign are in /opt/foreign.heal.sums, its marker /opt/foreign.heal.marker"
fi
OOSH_HEAL_ARM
     ;;
   devhome.missing)
     cat <<'OOSH_HEAL_ARM'
[ -n "$dh" ] || fail "developking is not in /etc/passwd"
if [ -d "$dh" ]; then rm -rf "$dh"; say "$dh removed, developking stays in /etc/passwd"; else say "already: $dh is missing"; fi
OOSH_HEAL_ARM
     ;;
   boot.era)
     # oosh-user's .bashrc of the boot era (templates/user/bashrcTemplate before 9dcf8021), the T9 drop-in and /etc/oosh/boot
     cat <<'OOSH_HEAL_ARM'
u=$(home_of oosh-user); [ -n "$u" ] || fail "no oosh-user"
if grep -q 'oosh/boot' "$u/.bashrc" 2>/dev/null; then
  say "already: $u/.bashrc is of the boot era"
else
OOSH_HEAL_ARM
     private.os.platform.heal.fixture.script.get boot.era/bashrc '$u/.bashrc' || return 1
     cat <<'OOSH_HEAL_ARM'
  chown oosh-user "$u/.bashrc"
  say "$u/.bashrc is the boot-era template"
fi
if grep -q 'root.boot.path.installed' /etc/profile.d/oosh.sh 2>/dev/null; then
  say "already: /etc/profile.d/oosh.sh is the T9 drop-in"
else
  mkdir -p /etc/profile.d
OOSH_HEAL_ARM
     private.os.platform.heal.fixture.script.get boot.era/profile.d.oosh.sh /etc/profile.d/oosh.sh || return 1
     cat <<'OOSH_HEAL_ARM'
  chmod 644 /etc/profile.d/oosh.sh
  say "/etc/profile.d/oosh.sh is the T9 drop-in"
fi
if [ -L /etc/oosh/boot ]; then say "already: /etc/oosh/boot"; else mkdir -p /etc/oosh && ln -sfn "$D/boot" /etc/oosh/boot || fail "/etc/oosh/boot"; say "/etc/oosh/boot -> $D/boot"; fi
OOSH_HEAL_ARM
     ;;
   no.bashrc)
     cat <<'OOSH_HEAL_ARM'
r=$(home_of root)
if [ ! -e "$r/.bashrc" ]; then say "already: no $r/.bashrc"
elif [ -e "$r/.bashrc.pre-oosh" ]; then rm -f "$r/.bashrc"; say "$r/.bashrc removed, $r/.bashrc.pre-oosh left"
else mv "$r/.bashrc" "$r/.bashrc.pre-oosh"; say "$r/.bashrc moved to $r/.bashrc.pre-oosh"; fi
OOSH_HEAL_ARM
     ;;
   safe.directory.stale)
     cat <<'OOSH_HEAL_ARM'
r=$(home_of root)
for e in /Users/Shared/EAMD.ucp/Components/com/ceruleanCircle/EAM/1_infrastructure/Once.sh/dev /Users/Shared/EAMD.ucp/Components/com/ceruleanCircle/EAM/1_infrastructure/Once.sh/main; do
  if rgit config --file "$r/.gitconfig" --get-all safe.directory 2>/dev/null | grep -qxF "$e"; then say "already: $e"
  else rgit config --file "$r/.gitconfig" --add safe.directory "$e" || fail "safe.directory $e"; say "safe.directory $e added to $r/.gitconfig"; fi
done
OOSH_HEAL_ARM
     ;;
   ssh.legacy)
     # the names user.ssh.backup.status looks for: ssh.original and ssh.<user>.<host>.for.<host>
     cat <<'OOSH_HEAL_ARM'
r=$(home_of root)
for d in "$r/ssh.original" "$r/ssh.root.oncedev.for.oncedev"; do
  if [ -d "$d" ]; then say "already: $d"; else mkdir -p "$d" && chmod 700 "$d" && : > "$d/known_hosts" || fail "$d"; say "$d made"; fi
done
OOSH_HEAL_ARM
     ;;
   state.30)
     cat <<'OOSH_HEAL_ARM'
r=$(home_of root); f="$r/config/current.state.machine.env"
if grep -qx 'state=30' "$f" 2>/dev/null && grep -qx 'machine=SETUP_SERVER' "$f"; then say "already: $f is at SETUP_SERVER 30"
elif [ -f "$f" ]; then sed -i -e 's/^machine=.*/machine=SETUP_SERVER/' -e 's/^state=.*/state=30/' "$f"; say "$f set to SETUP_SERVER 30"
else mkdir -p "${f%/*}"; printf 'machine=SETUP_SERVER\nstate=30\n' > "$f"; say "$f written at SETUP_SERVER 30"; fi
OOSH_HEAL_ARM
     ;;
   launcher.missing)
     cat <<'OOSH_HEAL_ARM'
if [ -e /usr/local/bin/this ] || [ -L /usr/local/bin/this ]; then rm -f /usr/local/bin/this; say "/usr/local/bin/this removed"; else say "already: no /usr/local/bin/this"; fi
OOSH_HEAL_ARM
     ;;
   worktree.layout)
     cat <<'OOSH_HEAL_ARM'
w="$B/testing"
if [ -f "$w/.git" ]; then say "already: $w is a linked worktree"; exit 0; fi
[ -d "$B/main/.git" ] || fail "no $B/main to hang a worktree on"
[ -e "$w" ] && rm -rf "$w"
rgit -C "$B/main" worktree add -f -B testing "$w" HEAD >/dev/null 2>&1 || fail "worktree add $w"
say "$w is a linked worktree of $B/main on branch testing"
OOSH_HEAL_ARM
     ;;
   missing.branch)
     cat <<'OOSH_HEAL_ARM'
if [ -e "$D" ] || [ -L "$D" ]; then rm -rf "$D"; say "$D removed"; else say "already: $D is missing"; fi
OOSH_HEAL_ARM
     ;;
   diverged)
     # a local commit origin lacks, and origin/<branch> one the folder lacks
     cat <<'OOSH_HEAL_ARM'
branch_dir_ensure
if rgit -C "$D" rev-parse -q --verify refs/heal-test/diverged >/dev/null; then say "already: $D has diverged"; exit 0; fi
rgit -C "$D" commit -q --allow-empty -m 'heal test: a local commit origin lacks' || fail "local commit"
up=$(rgit -C "$D" commit-tree 'HEAD~1^{tree}' -p HEAD~1 -m 'heal test: origin ahead') || fail "origin commit"
rgit -C "$D" update-ref "refs/remotes/origin/$H" "$up" && rgit -C "$D" update-ref refs/heal-test/diverged HEAD || fail "refs"
say "$D has a local commit origin lacks, origin/$H one $D lacks"
OOSH_HEAL_ARM
     ;;
   markers.committed)
     # the Mac's 6 Oct shape: conflict markers committed in this, log, oo and config
     cat <<'OOSH_HEAL_ARM'
branch_dir_ensure
if rgit -C "$D" grep -q -e '^>>>>>>> ' HEAD -- this log oo config 2>/dev/null; then say "already: markers are committed in $D"; exit 0; fi
for f in this log oo config; do
  [ -f "$D/$f" ] && printf '%s\n' '<<<<<<< HEAD' '# ours' '=======' '# theirs' '>>>>>>> origin/dev' >> "$D/$f"
done
rgit -C "$D" commit -q -m "Merge remote-tracking branch 'origin/dev' (heal test: conflict markers committed)" -- this log oo config || fail "commit of the markers"
say "conflict markers committed in $D: this log oo config"
OOSH_HEAL_ARM
     ;;
   merge.conflict)
     # a half-done merge: theirs is built with a temporary index, so no checkout moves the folder
     cat <<'OOSH_HEAL_ARM'
branch_dir_ensure
if [ -f "$D/.git/MERGE_HEAD" ]; then say "already: a merge is in progress in $D"; exit 0; fi
base=$(rgit -C "$D" rev-parse HEAD) || fail "HEAD of $D"
blob=$(printf 'theirs\n' | rgit -C "$D" hash-object -w --stdin) || fail "blob"
GIT_INDEX_FILE="$D/.git/heal-test.index"; export GIT_INDEX_FILE
rgit -C "$D" read-tree "$base" && rgit -C "$D" update-index --add --cacheinfo "100644,$blob,heal.conflict.txt" && tree=$(rgit -C "$D" write-tree)
ok=$?; unset GIT_INDEX_FILE; rm -f "$D/.git/heal-test.index"
[ "$ok" = 0 ] || fail "tree of theirs"
theirs=$(rgit -C "$D" commit-tree "$tree" -p "$base" -m 'heal test: theirs') || fail "commit of theirs"
printf 'ours\n' > "$D/heal.conflict.txt"
rgit -C "$D" add heal.conflict.txt && rgit -C "$D" commit -q -m 'heal test: ours' -- heal.conflict.txt || fail "commit of ours"
rgit -C "$D" merge --no-edit "$theirs" >/dev/null 2>&1
[ -f "$D/.git/MERGE_HEAD" ] || fail "the merge did not stop on its conflict"
say "$D is mid-merge: MERGE_HEAD set, markers in heal.conflict.txt"
OOSH_HEAL_ARM
     ;;
   dirty)
     cat <<'OOSH_HEAL_ARM'
branch_dir_ensure
if grep -qx '# heal test: an uncommitted change' "$D/os" 2>/dev/null; then say "already: $D/os is changed"
else echo '# heal test: an uncommitted change' >> "$D/os" || fail "$D/os"; say "$D/os changed, not committed"; fi
OOSH_HEAL_ARM
     ;;
   detached)
     cat <<'OOSH_HEAL_ARM'
branch_dir_ensure
if ! rgit -C "$D" symbolic-ref -q HEAD >/dev/null; then say "already: $D is on a detached HEAD"; exit 0; fi
rgit -C "$D" update-ref --no-deref HEAD "$(rgit -C "$D" rev-parse HEAD)" || fail "detach"
say "$D is on a detached HEAD"
OOSH_HEAL_ARM
     ;;
 esac
}


private.os.platform.root.script.run()     # <platform> <shell> <script> # run the text <script> as root in the platform container: base64 through ossh exec (the prelude, as test), decoded there and fed to sudo <shell> -s; stdout and stderr of the script pass through; rc of the script (ssh: 255) #
{
 # One transport for every script os platform.heal.test runs as root. The
 # script travels INSIDE the command line, base64-encoded: no quoting of its
 # text, and nothing depends on stdin reaching ssh through the ossh command.
 # test has NOPASSWD sudo in a platform container (private.os.platform.container.up).
 local platform="$1" shell="$2" script="$3" encoded
 if [ -z "$platform" ] || [ -z "$shell" ] || [ -z "$script" ]; then
   create.result 1 "private.os.platform.root.script.run requires <platform> <shell> <script>"
   error.log "$RESULT"
   return $(result)
 fi
 case "$shell" in
   sh|bash) ;;
   *) create.result 1 "private.os.platform.root.script.run: <shell> is sh or bash, not $shell"; error.log "$RESULT"; return $(result) ;;
 esac
 # raw: an encoding, no oosh method; one line, the remote base64 -d reads it
 encoded=$(printf '%s\n' "$script" | base64 | tr -d '\n')
 ossh exec "$platform" "echo $encoded | base64 -d | sudo $shell -s"
 local rc=$?
 create.result "$rc" "the script ran as root on $platform with rc $rc"
 return $rc
}


private.os.platform.heal.breakage.apply()     # <platform> <name> <?branch> # apply the breakage <name> in the platform container as root (private.os.platform.heal.breakage.script.get through private.os.platform.root.script.run); <branch> (default: the branch of this tree) names the canonical folder the folder arms break; rc of the arm, rc 1 for an unknown name #
{
 local platform="$1" name="$2" branch="$3" script
 if [ -z "$platform" ] || [ -z "$name" ]; then
   create.result 1 "private.os.platform.heal.breakage.apply requires <platform> <name>"
   error.log "$RESULT"
   return $(result)
 fi
 if [ -z "$branch" ]; then
   private.this.script.load ogit ogit.branch.get || return $(result)
   branch=$(ogit.branch.get "$OOSH_DIR")
 fi
 if ! script=$(private.os.platform.heal.breakage.script.get "$name" "$branch"); then
   create.result 1 "unknown breakage '$name' or no branch '$branch' — one of: $(private.os.platform.heal.breakage.names.get | tr '\n' ' ')"
   error.log "$RESULT"
   return $(result)
 fi
 console.log "breakage $name on $platform (canonical folder: $branch)"
 private.os.platform.root.script.run "$platform" sh "$script"
 local rc=$?
 create.result "$rc" "breakage $name on $platform: rc $rc"
 return $rc
}


private.os.platform.ref.branch.ensure()     # <ref> <?dir:$OOSH_DIR> # RESULT = the branch a platform container clones for <ref>: <ref> itself when it is a branch on origin (fetched once on a miss), else, for a commit sha of <dir>, the temporary branch platform-test/<sha>, pushed to origin at that commit (ogit.remote.push); rc 1 when <ref> is neither #
{
 # RESULT, not an echo: a log line (LOG_DEVICE may be /dev/stdout) would
 # end up in a $(...) that captured the name. The container
 # clones a BRANCH (init/oosh: git clone -b), and ossh install refuses
 # anything origin does not list (private.ossh.origin.branch.check), so a
 # sha travels as platform-test/<sha>; private.os.platform.ref.branch.drop
 # deletes it afterwards.
 local ref="$1" dir="${2:-$OOSH_DIR}" branch
 if [ -z "$ref" ] || [ "${ref#-}" != "$ref" ]; then
   create.result 1 "private.os.platform.ref.branch.ensure requires <ref> (no leading -): [$ref]"
   error.log "$RESULT"
   return $(result)
 fi
 private.this.script.load ogit ogit.branch.check || return $(result)
 private.this.script.load ogit ogit.remote.fetch || return $(result)
 private.this.script.load ogit ogit.remote.push || return $(result)
 if ogit.branch.check "refs/remotes/origin/$ref" "$dir" \
    || { ogit.remote.fetch no "$dir" >/dev/null 2>&1 && ogit.branch.check "refs/remotes/origin/$ref" "$dir"; }; then
   create.result 0 "$ref"
   return $(result)
 fi
 case "$ref" in
   *[!0-9a-f]*) ;;
   *)
     if [ "${#ref}" -ge 7 ] && [ "${#ref}" -le 40 ] && ogit.branch.check "$ref^{commit}" "$dir"; then
       branch="platform-test/$ref"
       # ogit.remote.push hands <branch> to git push as the refspec: <sha>:refs/heads/<branch>
       # makes the remote branch at the commit without a local branch — ogit.branch.reset,
       # the method that makes one, checks it out, which would move this tree.
       if ogit.remote.push "$ref:refs/heads/$branch" no "$dir" >/dev/null; then
         important.log "temporary branch $branch pushed to origin at $ref"
         create.result 0 "$branch"
         return $(result)
       fi
       create.result 1 "could not push the temporary branch $branch: $RESULT"
       error.log "$RESULT"
       return $(result)
     fi ;;
 esac
 create.result 1 "<ref> $ref is no branch on origin (fetched once) and no commit sha of $dir"
 error.log "$RESULT"
 return $(result)
}


private.os.platform.ref.branch.drop()     # <branch> <?dir:$OOSH_DIR> # delete the temporary branch <branch> on origin (ogit.remote.branch.delete) when it is a platform-test/* branch; any other branch is left alone with rc 0; rc 1 when origin refuses #
{
 local branch="$1" dir="${2:-$OOSH_DIR}"
 if [ -z "$branch" ]; then
   create.result 1 "private.os.platform.ref.branch.drop requires <branch>"
   error.log "$RESULT"
   return $(result)
 fi
 case "$branch" in
   platform-test/?*) ;;
   *) create.result 0 "$branch is no temporary branch of the platform test — left alone"; return $(result) ;;
 esac
 private.this.script.load ogit ogit.remote.branch.delete || return $(result)
 if ogit.remote.branch.delete "$branch" origin "$dir"; then
   create.result 0 "temporary branch $branch deleted on origin"
   important.log "$RESULT"
 else
   create.result 1 "temporary branch $branch stays on origin: $RESULT — delete it: ogit remote.branch.delete $branch"
   error.log "$RESULT"
 fi
 return $(result)
}


private.os.platform.user.run()     # <platform> <user> <command> <log> # run <command> as <user> (test, root, oosh-user or bash-user) in the platform container through the transport that fits the user (ossh exec / sudo bash -lc / runuser or sudo -H -u), from the user's home with the prelude of ossh.remote.prelude.get, tee into <log>; rc is the rc of <command> #
{
 local platform="$1" user="$2" command="$3" log="$4" prelude="" rc
 if [ -z "$platform" ] || [ -z "$user" ] || [ -z "$command" ] || [ -z "$log" ]; then
   create.result 1 "private.os.platform.user.run requires <platform> <user> <command> <log>"
   error.log "$RESULT"
   return $(result)
 fi
 case "$user" in test|root|oosh-user|bash-user) ;; *)
   create.result 1 "private.os.platform.user.run: unknown <user> $user (test, root, oosh-user or bash-user)"
   error.log "$RESULT"
   return $(result) ;;
 esac
 # <command> goes inside the single quotes of bash -lc / bash -c below.
 case "$command" in *"'"*)
   create.result 1 "private.os.platform.user.run: <command> must not hold a single quote: $command"
   error.log "$RESULT"
   return $(result) ;;
 esac

 # root, oosh-user and bash-user arrive through sudo/runuser, which run no
 # .bashrc: the prelude stands their shell up from their own
 # ~/config/user.env (ossh.remote.prelude.get).
 if [ "$user" != test ]; then
   private.this.script.load ossh ossh.remote.prelude.get || { create.result 1 "ossh.remote.prelude.get could not be loaded"; return $(result); }
   prelude=$(ossh.remote.prelude.get)
 fi

 if [ "$user" = test ]; then
   ossh exec "$platform" "$command" 2>&1 | tee "$log"
   rc=${PIPESTATUS[0]}
 elif [ "$user" = root ]; then
   # root (via test+sudo, needs -tt for TTY)
   # `cd ~` (root) first: ssh starts bash with cwd=/home/test (the ssh
   # user's home). Same find-chdir-back hazard the runuser cases below
   # describe — except for root, the direct `find` calls work because
   # root reads anything; the failure mode is subprocesses (e.g. man-db's
   # postinst, which drops to user `man`) inheriting /home/test as cwd.
   ossh exec.tty "$platform" "sudo bash -lc 'cd /root 2>/dev/null || cd /tmp; $prelude $command'" 2>&1 | tee "$log"
   rc=${PIPESTATUS[0]}
 else
   # oosh-user / bash-user (via test+sudo+runuser; login-shell equivalent of `user login <user>`).
   # Explicit source + PATH export mirrors the root case above: bashrcTemplate's
   # early-exit for non-interactive shells would otherwise skip the PATH / user.env
   # setup and `test.suite: command not found` fires.
   # `cd ~` first: ssh starts the bash with cwd=/home/test (the ssh user's
   # home, mode 700 owned by test). After `runuser -u <user>`, the new
   # user can't read /home/test, so any `find` invocation in test.suite
   # (e.g. state.machine.exists in state) emits hundreds of
   # `find: Failed to restore initial working directory: /home/test:
   # Permission denied` lines on stderr. cd'ing to the new user's own
   # home keeps find happy.
   # `runuser` is shadow-utils on Debian/RHEL/Alma but missing on Alpine
   # (busybox doesn't ship it). Use a runtime detector that prefers
   # runuser (less PAM friction) and falls back to `sudo -H -u`. Both
   # give us "switch to <user>, reset HOME" semantics under the
   # NOPASSWD sudoers entry installed in Phase A.
   ossh exec.tty "$platform" "
     if command -v runuser >/dev/null 2>&1; then
       sudo runuser -u $user -- bash -c 'cd ~ 2>/dev/null || cd /tmp; $prelude $command'
     else
       sudo -H -u $user bash -c 'cd ~ 2>/dev/null || cd /tmp; $prelude $command'
     fi
   " 2>&1 | tee "$log"
   rc=${PIPESTATUS[0]}
 fi
 create.result "$rc" "$command as $user on $platform ended with rc $rc (log: $log)"
 return $rc
}


private.os.platform.heal.log.get()     # <step> <platform> # echo the log file of a step of os platform.heal.test in <platform> (/tmp/oosh-heal-test-<step>-<platform>.log); <step> is a user (test, root, oosh-user, bash-user) or breakages, heal, pipe, idempotence-root, idempotence-bash-user, second-heal, foreign; silent getter #
{
 # NO create.result — a getter consumed as $(...): SILENT BY CONTRACT.
 # The sibling of private.os.platform.gate.log.get, one place for the names.
 [ -n "$1" ] && [ -n "$2" ] || return 1
 case "$1$2" in *[!A-Za-z0-9._-]*) return 1 ;; esac
 echo "/tmp/oosh-heal-test-$1-$2.log"
}


private.os.platform.heal.snapshot.get()     # <platform> <branch> # echo, as root in the platform container, a snapshot of what oo heal owns: test.platform.shared.idempotence.snapshot (sourced from <base>/<branch>) of the entries of <base>, of <base>/main and <base>/<branch> (not .git), the sharedConfig env files, the launcher, the retired drop-in, and in the homes of test, root, oosh-user, bash-user and developking: oosh, config, the .bashrc files, .gitconfig, *.orig.*, .config/oosh (no log files) and .once; plus the HEAD of main and <branch>; rc 1 when it cannot be read #
{
 # Echoes the snapshot lines only: called as $(...). The remote prints a
 # begin line first, and only what follows it is kept — a host that prints
 # noise on login (a .bashrc echoing under sshd) adds nothing to the
 # snapshot. bash, not sh: the helpers of the idempotence invariant have
 # dotted names. Log files are left out as the invariant leaves them out
 # (log.live.out, *.log): every oosh run appends to them.
 local platform="$1" branch="$2" preamble script out
 if [ -z "$platform" ] || [ -z "$branch" ]; then
   error.log "private.os.platform.heal.snapshot.get requires <platform> <branch>"
   return 1
 fi
 preamble=$(private.os.platform.heal.remote.preamble.get "$branch") || { error.log "bad <branch> $branch"; return 1; }
 script="$preamble
$(cat <<'OOSH_HEAL_SNAPSHOT'
TEST_PLATFORM_IDEMPOTENCE_HELPERS_ONLY=1 . "$D/test/test.platform.shared.idempotence.invariant" || fail "no snapshot helpers in $D"
set -- "$B" "$B/main/*" "$D/*" "$S/*.env" /usr/local/bin/this /etc/profile.d/oosh.sh /etc/oosh/boot
for u in test root oosh-user bash-user developking; do
  h=$(home_of "$u"); [ -n "$h" ] || continue
  set -- "$@" "$h/oosh" "$h/config" "$h/.bashrc" "$h/.bashrc*" "$h/.gitconfig" "$h/*.orig.*" "$h/.config/oosh" "$h/.once"
done
echo OOSH_HEAL_SNAPSHOT_BEGIN
test.platform.shared.idempotence.snapshot "$@" | awk -F '\t' '$1 !~ /\/log\.live\.out$/ && $1 !~ /\.log$/'
for d in "$B/main" "$D"; do printf 'HEAD of %s\t%s\t-\n' "$d" "$(rgit -C "$d" rev-parse HEAD 2>/dev/null || echo none)"; done
OOSH_HEAL_SNAPSHOT
)"
 out=$(private.os.platform.root.script.run "$platform" bash "$script") || { error.log "no snapshot of $platform: $out"; return 1; }
 printf '%s\n' "$out" | tr -d '\r' | sed -n '/^OOSH_HEAL_SNAPSHOT_BEGIN$/,$p' | sed '1d'
}


private.os.platform.heal.second.run()     # <platform> <branch> # the second heal: a snapshot (private.os.platform.heal.snapshot.get), oo heal <branch> all as root (private.os.platform.user.run, log second-heal), a snapshot again; rc 0 when the heal ends with rc 0 and the snapshots are the same (test.platform.shared.idempotence.compare), else rc 1 with every difference printed #
{
 local platform="$1" branch="$2" log work rcHeal differences
 if [ -z "$platform" ] || [ -z "$branch" ]; then
   create.result 1 "private.os.platform.heal.second.run requires <platform> <branch>"
   error.log "$RESULT"
   return $(result)
 fi
 log=$(private.os.platform.heal.log.get second-heal "$platform")
 work=$(private.this.temp.dir.get oosh-heal-second) || { create.result 1 "no temp dir"; error.log "$RESULT"; return $(result); }
 if ! private.os.platform.heal.snapshot.get "$platform" "$branch" > "$work/before" || [ ! -s "$work/before" ]; then
   rm -rf "$work"
   create.result 1 "second heal on $platform: no snapshot before it"
   error.log "$RESULT"
   return $(result)
 fi
 # A rewrite within the same second keeps the mtime (as the invariant waits).
 sleep 1
 console.log "second heal: oo heal $branch all as root on $platform — it must change nothing"
 private.os.platform.user.run "$platform" root "oo heal $branch all" "$log"
 rcHeal=$?
 private.os.platform.heal.snapshot.get "$platform" "$branch" > "$work/after"
 # The compare helper of the idempotence invariant, sourced alone (its POSIX
 # helpers only) in a subshell: the file also sets globals of a test run
 # (TEST_CATEGORY, TEST_SHARED_TIER_WRITER), which must not reach this shell.
 if differences=$(TEST_PLATFORM_IDEMPOTENCE_HELPERS_ONLY=1
       . "$OOSH_DIR/test/test.platform.shared.idempotence.invariant" || { echo "no idempotence helpers in $OOSH_DIR/test"; exit 1; }
       test.platform.shared.idempotence.compare "$work/before" "$work/after") && [ "$rcHeal" = 0 ]; then
   create.result 0 "second heal on $platform: rc 0, nothing changed"
 else
   create.result 1 "second heal on $platform: rc $rcHeal${differences:+, it changed:
$differences}"
   error.log "$RESULT"
   printf '%s\n' "$RESULT" >> "$log"
 fi
 rm -rf "$work"
 return $(result)
}


private.os.platform.heal.foreign.check()     # <platform> # rc 0 when /opt/foreign in the platform container is as the breakage foreign.symlink recorded it: the same entries and file checksums (/opt/foreign.heal.sums) and nothing in it newer than /opt/foreign.heal.marker; prints every difference; rc 1 otherwise, also when nothing was recorded #
{
 local platform="$1" preamble script
 if [ -z "$platform" ]; then
   create.result 1 "private.os.platform.heal.foreign.check requires <platform>"
   error.log "$RESULT"
   return $(result)
 fi
 # The preamble for foreign_sums and say/fail; its branch plays no part here.
 preamble=$(private.os.platform.heal.remote.preamble.get main)
 script="N=foreign.check
$preamble
$(cat <<'OOSH_HEAL_FOREIGN'
[ -f /opt/foreign.heal.sums ] && [ -f /opt/foreign.heal.marker ] || fail "nothing recorded — the breakage foreign.symlink was not applied"
now=$(foreign_sums)
rc=0
if [ "$now" != "$(cat /opt/foreign.heal.sums)" ]; then
  printf '%s\n' "$now" | awk 'NR == FNR { was[$0] = 1; next } !($0 in was) { print "foreign changed: now " $0 }' /opt/foreign.heal.sums -
  printf '%s\n' "$now" | awk 'NR == FNR { now[$0] = 1; next } !($0 in now) { print "foreign changed: was " $0 }' - /opt/foreign.heal.sums
  rc=1
fi
newer=$(find /opt/foreign -newer /opt/foreign.heal.marker)
if [ -n "$newer" ]; then printf 'foreign written after the breakage: %s\n' $newer; rc=1; fi
[ "$rc" = 0 ] && say "/opt/foreign is byte-identical, nothing in it is newer than its marker"
exit "$rc"
OOSH_HEAL_FOREIGN
)"
 private.os.platform.root.script.run "$platform" sh "$script"
 local rc=$?
 create.result "$rc" "foreign check on $platform: rc $rc"
 return $rc
}


private.os.platform.heal.pipe.run()     # <platform> <branch> # the pure pipe form once, as the user test: this tree's init/oosh and a bundle of <branch> go to temp files on the platform (private.ossh.heal.push, private.ossh.heal.bundle.push), then cat <init> | env OOSH_REPO=<bundle> sh -s -- heal <branch> through ossh exec.tty, tee into the log of step pipe; the temp files are removed; rc of the heal #
{
 # ossh heal runs `sh <file> heal …` — the arm from a FILE. The curl form a
 # user types reads the script from STDIN (`curl … | sh -s -- heal`), where
 # stdin IS the script; this runs that form for real, once.
 local platform="$1" branch="$2" log init bundle rc
 if [ -z "$platform" ] || [ -z "$branch" ]; then
   create.result 1 "private.os.platform.heal.pipe.run requires <platform> <branch>"
   error.log "$RESULT"
   return $(result)
 fi
 private.this.script.load ossh private.ossh.heal.push || return $(result)
 log=$(private.os.platform.heal.log.get pipe "$platform")
 private.ossh.heal.push "$platform" || return $(result)
 init="$RESULT"
 if ! private.ossh.heal.bundle.push "$platform" "$branch"; then
   ossh exec "$platform" "rm -f '$init'"
   return $(result)
 fi
 bundle="$RESULT"
 console.log "pipe form: cat $init | sh -s -- heal $branch as test on $platform"
 ossh exec.tty "$platform" "cat '$init' | env OOSH_REPO='$bundle' sh -s -- heal $branch" 2>&1 | tee "$log"
 rc=${PIPESTATUS[0]}
 ossh exec "$platform" "rm -f '$init' '$bundle'" \
   || warn.log "pipe form: could not remove $init $bundle on $platform"
 create.result "$rc" "pipe form heal on $platform: rc $rc (log: $log)"
 return $rc
}


os.platform.heal.test()     # <platform> <oldRef> <?breakages...:all> # install <oldRef> (a branch on origin, or a sha shipped as platform-test/<sha>) for test, root, oosh-user and bash-user in a fresh <platform> container, apply the named breakages (default: all), heal once as root through the curl form, then test.suite gate 1 per user, the idempotence invariant, a second heal that must change nothing, and the untouched-foreign check; PASS/FAIL line + create.result like platform.test; the words terminal (keep the container) and pipe (run the pure pipe form too) may stand among the breakages #
{
 # The proof the heal needs before it touches a real machine: an OLD install,
 # broken the ways the real machines are broken, healed ONCE, then everything
 # that checks an install. Built from the blocks of os platform.test
 # (private.os.platform.parse, container.up, users.install, gate.run,
 # shared.config.repair, cleanup). The heal is THIS tree: ossh heal with
 # OOSH_HEAL_LOCAL=1 pushes this tree's init/oosh and a bundle of its branch.
 # The first heal's rc 1 is no failure: it moves broken canonical folders
 # aside and says so (private.oo.heal.code); rc 2 (cannot heal) or an ssh
 # failure is. Docker port 8022, as os platform.test.
 local platform="$1" oldRef="$2"
 if [ -z "$platform" ] || [ -z "$oldRef" ]; then
   create.result 1 "Usage: os platform.heal.test <platform> <oldRef> <?breakages...:all> — words terminal and pipe may stand among the breakages"
   error.log "$RESULT"
   return $(result)
 fi
 shift 2
 local word terminal="" pipe="" words=()
 for word in "$@"; do
   case "$word" in
     terminal) terminal=yes ;;
     pipe)     pipe=yes ;;
     *)        words+=("$word") ;;
   esac
 done
 private.os.platform.heal.breakage.list.get "${words[@]}" || return $(result)
 local breakages="$RESULT"

 private.os.platform.parse "$platform" || return $(result)
 if [ "$PLATFORM_WORKSPACE" = native ]; then
   create.result 1 "$platform is a native platform — the heal scenario needs a disposable Docker container"
   error.log "$RESULT"
   return $(result)
 fi
 private.this.script.load ogit ogit.branch.get || return $(result)
 local healBranch
 healBranch=$(ogit.branch.get "$OOSH_DIR")
 if [ -z "$healBranch" ]; then
   create.result 1 "$OOSH_DIR is on a detached HEAD — the heal ships a bundle of a branch of this tree"
   error.log "$RESULT"
   return $(result)
 fi

 # The ref the container clones: a branch on origin, or platform-test/<sha>.
 private.os.platform.ref.branch.ensure "$oldRef" || return $(result)
 local branch="$RESULT"
 # Era gate: an era-B ref (mode ssh) is refused with the eraB.* hint.
 if ! private.os.platform.branch.gate "$branch"; then
   local refusal="$RESULT"
   private.os.platform.ref.branch.drop "$branch"
   create.result 1 "$refusal"
   return $(result)
 fi

 local imageTag sshPort=8022 rc step logs=""
 imageTag=$(private.os.platform.image.from.workspace "$PLATFORM_WORKSPACE")
 # The logs of every step, emptied first: a step that does not run this time
 # (pipe) must not show the FAIL lines of an earlier run.
 for step in breakages heal pipe test root oosh-user bash-user idempotence-root idempotence-bash-user second-heal foreign; do
   logs="$logs $(private.os.platform.heal.log.get "$step" "$platform")"
 done
 # shellcheck disable=SC2086 # the log paths have no spaces
 rm -f $logs
 if ! OSSH_INSTALL_BRANCH="$branch" private.os.platform.container.up "$platform" "$imageTag" "$sshPort"; then
   private.os.platform.ref.branch.drop "$branch"
   private.os.platform.cleanup "$sshPort"
   printf "FAIL: heal %s %s (the container did not come up)\n" "$platform" "$oldRef"
   create.result 1 "FAIL: heal $platform $oldRef — the container did not come up"
   error.log "$RESULT"
   return $(result)
 fi
 OSSH_INSTALL_BRANCH="$branch" private.os.platform.users.install "$platform"

 # ─── the breakages, in the order of private.os.platform.heal.breakage.names.get ─
 local name rcBreak=0 breakLog healLog
 breakLog=$(private.os.platform.heal.log.get breakages "$platform")
 for name in $breakages; do
   private.os.platform.heal.breakage.apply "$platform" "$name" "$healBranch" 2>&1 | tee -a "$breakLog"
   [ "${PIPESTATUS[0]}" = 0 ] || rcBreak=1
 done

 # ─── ONE heal as root, the curl form over ssh (ossh heal → sh <init> heal <branch> all) ─
 local rcHeal rcPipe=""
 healLog=$(private.os.platform.heal.log.get heal "$platform")
 OOSH_HEAL_LOCAL=1 ossh heal "$platform" all "$healBranch" 2>&1 | tee "$healLog"
 rcHeal=${PIPESTATUS[0]}
 # pipe: the pure pipe form as test, once (C2 runs it on the first platform)
 if [ -n "$pipe" ]; then
   private.os.platform.heal.pipe.run "$platform" "$healBranch"
   rcPipe=$?
 fi

 # ─── test.suite gate 1 per user, as os platform.test runs it ─────────────
 local rcTest rcRoot rcOoshUser rcBashUser
 private.os.platform.gate.run "$platform" test "$(private.os.platform.heal.log.get test "$platform")"
 rcTest=$?
 private.os.platform.gate.run "$platform" root "$(private.os.platform.heal.log.get root "$platform")"
 rcRoot=$?
 # root's test.suite leaves root-owned files in sharedConfig (os.platform.test)
 private.os.platform.shared.config.repair "$platform"
 private.os.platform.gate.run "$platform" oosh-user "$(private.os.platform.heal.log.get oosh-user "$platform")"
 rcOoshUser=$?
 private.os.platform.gate.run "$platform" bash-user "$(private.os.platform.heal.log.get bash-user "$platform")"
 rcBashUser=$?

 # ─── the idempotence invariant as root and as bash-user ──────────────────
 local rcIdem=0
 private.os.platform.user.run "$platform" root "test.suite run platform.shared.idempotence.invariant 1" \
   "$(private.os.platform.heal.log.get idempotence-root "$platform")" || rcIdem=1
 private.os.platform.shared.config.repair "$platform"
 private.os.platform.user.run "$platform" bash-user "test.suite run platform.shared.idempotence.invariant 1" \
   "$(private.os.platform.heal.log.get idempotence-bash-user "$platform")" || rcIdem=1

 # ─── a second heal that changes nothing, and the foreign tree untouched ──
 local rcSecond rcForeign="skipped" foreignLog
 private.os.platform.heal.second.run "$platform" "$healBranch"
 rcSecond=$?
 case " $breakages " in
   *" foreign.symlink "*)
     foreignLog=$(private.os.platform.heal.log.get foreign "$platform")
     private.os.platform.heal.foreign.check "$platform" 2>&1 | tee "$foreignLog"
     rcForeign=${PIPESTATUS[0]} ;;
 esac

 # ─── the verdict ──────────────────────────────────────────────────────────
 local line="breakages=$rcBreak heal=$rcHeal${rcPipe:+ pipe=$rcPipe} test=$rcTest root=$rcRoot oosh-user=$rcOoshUser bash-user=$rcBashUser idempotence=$rcIdem second-heal=$rcSecond foreign=$rcForeign"
 if [ "$rcBreak" = 0 ] && [ "$rcHeal" -le 1 ] && [ "${rcPipe:-0}" = 0 ] && [ "$rcTest" = 0 ] && [ "$rcRoot" = 0 ] \
    && [ "$rcOoshUser" = 0 ] && [ "$rcBashUser" = 0 ] && [ "$rcIdem" = 0 ] && [ "$rcSecond" = 0 ] \
    && { [ "$rcForeign" = 0 ] || [ "$rcForeign" = skipped ]; }; then
   printf "PASS: heal %s %s (%s)\n" "$platform" "$oldRef" "$line"
   important.log "PASS: heal $platform $oldRef ($line)"
   create.result 0 "PASS"
   # shellcheck disable=SC2086 # the log paths have no spaces
   rm -f $logs
   rc=0
 else
   printf "FAIL: heal %s %s (%s)\n" "$platform" "$oldRef" "$line"
   error.log "FAIL: heal $platform $oldRef ($line)"
   local l
   for l in $logs; do
     [ -s "$l" ] || continue
     grep -qi "FAIL\|✗" "$l" 2>/dev/null || continue
     error.log "--- first FAIL lines of $l ---"
     grep -i -m 10 "FAIL\|✗" "$l"
   done
   create.result 1 "FAIL"
   rc=1
 fi

 private.os.platform.ref.branch.drop "$branch"
 # terminal: the container stays for a look inside (C2 debugging); else it goes.
 if [ -n "$terminal" ]; then
   console.log "terminal: the container of $platform stays on port $sshPort — enter it: ossh exec.tty $platform 'sudo -i'; remove it: docker rm -f \$(docker ps -q --filter publish=$sshPort)"
 else
   ossh connection.close "$platform" 2>/dev/null
   private.os.platform.cleanup "$sshPort"
 fi
 create.result "$rc" "$([ "$rc" = 0 ] && echo PASS || echo FAIL)"
 return $rc
}
os.platform.heal.test.completion.platform() {
  private.os.platform.names
}
os.platform.heal.test.completion.oldRef() {
  # the remote branches; a sha is typed
  private.this.script.load ogit ogit.branch.list && ogit.branch.list remote
}
os.platform.heal.test.completion.breakages() {
  echo all
  private.os.platform.heal.breakage.names.get
  echo terminal
  echo pipe
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
    create.result 1 "Unknown platform: $platform"
    error.log "$RESULT"
    return $(result)
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

os.platform.test()     # <platform> <?terminal> <?notests> <?branch> # tests oosh installation on a single platform; <branch> (a branch on origin of this repo, installer contract mode root i.e. b8b90b82 or newer; a sha or a local-only branch is refused by the gate, the scenario test os platform.heal.test ships a sha as platform-test/<sha>) is exported as OSSH_INSTALL_BRANCH to the two ossh install calls, so an older ref can be installed first (ossh honours it: package B4) #
{
 local platform="$1"
 if [ -z "$platform" ]; then
  create.result 1 "Usage: os platform.test <platform> <?terminal> <?notests> <?branch>"
  error.log "$RESULT"
  return $(result)
 fi
 shift
 # positional: an empty placeholder ("") for <terminal> or <notests> must still
 # move on to the next parameter, so <branch> can be given without them
 local terminal="$1"
 if [ $# -gt 0 ]; then shift; fi
 local notests="$1"
 if [ $# -gt 0 ]; then shift; fi
 local branch="$1"
 if [ $# -gt 0 ]; then shift; fi

 private.os.platform.parse "$platform" || return $(result)

 if [ "$PLATFORM_WORKSPACE" = "native" ]; then
  if [ "$platform" = "macos" ]; then
   if [ -n "$branch" ]; then
    create.result 1 "<branch> $branch cannot be installed first on macos: the CI workflow installs its own branch"
    error.log "$RESULT"
    return $(result)
   fi
   private.os.platform.test.ci "$platform" "$terminal" "$notests"
   return $?
  fi
  console.log "SKIP: $platform is a native platform (no Docker test)"
  create.result 1 "SKIP"
  return $(result)
 fi

 # Era gate, before anything starts: the ref must carry the mode root installer contract
 if [ -n "$branch" ]; then
  private.os.platform.branch.gate "$branch" || return $(result)
 fi

 local imageTag sshPort rc
 imageTag=$(private.os.platform.image.from.workspace "$PLATFORM_WORKSPACE")
 sshPort=8022

 # <branch> reaches ossh install (container.up installs test, users.install bash-user)
 # as OSSH_INSTALL_BRANCH: a prefix assignment lives for that one call only.
 if [ -n "$branch" ]; then
  OSSH_INSTALL_BRANCH="$branch" private.os.platform.container.up "$platform" "$imageTag" "$sshPort" || return $(result)
 else
  private.os.platform.container.up "$platform" "$imageTag" "$sshPort" || return $(result)
 fi

 # ─── PHASE A: install all 4 users (no tests yet) ────────────────────────
 # Covers every install path we support in one run:
 #   test      — initial `ossh install <platform> test` (caller-side + user.oosh.install)
 #   root      — sudo re-exec during the above state-machine install
 #   oosh-user — `user create oosh-user password oosh-user` from test session
 #               (oosh-native user creation; user.create calls user.oosh.install internally)
 #   bash-user — raw `useradd` on remote, then `ossh install <platform> bash-user`
 #               (caller-initiated install for a pre-existing account)
 if [ -n "$branch" ]; then
  OSSH_INSTALL_BRANCH="$branch" private.os.platform.users.install "$platform"
 else
  private.os.platform.users.install "$platform"
 fi

 # ─── PHASE B: run test.suite gate 1 (core + platform invariant) on all 4 users ─
 local rcTest=0 rcRoot=0 rcOoshUser=0 rcBashUser=0
 local testLog="" rootLog="" ooshUserLog="" bashUserLog=""

 if [ -z "$notests" ]; then
  testLog=$(private.os.platform.gate.log.get test "$platform")
  private.os.platform.gate.run "$platform" test
  rcTest=$?

  rootLog=$(private.os.platform.gate.log.get root "$platform")
  private.os.platform.gate.run "$platform" root
  rcRoot=$?

  # Root's test.suite writes into sharedConfig (via /root/config symlink)
  # with root:root ownership, blocking the unprivileged users that come
  # next. Repair group+perms + setgid so oosh-user and bash-user can write.
  private.os.platform.shared.config.repair "$platform"

  ooshUserLog=$(private.os.platform.gate.log.get oosh-user "$platform")
  private.os.platform.gate.run "$platform" oosh-user
  rcOoshUser=$?

  bashUserLog=$(private.os.platform.gate.log.get bash-user "$platform")
  private.os.platform.gate.run "$platform" bash-user
  rcBashUser=$?
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

os.platform.test.completion.branch() {
  private.this.script.load ogit ogit.branch.list && ogit.branch.list remote
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
  # ~/config symlink (set up by user.oosh.install).
  # chgrp+chmod+setgid recover the dev-group-writable invariant; setgid
  # on dirs causes new files to inherit the dev group ownership, so
  # this doesn't have to run between every step — once after root is
  # enough.
  ossh exec.tty "$platform" "sudo bash -c '
    shared=\$(readlink -f /root/config 2>/dev/null)
    if [ -n \"\$shared\" ] && [ -d \"\$shared\" ]; then
      chgrp -R dev \"\$shared\" 2>/dev/null # recursive-exception: ephemeral platform container, the shared tree it created
      chmod -R g+rw \"\$shared\" 2>/dev/null # recursive-exception: ephemeral platform container, the shared tree it created
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
        # downstream consumers; mirrors the linux* case in private.check.root.installation.done (oo).
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

