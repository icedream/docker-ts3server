FROM debian:9

# Add "app" user
RUN mkdir -p /tmp/empty \
	&& groupadd -g 9999 app \
	&& useradd -d /data -l -N -g app -m -k /tmp/empty -u 9999 app \
	&& rmdir /tmp/empty

# Prepare data volume
RUN mkdir -p /data && chown app:app /data
WORKDIR /data

ARG TS3SERVER_VERSION="3.4.0"
ARG TS3SERVER_URL="http://teamspeak.gameserver.gamed.de/ts3/releases/${TS3SERVER_VERSION}/teamspeak3-server_linux_amd64-${TS3SERVER_VERSION}.tar.bz2"
#ARG TS3SERVER_URL="http://dl.4players.de/ts/releases/${TS3SERVER_VERSION}/teamspeak3-server_linux_amd64-${TS3SERVER_VERSION}.tar.bz2"
ARG TS3SERVER_SHA256="7d6ec8e97d4a9e9913a7e01f2e7f5f9fddfdc41b11e668d013a0f4b574d1918b"
ARG TS3SERVER_SHA384=""
ARG TS3SERVER_TAR_ARGS="-j"
ARG TS3SERVER_INSTALL_DIR="/opt/ts3server"

# Set up server
ADD ${TS3SERVER_URL} "/ts3server.tar.bz2"
RUN \
	export INITRD=no \
	&& export DEBIAN_FRONTEND=noninteractive \
\
	&& apt-get update \
	&& apt-get install -y --no-install-recommends \
		ca-certificates \
		libmariadb2 \
		tar \
		bzip2 \
		gzip \
		xz-utils \
	&& apt-mark auto \
		tar \
		bzip2 \
		gzip \
		xz-utils \
\
	&& ( \
		[ ! -z "${TS3SERVER_SHA384}" ] \
		&& TS3SERVER_ACTUAL_SHA384="$(sha384sum /ts3server.tar.bz2 | awk '{print $1}')" \
		&& if [ "${TS3SERVER_ACTUAL_SHA384}" != "${TS3SERVER_SHA384}" ]; then \
			echo "Invalid checksum: ${TS3SERVER_ACTUAL_SHA384} != ${TS3SERVER_SHA384}" >&2; \
			exit 1; \
		fi \
	) || ( \
		[ ! -z "${TS3SERVER_SHA256}" ] \
		&& TS3SERVER_ACTUAL_SHA256="$(sha256sum /ts3server.tar.bz2 | awk '{print $1}')" \
		&& if [ "${TS3SERVER_ACTUAL_SHA256}" != "${TS3SERVER_SHA256}" ]; then \
			echo "Invalid checksum: ${TS3SERVER_ACTUAL_SHA256} != ${TS3SERVER_SHA256}" >&2; \
			exit 1; \
		fi \
	) || ( \
		echo "No hash configured!" \
		&& exit 1 \
	) \
\
	&& mkdir -vp "${TS3SERVER_INSTALL_DIR}" \
	&& tar -v -C "${TS3SERVER_INSTALL_DIR}" -xf /ts3server.tar.bz2 --strip 1 \
		${TS3SERVER_TAR_ARGS} teamspeak3-server_linux_amd64/ \
	&& rm -vfr \
		/ts3server.tar.bz2 \
		"${TS3SERVER_INSTALL_DIR}"/*.sh \
		"${TS3SERVER_INSTALL_DIR}"/CHANGELOG \
		"${TS3SERVER_INSTALL_DIR}"/doc \
		"${TS3SERVER_INSTALL_DIR}"/redist \
		"${TS3SERVER_INSTALL_DIR}"/tsdns \
	&& chown -v root:root -R "${TS3SERVER_INSTALL_DIR}" \
	&& chmod -v g-w,o-w -R "${TS3SERVER_INSTALL_DIR}" \
\
	&& ln -vs ${TS3SERVER_INSTALL_DIR}/ts3server /usr/local/bin/ts3server \
\
	&& apt-get autoremove -y --purge \
	&& apt-get clean \
	&& rm -vfr \
		/tmp/* \
		/var/tmp/* \
		/var/lib/apt/lists/*

# Prepare runtime
ENV LD_LIBRARY_PATH ${TS3SERVER_INSTALL_DIR}
USER app
# Can't use $TS3SERVER_INSTALL_DIR here because ENTRYPOINT does not accept variables
ENTRYPOINT [ "ts3server", "dbsqlpath=/opt/ts3server/sql/", "serverquerydocs_path=/opt/ts3server/serverquerydocs/", "query_ip_whitelist=/data/query_ip_whitelist.txt", "query_ip_blacklist=/data/query_ip_blacklist.txt", "createinifile=1" ]

EXPOSE 9987/udp 10011 30033 41144
