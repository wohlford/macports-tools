# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

Personal MacPorts migration tooling for a macOS host. `migrate/` captures the installed port set on one Mac and reinstalls it on another (or after a wipe) — a list-based reinstall, **not** a file copy of `/opt/local` (which doesn't survive an Intel→Apple Silicon move or a disk erase). See `migrate/README.md` for the full procedure.

- `migrate/capture.sh` — run on the source Mac; writes everything needed into `migrate/snapshot/`.
- `migrate/restore.sh` — run on the target Mac; reinstalls requested ports + variants + `port select` defaults. Uses system `/bin/bash` because MacPorts bash isn't installed yet at restore time.
- `migrate/snapshot/` — generated artifacts (requested ports with variants, `variants.conf`, select defaults, full inventory). Lives in the repo, **outside `/opt/local`**, which is what makes it survive a wipe.

## Running `port` from a Claude session

- `sudo` prompts for a password the Bash tool can't supply — it hangs. Have the user authenticate and launch long runs detached from their own prompt: `! sudo -v && { nohup sudo bash <script> >/dev/null 2>&1 & }`. One auth runs the whole script as root; no per-command sudo.
- `port` exit codes are unreliable — detect failures by grepping logs (`^Error:|Failed to|Unable to`).
- Inventory model: `port echo requested` (~208) are the ports actually chosen; `port installed` (~1044) includes auto-pulled deps. Reinstall/migrate the *requested* set only — deps resolve themselves. `port -qv installed requested` adds variants; `port select --summary` shows defaults.

## Editing the scripts

- Tabs for indentation (matches existing files and global STYLE.md).
- The PostToolUse style hook requires `set -euo pipefail` in the first 5 lines and runs shellcheck. For scripts that must continue past failures, follow it with `set +e`; mark intentional unquoted word-splitting with `# shellcheck disable=SC2086`.
