local k = import 'github.com/jsonnet-libs/k8s-libsonnet/1.25/main.libsonnet';

local deployment = k.apps.v1.deployment;
local container = k.core.v1.container;
local containerPort = k.core.v1.containerPort;
local service = k.core.v1.service;
local servicePort = k.core.v1.servicePort;
local volume = k.core.v1.volume;
local volumeMount = k.core.v1.volumeMount;

local name = 'inner';
local config_map_name = 'inner-envoy-config';

local ports = {
  app: { name: 'app-grpc-port', value: 1080 },
  sidecar: { name: 'side-grpc-port', value: 2080 },
  service: { value: 3080 },
};

local appLabels = {
  'app.kubernetes.io/name': name,
  'app.kubernetes.io/part-of': 'mesh',
};

[
  deployment.new(
    name=name,
    replicas=1,
    podLabels=appLabels,
    containers=[
      container.new(name, 'mesh.local/' + name + ':latest')
      + container.withArgs(['api', '-p', std.toString(ports.app.value)])
      + container.withImagePullPolicy('Never')
      + container.withPorts([
        containerPort.newNamed(ports.app.value, ports.app.name),
      ]),

      container.new('proxy-sidecar', 'mesh.local/envoy:latest')
      + container.withImagePullPolicy('Never')
      + container.withPorts([
        containerPort.newNamed(ports.sidecar.value, ports.sidecar.name),
      ])
      + container.withVolumeMounts([
        volumeMount.new(config_map_name, '/home/main/configs/envoy') + volumeMount.withReadOnly(true),
      ]),
    ],
  ) + deployment.metadata.withLabels(appLabels)
  + deployment.spec.template.spec.withVolumes([
    volume.withName(config_map_name) + volume.configMap.withName(config_map_name),
  ]),

  service.new(
    name=name + '-service',
    selector=appLabels { name: name },
    ports=[servicePort.new(ports.service.value, ports.sidecar.name)]
  ) + service.spec.withClusterIP('None'),
]
