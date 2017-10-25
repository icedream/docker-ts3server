#!/bin/bash -e

. /etc/os-release

exec 3<>/dev/tcp/localhost/10011

if [ "$ID" = "alpine" ]; then
	timeout -t 2 head -n1 >/dev/null <&3
else
	timeout 2 head -n1 >/dev/null <&3
fi
