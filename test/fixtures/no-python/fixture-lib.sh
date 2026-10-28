#!/usr/bin/env bash
# no-python burn-down — SHARED fixture builder (sourced by record-goldens.sh AND by any parity test).
# Everything is DETERMINISTIC: fixed uuids, fixed content, fixed ABSOLUTE mtimes (all far in the past,
# so time-relative branches resolve the same way on every run — e.g. roles.list.uuids => 'orphan').
#
#   np.build.projects <sbx>   ~/.claude/projects tree + sandbox registry under <sbx>
#   np.plant.panes    <sbx>   tmux session fxnpg (4 panes) running a fake `claude`; prints nothing
#   np.sweep                  kill fixture sessions (idempotent)
#
# PATH RULE: build <sbx> under the TREE's own test/gen, never under a path containing a session uuid
# (several sites regex a uuid out of `ps` args that contain "claude" — a uuid in the fake binary's
# path would leak into their detection and make goldens depend on who recorded them).

NP_SESS=fxnpg
NP_UUID_A=11111111-aaaa-4aaa-8aaa-000000000001   # fxnp-alpha  customTitle, peak 300k, last nz 250k, zero stub
NP_UUID_B=11111111-aaaa-4aaa-8aaa-000000000002   # fxnp-beta   customTitle, ZERO-only usage
NP_UUID_C=11111111-aaaa-4aaa-8aaa-000000000003   # agentName fxnp-beta@, nz 90k,  older
NP_UUID_D=11111111-aaaa-4aaa-8aaa-000000000004   # agentName fxnp-beta@, nz 120k, newer  <- expected pick
NP_UUID_E=11111111-aaaa-4aaa-8aaa-000000000005   # agentName fxnp-beta@, ZERO-only, newest (must be skipped)

np.A(){ printf '{"type":"assistant","message":{"usage":{"input_tokens":%s,"cache_creation_input_tokens":%s,"cache_read_input_tokens":%s,"cache_creation":{"ephemeral_5m_input_tokens":0,"ephemeral_1h_input_tokens":%s}}},"timestamp":"%s"%s}\n' "$1" "$2" "$3" "$2" "$4" "${5:+,\"agentName\":\"$5\"}"; }
np.title(){ printf '{"type":"custom-title","customTitle":"%s","sessionId":"%s"}\n' "$1" "$2"; }
np.tool(){ printf '{"type":"assistant","message":{"content":[{"type":"tool_use","id":"tu%s","name":"Bash"}]},"timestamp":"2026-01-01T00:00:0%s.000Z"}\n' "$1" "$1"; }
np.pad(){ local n="$1" i=0; while [ "$i" -lt "$n" ]; do printf '{"type":"user","message":{"role":"user","content":"%0120d"}}\n' "$i"; i=$((i+1)); done; }
np.mtime(){ touch -d "$2" "$1"; }   # fixed absolute mtime

