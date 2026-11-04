# T09 — `oo method.delete` / `replace block` cannot remove legacy `private.<verb>` names

- **Type:** tooling · **Priority:** P2 · **Area:** `oo`, `replace`
- **State:** open
- **Found by:** removing `private.isPaneTarget` / `private.isSessionName` (T04)

## Evidence

```
$ ./oo method.delete otmux.private.isPaneTarget
ERROR> oo.method.delete: otmux.private.isPaneTarget is not defined in …/otmux

$ ./oo method.delete private.isPaneTarget
ERROR> oo.method.delete: no method name in 'private.isPaneTarget'

$ ./replace block otmux "private.isPaneTarget() {" "}" by ""
(no change; the end anchor "}" is not unique)
```

- `private.oo.method.name.resolve` understands `private.<script>.<verb>` (script = second segment),
  but `method.delete` then greps the **full argument** in the file; `otmux.private.isPaneTarget`
  never matches the definition line. A legacy `private.isX` has no script segment at all.
- `replace block` needs a unique **end** line: every shell function ends in `}`.

The applied removal used an exact-range `awk` (documented in
`docs/private-methods-burndown.md` §6), which is proof that the tool should do it.

## Acceptance

- `oo method.delete <script>.private.<verb>` removes the block, its `*.completion.*` siblings and
  reports the tests that still reference it (the current behaviour for modern names);
- `replace block` accepts a unique start and finds the end by brace depth, or grows a
  `--until-end`/`--brace` flag;
- one red-first test per behaviour in `test/test.oo` (and `test/test.replace` if the selector
  changes).

## Notes

A related, smaller gap: the tool's usage line still shows the old `<script.method>` only; the
resolution rule ("private.<script>.<verb> belongs to <script>") is in the docstring but not in
`oo.usage`.
