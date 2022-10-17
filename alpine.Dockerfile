FROM busybox

COPY *.sh /target/usr/local/bin/
RUN chmod +x /target/usr/local/bin/*

###

FROM alpine:3.13

# Add "app" user
RUN mkdir -p /tmp/empty \
	&& addgroup -g 9999 app \
	&& adduser -G app -u 9999 -D app \
	&& rmdir /tmp/empty

# Prepare data volume
RUN mkdir -p /data && chown app:app /data
WORKDIR /data

ARG TS3SERVER_VERSION="3.13.7"
# Possible values are alpine, amd64, x86
ARG TS3SERVER_VARIANT="alpine"
ARG TS3SERVER_URL="https://files.teamspeak-services.com/releases/server/${TS3SERVER_VERSION}/teamspeak3-server_linux_${TS3SERVER_VARIANT}-${TS3SERVER_VERSION}.tar.bz2"
ARG TS3SERVER_SHA256="359aac972679cfd98d62af51ddaf80e674cab166e13c6a835e81759097f9ba2e"
ARG TS3SERVER_TAR_ARGS="-j"
ENV TS3SERVER_INSTALL_DIR="/opt/ts3server"

# Set up server
ADD ${TS3SERVER_URL} "/ts3server.tar.bz2"
RUN \
	apk --no-cache add \
		bash \
		libstdc++ \
		tzdata \
		ca-certificates \
	&& apk --no-cache add --virtual .build-deps \
		coreutils \
		tar \
		bzip2 \
		gzip \
		xz \
\
	&& ( \
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
		${TS3SERVER_TAR_ARGS} teamspeak3-server_linux_${TS3SERVER_VARIANT}/ \
	&& mv -v "${TS3SERVER_INSTALL_DIR}"/redist/libmariadb*.so* "${TS3SERVER_INSTALL_DIR}" \
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
	&& apk --no-cache del .build-deps \
	&& rm -vfr \
		/tmp/* \
		/var/tmp/* \
		/var/lib/apt/lists/*

COPY --from=0 /target/ /

USER app
ENTRYPOINT [ "docker-ts3server-entrypoint.sh" ]

EXPOSE 9987/udp 10011 10022 10080 10443 30033 41144
