#!/bin/bash

echo "Starting LoadWatch installer..."

ZIP_URL="https://github.com/satyambaral/cpanel/raw/main/loadwatch_plugin.zip"
TMP="/tmp/loadwatch_auto"

mkdir -p $TMP && cd $TMP || exit

curl -L -o plugin.zip $ZIP_URL
unzip -o plugin.zip

# Install UI
mkdir -p /usr/local/cpanel/base/frontend/jupiter/loadwatch
cp -f index.live.php save.php /usr/local/cpanel/base/frontend/jupiter/loadwatch/

# Install script
cp -f loadwatch_check.sh /usr/local/cpanel/scripts/
chmod +x /usr/local/cpanel/scripts/loadwatch_check.sh

# Install deps (EL9 compatible)
if command -v dnf &> /dev/null; then
    dnf install -y jq curl unzip mailx || dnf install -y s-nail
fi

# Config
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

# Cron
(crontab -l 2>/dev/null | grep -v loadwatch_check.sh; echo "* * * * * /usr/local/cpanel/scripts/loadwatch_check.sh") | crontab -

# WHM config (fixed name)
cat <<EOF > /var/cpanel/apps/loadwatch.conf
service=whostmgr
name=LoadMonitor
url=/cgi/loadwatch/index.live.php
group=server_configuration
EOF

/usr/local/cpanel/bin/register_appconfig /var/cpanel/apps/loadwatch.conf

# Correct restart command
/scripts/restartsrv_cpsrvd

echo "✅ Installation complete"
