# Zigbee2MQTT
[![Build Status](https://cloud.drone.io/api/badges/LANsible/docker-zigbee2mqtt/status.svg)](https://cloud.drone.io/LANsible/docker-zigbee2mqtt)
[![Docker Pulls](https://img.shields.io/docker/pulls/lansible/zigbee2mqtt.svg)](https://hub.docker.com/r/lansible/zigbee2mqtt)
[![Docker Version](https://images.microbadger.com/badges/version/lansible/zigbee2mqtt:latest.svg)](https://microbadger.com/images/lansible/zigbee2mqtt:latest)
[![Docker Size/Layers](https://images.microbadger.com/badges/image/lansible/zigbee2mqtt:latest.svg)](https://microbadger.com/images/lansible/zigbee2mqtt:latest)

## Why not use the official container?

It does not work on Kubernetes with a configmap since it tries to create the database.db, state.json etc in the directory where the config is mounted.
This container allows this setup to work flawlessly!

## Test container with docker-compose

```
cd examples/compose
docker-compose up
```

### Building the container locally

You could build the container locally to add plugins. It works like this:

```bash
docker build . \
      --build-arg VERSION=1.4.0 \
      --tag lansible/zigbee2mqtt:1.4.0
```
The arguments are:

| Build argument | Description                                    | Example                 |
|----------------|------------------------------------------------|-------------------------|
| `VERSION`      | Version of Zigbee2MQTT                         | `1.4.0`                 |

## Credits

* [Koenkk/zigbee2mqtt](https://github.com/Koenkk/zigbee2mqtt)