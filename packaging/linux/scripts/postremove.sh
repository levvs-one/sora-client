#!/bin/sh
# The core removes its nftables table when it stops; a core that was killed
# could not, so the table is removed here as well. Nothing else of the system
# was changed by the package.
case "${1:-remove}" in
upgrade | 1) exit 0 ;;
esac
nft delete table inet sora 2>/dev/null || true
if [ -d /run/systemd/system ]; then
	systemctl daemon-reload
fi
