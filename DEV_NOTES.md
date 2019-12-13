```
# Static compile bindings
WORKDIR /zigbee2mqtt/node_modules/zigbee-herdsman/node_modules/@serialport/bindings
RUN sed -i "s/'target_name': 'bindings',/&\n    'type': 'static_library',/" binding.gyp && \
  node-gyp clean && \
  node-gyp configure && \
  node-gyp build
```
Results in a nice static /zigbee2mqtt/node_modules/zigbee-herdsman/node_modules/@serialport/bindings/build/Release/bindings.a
