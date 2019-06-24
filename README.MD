# Zigbee2MQTT

## Why not use the official container?

It does not work on Kubernetes with a configmap since it tries to create the deps folder where the config is mounted.
This container allows this setup to work flawlessly!

## Test container with docker-compose

```
cd examples/compose
docker-compose up
```

### Forking the repository

You can easily add plugins to the container by forking the repository and running your own build.

* Change are the `DOCKER_NAMESPACE` and `PLUGINS` variables in the .travis.yml file.
* Enable the repository on travis.org
* Add `DOCKER_USERNAME` and `DOCKER_PASSWORD` to the environment variables on travis.org

### Building the container locally

You could build the container locally to add plugins. It works like this:

```bash
docker build . \
      --build-arg ARCH=amd64 \
      --build-arg VERSION=1.4.0 \
      --tag lansible/zigbee2mqtt:1.4.0
```
The arguments are:

| Build argument | Description                                    | Example                 |
|----------------|------------------------------------------------|-------------------------|
| `ARCH`         | Architecture to build (amd64, arm64, i386)     | `amd64`                 |
| `VERSION`      | Version of Home Assistant                      | `1.4.0`                 |
