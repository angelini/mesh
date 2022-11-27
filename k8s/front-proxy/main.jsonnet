local k = import 'github.com/jsonnet-libs/k8s-libsonnet/1.25/main.libsonnet';

local deployment = k.apps.v1.deployment;
local container = k.core.v1.container;
local containerPort = k.core.v1.containerPort;
local service = k.core.v1.service;
local servicePort = k.core.v1.servicePort;
local volume = k.core.v1.volume;
local volumeMount = k.core.v1.volumeMount;

local name = 'front-proxy';
local config_map_name = 'front-proxy-envoy-config';
local tls_secret_name = 'tls-secret';

local container_port = 1080;
local admin_port = 1090;
local service_port = 2010;
local admin_service_port = 2090;

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
      container.new(name, 'mesh.local/envoy:latest')
      + container.withImagePullPolicy('Never')
      + container.withVolumeMounts([
        volumeMount.new(config_map_name, '/home/main/configs/envoy') + volumeMount.withReadOnly(true),
        volumeMount.new(tls_secret_name, '/home/main/secrets/tls') + volumeMount.withReadOnly(true),
      ])
      + container.withPorts([
        containerPort.newNamed(container_port, 'grpc-port'),
        containerPort.newNamed(admin_port, 'admin-port'),
      ]),
    ],
  ) + deployment.metadata.withLabels(appLabels)
  + deployment.spec.template.spec.withVolumes([
    volume.withName(config_map_name) + volume.configMap.withName(config_map_name),
    volume.withName(tls_secret_name) + volume.secret.withSecretName(tls_secret_name),
  ]),

  service.new(
    name=name + '-service',
    selector=appLabels { name: name },
    ports=[
      servicePort.newNamed('service', service_port, 'grpc-port'),
      servicePort.newNamed('admin', admin_service_port, 'admin-port'),
    ]
  ) + service.spec.withType('LoadBalancer'),
]
