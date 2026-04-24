---
description: Append a message to this repo's per-agent log in the shared dir
argument-hint: <to> <body…>
allowed-tools: Bash
---

Args: `$ARGUMENTS`. First word = `<to>`, rest = `<body>`. `<from>`: `.claude-message` line 1 or `basename $(pwd)`. `<thread>`: `<id>` from leading `[thread:<id>]` (strip prefix), else `YYYY-MM-DD-<from>-<slug40>` (first line, lowercase, non-alphanumeric → `-`, trim 40). Write appends to `$DIR/log-<from>.jsonl` (single-writer per agent). `$DIR` = `${CLAUDE_MESSAGE_DIR:-$HOME/dev/.message}`.

```bash
python3 - <<'PY'
import json, os, time, hashlib
from pathlib import Path
FROM="<from>"; TO="<to>"; THREAD="<thread>"; BODY="""<body>"""
d=Path(os.environ.get("CLAUDE_MESSAGE_DIR", str(Path.home()/"dev"/".message"))); d.mkdir(parents=True, exist_ok=True)
ts=int(time.time())
core={"ts":ts,"from":FROM,"to":TO,"thread":THREAD,"body":BODY}
mid=hashlib.sha256(json.dumps(core, ensure_ascii=False, sort_keys=True).encode()).hexdigest()[:16]
rec={"id":mid, **core}
with open(d/f"log-{FROM}.jsonl", "a") as f:
    f.write(json.dumps(rec, ensure_ascii=False)+"\n")
print(f"sent {FROM}→{TO} thread={THREAD} id={mid}")
PY
```

Substitute `<from>/<to>/<thread>/<body>`. Keep the `"""…"""` so newlines/quotes survive.
