<!-- Read CONTRIBUTING.md before opening. -->

## What

<!-- 1-3 sentences. -->

## Why

<!-- The user-facing problem this solves. Link the issue. -->

Closes #

## Which axis does this serve?

- [ ] **Smaller** — reduces lines / tokens / surface
- [ ] **Cheaper** — reduces shell calls / tokens / runtime deps
- [ ] **Faster** — reduces wall-clock latency
- [ ] **Other** — explain below

If you check more than one, name the tradeoff. If you check "Other", explain why this is in scope.

## Tested

- [ ] `./test.sh` passes locally (CI runs it on Linux + macOS)
- [ ] Added a new test for any new behaviour
- [ ] Manual Claude-Code round-trip (only required for `commands/*.md` edits)
- [ ] Re-ran `./install.sh` after editing `commands/*.md`, `shell/msg.sh`, or `bin/agent-message-cmd`
- [ ] Schema / contract changes landed in BOTH `bin/agent-message-cmd` AND `shell/msg.sh` (n/a if no contract change)

## Line budgets

- `commands/message-send.md` ≤ 40 lines:  `wc -l commands/message-send.md` =
- `commands/message-reply.md` ≤ 40 lines: `wc -l commands/message-reply.md` =
- `commands/message-inbox.md` ≤ 60 lines: `wc -l commands/message-inbox.md` =
- `README.md` ≤ 200 lines:                `wc -l README.md` =

(Skip the lines that don't apply.)
