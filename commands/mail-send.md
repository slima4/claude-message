---
description: Append a message to the shared JSONL mailbox for another repo
argument-hint: <to> <body…>
allowed-tools: Bash
---

Append one JSONL line to the shared mailbox. Arguments: `$ARGUMENTS`.

The mailbox path is `${CLAUDE_MAIL_PATH:-$HOME/dev/.mail/mail.jsonl}`.

Resolve the sender alias (`from`) like this:
1. If the repo root contains a file `.claude-mail` and it is non-empty, use its first line.
2. Otherwise, use `basename $(pwd)`.

Parse `$ARGUMENTS`:
- First whitespace-delimited word → recipient alias (`to`). Just pass it through verbatim; no validation.
- Rest of the string → body.

Derive `thread`:
- If the body starts with `[thread:<id>]`, use that literal id and strip it from the stored body.
- Otherwise, slugify the first line of the body (lowercase, non-alphanumeric → `-`, trim to 40 chars) and prefix with today's date `YYYY-MM-DD-`.

Append with a single Bash call. Use Python for JSON-safe encoding so multi-line / quoted bodies survive intact:

```bash
python3 - <<'PY' >> "${CLAUDE_MAIL_PATH:-$HOME/dev/.mail/mail.jsonl}"
import json, time
line = {"ts": int(time.time()), "from": "<from>", "to": "<to>", "thread": "<thread>", "body": """<body>"""}
print(json.dumps(line, ensure_ascii=False))
PY
```

Substitute `<from>`, `<to>`, `<thread>`, `<body>` into the heredoc before running. Keep the `"""…"""` triple-quoted string so newlines and quotes in the body pass through.

Report one line: `sent: <from> → <to> · thread=<thread>`. Nothing else.
