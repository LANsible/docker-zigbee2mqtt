# Inspired from https://github.com/seblucas/alpine-homeassistant
ARG ARCH=amd64
FROM multiarch/alpine:${ARCH}-v3.9 as builder

ARG VERSION=master
ARG ARCH=amd64

RUN apk --no-cache add \
        git \
        make \
        gcc \
        g++ \
        python \
        linux-headers \
        udev \
        nodejs \
        npm \
        libstdc++ \
        libgcc

RUN git clone --depth 1 --branch "${VERSION}" https://github.com/Koenkk/zigbee2mqtt.git /zigbee2mqtt

WORKDIR /zigbee2mqtt

RUN npm install --unsafe-perm && npm install --unsafe-perm --global pkg
RUN if [ "$ARCH" = "amd64" ]; then target=node10-alpine-x64; elif [ "$ARCH" = "aarch64" ]; then target=node10-alpine-arm64; fi \
    && pkg --targets ${target} --options expose-gc --output zigbee2mqtt index.js

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
COPY --from=builder /zigbee2mqtt/node_modules/cc-znp /zigbee2mqtt/node_modules/cc-znp
COPY --from=builder /zigbee2mqtt/data/ /app/data

WORKDIR /zigbee2mqtt
CMD ["./zigbee2mqtt"]