np.build.projects(){
  local sbx="$1" p="$1/.claude/projects/-fxnpg" ct="$1/.claude/projects/-fxct"
  mkdir -p "$p" "$ct" "$sbx/config"
  # ── context.live.jsonl / denom / from.jsonl.reading / roles.list.uuids ──
  { np.title 'fxnp-alpha@WODA.prod' "$NP_UUID_A"; np.A 1 1000 299000 2026-01-01T00:00:00Z; np.tool 1; np.tool 2
    np.A 1 0 249999 2026-01-01T00:05:00Z; np.A 0 0 0 2026-01-01T00:06:00Z; } > "$p/$NP_UUID_A.jsonl"
  { np.title 'fxnp-beta@WODA.prod' "$NP_UUID_B"; np.A 0 0 0 2026-01-02T00:00:00Z; } > "$p/$NP_UUID_B.jsonl"
  { np.A 1 0 89999 2026-01-03T00:00:00Z 'fxnp-beta@WODA.prod'; } > "$p/$NP_UUID_C.jsonl"
  { np.A 1 0 119999 2026-01-04T00:00:00Z 'fxnp-beta@WODA.prod'; } > "$p/$NP_UUID_D.jsonl"
  { np.A 0 0 0 2026-01-05T00:00:00Z 'fxnp-beta@WODA.prod'; } > "$p/$NP_UUID_E.jsonl"
  np.mtime "$p/$NP_UUID_A.jsonl" '2026-01-01 00:06:00 UTC'
  np.mtime "$p/$NP_UUID_B.jsonl" '2026-01-02 00:00:00 UTC'
  np.mtime "$p/$NP_UUID_C.jsonl" '2026-01-03 00:00:00 UTC'
  np.mtime "$p/$NP_UUID_D.jsonl" '2026-01-04 00:00:00 UTC'
  np.mtime "$p/$NP_UUID_E.jsonl" '2026-01-05 00:00:00 UTC'
  # ── fork.best picker: bare vs fallback-, >=50KB threshold, ±10% tie, tool counts ──
  # The picker reads customTitle ONLY from the LAST 64KB (measured: a head-title in a ~90KB file is
  # invisible) -> qualifying files carry the title LAST; 014 pins the invisible-head case on purpose.
  { np.tool 1; np.tool 2; np.pad 600; np.title 'fxnp-fork@WODA.prod' 22222222-bbbb-4bbb-8bbb-000000000011; } > "$p/22222222-bbbb-4bbb-8bbb-000000000011.jsonl"
  { np.tool 1; np.tool 2; np.tool 3; np.pad 580; np.title 'fallback-fxnp-fork@WODA.prod' 22222222-bbbb-4bbb-8bbb-000000000012; } > "$p/22222222-bbbb-4bbb-8bbb-000000000012.jsonl"
  { np.title 'fxnp-fork@WODA.prod' 22222222-bbbb-4bbb-8bbb-000000000014; np.pad 600; } > "$p/22222222-bbbb-4bbb-8bbb-000000000014.jsonl"
  np.mtime "$p/22222222-bbbb-4bbb-8bbb-000000000014.jsonl" '2026-02-07 00:00:00 UTC'
  { np.title 'fxnp-fork@WODA.prod' 22222222-bbbb-4bbb-8bbb-000000000013; np.pad 40; } > "$p/22222222-bbbb-4bbb-8bbb-000000000013.jsonl"
  { np.title 'fxnp-small@WODA.prod' 22222222-bbbb-4bbb-8bbb-000000000021; np.pad 10; } > "$p/22222222-bbbb-4bbb-8bbb-000000000021.jsonl"
  { np.title 'fxnp-small@WODA.prod' 22222222-bbbb-4bbb-8bbb-000000000022; np.pad 12; } > "$p/22222222-bbbb-4bbb-8bbb-000000000022.jsonl"
  np.mtime "$p/22222222-bbbb-4bbb-8bbb-000000000011.jsonl" '2026-02-01 00:00:00 UTC'
  np.mtime "$p/22222222-bbbb-4bbb-8bbb-000000000012.jsonl" '2026-02-03 00:00:00 UTC'
  np.mtime "$p/22222222-bbbb-4bbb-8bbb-000000000013.jsonl" '2026-02-05 00:00:00 UTC'
  np.mtime "$p/22222222-bbbb-4bbb-8bbb-000000000021.jsonl" '2026-03-01 00:00:00 UTC'
  np.mtime "$p/22222222-bbbb-4bbb-8bbb-000000000022.jsonl" '2026-03-02 00:00:00 UTC'
  # ── claudeCode.session.name (custom-title, claudeCode:1351) ──
  np.title 'fxct-plain@WODA.prod' 33333333-cccc-4ccc-8ccc-000000000031 > "$ct/33333333-cccc-4ccc-8ccc-000000000031.jsonl"
  printf '%s\n' '{"type":"custom-title","customTitle":"say \"hi\" \\ x","sessionId":"q"}' > "$ct/33333333-cccc-4ccc-8ccc-000000000032.jsonl"
  printf '%s\n' '{"type":"custom-title","customTitle":"café-agent","sessionId":"u"}' > "$ct/33333333-cccc-4ccc-8ccc-000000000033.jsonl"
  { np.title 'first-title' x; np.title 'second-title' x; } > "$ct/33333333-cccc-4ccc-8ccc-000000000034.jsonl"
  printf '%s\n' '{"type":"custom-title","customTitle":"","sessionId":"e"}' '{"type":"user","message":{"role":"user","content":"hello first prompt"}}' > "$ct/33333333-cccc-4ccc-8ccc-000000000035.jsonl"
  printf '%s\n' '{"type":"custom-title","customTitle":"slash\/and\ttab","sessionId":"s"}' > "$ct/33333333-cccc-4ccc-8ccc-000000000036.jsonl"
  # ── sandbox registry: only the fallback row the agentName path needs ──
  printf '%s\n' "${NP_SESS}:0.1|fxnp-beta|0" > "$sbx/config/hivemind.roles.env"
}

