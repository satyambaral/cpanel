#!/bin/bash

echo "======================================"
echo "   LoadWatch Uninstaller Starting"
echo "======================================"

# Remove WHM UI
echo "Removing WHM plugin UI..."
rm -rf /usr/local/cpanel/base/frontend/jupiter/loadwatch

# Remove monitoring script
echo "Removing monitoring script..."
rm -f /usr/local/cpanel/scripts/loadwatch_check.sh

# Remove cron job
echo "Removing cron job..."
(crontab -l 2>/dev/null | grep -v loadwatch_check.sh) | crontab -

# Remove config
echo "Removing config file..."
rm -f /etc/loadwatch_config.json

# Remove log file
echo "Removing logs..."
rm -f /var/log/loadwatch.log

# Unregister WHM plugin
echo "Unregistering WHM plugin..."
rm -f /var/cpanel/apps/loadwatch.conf

# Remove WHM cache entry (optional cleanup)
rm -f /var/cpanel/apps/loadwatch.cache

# Restart cPanel service
echo "Restarting cPanel..."
if [ -x /scripts/restartsrv_cpsrvd ]; then
    /scripts/restartsrv_cpsrvd
elif [ -x /usr/local/cpanel/bin/restartsrv_cpsrvd ]; then
    /usr/local/cpanel/bin/restartsrv_cpsrvd
fi

echo "======================================"
echo "✅ LoadWatch COMPLETELY REMOVED"
echo "======================================"
