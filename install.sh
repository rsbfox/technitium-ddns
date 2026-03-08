#!/bin/bash
# install.sh — installs technitium-ddns
# Run from the cloned repository root: sudo bash install.sh

set -e

if [ "$(id -u)" -ne 0 ]; then
    echo "ERROR: install.sh must be run as root" >&2
    exit 1
fi

# Install script
cp technitium-ddns /usr/local/bin/technitium-ddns
chown root:root /usr/local/bin/technitium-ddns
chmod 755 /usr/local/bin/technitium-ddns

# Install config
mkdir -p /etc/technitium-ddns
if [ ! -f /etc/technitium-ddns/technitium-ddns.conf ]; then
    cp technitium-ddns.conf /etc/technitium-ddns/technitium-ddns.conf
    chown root:root /etc/technitium-ddns/technitium-ddns.conf
    chmod 640 /etc/technitium-ddns/technitium-ddns.conf
    echo "Config installed — edit /etc/technitium-ddns/technitium-ddns.conf before running"
else
    echo "Config already exists — skipping"
fi

# Install example zone
mkdir -p /etc/technitium-ddns/zones/example.com
cp example.com/main.zone /etc/technitium-ddns/zones/example.com/main.zone
chown root:root /etc/technitium-ddns/zones/example.com/main.zone
chmod 640 /etc/technitium-ddns/zones/example.com/main.zone

# Install stress test zone
mkdir -p /etc/technitium-ddns/tests/stress.test
cp tests/stress.test/main.zone /etc/technitium-ddns/tests/stress.test/main.zone
chown root:root /etc/technitium-ddns/tests/stress.test/main.zone
chmod 640 /etc/technitium-ddns/tests/stress.test/main.zone

echo "Done. Run: sudo technitium-ddns"
