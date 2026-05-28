#!/bin/bash
mkdir -p /usr/local/cpanel/base/frontend/jupiter/loadwatch
cp index.live.php save.php /usr/local/cpanel/base/frontend/jupiter/loadwatch/
cp loadwatch_check.sh /usr/local/cpanel/scripts/
chmod +x /usr/local/cpanel/scripts/loadwatch_check.sh
cp loadwatch.conf /var/cpanel/apps/loadwatch.conf
/usr/local/cpanel/bin/register_appconfig /var/cpanel/apps/loadwatch.conf
(crontab -l 2>/dev/null|grep -v loadwatch_check.sh;echo "* * * * * /usr/local/cpanel/scripts/loadwatch_check.sh")|crontab -
