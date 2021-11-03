local k = import "k.libsonnet";
local flux = import "flux.libsonnet";
local hr = flux.toolkit.helm.v2beta1.helmRelease;

{
    namespace: k.core.v1.namespace.new('cert-manager') + k.core.v1.namespace.withLabel('foo', 'bar'),
    helmRelease: hr.new('cert-manager')
}