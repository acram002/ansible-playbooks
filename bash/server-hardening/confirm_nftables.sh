#!/usr/bin/env bash

set -euo pipefail

FLAG_POINTER="/etc/nftables.rollback/current-confirm-flag"

if [[ ! -f "$FLAG_POINTER" ]]; then
	echo "no pending rollback found (nuthing to confirm)" >&2
	exit 0
fi

CONFIRM_FLAG="$(cat "$FLAG_POINTER")"
touch "$CONFIRM_FLAG"
rm -f "$FLAG_POINTER"

echo "confirmed, scheduled nftables rollback has been cancelled"

# delete scheduled rollback?
