local k = import 'github.com/jsonnet-libs/k8s-libsonnet/1.25/main.libsonnet';

local deployment = k.apps.v1.deployment;
local container = k.core.v1.container;
local containerPort = k.core.v1.containerPort;
local service = k.core.v1.service;
local servicePort = k.core.v1.servicePort;

local name = 'front-proxy';
local container_port = 1080;
local admin_port = 1090;
local service_port = 2080;
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
      + container.withPorts([
        containerPort.newNamed(container_port, 'grpc-port'),
        containerPort.newNamed(admin_port, 'admin-port'),
      ]),
    ],
  ) + deployment.metadata.withLabels(appLabels),

  service.new(
    name=name + '-service',
    selector=appLabels { name: name },
    ports=[
      servicePort.newNamed('service', service_port, 'grpc-port') + servicePort.withProtocol('TCP'),
      servicePort.newNamed('admin', admin_service_port, 'admin-port'),
    ]
  ) + service.spec.withType('LoadBalancer'),
]
