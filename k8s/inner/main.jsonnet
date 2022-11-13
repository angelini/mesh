local k = import 'github.com/jsonnet-libs/k8s-libsonnet/1.25/main.libsonnet';

local deployment = k.apps.v1.deployment;
local container = k.core.v1.container;
local containerPort = k.core.v1.containerPort;
local service = k.core.v1.service;
local servicePort = k.core.v1.servicePort;

local name = 'inner';
local container_port = 1080;
local service_port = 2080;

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
      + container.withArgs(['api', '-p', std.toString(container_port)])
      + container.withImagePullPolicy('Never')
      + container.withPorts(containerPort.newNamed(container_port, 'grpc-port')),
    ],
  ) + deployment.metadata.withLabels(appLabels),

  service.new(
    name=name + '-service',
    selector=appLabels { name: name },
    ports=[servicePort.new(service_port, 'grpc-port') + servicePort.withProtocol('TCP')]
  ),
]
