#!/bin/sh -e

if [ -n "$TZ" ]; then
	# https://wiki.alpinelinux.org/wiki/Setting_the_timezone
	if [ -f /usr/share/zoneinfo/"$TZ" ]; then
		cp /usr/share/zoneinfo/"$TZ" /etc/localtime
	fi
	echo "$TZ" > /etc/timezone
fi

exec ts3server "$@"
