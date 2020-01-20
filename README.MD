# Zigbee2MQTT from scratch!
[![Build Status](https://cloud.drone.io/api/badges/LANsible/docker-zigbee2mqtt/status.svg)](https://cloud.drone.io/LANsible/docker-zigbee2mqtt)
[![Docker Pulls](https://img.shields.io/docker/pulls/lansible/zigbee2mqtt.svg)](https://hub.docker.com/r/lansible/zigbee2mqtt)
[![Docker Version](https://images.microbadger.com/badges/version/lansible/zigbee2mqtt:latest.svg)](https://microbadger.com/images/lansible/zigbee2mqtt:latest)
[![Docker Size/Layers](https://images.microbadger.com/badges/image/lansible/zigbee2mqtt:latest.svg)](https://microbadger.com/images/lansible/zigbee2mqtt:latest)

## Why not use the official container?

It does not work on Kubernetes with a configmap since it tries to create the database.db, state.json etc in the directory where the config is mounted.
This container allows this setup to work flawlessly!
Also it is super small since Zigbee2Mqtt is build as a single binary and put into a FROM scratch container.
The container run as user 1000 with primary group 1000 and dailout(20) as secondary group for tty access.

## Test container with docker-compose

```
cd examples/compose
docker-compose up
```

### Building the container locally

You could build the container locally like this:

```bash
docker build . \
      --build-arg ARCHITECTURE=amd64 \
      --tag lansible/zigbee2mqtt:dev-amd64
```
The arguments are:

| Build argument | Description                                    | Example                 |
|----------------|------------------------------------------------|-------------------------|
| `ARCHITECTURE` | For what architecture to build the container   | `arm64`                 |

Available architectures are what `lansible/nexe` supports:
https://hub.docker.com/r/lansible/nexe/tags

## Credits

* [Koenkk/zigbee2mqtt](https://github.com/Koenkk/zigbee2mqtt)