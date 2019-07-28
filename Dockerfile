FROM alpine:3.10 as builder

ARG VERSION=master

LABEL maintainer="wilmardo" \
      description="Zigbee2MQTT from scratch"

RUN addgroup -S -g 8123 zigbee2mqtt 2>/dev/null && \
    adduser -S -u 8123 -D -H -h /dev/shm -s /sbin/nologin -G zigbee2mqtt -g zigbee2mqtt zigbee2mqtt 2>/dev/null && \
    addgroup zigbee2mqtt dialout

RUN apk --no-cache add \
        git \
        python \
        make \
        gcc \
        g++ \
        linux-headers \
        udev \
        npm \
        upx

RUN git clone --depth 1 --branch "${VERSION}" https://github.com/Koenkk/zigbee2mqtt.git /zigbee2mqtt

WORKDIR /zigbee2mqtt

# Makeflags source: https://math-linux.com/linux/tip-of-the-day/article/speedup-gnu-make-build-and-compilation-process
# NOTE(wilmardo): --build is needed for dynamic require that serialport/bindings seems to use
# NOTE(wilmardo): For the upx steps and why --empty see: https://github.com/nexe/nexe/issues/366
RUN CORES=$(grep -c '^processor' /proc/cpuinfo); \
    export MAKEFLAGS="-j$((CORES+1)) -l${CORES}"; \
    npm install --unsafe-perm && \
    npm install --unsafe-perm --global nexe && \
    nexe \
      --build \
      --empty \
      --output zigbee2mqtt && \
    upx --best /root/.nexe/*/out/Release/node && \
    nexe \
      --build \
      --output zigbee2mqtt

# Create symlink
RUN ln -sf /config/$filename /dev/shm/$filename

FROM scratch

ENV ZIGBEE2MQTT_DATA=/dev/shm

# Copy /bin/sh to be able to use an entrypoint
COPY --from=builder /bin/sh /bin/sh

# Copy users from builder
COPY --from=builder \
    /etc/passwd \
    /etc/group \
    /etc/

# Copy needed libs
COPY --from=builder \
        /lib/ld-musl-*.so.1 \
        /lib/libc.musl-*.so.1 \
        /lib/
COPY --from=builder \
        /usr/lib/libstdc++.so.6 \
        /usr/lib/libgcc_s.so.1 \
        /usr/lib/

# Copy zigbee2mqtt binary and stupid dynamic @serialport
COPY --from=builder /zigbee2mqtt/zigbee2mqtt /zigbee2mqtt/zigbee2mqtt
COPY --from=builder \
  /zigbee2mqtt/node_modules/zigbee-herdsman/node_modules/@serialport/bindings/ \
  /zigbee2mqtt/node_modules/zigbee-herdsman/node_modules/@serialport/bindings/

# Adds entrypoint
COPY ./entrypoint.sh /entrypoint.sh

USER zigbee2mqtt
ENTRYPOINT [ "/entrypoint.sh" ]
WORKDIR /zigbee2mqtt
CMD ["./zigbee2mqtt"]
