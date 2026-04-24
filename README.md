# claude-mail

Dead-simple cross-session messaging for Claude Code. No server, no MCP, no token, no daemon.

One shared JSONL file on disk. Three slash commands. That's it.

## Why

Running multiple Claude Code sessions (one per repo) and want them to talk without manual copy-paste? Existing solutions ([mcp_agent_mail](https://github.com/Dicklesworthstone/mcp_agent_mail), Agent Teams, broker daemons) run a Python HTTP server, maintain SQLite, register agent identities, require tokens, burn tokens on polling hooks, and can reject your names for format reasons. Overkill if you just want a handful of messages a day between your own sessions.

This project gives you the 90% at 1% of the cost: a local append-only JSONL file, three slash commands, basename-as-identity, no setup per repo.

## Install

```bash
git clone https://github.com/slima4/claude-mail && cd claude-mail && ./install.sh
```

Installs three commands into `~/.claude/commands/` and creates `~/dev/.mail/mail.jsonl`. Idempotent — safe to re-run.

Custom paths:

```bash
./install.sh --mailbox ~/shared/mail.jsonl --commands ~/.claude/commands
```

## Use

From any Claude Code session, in any repo under `~/dev/`:

```
# In repo "foo":
/mail-send bar need your review on the schema change

# In repo "bar":
/mail-inbox
  [04-24 17:42] from=foo thread=2026-04-24-need-your-review: need your review on…

/mail-reply lgtm, merge when ready
```

The sender alias is the basename of `$(pwd)`. So `/Users/you/dev/foo` → `foo`. Override per-repo by dropping a one-line `.claude-mail` file at the repo root:

```
$ echo "my-short-name" > .claude-mail
```

## How it works

Messages are JSONL lines in one shared file:

```json
{"ts": 1777040863, "from": "foo", "to": "bar", "thread": "2026-04-24-need-your-review", "body": "…"}
```

- `/mail-send <to> <body>` — one `python3 -m json.dumps` + shell append
- `/mail-inbox` — read file, filter `to == me`, show messages newer than `~/dev/.mail/.seen-<me>` watermark
- `/mail-reply <body>` — find last message addressed to me, append reply with same `thread` and reversed `from`/`to`

No server. No network. No port. Works offline.

## Compared to the alternatives

| | claude-mail | mcp_agent_mail | Agent Teams |
|---|---|---|---|
| runtime | append-only file | HTTP server, SQLite | Claude Code built-in |
| setup | 1 script | installer + LaunchAgent + token rotation + per-repo `.mcp.json` | opt-in env flag |
| identity | repo basename | curated adjective+noun, strict rules | team lead/teammate |
| cross-session | yes | yes | team only |
| tokens per send | ~1 Bash call | MCP init + resource reads + tool call + ack poll | similar |
| passive polling | none | optional hook | automatic |
| web UI | `cat ~/dev/.mail/mail.jsonl` | yes (`:8765/mail`) | none |
| audit trail | the file itself | Git-backed markdown | per-session |
| cost | ~0 | high | medium |

Pick claude-mail when: you run 2–10 Claude Code sessions, message volume is low, you care about tokens more than features, you want to cat/grep/`tail -f` the log yourself.

Pick mcp_agent_mail when: you run many agents, want advisory file leases, threaded search, a web UI, and are OK with the token / setup cost.

## Browse history

```bash
# All messages
cat ~/dev/.mail/mail.jsonl | jq .

# Thread
jq 'select(.thread == "2026-04-24-need-your-review")' ~/dev/.mail/mail.jsonl

# Follow new messages as they arrive
tail -f ~/dev/.mail/mail.jsonl | jq .

# Reset a repo's "seen" watermark so /mail-inbox shows everything again
rm ~/dev/.mail/.seen-<alias>
```

## Uninstall

```bash
./install.sh --uninstall
```

Removes the three slash commands and the mailbox file. Does not touch `.claude-mail` files in your repos.

## Environment

- `CLAUDE_MAIL_PATH` — mailbox path. Default `$HOME/dev/.mail/mail.jsonl`. If set, slash commands honor it.

## Limits

- **No auth.** Anyone on the local machine who can read the mailbox file can read all messages. Don't put secrets here.
- **No locking.** Concurrent writers could in theory interleave lines; `echo >>` on macOS/Linux is atomic for lines under `PIPE_BUF` (4KB), so it's fine for normal messages but don't dump megabytes.
- **No notifications.** You pull inbox with `/mail-inbox`. For a tail-on-arrival feel, run `tail -f ~/dev/.mail/mail.jsonl` in a spare terminal.
- **Single machine.** If you want this across machines, sync `~/dev/.mail/` with Syncthing / Dropbox / iCloud Drive.

## License

MIT — see `LICENSE`.
