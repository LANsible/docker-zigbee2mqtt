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
        npm \
        upx

# Build NodeJS seperatly to enable docker caching
RUN npm install --unsafe-perm --global nexe && \
    nexe --build

RUN git clone --depth 1 --branch "${VERSION}" https://github.com/Koenkk/zigbee2mqtt.git /zigbee2mqtt

WORKDIR /zigbee2mqtt

# NOTE(wilmardo): --build is needed for dynamic require that serialport/bindings seems to use
RUN npm install --unsafe-perm && \
    nexe -o zigbee2mqtt \
      --build \
      -r node_modules/cc-znp/node_modules/serialport && \
    upx --best zigbee2mqtt

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
COPY --from=builder /zigbee2mqtt/data/ /app/data

WORKDIR /zigbee2mqtt
CMD ["./zigbee2mqtt"]
