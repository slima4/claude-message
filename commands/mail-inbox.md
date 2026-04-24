---
description: Show messages addressed to this repo from the shared JSONL mailbox
argument-hint: (no args; or `all` to include already-seen; `raw` to dump JSON)
allowed-tools: Bash
---

Read the shared mailbox and show messages addressed to this repo. Arguments: `$ARGUMENTS`.

The mailbox path is `${CLAUDE_MAIL_PATH:-$HOME/dev/.mail/mail.jsonl}`.

Resolve the recipient alias (`me`) like this:
1. If the repo root contains a file `.claude-mail` and it is non-empty, use its first line.
2. Otherwise, use `basename $(pwd)`.

Modes:
- `default` (no args) — show messages newer than the per-repo seen watermark. Update the watermark after displaying.
- `all` — show every message addressed to this repo, don't touch the watermark.
- `raw` — dump matching JSONL lines verbatim.

Single Bash call, all logic in Python:

```bash
python3 - <<'PY'
import json, os, time
from pathlib import Path
ME = "<me>"
MODE = "<mode>"   # default | all | raw
mail_path = Path(os.environ.get("CLAUDE_MAIL_PATH", str(Path.home() / "dev" / ".mail" / "mail.jsonl")))
seen_dir = mail_path.parent
seen_file = seen_dir / f".seen-{ME}"
since = 0
if MODE == "default" and seen_file.exists():
    try: since = int(seen_file.read_text().strip())
    except: pass
lines = [json.loads(l) for l in mail_path.read_text().splitlines() if l.strip()] if mail_path.exists() else []
mine = [m for m in lines if m.get("to") == ME and (MODE != "default" or m.get("ts", 0) > since)]
if not mine:
    print("no new messages" if MODE == "default" else "no messages")
    raise SystemExit
if MODE == "raw":
    for m in mine: print(json.dumps(m, ensure_ascii=False))
    raise SystemExit
for m in mine:
    ts = time.strftime("%m-%d %H:%M", time.localtime(m.get("ts", 0)))
    first = (m.get("body") or "").strip().splitlines()[0][:80]
    print(f"[{ts}] from={m.get('from')} thread={m.get('thread')}: {first}")
if MODE == "default":
    seen_file.write_text(str(max(m.get("ts", 0) for m in mine)))
PY
```

Substitute `<me>` and `<mode>` before running.

End with one summary line: `N new from: <from1>, <from2>, …`. Offer `/mail-reply <body>` as the quick reply path.
