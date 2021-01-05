#######################################################################################################################
# Nexe packaging of binary
#######################################################################################################################
FROM lansible/nexe:master-amd64 as builder

ENV VERSION=1.17.0

# eudev: needed for udevadm binary
RUN apk --no-cache add \
  eudev

RUN git clone --depth 1 --single-branch --branch ${VERSION} https://github.com/Koenkk/zigbee2mqtt.git /zigbee2mqtt

WORKDIR /zigbee2mqtt

# Makeflags source: https://math-linux.com/linux/tip-of-the-day/article/speedup-gnu-make-build-and-compilation-process
RUN CORES=$(grep -c '^processor' /proc/cpuinfo); \
  export MAKEFLAGS="-j$((CORES+1)) -l${CORES}"; \
  npm ci --production

# # Package the binary
# # Create /data to copy into final stage
# RUN nexe --build --target alpine --output zigbee2mqtt && \
#   mkdir /data

ENTRYPOINT /bin/sh