# syntax=docker/dockerfile:experimental

FROM alpine:3.10 as builder

ENV VERSION=1.7.1

LABEL maintainer="wilmardo" \
  description="Zigbee2MQTT from scratch"

# Add unprivileged user
RUN echo "zigbee2mqtt:x:1000:1000:zigbee2mqtt:/:" > /etc_passwd

# See the upstream Dockerfile for reference:
# https://github.com/Koenkk/zigbee2mqtt/blob/dev/docker/Dockerfile
RUN apk --no-cache add \
  git \
  python \
  make \
  gcc \
  g++ \
  linux-headers \
  eudev \
  npm \
  upx

RUN git clone --depth 1 --single-branch --branch ${VERSION} https://github.com/Koenkk/zigbee2mqtt.git /zigbee2mqtt

WORKDIR /zigbee2mqtt

# Makeflags source: https://math-linux.com/linux/tip-of-the-day/article/speedup-gnu-make-build-and-compilation-process
RUN CORES=$(grep -c '^processor' /proc/cpuinfo); \
  export MAKEFLAGS="-j$((CORES+1)) -l${CORES}"; \
  npm install --unsafe-perm && \
  npm install --unsafe-perm --global nexe

# NOTE(wilmardo): --build is needed for dynamic require that serialport/bindings seems to use
# NOTE(wilmardo): For the upx steps and why --empty see: https://github.com/nexe/nexe/issues/366
RUN nexe \
    --build \
    --empty \
    --output zigbee2mqtt && \
  upx --best /root/.nexe/*/out/Release/node

RUN nexe \
    --build \
    --output zigbee2mqtt

FROM scratch

ENV ZIGBEE2MQTT_DATA=/data

# Copy the unprivileged user
COPY --from=builder /etc_passwd /etc/passwd

# Copy /bin/busybox to be able to use an entrypoint
# Entrypoint uses basename, mkdir and ln
# udevadm binary is used by zigbee2mqtt
COPY --from=builder \
  /bin/busybox \
  /bin/udevadm \
  /bin/

# Copy needed libs
COPY --from=builder \
  /lib/ld-musl-*.so.1 \
  /lib/libc.musl-*.so.1 \
  /lib/
COPY --from=builder \
  /usr/lib/libstdc++.so.6 \
  /usr/lib/libgcc_s.so.1 \
  /usr/lib/

# Copy zigbee2mqtt binary and bindings for @serialport
COPY --from=builder /zigbee2mqtt/zigbee2mqtt /zigbee2mqtt/zigbee2mqtt
COPY --from=builder \
  /zigbee2mqtt/node_modules/zigbee-herdsman/node_modules/@serialport/bindings/build/Release/bindings.node \
  /zigbee2mqtt/build/bindings.node

# Symlink bindings to directory for zigbee-herdsman
RUN ["/bin/busybox", "mkdir", "-p", "/zigbee2mqtt/node_modules/zigbee-herdsman/build"]
RUN ["/bin/busybox", "ln", "-sf", "/zigbee2mqtt/build/bindings.node", "/zigbee2mqtt/node_modules/zigbee-herdsman/build/bindings.node"]

# Adds entrypoint
COPY ./entrypoint.sh /entrypoint.sh

USER zigbee2mqtt
ENTRYPOINT ["/bin/busybox", "ash", "/entrypoint.sh" ]
WORKDIR /zigbee2mqtt
CMD ["./zigbee2mqtt"]
