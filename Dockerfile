# QQ has its own desktop, account data and image. Build natively on amd64 or arm64.
ARG BASE_IMAGE=ghcr.io/linuxserver/baseimage-selkies@sha256:7cab02f9222937ad1e704cd904534d69a2300b2406af466241817be0ce1d0493
FROM ${BASE_IMAGE}
ARG TARGETARCH
COPY mobile/requirements*.txt /opt/nas-im-bridge/
COPY scripts/install-qq.sh /opt/nas-im-bridge/install-qq.sh
RUN bash /opt/nas-im-bridge/install-qq.sh "${TARGETARCH}" && \
    python3 -m venv /opt/nas-im-bridge/venv && \
    /opt/nas-im-bridge/venv/bin/python3 -m pip install --no-cache-dir \
        -r /opt/nas-im-bridge/requirements.txt && \
    rm -rf /var/lib/apt/lists/* /opt/nas-im-bridge/install-qq.sh
COPY mobile-services/qq/start /defaults/autostart
RUN chmod 755 /defaults/autostart
ENV CHAT_CLIENT=qq
LABEL org.opencontainers.image.title="nas-im-bridge"
