#!/bin/bash -e

if [ "$#" -eq 0 ]
then
	default_query_ip_allowlist=/data/query_ip_allowlist.txt
	legacy_query_ip_allowlist=/data/query_ip_whitelist.txt
	default_query_ip_denylist=/data/query_ip_denylist.txt
	legacy_query_ip_denylist=/data/query_ip_blacklist.txt

	dbsqlpath="${TS3SERVER_INSTALL_DIR}/sql/"
	serverquerydocs_path="${TS3SERVER_INSTALL_DIR}/serverquerydocs/"
	query_ip_allowlist=
	query_ip_denylist=
	createinifile=1

	ts3server_args=()

	for arg in "$@"
	do
		case "$arg" in
		{query_ip_{allow,deny}list,serverquerydocs_path,dbsqlpath,createinifile}=*)
			IFS='=' read name value <<< "$arg"
			"${name}"="$1"
			continue
			;;
		query_ip_whitelist=*)
			IFS='=' read name value <<< "$arg"
			query_ip_allowlist="$value"
			continue
			;;
		query_ip_blacklist=*)
			IFS='=' read name value <<< "$arg"
			query_ip_denylist="$value"
			continue
			;;
		esac
		ts3server_args+=("$arg")
	done

	# 3.13.x - renamed option query_ip_allowlist
	if [ -z "$query_ip_allowlist" ]
	then
		if [ -e "$legacy_query_ip_allowlist" ]
		then
			query_ip_allowlist="$legacy_query_ip_allowlist"
		else
			query_ip_allowlist="$default_query_ip_allowlist"
		fi
	fi

	# 3.13.x - renamed option query_ip_denylist
	if [ -z "$query_ip_denylist" ]
	then
		if [ -e "$legacy_query_ip_denylist" ]
		then
			query_ip_denylist="$legacy_query_ip_denylist"
		else
			query_ip_denylist="$default_query_ip_denylist"
		fi
	fi

	ts3server_args=(
		"dbsqlpath=$dbsqlpath"
		"serverquerydocs_path=$serverquerydocs_path"
		"query_ip_allowlist=$query_ip_allowlist"
		"query_ip_denylist=$query_ip_denylist"
		"createinifile=$createinifile"
		"${ts3server_args[@]}"
	)

	exec ts3server "${ts3server_args[@]}"
else
	exec "$@"
fi
