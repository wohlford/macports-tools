#!/bin/bash
# Restore MacPorts ports on a NEW Mac from a snapshot/ produced by capture.sh.
# Prereqs (see README.md): Xcode CLT + MacPorts .pkg installed, fresh shell.
# Uses system /bin/bash because MacPorts bash isn't installed yet at restore time.
set -euo pipefail

SNAP="$(cd "$(dirname "$0")" && pwd)/snapshot"

if [ "$(id -u)" -ne 0 ]; then
	echo "Run with sudo: sudo bash $0"
	exit 1
fi
if ! command -v port >/dev/null 2>&1; then
	echo "MacPorts 'port' not found. Install the MacPorts .pkg first."
	exit 1
fi
if [ ! -d "$SNAP" ]; then
	echo "No snapshot/ dir next to this script. Copy the whole migrate/ folder over."
	exit 1
fi

echo "=== selfupdate ==="
port -v selfupdate

# Apply captured variant preferences (architecture-neutral). Back up any existing file.
VARCONF=/opt/local/etc/macports/variants.conf
if [ -f "$SNAP/variants.conf" ]; then
	[ -f "$VARCONF" ] && cp "$VARCONF" "$VARCONF.bak.$(date +%s)"
	cp "$SNAP/variants.conf" "$VARCONF"
	echo "Installed variants.conf"
fi

echo "=== reinstall requested ports (with captured variants) ==="
fails=""
while IFS= read -r line; do
	[ -z "$line" ] && continue
	name=${line%% *}
	variants=${line#"$name"}
	echo "--- $name$variants ---"
	# Word-splitting on $variants is intentional: turns "+a -b" into separate args.
	# shellcheck disable=SC2086
	if ! port -N install $name $variants; then
		fails="$fails $name"
	fi
done < "$SNAP/requested-with-variants.txt"

echo "=== restore 'port select' defaults ==="
if [ -f "$SNAP/port-select-restore.sh" ]; then
	while IFS= read -r cmd; do
		[ -z "$cmd" ] && continue
		echo "$cmd"
		# shellcheck disable=SC2086
		$cmd || true
	done < "$SNAP/port-select-restore.sh"
fi

echo
if [ -n "$fails" ]; then
	echo "Ports that FAILED (check arm64 availability / variants):"
	for f in $fails; do echo "  - $f"; done
	echo "Retry after fixing: sudo port install <name>"
else
	echo "All requested ports installed."
fi
echo "Done. Review 'port outdated' and 'port installed' to confirm."
