local k = import 'github.com/jsonnet-libs/k8s-libsonnet/1.25/main.libsonnet';

local namespace = k.core.v1.namespace;

[
  namespace.new('mesh'),
]
