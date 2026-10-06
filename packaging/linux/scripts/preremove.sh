#!/bin/sh
# Stops the service before its files go. An upgrade keeps it: Debian passes
# "upgrade", RPM passes the number of versions left (1); pacman runs this only
# on removal.
case "${1:-remove}" in
upgrade | 1) exit 0 ;;
esac
if [ -d /run/systemd/system ]; then
	systemctl disable --now sora-core.service || true
fi
