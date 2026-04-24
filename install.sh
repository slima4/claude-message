#!/usr/bin/env bash
#
# claude-mail installer
#
# Installs three slash commands (/mail-send, /mail-inbox, /mail-reply) for
# Claude Code and creates the shared JSONL mailbox. Idempotent: safe to re-run.
#
# Options:
#   --mailbox <path>    Override mailbox path (default: $HOME/dev/.mail/mail.jsonl)
#   --commands <dir>    Override Claude commands dir (default: $HOME/.claude/commands)
#   --uninstall         Remove installed commands and mailbox files
#   -h, --help          Show this help

set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

MAILBOX_DEFAULT="$HOME/dev/.mail/mail.jsonl"
COMMANDS_DEFAULT="$HOME/.claude/commands"

MAILBOX_PATH="$MAILBOX_DEFAULT"
COMMANDS_DIR="$COMMANDS_DEFAULT"
UNINSTALL=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --mailbox) shift; MAILBOX_PATH="${1:?}";;
    --mailbox=*) MAILBOX_PATH="${1#*=}";;
    --commands) shift; COMMANDS_DIR="${1:?}";;
    --commands=*) COMMANDS_DIR="${1#*=}";;
    --uninstall) UNINSTALL=1;;
    -h|--help)
      sed -n '2,14p' "$0" | sed 's/^# \{0,1\}//'
      exit 0;;
    *) echo "unknown option: $1" >&2; exit 2;;
  esac
  shift
done

if ! command -v python3 >/dev/null 2>&1; then
  echo "python3 is required (macOS ships it; on Linux install python3)." >&2
  exit 1
fi

CMDS=(mail-send.md mail-inbox.md mail-reply.md)

if [[ "$UNINSTALL" -eq 1 ]]; then
  for f in "${CMDS[@]}"; do
    rm -f "$COMMANDS_DIR/$f"
  done
  rm -f "$MAILBOX_PATH"
  # Remove per-alias watermark files in the mailbox dir (best-effort)
  mailbox_dir=$(dirname "$MAILBOX_PATH")
  [[ -d "$mailbox_dir" ]] && find "$mailbox_dir" -maxdepth 1 -name ".seen-*" -delete 2>/dev/null || true
  echo "claude-mail uninstalled."
  echo "  removed: ${CMDS[*]/#/$COMMANDS_DIR/}"
  echo "  removed: $MAILBOX_PATH"
  exit 0
fi

mkdir -p "$COMMANDS_DIR"
mkdir -p "$(dirname "$MAILBOX_PATH")"
touch "$MAILBOX_PATH"
chmod 0644 "$MAILBOX_PATH"

for f in "${CMDS[@]}"; do
  src="$SCRIPT_DIR/commands/$f"
  if [[ ! -f "$src" ]]; then
    echo "missing source file: $src" >&2
    exit 1
  fi
  cp "$src" "$COMMANDS_DIR/$f"
done

cat <<EOF
claude-mail installed.

  commands: $COMMANDS_DIR/{mail-send,mail-inbox,mail-reply}.md
  mailbox:  $MAILBOX_PATH

Use from any Claude Code session in a repo under ~/dev/:

  /mail-send <recipient-alias> <body…>
  /mail-inbox
  /mail-reply <body…>

Sender alias defaults to \$(basename "\$PWD"). Override per-repo by putting the
alias on the first line of a \`.claude-mail\` file at the repo root.

Uninstall: $SCRIPT_DIR/install.sh --uninstall
EOF
