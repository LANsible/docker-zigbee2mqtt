#######################################################################################################################
# Nexe packaging of binary
#######################################################################################################################
FROM lansible/nexe:4.0.0-rc.2 as builder

# https://github.com/docker/buildx#building-multi-platform-images
ARG TARGETPLATFORM
# https://github.com/Koenkk/zigbee2mqtt/releases
ENV VERSION=1.32.1

# Add unprivileged user
RUN echo "zigbee2mqtt:x:1000:1000:zigbee2mqtt:/:" > /etc_passwd
# Add to dailout as secondary group (20)
RUN echo "dailout:x:20:zigbee2mqtt" > /etc_group

# eudev: needed for udevadm binary
RUN apk --no-cache add \
  eudev

RUN git clone --depth 1 --single-branch --branch ${VERSION} https://github.com/Koenkk/zigbee2mqtt.git /zigbee2mqtt

WORKDIR /zigbee2mqtt

# Install all modules
# Save hash file otherwise will start building on startup
# Run build to make all html files
# Serialport needs to be rebuild for Alpine https://serialport.io/docs/9.x.x/guide-installation#alpine-linux
RUN CORES=$(grep -c '^processor' /proc/cpuinfo); \
  export MAKEFLAGS="-j$((CORES+1)) -l${CORES} CFLAGS=-fuse-ld=mold"; \
  npm ci --no-audit --omit=optional --no-update-notifier && \
  npm run build && \
  npm ci --no-audit --omit=optional --omit=dev --no-update-notifier && \
  echo $(git rev-parse --short HEAD) > dist/.hash

# Remove all unneeded prebuilds
RUN if [ "$TARGETPLATFORM" = "linux/amd64" ]; then \
    export TARGETPLATFORM="linux/x64"; \
  fi && \
  export PLATFORM=${TARGETPLATFORM/\//-}; \
  find . -name *.node -path *prebuilds/* -not -path *${PLATFORM}* -name *.node -delete && \
  find . -name *.glibc.node -path *prebuilds/* -delete

# Package the binary
# zigbee2mqtt dist contains typescript compile
# .hash need explicit resource otherwise not matched
# frontend/dist contains the frontend compiled stuff
# devices and lib are both needed at runtime
# Create /data to copy into final stage
RUN nexe --build \
    --resource dist/ \
    --resource dist/.hash \
    --resource lib/ \
    --resource node_modules/zigbee2mqtt-frontend/dist \
    --resource node_modules/zigbee-herdsman-converters/devices \
    --resource node_modules/zigbee-herdsman-converters/lib \
    --resource node_modules/deep-object-diff \
    --input index.js \
    --output zigbee2mqtt && \
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

# Add bindings.node for serialport
COPY --from=builder \
  /zigbee2mqtt/node_modules/@serialport/bindings-cpp/prebuilds/ \
  /zigbee2mqtt/node_modules/@serialport/bindings-cpp/prebuilds/

# Create default data directory
# Will fail at runtime due missing the mkdir binary
COPY --from=builder /data /data

# Add example config, also create the /config dir
COPY examples/compose/config/configuration.yaml ${ZIGBEE2MQTT_CONFIG}

EXPOSE 8080
USER zigbee2mqtt
WORKDIR /zigbee2mqtt
ENTRYPOINT ["./zigbee2mqtt"]
