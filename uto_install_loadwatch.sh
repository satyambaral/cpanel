#!/bin/bash

echo "======================================"
echo "  LoadWatch Auto Installer Starting"
echo "======================================"

ZIP_URL="https://github.com/satyambaral/cpanel/raw/main/loadwatch_plugin.zip"
TMP_DIR="/tmp/loadwatch_auto"

# Create temp dir
mkdir -p $TMP_DIR && cd $TMP_DIR || exit

echo "Downloading plugin..."
curl -L -o loadwatch_plugin.zip $ZIP_URL

if [ ! -f loadwatch_plugin.zip ]; then
    echo "❌ Failed to download plugin"
    exit 1
fi

echo "Extracting..."
unzip -o loadwatch_plugin.zip

# Install WHM plugin UI
echo "Installing WHM UI..."
mkdir -p /usr/local/cpanel/base/frontend/jupiter/loadwatch
cp -f index.live.php save.php /usr/local/cpanel/base/frontend/jupiter/loadwatch/

# Install script
echo "Installing monitoring script..."
cp -f loadwatch_check.sh /usr/local/cpanel/scripts/
chmod +x /usr/local/cpanel/scripts/loadwatch_check.sh

# Install dependencies
echo "Installing dependencies..."
if command -v yum &> /dev/null; then
    yum install -y jq mailx curl unzip
elif command -v dnf &> /dev/null; then
    dnf install -y jq mailx curl unzip
elif command -v apt &> /dev/null; then
    apt update && apt install -y jq mailutils curl unzip
fi

# Create config
echo "Creating config..."
cat <<EOF > /etc/loadwatch_config.json
{
  "threshold": 90,
  "duration": 5,
  "email": "root@localhost",
  "alerts": {
    "slack_webhook": "",
    "telegram_bot_token": "",
    "telegram_chat_id": ""
  }
}
EOF

chmod 600 /etc/loadwatch_config.json

# Setup cron
echo "Setting cron job..."
(crontab -l 2>/dev/null | grep -v loadwatch_check.sh; echo "* * * * * /usr/local/cpanel/scripts/loadwatch_check.sh") | crontab -

# Register WHM plugin
echo "Registering WHM plugin..."
cat <<EOF > /var/cpanel/apps/loadwatch.conf
service=whostmgr
name=Load Monitor
url=/cgi/loadwatch/index.live.php
group=server_configuration
EOF

/usr/local/cpanel/bin/register_appconfig /var/cpanel/apps/loadwatch.conf

# Restart cPanel
echo "Restarting cPanel..."
/usr/local/cpanel/bin/restartsrv_cpsrvd

echo "======================================"
echo "✅ INSTALLATION COMPLETE"
echo "WHM → Server Configuration → Load Monitor"
echo "======================================"
