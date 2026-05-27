#!/opt/local/bin/bash
# Capture this Mac's MacPorts state for a list-based reinstall on a new Mac.
# Re-run this right before you leave so the snapshot is current.
set -euo pipefail

OUTDIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/snapshot"
mkdir -p "$OUTDIR"
echo "Capturing MacPorts state -> $OUTDIR"

# 1. Requested port names only (dependencies resolve automatically on reinstall).
port echo requested | awk '{print $1}' | sort -u > "$OUTDIR/requested-ports.txt"

# 2. Requested ports WITH the exact variants requested -> faithful reinstall list.
#    Emits "portname +var -var" lines (variants column may be empty).
port -qv installed requested \
	| sed -nE "s/^[[:space:]]*([^[:space:]]+).*requested_variants='([^']*)'.*/\1 \2/p" \
	| sort -u > "$OUTDIR/requested-with-variants.txt"

# 3. Full inventory (everything installed, incl. dependencies) — reference/backup only.
port -qv installed > "$OUTDIR/full-inventory.txt"

# 4. `port select` defaults, plus a replayable script of set commands.
port select --summary > "$OUTDIR/port-select-summary.txt"
awk 'NR>2 && $2!="none" {print "port select --set "$1" "$2}' \
	"$OUTDIR/port-select-summary.txt" > "$OUTDIR/port-select-restore.sh"

# 5. Config: variants.conf is the important, architecture-neutral one.
#    macports.conf is kept for reference ONLY — do not copy build_arch to arm64.
cp /opt/local/etc/macports/variants.conf "$OUTDIR/variants.conf"
cp /opt/local/etc/macports/macports.conf "$OUTDIR/macports.conf.reference"

# 6. Source-system facts for the record.
{ port version; echo; sw_vers; echo "arch: $(uname -m)"; } > "$OUTDIR/source-system.txt" 2>&1

echo "Done. Snapshot contents:"
ls -1 "$OUTDIR"
echo
echo "Requested ports: $(wc -l < "$OUTDIR/requested-ports.txt")"
