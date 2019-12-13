# syntax=docker/dockerfile:experimental

FROM lansible/nexe:latest as builder

ENV VERSION=1.7.1

LABEL maintainer="wilmardo" \
  description="Zigbee2MQTT from scratch"

# Add unprivileged user
RUN echo "zigbee2mqtt:x:1000:1000:zigbee2mqtt:/:" > /etc_passwd

# git: needed for git clone
# python, build-base, linux-headers: needed for compile of serialport
# https://serialport.io/docs/guide-installation#alpine-linux
# npm: needed for node_modules install
# eudev: needed for udevadm binary
RUN apk --no-cache add \
  git \
  make \
  gcc \
  g++ \
  python \
  linux-headers \
  npm \
  eudev

# RUN git clone --depth 1 --single-branch --branch ${VERSION} https://github.com/Koenkk/zigbee2mqtt.git /zigbee2mqtt
RUN git clone --depth 1 --single-branch --branch my-dev https://github.com/wilmardo/zigbee2mqtt.git /zigbee2mqtt

WORKDIR /zigbee2mqtt

# Makeflags source: https://math-linux.com/linux/tip-of-the-day/article/speedup-gnu-make-build-and-compilation-process
RUN CORES=$(grep -c '^processor' /proc/cpuinfo); \
  export MAKEFLAGS="-j$((CORES+1)) -l${CORES}"; \
  npm install --unsafe-perm

RUN nexe --build --target alpine --output zigbee2mqtt

FROM scratch

ENV ZIGBEE2MQTT_CONFIG=/config/configuration.yaml \
    ZIGBEE2MQTT_DATA=/data

# Copy the unprivileged user
COPY --from=builder /etc_passwd /etc/passwd

# Serialport is using the udevadm binary
COPY --from=builder /bin/udevadm /bin/udevadm

# Copy needed libs for nodejs since it is partially static
COPY --from=builder \
  /usr/lib/libstdc++.so.* \
  /usr/lib/libgcc_s.so.* \
  /usr/lib/

# Copy zigbee2mqtt binary
COPY --from=builder /zigbee2mqtt/zigbee2mqtt /zigbee2mqtt/zigbee2mqtt

# Add example config
COPY examples/compose/config/configuration.yaml ${ZIGBEE2MQTT_CONFIG}

# Add bindings file needed for serialport
COPY --from=builder \
  /zigbee2mqtt/node_modules/zigbee-herdsman/node_modules/@serialport/bindings/build/Release/bindings.node \
  /zigbee2mqtt/build/bindings.node

# Symlink bindings to directory for zigbee-herdsman
# NOTE: don't try to remove one, both zigbee2mqtt and zigbee-herdsman need the bindings file
RUN --mount=from=builder,source=/bin/busybox.static,target=/bin/busybox.static \
  ["/bin/busybox.static", "mkdir", "-p", "/zigbee2mqtt/node_modules/zigbee-herdsman/build"]
RUN --mount=from=builder,source=/bin/busybox.static,target=/bin/busybox.static \
  ["/bin/busybox.static", "ln", "-sf", "/zigbee2mqtt/build/bindings.node", "/zigbee2mqtt/node_modules/zigbee-herdsman/build/bindings.node"]

# Create default data directory
RUN --mount=from=builder,source=/bin/busybox.static,target=/bin/busybox.static \
  ["/bin/busybox.static", "mkdir", "/data"]

USER zigbee2mqtt
WORKDIR /zigbee2mqtt
ENTRYPOINT ["/zigbee2mqtt/zigbee2mqtt"]
