# macports-tools

Personal MacPorts migration tooling: capture the set of ports installed on one Mac and
reinstall it on another — or after a wipe — without copying `/opt/local`.

## What's here

- **`migrate/capture.sh`** — run on the source Mac; writes everything needed into `migrate/snapshot/`.
- **`migrate/restore.sh`** — run on the target Mac; reinstalls the captured ports with their
  variants and replays your `port select` defaults.
- **`migrate/snapshot/`** — the captured state: requested ports (with variants), the full
  installed inventory, `variants.conf`, `port select` defaults, and source-system facts.
- **`migrate/README.md`** — the full procedure and rationale.

## Why list-based, not a file copy

MacPorts installs aren't portable across machines or architectures (e.g. Intel → Apple Silicon):
the built binaries can't be reused and copying `/opt/local` doesn't survive an OS or arch change.
So this captures *what* you asked for and lets the new machine rebuild/fetch it natively.

## Quick start

On the old Mac:

```bash
bash migrate/capture.sh
```

On the new Mac (after installing Xcode Command Line Tools + the MacPorts pkg for its macOS):

```bash
sudo bash migrate/restore.sh
```

See [`migrate/README.md`](migrate/README.md) for the full step-by-step, the Apple Silicon notes,
and the same-machine wipe/reload variant.

## Scope

Captures MacPorts-managed ports + variants + `port select` defaults only. It does not back up
hand-edited data/config under `/opt/local`; reinstalling ports recreates their default config files.
