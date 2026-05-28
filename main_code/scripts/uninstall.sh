#!/bin/bash

PLUGIN_NAME="load_monitor"

# Unregister plugin
/usr/local/cpanel/bin/unregister_cpanelplugin /usr/local/cpanel/etc/$PLUGIN_NAME.conf

# Remove files
rm -rf /usr/local/cpanel/base/frontend/paper_lantern/$PLUGIN_NAME
rm -f /usr/local/cpanel/etc/$PLUGIN_NAME.conf
rm -f /etc/load_monitor_config.json
rm -f /etc/cron.d/load_monitor
rm -f /var/run/load_monitor_state.json

echo "Load Monitor plugin uninstalled successfully"
