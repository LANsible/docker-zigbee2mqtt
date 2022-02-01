# Zigbee2MQTT from scratch!
[![Build Status](https://gitlab.com/lansible1/docker-zigbee2mqtt/badges/master/pipeline.svg)](https://gitlab.com/lansible1/docker-zigbee2mqtt/pipelines)
[![Docker Pulls](https://img.shields.io/docker/pulls/lansible/zigbee2mqtt.svg)](https://hub.docker.com/r/lansible/zigbee2mqtt)
[![Docker Version](https://img.shields.io/docker/v/lansible/zigbee2mqtt?sort=semver)](https://hub.docker.com/r/lansible/zigbee2mqtt)
[![Docker Image Size](https://img.shields.io/docker/image-size/lansible/zigbee2mqtt?sort=semver)](https://hub.docker.com/r/lansible/zigbee2mqtt)

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
docker run --privileged --rm tonistiigi/binfmt --install all
docker buildx build --load --platform linux/amd64 . -t test
```

Available architectures are what `lansible/nexe` supports:
https://hub.docker.com/r/lansible/nexe/tags

## Credits

* [Koenkk/zigbee2mqtt](https://github.com/Koenkk/zigbee2mqtt)