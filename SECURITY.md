# Security Policy

## Reporting a vulnerability

Do **not** open a public GitHub issue for security problems.

Use one of:

1. **GitHub Security Advisories (preferred)** — open a private advisory at <https://github.com/slima4/agent-message/security/advisories/new>. Only the maintainer sees it.
2. **Email** — <slima4.u8@gmail.com>. Subject line: `[security] agent-message: <short summary>`.

You will get an acknowledgement within 7 days. Expect resolution within 30 days for high-severity issues, longer for low-severity ones — agent-message is a side project, not a paid product.

## Scope

In scope:

- Path traversal or arbitrary file write via crafted alias / `.agent-message` content / `to` field / `thread` field
- Code execution via the wrapper or shell helper
- Privilege escalation via the installer (e.g. abusing `chmod`, `cp`, rc-block injection)

Out of scope (these are documented in [`docs/limits.md`](docs/limits.md)):

- Anyone with read access to the message directory can read all messages — this is by design. Don't put secrets here.
- No authentication, encryption, or network transport — the protocol is file-based and local.
- Denial of service via filling the disk or sending huge messages.

## Disclosure

After a fix lands, the security advisory is published with attribution unless you ask to remain anonymous.
