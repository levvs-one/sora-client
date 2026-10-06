#!/bin/sh
# Creates the service account and starts the service, so a person who installs
# the package from a software center never needs a terminal. An upgrade
# restarts the service onto the new binary.
set -e
systemd-sysusers /usr/lib/sysusers.d/sora.conf
if [ -d /run/systemd/system ]; then
	systemctl daemon-reload
	systemctl enable sora-core.service
	systemctl restart sora-core.service
fi
