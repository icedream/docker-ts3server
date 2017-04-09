FROM frolvlad/alpine-glibc:alpine-3.5_glibc-2.24

ARG TS3SERVER_URL="http://teamspeak.gameserver.gamed.de/ts3/releases/3.0.13.6/teamspeak3-server_linux_amd64-3.0.13.6.tar.bz2"
ARG TS3SERVER_SHA384="c126cb43098c3ccd8f0eaaa871cc128ecda21261a1a862815ffc5bd6e8ed8dd45dff862a222ccfebe670a6dd5df4dfbb"

ADD ${TS3SERVER_URL} "/ts3server.tar.bz2"
RUN \
  apk --no-cache add --virtual .build-deps \
    coreutils \
    tar \
    && \
\
  echo "Validating checksum..." && \
  TS3SERVER_ACTUAL_SHA384="$(sha384sum /ts3server.tar.bz2 | awk '{print $1}')" && \
  if [ "${TS3SERVER_ACTUAL_SHA384}" != "${TS3SERVER_SHA384}" ]; then echo "Invalid checksum: ${TS3SERVER_ACTUAL_SHA384} != ${TS3SERVER_SHA384}" >&2; exit 1; fi && \
\
  mkdir -vp /opt/teamspeak3 && \
  tar -v -C /opt/teamspeak3 -xf /ts3server.tar.bz2 --strip 1 && \
\
  rm -vr \
    /ts3server.tar.bz2 \
    && \
  rm -vrf \
    /opt/teamspeak3/*.sh \
    /opt/teamspeak3/CHANGELOG \
    /opt/teamspeak3/doc \
    /opt/teamspeak3/redist \
    /opt/teamspeak3/serverquerydocs \
    /opt/teamspeak3/tsdns \
    /tmp/* \
    /var/tmp/* \
    && \
  ls -lAh /opt/teamspeak3 && \
  apk --no-cache del .build-deps

COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint
RUN chmod +x /usr/local/bin/docker-entrypoint

RUN \
  for path in \
    files \
    logs \
    query_ip_blacklist.txt \
    query_ip_whitelist.txt \
    ts3server.sqlitedb; \
  do \
    ln -vsf "/data/${path}" "/opt/teamspeak3/${path}"; \
  done

ENTRYPOINT ["docker-entrypoint"]
