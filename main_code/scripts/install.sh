#!/bin/bash

PLUGIN_NAME="load_monitor"
PLUGIN_DIR="/usr/local/cpanel/base/frontend/paper_lantern/$PLUGIN_NAME"

# Create plugin directory
mkdir -p $PLUGIN_DIR
mkdir -p $PLUGIN_DIR/scripts
mkdir -p $PLUGIN_DIR/hooks

# Copy files
cp load_monitor.conf /usr/local/cpanel/etc/$PLUGIN_NAME.conf
cp load_monitor.cgi $PLUGIN_DIR/
cp load_monitor.html.tt $PLUGIN_DIR/
cp scripts/monitor_load.pl $PLUGIN_DIR/scripts/
cp hooks/run_monitor $PLUGIN_DIR/hooks/

# Set permissions
chmod 755 $PLUGIN_DIR/load_monitor.cgi
chmod 755 $PLUGIN_DIR/scripts/monitor_load.pl
chmod 755 $PLUGIN_DIR/hooks/run_monitor

# Register plugin with cPanel
/usr/local/cpanel/bin/register_cpanelplugin /usr/local/cpanel/etc/$PLUGIN_NAME.conf

# Create log file
touch /var/log/load_monitor.log
chmod 644 /var/log/load_monitor.log

# Create default config if not exists
if [ ! -f /etc/load_monitor_config.json ]; then
    cat > /etc/load_monitor_config.json <<EOF
{
    "load_threshold": 80,
    "time_duration": 5,
    "action": "email",
    "email": "root@localhost",
    "monitor_enabled": 0,
    "check_interval": 60
}
EOF
    chmod 644 /etc/load_monitor_config.json
fi

echo "Load Monitor plugin installed successfully"
echo "You can access it from WHM -> Plugins -> Load Monitor"
