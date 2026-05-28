#!/bin/bash
CONFIG=/etc/loadwatch_config.json
STATE=/tmp/loadwatch_state
LOCK=/tmp/loadwatch_rebooted
LOG=/var/log/loadwatch.log

command -v jq >/dev/null 2>&1 || exit 1

THRESHOLD=$(jq .threshold $CONFIG)
DURATION=$(jq .duration $CONFIG)
EMAIL=$(jq -r .email $CONFIG)
SMART=$(jq .smart_action $CONFIG)

LOAD=$(uptime | awk -F'load average:' '{print $2}'|cut -d',' -f1|xargs)
CORES=$(nproc)
LOAD_INT=$(printf "%.0f" "$LOAD")
THRESHOLD=$(($THRESHOLD * $CORES / 100))
TIME=$(date +%s)
DATE=$(date)

echo "$DATE Load: $LOAD" >> $LOG

send_email(){
 if command -v mail >/dev/null 2>&1; then
  echo "$2" | mail -s "$1" "$EMAIL"
 fi
}

send_slack(){
 URL=$(jq -r .alerts.slack_webhook $CONFIG)
 [ "$URL" != "null" ] && curl -s -X POST -H 'Content-type: application/json' --data "{"text":"$1"}" $URL
}

send_telegram(){
 TOKEN=$(jq -r .alerts.telegram_bot_token $CONFIG)
 CHAT=$(jq -r .alerts.telegram_chat_id $CONFIG)
 [ "$TOKEN" != "null" ] && curl -s "https://api.telegram.org/bot$TOKEN/sendMessage" -d "chat_id=$CHAT&text=$1"
}

notify(){
 send_email "$1" "$2"
 send_slack "$2"
 send_telegram "$2"
}

if [ "$LOAD_INT" -gt "$THRESHOLD" ]; then
 if [ ! -f "$STATE" ]; then echo $TIME > $STATE; notify "High Load" "Load $LOAD"; exit 0; fi
 START=$(cat $STATE)
 ELAPSED=$(( (TIME-START)/60 ))

 if [ "$SMART" = "true" ] && [ "$ELAPSED" -ge 2 ]; then
  systemctl restart httpd
  systemctl restart mysqld
  notify "Smart Recovery" "Services restarted"
  exit 0
 fi

 if [ "$ELAPSED" -ge "$DURATION" ]; then
  if [ -f "$LOCK" ]; then exit 0; fi
  touch $LOCK
  notify "Reboot" "Load $LOAD for $ELAPSED min"
  /sbin/reboot
 fi
else
 rm -f $STATE
fi
