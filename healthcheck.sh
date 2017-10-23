#!/bin/bash -e

exec 3<>/dev/tcp/localhost/10011

timeout 2 head -n1 >/dev/null <&3
