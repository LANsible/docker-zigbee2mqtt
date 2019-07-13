FROM alpine:3.10 as builder

ARG VERSION=master

LABEL maintainer="wilmardo" \
      description="Zigbee2MQTT from scratch"

RUN apk --no-cache add \
        git \
        make \
        gcc \
        g++ \
        python \
        linux-headers \
        udev \
        nodejs \
        npm

RUN git clone --depth 1 --branch "${VERSION}" https://github.com/Koenkk/zigbee2mqtt.git /zigbee2mqtt

WORKDIR /zigbee2mqtt

RUN npm install --unsafe-perm && npm install --unsafe-perm --global nexe @zeit/ncc
RUN if [[ $(arch) == "x86_64" ]]; then \
      ncc build index.js && cat dist/index.js | nexe -o zigbee2mqtt; \
    elif [[ $(arch) == "aarch64" ]]; then \
      ncc build index.js && cat dist/index.js | nexe --build -o zigbee2mqtt; \
    fi;

# FROM scratch

# ENV ZIGBEE2MQTT_DATA=/app/data

# COPY --from=builder \
#         /lib/ld-musl-*.so.1 \
#         /lib/libc.musl-*.so.1 \
#         /lib/

# COPY --from=builder \
#         /usr/lib/libstdc++.so.6 \
#         /usr/lib/libgcc_s.so.1 \
#         /usr/lib/

# COPY --from=builder /zigbee2mqtt/zigbee2mqtt /zigbee2mqtt/zigbee2mqtt
# COPY --from=builder /zigbee2mqtt/node_modules/cc-znp /zigbee2mqtt/node_modules/cc-znp
# COPY --from=builder /zigbee2mqtt/data/ /app/data

# WORKDIR /zigbee2mqtt
# CMD ["./zigbee2mqtt"]
