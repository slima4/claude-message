# Contributing to agent-message

Thanks for thinking about it. Reading the rules below first will save us both time.

## North star: smaller, cheaper, faster

Every change must serve at least one of three axes — or deliberately trade one for another with the trade named in the PR description.

- **Smaller** — line count is a first-class metric.
  - `commands/*.md` carry a per-invocation Claude input-token cost. Per-file budgets: `message-send` ≤ 40 lines, `message-reply` ≤ 40, `message-inbox` ≤ 60.
  - `bin/agent-message-cmd` and `shell/msg.sh` run locally — no token cost, but brevity is still the default.
  - `README.md` ≤ 200 lines. If you grow it past, delete something else.
- **Cheaper** — two invariants:
  1. The Claude / agent path stays at **1 shell call per operation**. No MCP, no hook, no tool-call chain.
  2. The shell path stays at **0 LLM tokens**. The `msg` function never touches a model.
- **Faster** — `mtime` short-circuit before parse; stat/glob before disk reads. `python3` startup (~30 ms) is the floor; don't add cycles on top.

Features that don't serve any of the three axes are out of scope. Point those at [`mcp_agent_mail`](https://github.com/Dicklesworthstone/mcp_agent_mail) or open a Discussion.

## Hard rules

- **No new runtime deps beyond `python3`.** No pip, no npm, no Docker.
- **No MCP, no daemon, no broker, no network transport.** The protocol is file-based by design.
- **Single-writer-per-file.** A writer with alias `<frm>` only ever writes to `log-<frm>.jsonl`. Readers union across all logs and dedup by id.
- **Wrapper and shell paths share the on-disk contract.** Any change to the JSONL schema, thread-slug rules, id computation, watermark semantics, or dedup rules must land in `bin/agent-message-cmd` AND `shell/msg.sh` in the same PR. They are the same protocol, two implementations.
- **Re-run `./install.sh` after editing `commands/*.md`, `shell/msg.sh`, or `bin/agent-message-cmd`.** The installer copies (does not symlink). Working-tree edits do not take effect until re-install.
- **No backwards-compat shims.** Project has no shipped users. Rename freely.

## How to contribute

1. **Open an issue first** for non-trivial work — bug, feature, or question. Saves a wasted PR if the idea is out of scope.
2. **Fork + branch.** Branch name: `feat/<short>`, `fix/<short>`, `docs/<short>`, `ci/<short>`.
3. **Code.**
4. **Test.** See `## Testing` below.
5. **Open a PR.** The template will ask which axis your change serves and whether you ran the round-trips.

## Testing

There is no build step, no linter, no test framework. Verification is a small set of round-trips:

```bash
# Shell round-trip (fast, run during dev)
TMP=$(mktemp -d); export AGENT_MESSAGE_DIR="$TMP/.message"
source shell/msg.sh
mkdir -p "$TMP/foo" "$TMP/bar"
(cd "$TMP/foo" && msg send bar "hi")
(cd "$TMP/bar" && msg)             # sees hi
(cd "$TMP/bar" && msg)             # "no new messages" (mtime short-circuit)
(cd "$TMP/bar" && msg reply "lgtm")
(cd "$TMP/foo" && msg)             # sees lgtm
rm -rf "$TMP"
```

Cases to also check before submitting:

- **Same-second burst** — two sends in the same second must both be visible to the recipient's first `msg` call.
- **Dedup** — copy `log-foo.jsonl` to `log-foo-replica.jsonl` (simulating sync duplicate), reset `.seen-*` + `.mtime-*`, run `msg` — duplicate must appear exactly once.
- **Claude round-trip** — in two Claude Code sessions: `/message-send <other> hi` → `/message-inbox` → `/message-reply lgtm` → `/message-inbox` on the first side.
- **Installer** — `./install.sh && ./install.sh && ./install.sh --uninstall` must all succeed cleanly. Double-install must not duplicate the rc-block. Uninstall must strip it.

## Style

- Match surrounding code. The slash commands are terse on purpose; don't add prose.
- Comments only when WHY is non-obvious. Don't narrate WHAT.
- Commit messages: title under 60 chars (`feat:`/`fix:`/`docs:`/`ci:`), body as bullets if needed. No long paragraphs.

## Discussions and questions

Open an issue with the `question` template, or use the GitHub Discussions tab if enabled. Don't email the maintainer with usage questions — keep them public so others benefit.
