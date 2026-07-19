#!/usr/bin/env bash

set -euo pipefail

ROLLBACK_MINUTES="${1:-5}"
EXTRA_TCP_PORTS="${2:-}"
EXTRA_UDP_PORTS="${3:-}"

NFT_CONF="/etc/nftables.conf"
BACKUP_DIR="/etc/nftables.rollback"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
BACKUP_FILE="${BACKUP_DIR}/nftables.conf.${TIMESTAMP}.bak"
CONFIRM_FLAG="/etc/nftables.rollback/confirm-${TIMESTAMP}"
ROLLBACK_SCRIPT="/etc/nftables.rollback/do-rollback-${TIMESTAMP}.sh"

if [[ $EUID -ne 0 ]]; then
	echo "error: must be run as root (use sudo)" >&2
	exit 1
fi

mkdir -p "$BACKUP_DIR"

# ensure at available for rollback timer
if ! command -v at >/dev/null 2>&1; then 
	if command -v apt-get >/dev/null 2>&1; then
		apt-get update -qq && apt-get install -y -qq at
	else
		printf "error: at not found & no supported pkg found to install\nScript uses apt-get, modify script or install apt-get pkg mgr" >&2
		exit 1
	fi
	systemctl enable --now atd >dev/nnull 2>&1 || true
fi

# backup current ruleset
if [[ -f "$NFT_CONF" ]]; then
	cp -a "$NFT_CONF" "$BACKUP_FILE"
	echo "backup up existing ruleset to $BACKUP_FILE"
else
	# create dummy backup to rollback to
	cat > "$BACKUP_FILE" <<'EOF'
#!/usr/sbin/nft -f
flush ruleset
table inet filter {
	chain input  { type filter hook input priority 0; policy accept; }
	chain forward { type filter hook forward priority 0; policy accept; }
	chain output { type filter hook output priority 0; policy accept; }
}
EOF
	echo "no existing $NFT_CONF found, created fully permissive dummy backup"
fi

# extra port rule inserts
EXTRA_TCP_RULE=""
if [[ -n "$EXTRA_TCP_PORTS" ]]; then
	EXTRA_TCP_RULE="tcp dport {  ${EXTRA_TCP_PORTS} } ct state new accept"
fi

EXTRA_UDP_RULE=""
if [[ -n "$EXTRA_UDP_PORTS" ]]; then
	EXTRA_UDP_RULE="udp dport {  ${EXTRA_UDP_PORTS} } accept"
fi

# new ruleset
cat > "$NFT_CONF" <<EOF
#!/usr/sbin/nft -f
flush ruleset
table inet filter {
	chain input {
		type filter hook input priority 0; policy drop;

		# loopback always trusted
		iif "lo" accept

		# allow return traffic for connections machine intitiated
		ct state established,related accept
		ct state invalid drop

		# basic icmp needed for netw stack to behave
		ip protocol icmp icmp type { echo-request, destination-unreachable, time-exceeded, parameter-problem } accept

		# may be able to live w/o icmpv6
		# ip6 nexthdr icmpv6 icmpv6 type { echo-request, destination-unreachable, time-exceeded, packet-too-big, parameter-problem, nd-router-advert, nd-neighbor-solicit, nd-neighbor-advert } accept

		# ssh mgmt access
		tcp dport 22 ct state new accept

		# dhcp client, lease reply from dhcp server
		udp dport 68 udp sport 67 accept

		# extra role-specific ports specified
		${EXTRA_TCP_RULE}
		${EXTRA_UDP_RULE}

		# log anything else b/f it's dropped (rate-limited to not flood log)
		limit rate 5/minute log prefix "nft-input-drop: "
	}

	chain forward {
		type filter hook forward priority 0; policy drop;
}

	chain output {
		# outbound left open: dns, dhcp, ntp, pkg updates, ansible's own ssh, etc
		# can tighten later for egress filtering too
		type filter hook output priority 0; policy accept;
	}
}
EOF

# syntax check b/f touching live ruleset :)
if ! nft -c -f "$NFT_CONF"; then
	echo "error: syntax check failed, not applying. restoring backup ruleset" >&2
	cp -a "$BACKUP_FILE" "$NFT_CONF"
	exit 1
fi

# schedule auto rollback
cat > "$ROLLBACK_SCRIPT" <<EOF
#!/usr/bin/env bash
# auto-rollback for nftables change made at ${TIMESTAMP}
if [[ ! -f "${CONFIRM_FLAG}" ]]; then
	cp -a "${BACKUP_FILE}" "${NFT_CONF}"
	nft -f "${NFT_CONF} || systemctl restart nftables
	logger "nftables rollback exec, change at ${TIMESTAMP} not confirmed"
fi
# clean up this job's script
rm -f "${ROLLBACK_SCRIPT}"
EOF
chmod +x "$ROLLBACK_SCRIPT"
# ^double check rm
echo "$ROLLBACK_SCRIPT" | at -t "$(date -d "+${ROLLBACK_MINUTES} minutes" +%Y%m%d%H%M)" 2>&1 | tee /tmp/nft-at-job.log
echo "rollback scheduled in ${ROLLBACK_MINUTES} minute(s) unless confirmed"
echo "confirm flag expected at $CONFIRM_FLAG"
echo "$CONFIRM_FLAG" > /etc/nftables.rollback/current-confirm-flag

# apply new ruleset
systemctl enable nftables >/dev/null 2>&1 || true
nft -f "$NFT_CONF"
systemctl restart nftables || true

echo "new ruleset applied. reconnect via ssh now to verify access b/f rollback timer expires"
echo "if access if confirmed run: confirm-nftables.sh"
