#!/bin/sh -e

# files and directories that should exist beforehand
mkdir -p \
  /data/files \
  /data/logs
touch \
  /data/query_ip_blacklist.txt \
  /data/query_ip_whitelist.txt \
  /data/ts3server.sqlitedb

LD_LIBRARY_PATH="/opt/teamspeak3:${LD_LIBRARY_PATH}"
export LD_LIBRARY_PATH

/opt/teamspeak3/ts3server "$@" &
TS3SERVER_PID=$!

trap 'kill -2 ${TS3SERVER_PID}' INT
trap 'kill -15 ${TS3SERVER_PID}' TERM

wait ${TS3SERVER_PID}
