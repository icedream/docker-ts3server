#!/bin/sh -e

# files and directories that should exist beforehand
mkdir -p \
  files \
  logs
touch \
  query_ip_blacklist.txt \
  query_ip_whitelist.txt \
  ts3server.sqlitedb

for path in \
  files \
  logs \
  query_ip_blacklist.txt \
  query_ip_whitelist.txt \
  ts3server.sqlitedb; \
do \
  ln -sf "$(pwd)/${path}" "/opt/teamspeak3/${path}"; \
done

cd /opt/teamspeak3
LD_LIBRARY_PATH=".:${LD_LIBRARY_PATH}" /opt/teamspeak3/ts3server "$@" &
TS3SERVER_PID=$!

trap 'kill -2 ${TS3SERVER_PID}' INT
trap 'kill -15 ${TS3SERVER_PID}' TERM

wait ${TS3SERVER_PID}
