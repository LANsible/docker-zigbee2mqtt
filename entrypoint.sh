#!/bin/sh

# Create aliases to busybox
alias basename="/bin/busybox basename"
alias ln="/bin/busybox ln"
alias mkdir="/bin/busybox mkdir"

# Create symlinks when config mounted, else exit
if [ ! -d "/data" ]; then
  echo "No /data found, please data volume to container"
  exit 1
fi
# Print warning when no config was found, could be intentional
if [ ! -d "/config" ]; then
  echo "No /config found, no symlink will be created"
fi

# For each config file create a symlink
for file in /config/*; do
  filename=$(basename "$file")
  # Create symlink when it does not exist yet
  if [ ! -L "/data/$filename" ]; then
    echo "Creating symlink from /config/$filename to /data/$filename"
    ln -sf "/config/$filename" "/data/$filename"
  fi
done

# Start docker CMD
exec "$@"
