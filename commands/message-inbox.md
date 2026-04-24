---
description: Show messages addressed to this repo — union across all agent logs
argument-hint: [all|raw]
allowed-tools: Bash
---

`<mode>` from `$ARGUMENTS`: `default` (empty), `all`, or `raw`. `<me>`: `.claude-message` line 1 or `basename $(pwd)`. `default` uses + updates `.seen-<me>` watermark (ts + ids-at-max-ts to handle same-second messages) and `.mtime-<me>` short-circuit; `all`/`raw` don't.

```bash
python3 - <<'PY'
import json, os, time, hashlib
from pathlib import Path
ME,MODE="<me>","<mode>"
d=Path(os.environ.get("CLAUDE_MESSAGE_DIR", str(Path.home()/"dev"/".message")))
logs=sorted(d.glob("log-*.jsonl"))
mt=d/f".mtime-{ME}"
cur_max=max((p.stat().st_mtime for p in logs), default=0.0); cur_n=len(logs)
if MODE=="default" and mt.exists():
    try:
        c=json.loads(mt.read_text())
        if c.get("max_mtime",0)>=cur_max and c.get("files",0)==cur_n:
            print("no new messages"); raise SystemExit
    except json.JSONDecodeError: pass
sf=d/f".seen-{ME}"; since=0; since_ids=set()
if MODE=="default" and sf.exists():
    try:
        c=json.loads(sf.read_text()); since=c.get("ts",0); since_ids=set(c.get("ids",[]))
    except json.JSONDecodeError: pass
def cid(m):
    c={k:m[k] for k in ("ts","from","to","thread","body") if k in m}
    return hashlib.sha256(json.dumps(c, ensure_ascii=False, sort_keys=True).encode()).hexdigest()[:16]
seen=set(); out=[]
for lf in logs:
    for ln in open(lf):
        ln=ln.strip()
        if not ln: continue
        try: m=json.loads(ln)
        except: continue
        if m.get("to")!=ME: continue
        i=m.get("id") or cid(m)
        if i in seen: continue
        seen.add(i); t=m.get("ts",0)
        if MODE=="default" and (t<since or (t==since and i in since_ids)): continue
        m["_id"]=i; out.append(m)
out.sort(key=lambda x: x.get("ts",0))
if not out:
    print("no new messages" if MODE=="default" else "no messages")
    if MODE=="default": mt.write_text(json.dumps({"max_mtime":cur_max,"files":cur_n}))
    raise SystemExit
if MODE=="raw":
    for m in out: m.pop("_id", None); print(json.dumps(m, ensure_ascii=False))
    raise SystemExit
for m in out:
    t=time.strftime("%m-%d %H:%M", time.localtime(m.get("ts",0)))
    body=m.get("body") or ""; first=body.splitlines()[0][:80] if body else ""
    print(f"[{t}] from={m['from']} thread={m['thread']}: {first}")
if MODE=="default":
    nm=max(m.get("ts",0) for m in out)
    nids=[m["_id"] for m in out if m.get("ts",0)==nm]
    if nm==since: nids=sorted(since_ids|set(nids))
    sf.write_text(json.dumps({"ts":nm,"ids":list(nids)}))
    mt.write_text(json.dumps({"max_mtime":cur_max,"files":cur_n}))
PY
```

Substitute `<me>/<mode>`. End with `N new from: <from1>, …`. Suggest `/message-reply <body>`.
