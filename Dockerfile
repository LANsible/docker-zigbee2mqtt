ARG ARCHITECTURE
#######################################################################################################################
# Nexe packaging of binary
#######################################################################################################################
FROM lansible/nexe:4.0.0-beta.6-${ARCHITECTURE} as builder

ENV VERSION=1.17.0

# Add unprivileged user
RUN echo "zigbee2mqtt:x:1000:1000:zigbee2mqtt:/:" > /etc_passwd
# Add to dailout as secondary group (20)
RUN echo "dailout:x:20:zigbee2mqtt" > /etc_group

# eudev: needed for udevadm binary
RUN apk --no-cache add \
  eudev

RUN git clone --depth 1 --single-branch --branch ${VERSION} https://github.com/Koenkk/zigbee2mqtt.git /zigbee2mqtt

WORKDIR /zigbee2mqtt

# Makeflags source: https://math-linux.com/linux/tip-of-the-day/article/speedup-gnu-make-build-and-compilation-process
RUN CORES=$(grep -c '^processor' /proc/cpuinfo); \
  export MAKEFLAGS="-j$((CORES+1)) -l${CORES}"; \
  npm ci --production

# Package the binary
# Create /data to copy into final stage
RUN nexe --build --target alpine --output zigbee2mqtt && \
  mkdir /data

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
COPY --from=builder /etc_group /etc/group

# Serialport is using the udevadm binary
COPY --from=builder /bin/udevadm /bin/udevadm

# Copy needed libs(libstdc++.so, libgcc_s.so) for nodejs since it is partially static
# Copy linker to be able to use them (lib/ld-musl)
# Can't be fullly static since @serialport uses a C++ node addon
# https://github.com/serialport/node-serialport/blob/master/packages/bindings/lib/linux.js#L2
COPY --from=builder /lib/ld-musl-*.so.1 /lib/
COPY --from=builder \
  /usr/lib/libstdc++.so.6 \
  /usr/lib/libgcc_s.so.1 \
  /usr/lib/

# Copy zigbee2mqtt binary
COPY --from=builder /zigbee2mqtt/zigbee2mqtt /zigbee2mqtt/zigbee2mqtt

# NOTE: don't try to remove one, both zigbee2mqtt and zigbee-herdsman need the bindings file
# Just 78kb so not worth symlink
# FUTURE: when RUN --mount makes it to kaniko symlinking is an option again
COPY --from=builder \
  /zigbee2mqtt/node_modules/zigbee-herdsman/node_modules/@serialport/bindings/build/Release/bindings.node \
  /zigbee2mqtt/build/bindings.node
COPY --from=builder \
  /zigbee2mqtt/node_modules/zigbee-herdsman/node_modules/@serialport/bindings/build/Release/bindings.node \
  /zigbee2mqtt/node_modules/zigbee-herdsman/build/bindings.node

# Create default data directory
# Will fail at runtime due missing the mkdir binary
COPY --from=builder /data /data

# Add example config, also create the /config dir
COPY examples/compose/config/configuration.yaml ${ZIGBEE2MQTT_CONFIG}

USER zigbee2mqtt
WORKDIR /zigbee2mqtt
ENTRYPOINT ["./zigbee2mqtt"]