np.plant.panes(){
  local sbx="$1"
  mkdir -p "$sbx/bin" "$sbx/cwd"
  # A real BINARY named `claude` = a copy of bash (measured, each other way FAILS):
  #  - a '#!/bin/sh' script shows pane_current_command=sh, so claudeCode never treats it as Claude;
  #  - 'exec -a "claude --resume U"' folds the args into argv[0], so session.cmdline.uuid finds NO
  #    separate --resume arg (deployed identity is cmdline-first);
  #  - a copied `sleep` rejects the extra args.
  # bash copy + builtin-only wait (read -t: no child takes the pane foreground) => comm=claude AND
  # --resume <uuid> / --model x[1m] are REAL separate argv entries. The fixture path is under the
  # recorded tree's test/gen (no session uuid in it). NO exec: session.cmdline.uuid walks pane_pid DESCENDANTS only
  # (a real claude is a CHILD of the pane shell) — an exec'd claude IS pane_pid and is never matched.
  cp "$(command -v bash)" "$sbx/bin/claude"
  local W='while :; do read -r -t 86400 _ || :; done'
  tmux kill-session -t "$NP_SESS" 2>/dev/null
  tmux new-session -d -s "$NP_SESS" -x 120 -y 40 -c "$sbx/cwd"
  local i; for i in 1 2 3; do tmux split-window -t "$NP_SESS" -v -c "$sbx/cwd"; tmux select-layout -t "$NP_SESS" even-vertical; done
  tmux send-keys -t "$NP_SESS:0.0" "'$sbx/bin/claude' -c '$W' claude --resume $NP_UUID_A --model x" Enter
  tmux send-keys -t "$NP_SESS:0.1" "'$sbx/bin/claude' -c '$W' claude --model 'x[1m]'" Enter
  tmux send-keys -t "$NP_SESS:0.2" "'$sbx/bin/claude' -c '$W' claude --model x" Enter
  sleep 1.2
  tmux select-pane -t "$NP_SESS:0.0" -T 'fxnp-alpha@WODA.prod'
  tmux select-pane -t "$NP_SESS:0.1" -T 'fxnp-beta@WODA.prod'
  tmux select-pane -t "$NP_SESS:0.2" -T 'fxnp-gamma@WODA.prod'
  tmux select-pane -t "$NP_SESS:0.3" -T 'v60211.1blu.de'
  sleep 0.3
}

np.sweep(){ tmux kill-session -t "$NP_SESS" 2>/dev/null; return 0; }

# Ruling R1 (design §5a): P1 counts ONLY total>0 records, in EVERY mode. The CORRECT golden for a
# fixture = the old python run on that fixture with its zero-total assistant-usage records REMOVED
# (that is what "only total>0 counts" means) — derived mechanically, never hand-computed.
# Scope: the fixtures' own controlled shape (one compact object per line); not a general JSON tool.
np.strip.zero(){ # <jsonl> : print the fixture without assistant records whose usage total is 0
  awk '
    function num(k,   r) { r = 0; if (match($0, "\"" k "\": ?[0-9]+")) { r = substr($0, RSTART, RLENGTH); sub(/.*: ?/, "", r) } return r + 0 }
    /"type": ?"assistant"/ && /"usage": ?\{/ {
      if (num("input_tokens") + num("cache_creation_input_tokens") + num("cache_read_input_tokens") == 0) next
    }
    { print }' "$1"
}
