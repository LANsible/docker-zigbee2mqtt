FROM alpine:3.10 as builder

ARG VERSION=master

LABEL maintainer="wilmardo" \
      description="Zigbee2MQTT from scratch"

RUN apk --no-cache add \
        git \
        python \
        make \
        gcc \
        g++ \
        linux-headers \
        udev \
        npm

RUN git clone --depth 1 --branch "${VERSION}" https://github.com/Koenkk/zigbee2mqtt.git /zigbee2mqtt

WORKDIR /zigbee2mqtt

# Makeflags source: https://math-linux.com/linux/tip-of-the-day/article/speedup-gnu-make-build-and-compilation-process
# NOTE(wilmardo): --build is needed for dynamic require that serialport/bindings seems to use
# NOTE(wilmardo): upx --brute does not work see: https://github.com/nexe/nexe/issues/610#issuecomment-483280452
RUN CORES=$(grep -c '^processor' /proc/cpuinfo); \
    export MAKEFLAGS="-j$((CORES+1)) -l${CORES}"; \
    npm install --unsafe-perm && \
    npm install --unsafe-perm --global nexe && \
    nexe \
      --build \
      --output zigbee2mqtt

FROM scratch

ENV ZIGBEE2MQTT_DATA=/app/data

COPY --from=builder \
        /lib/ld-musl-*.so.1 \
        /lib/libc.musl-*.so.1 \
        /lib/

COPY --from=builder \
        /usr/lib/libstdc++.so.6 \
        /usr/lib/libgcc_s.so.1 \
        /usr/lib/

COPY --from=builder /zigbee2mqtt/zigbee2mqtt /zigbee2mqtt/zigbee2mqtt
COPY --from=builder \
  /zigbee2mqtt/node_modules/zigbee-herdsman/node_modules/@serialport/bindings/ \
  /zigbee2mqtt/node_modules/zigbee-herdsman/node_modules/@serialport/bindings/
COPY --from=builder /zigbee2mqtt/data/ /app/data

WORKDIR /zigbee2mqtt
CMD ["./zigbee2mqtt"]
