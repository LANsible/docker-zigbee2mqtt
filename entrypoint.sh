#!/bin/sh

# Create symlinks when config mounted, else exit
if [ -d "/config" ]; then
    for file in /config/*; do
        filename=$(basename $file)
        ln -sf /config/$filename /dev/shm/$filename
    done
else
  echo "No /config found, please mount config to container"
  exit 1
fi

# Create symlink for .storage directory
# Create symlink for state.json:
# https://github.com/Koenkk/zigbee2mqtt/commit/9396bde1f3b022e0f634487d1a37d2a5127c8cb3#diff-f68567477d803b49930337bf7fe1556bR16
if [ -d "/data" ]; then
    ln -sf /data /dev/shm/.storage
    ln -sf /data/state.json /dev/shm/state.json
fi

# Start zigbee2mqtt
exec "$@"