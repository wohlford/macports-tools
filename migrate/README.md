# MacPorts migration: Intel Mac → Apple Silicon Mac

Moves your MacPorts toolset to a new Mac by **reinstalling from a captured list**, not
by copying files. Copying `/opt/local` is the wrong approach here: the source is Intel
(x86_64) and the target is Apple Silicon (arm64), so none of the built binaries are
reusable. We capture *what* you asked for and let the new machine rebuild/fetch it natively.

This is deliberately **not** `sudo port migrate` (that snapshots the local registry for a
*same-machine* OS upgrade) and **not** Migration Assistant for `/opt/local`.

## Files

| File | Where it runs | Purpose |
| :--- | :--- | :--- |
| `capture.sh` | old Mac | Writes everything needed into `snapshot/` |
| `restore.sh` | new Mac | Reinstalls the ports + variants + selects |
| `snapshot/` | — | Generated artifacts (see below) |

### `snapshot/` contents
- `requested-with-variants.txt` — the 208 ports you explicitly installed, each with its
  exact variants. This is what `restore.sh` replays.
- `requested-ports.txt` — same list, names only (handy reference).
- `variants.conf` — your global variant preferences; copied verbatim to the new Mac.
- `port-select-restore.sh` — replays your `port select` defaults (python313, gcc15, etc.).
- `port-select-summary.txt` — human-readable view of those defaults.
- `full-inventory.txt` — all ~1,044 installed ports incl. dependencies (reference only).
- `macports.conf.reference` — your old config, for reference. **Do not copy wholesale** —
  it pins `build_arch x86_64`, which is wrong on Apple Silicon.
- `source-system.txt` — MacPorts/macOS/arch the snapshot came from.

## Step 1 — On the OLD Mac (this one)

Re-run the capture right before you leave so it reflects your latest state, then bring the
`migrate/` folder with you (commit the repo and clone it on the new Mac, or copy via USB):

```bash
bash migrate/capture.sh
```

## Step 2 — On the NEW Mac

1. Install Xcode and the command-line tools:
   ```bash
   xcode-select --install
   ```
   (Open Xcode once to accept the license if you install the full app.)
2. Install the **MacPorts `.pkg` for the new macOS version** from
   <https://www.macports.org/install.php>. Do not reuse the old installer if the OS differs.
3. Open a fresh terminal so `/opt/local/bin` is on `PATH`.
4. Copy the `migrate/` folder onto the new Mac, then:
   ```bash
   sudo bash migrate/restore.sh
   ```

`restore.sh` runs `selfupdate`, installs your `variants.conf`, reinstalls all 208 requested
ports (with their variants, fetching arm64 binary archives where available and building the
rest), then restores your `port select` defaults. It continues past any failure and prints a
list of ports that didn't install at the end.

## Known risks on arm64

- **`ghc` / `clang-22`**: the latest `ghc` pulls in `clang-22` (llvm-22), which currently
  fails to build from source on macOS 26 due to a stale MacPorts driver patch (seen on this
  Intel box; may recur on arm64). If `ghc` lands in the failure list, retry later after a
  `selfupdate`, or install an older `ghc` revision.
- **Any x86-only ports**: a few ports may lack arm64 support or need different variants.
  They'll appear in `restore.sh`'s failure list — handle them individually with
  `sudo port install <name>`.
- **Build time**: ports without arm64 binary archives build from source; expect the first
  run to take a while for the heavy ones (llvm, gcc, texlive, etc.).

## Rebuilding this same machine (wipe & reload)

The same tooling reinitializes MacPorts after erasing *this* Intel Mac — and it's the easiest
case, since same-arch (x86_64) means `port` fetches matching binary archives for almost
everything instead of building from source. This beats MacPorts' own `port snapshot` /
`port migrate` for a wipe, because the snapshot lives in this repo **outside `/opt/local`**,
which a disk erase destroys.

Procedure (after erase + macOS reinstall):

1. `xcode-select --install`
2. Install the MacPorts `.pkg` for **the same macOS version** you're reloading.
3. `sudo bash migrate/restore.sh`

Deltas from the Apple Silicon migration above:

- **`macports.conf` is safe to restore here.** The "don't copy it" warning was only about the
  `build_arch x86_64` line being wrong on arm64; on this Intel box it's correct (and is the
  default anyway), so you can just rely on `variants.conf`, which `restore.sh` already applies.
- **Re-run `capture.sh` before you wipe** — you can't capture after the disk is gone — and make
  sure this repo (with `snapshot/`) is **backed up off the disk** (push to a remote or copy it
  elsewhere). If `snapshot/` goes down with the disk, there's nothing to restore from.
- **Not captured:** hand-edited data/config under `/opt/local` (e.g. `/opt/local/etc/gitconfig`,
  `lftp.conf`, port-managed databases, web roots, launchd/cron items). Reinstalling ports only
  recreates their *default* config files — back up any local edits separately.
