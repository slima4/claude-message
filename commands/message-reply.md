---
description: Reply (in the thread of the most recent inbox message) to its sender
argument-hint: <body…>
allowed-tools: Bash
---

Body = `$ARGUMENTS`. `<me>`: `.claude-message` line 1 or `basename $(pwd)`. Scans all `$DIR/log-*.jsonl` to find the most recent `to==me`. Appends reply to `$DIR/log-<me>.jsonl`. `$DIR` = `${CLAUDE_MESSAGE_DIR:-$HOME/dev/.message}`.

```bash
python3 - <<'PY'
import json, os, sys, time, hashlib
from pathlib import Path
ME="<me>"; BODY="""<body>"""
d=Path(os.environ.get("CLAUDE_MESSAGE_DIR", str(Path.home()/"dev"/".message"))); d.mkdir(parents=True, exist_ok=True)
mine=[]
for lf in sorted(d.glob("log-*.jsonl")):
    for ln in open(lf):
        ln=ln.strip()
        if not ln: continue
        try: m=json.loads(ln)
        except: continue
        if m.get("to")==ME: mine.append(m)
if not mine: sys.exit("no inbox messages to reply to")
mine.sort(key=lambda m: m.get("ts",0))
last=mine[-1]
ts=int(time.time())
core={"ts":ts,"from":ME,"to":last["from"],"thread":last["thread"],"body":BODY}
mid=hashlib.sha256(json.dumps(core, ensure_ascii=False, sort_keys=True).encode()).hexdigest()[:16]
rec={"id":mid, **core}
with open(d/f"log-{ME}.jsonl", "a") as f:
    f.write(json.dumps(rec, ensure_ascii=False)+"\n")
print(f"reply {ME}→{last['from']} thread={last['thread']} id={mid}")
PY
```

Substitute `<me>/<body>`. Keep the triple-quotes.
