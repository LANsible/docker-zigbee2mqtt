#!/bin/sh

# Create symlinks when config mounted, else exit
if [ -d "/config" ]; then
  # For each config file create a symlink
  for file in /config/*; do
    filename=$(basename "$file")
    # Create symlink when it does not exist yet
    if [ ! -L "/dev/shm/$filename" ]; then
      echo "Creating symlink from /config/$filename to /dev/shm/$filename"
      ln -sf "/config/$filename" "/dev/shm/$filename"
    fi
  done
else
  echo "No /config found, please mount config to container"
  exit 1
fi

# Create symlink for .storage directory
# Create symlink for state.json:
# https://github.com/Koenkk/zigbee2mqtt/commit/9396bde1f3b022e0f634487d1a37d2a5127c8cb3#diff-f68567477d803b49930337bf7fe1556bR16
if [ -d "/data" ]; then
  # Create .storage dir when not already there
  if [ ! -d "/data/.storage" ]; then
    echo "Creating /data/.storage directory"
    mkdir /data/.storage
  fi

  # Create symlinks needed for persistance
  # devices.yml and group.yml are appended to when joining
  for symlink in .storage state.json database.db devices.yaml groups.yaml; do
    if [ ! -L "/dev/shm/$symlink" ]; then
      echo "Creating symlink from /data/$symlink to /dev/shm/$symlink"
      ln -sf "/data/$symlink" "/dev/shm/$symlink"
    fi
  done
fi

# Start zigbee2mqtt
exec "$@"