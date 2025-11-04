#!/bin/bash
# Install PiFrame connection monitor on Pi

set -e

echo "Installing PiFrame connection monitor..."

# Copy monitor script
cp monitor-connection.sh /usr/local/bin/
chmod +x /usr/local/bin/monitor-connection.sh

# Install systemd service and timer
cp piframe-monitor.service /etc/systemd/system/
cp piframe-monitor.timer /etc/systemd/system/

# Reload systemd
systemctl daemon-reload

# Enable and start timer
systemctl enable piframe-monitor.timer
systemctl start piframe-monitor.timer

echo ""
echo "Connection monitor installed!"
echo ""
echo "Status: systemctl status piframe-monitor.timer"
echo "Logs:   journalctl -u piframe-monitor.service -f"
echo ""
echo "Monitor checks NFS mount every 2 minutes:"
echo "- Displays warning overlay if connection lost"
echo "- Retries mount 3 times (10 second intervals)"
echo "- Reboots once if all retries fail"
echo "- Shows permanent error if still fails after reboot"
