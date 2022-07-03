#!/bin/bash
set -e
set -u
set -o pipefail

teamspeak_versions_server_json_url="https://teamspeak.com/versions/server.json"
readonly teamspeak_versions_server_json_url
teamspeak_versions_server_json="$(curl -sL "$teamspeak_versions_server_json_url" | jq -c .)"

jq_image="registry.gitlab.com/gitlab-ci-utils/curl-jq"
jq() {
	if command -v jq >/dev/null; then
		command jq "$@"
	else
		docker run --rm -i "$jq_image" jq "$@"
	fi
}

update_checksum_for_dockerfile() {
	dockerfile="$1"

	echo "Processing $dockerfile" >&2

	final_base_image="$(grep -Ei '^FROM .+' "$dockerfile" | tail -n1 | sed -e 's#FROM \(.\+\)#\1#')"
	case "$final_base_image" in
	alpine:*)
		platform=alpine
		;;
	*)
		platform=amd64
		;;
	esac
	echo "> platform $platform" >&2

	ts3server_version="$(
		grep -E 'TS3SERVER_VERSION=.+' "$dockerfile" |
			sed -e "s,.\+TS3SERVER_VERSION=[\"']\(.\+\)[\"'],\1,"
	)"
	ts3server_sha256="$(
		grep -E 'TS3SERVER_SHA256=.+' "$dockerfile" |
			sed -e "s,.\+TS3SERVER_SHA256=[\"']\(.\+\)[\"'],\1,"
	)"
	ts3server_url="$(
		grep -E 'TS3SERVER_URL=.+' "$dockerfile" |
			sed -e "s,.\+TS3SERVER_URL=[\"']\(.\+\)[\"'],\1,"
	)"

	# JSON looks like this:
	# {
	#   "<OS>": {
	#     "<ARCH>": {
	#       "version": "<VERSION>",
	#       "checksum": "<SHA256>",
	#       "mirrors": {
	#         "<HOSTNAME>": "<URL>"
	#       }
	#     },
	#     // …
	#   },
	#   // …
	# }
	# OS: windows|macos|linus
	# ARCH: x86_64|x86
	new_ts3server_version_json="$(jq -c .linux.x86_64 <<<"$teamspeak_versions_server_json")"
	new_ts3server_version="$(jq -r .version <<<"$new_ts3server_version_json")"
	new_ts3server_sha256="$(jq -r .checksum <<<"$new_ts3server_version_json")"
	new_ts3server_url="$(jq -r '.mirrors | to_entries | .[] | .value' <<<"$new_ts3server_version_json" | head -n1)"

	if [ "$new_ts3server_version" != "$ts3server_version" ]; then
		echo "WARNING: Newest version in remote JSON mismatches version in Dockerfile." >&2
	fi

	# derive platform-specific download url from x86_64 provided one
	new_ts3server_url_fixed="${new_ts3server_url//amd64/${platform}}"

	# get correct sha256 sum for the platform if it differs
	if [ "$new_ts3server_url_fixed" != "new_ts3server_url" ]; then
		new_ts3server_sha256=$(curl -sL "${new_ts3server_url_fixed}" |
			sha256sum - |
			awk '{print $1}')
	fi

	echo "> $ts3server_version => $new_ts3server_version" >&2
	echo "> $ts3server_sha256 => $new_ts3server_sha256" >&2
	echo "> $new_ts3server_url => $new_ts3server_url_fixed" >&2

	# replace fixed URL parts with variables in Dockerfile
	# shellcheck disable=SC2016
	new_ts3server_url="${new_ts3server_url_fixed//${new_ts3server_version}/'${TS3SERVER_VERSION}'}"
	# shellcheck disable=SC2016
	new_ts3server_url="${new_ts3server_url//${platform}/'${TS3SERVER_VARIANT}'}"

	sed -i \
		-e "s#\b${ts3server_version}\b#${new_ts3server_version}#g" \
		-e "s#\b${ts3server_sha256}\b#${new_ts3server_sha256}#g" \
		-e "s#\b${ts3server_url}\b#${new_ts3server_url}#g" \
		"${dockerfile}"
}

for dockerfile in *.Dockerfile Dockerfile; do
	if [ -f "$dockerfile" ]; then
		update_checksum_for_dockerfile "$dockerfile"
	fi
done
