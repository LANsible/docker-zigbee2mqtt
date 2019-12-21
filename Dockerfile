#######################################################################################################################
# Nexe packaging of binary
#######################################################################################################################
FROM lansible/nexe:latest as builder

ENV VERSION=dev

# Add unprivileged user
RUN echo "zigbee2mqtt:x:1000:1000:zigbee2mqtt:/:" > /etc_passwd

# eudev: needed for udevadm binary
RUN apk --no-cache add \
  eudev

RUN git clone --depth 1 --single-branch --branch ${VERSION} https://github.com/Koenkk/zigbee2mqtt.git /zigbee2mqtt

WORKDIR /zigbee2mqtt

# Makeflags source: https://math-linux.com/linux/tip-of-the-day/article/speedup-gnu-make-build-and-compilation-process
RUN CORES=$(grep -c '^processor' /proc/cpuinfo); \
  export MAKEFLAGS="-j$((CORES+1)) -l${CORES}"; \
  npm install --unsafe-perm

# Package the binary
RUN nexe --build --target alpine --output zigbee2mqtt


#######################################################################################################################
# Final scratch image
#######################################################################################################################
FROM scratch

# Set env vars for persitance
ENV ZIGBEE2MQTT_CONFIG=/config/configuration.yaml \
    ZIGBEE2MQTT_DATA=/data

# Add description
LABEL org.label-schema.description="Zigbee2MQTT as single binary in a scratch container"

# Copy the unprivileged user
COPY --from=builder /etc_passwd /etc/passwd

# Serialport is using the udevadm binary
COPY --from=builder /bin/udevadm /bin/udevadm

# Copy needed libs(libstdc++.so, libgcc_s.so) for nodejs since it is partially static
# Copy linker to be able to use them (lib/ld-musl)
# Can't be fullly static since @serialport uses a C++ node addon
# https://github.com/serialport/node-serialport/blob/master/packages/bindings/lib/linux.js#L2
COPY --from=builder \
  /lib/ld-musl-*.so.* \
  /usr/lib/libstdc++.so.* \
  /usr/lib/libgcc_s.so.* \
  /lib/

# Copy zigbee2mqtt binary
COPY --from=builder /zigbee2mqtt/zigbee2mqtt /zigbee2mqtt/zigbee2mqtt

# Add bindings file needed for serialport
COPY --from=builder \
  /zigbee2mqtt/node_modules/zigbee-herdsman/node_modules/@serialport/bindings/build/Release/bindings.node \
  /zigbee2mqtt/build/bindings.node

# Add static busybox for symlinking
COPY --from=builder /bin/busybox.static /bin/busybox.static

# Symlink bindings to directory for zigbee-herdsman
# NOTE: don't try to remove one, both zigbee2mqtt and zigbee-herdsman need the bindings file
RUN ["/bin/busybox.static", "mkdir", "-p", "/zigbee2mqtt/node_modules/zigbee-herdsman/build"]
RUN ["/bin/busybox.static", "ln", "-sf", "/zigbee2mqtt/build/bindings.node", "/zigbee2mqtt/node_modules/zigbee-herdsman/build/bindings.node"]

# Create default data directory
# Will fail at runtime due missing the mkdir binary
RUN ["/bin/busybox.static", "mkdir", "/data"]

# Let busybox remove itself
RUN ["/bin/busybox.static", "rm", "-s", "/bin/busybox.static"]

# Add example config
COPY examples/compose/config/configuration.yaml ${ZIGBEE2MQTT_CONFIG}

USER zigbee2mqtt
WORKDIR /zigbee2mqtt
ENTRYPOINT ["./zigbee2mqtt"]
