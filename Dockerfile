# Inspired from https://github.com/seblucas/alpine-homeassistant
ARG ARCH=amd64
FROM multiarch/alpine:${ARCH}-v3.9 as builder

ARG VERSION=master

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

RUN npm install --unsafe-perm
RUN npm install -g pkg
RUN pkg --targets node10-alpine-x64 --options expose-gc --output zigbee2mqtt index.js

FROM multiarch/alpine:${ARCH}-v3.9

ENV ZIGBEE2MQTT_DATA=/app/data

COPY --from=builder \
        /usr/lib/libstdc++.so.6 \
        /usr/lib/libgcc_s.so.1 \
        /usr/lib/
COPY --from=builder /zigbee2mqtt/zigbee2mqtt /zigbee2mqtt/zigbee2mqtt
COPY --from=builder /zigbee2mqtt/node_modules/cc-znp /zigbee2mqtt/node_modules/cc-znp
COPY --from=builder /zigbee2mqtt/data/ /app/data

WORKDIR /zigbee2mqtt
CMD ["./zigbee2mqtt"]