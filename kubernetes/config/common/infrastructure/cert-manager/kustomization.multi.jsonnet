local flux = import 'flux.libsonnet';
local k8s = import 'k8s.io.libsonnet';
local k = import 'k.libsonnet';

local ns = k.core.v1.namespace;
local kust = k8s.config.kustomize.v1beta1.kustomization;
local gr = flux.toolkit.source.v1beta1.gitRepository;
local hr = flux.toolkit.helm.v2beta1.helmRelease;
local fluxKust = flux.toolkit.kustomize.v1beta2.kustomization;

local chartName = 'cert-manager';

# renovate: helmChartVar registryUrl=https://charts.jetstack.io chart=cert-manager
local chartTag = 'v1.6.1';

kust.new + kust.withNamespace(chartName) + kust.withResources([
    'https://github.com/jetstack/cert-manager/releases/download/%s/cert-manager.crds.yaml' % chartTag,
    ['namespace', ns.new(chartName)],
    ['helm-release', hr.new(chartName)
        + hr.withHelmSource('jetstack')
        + hr.withChartName(chartName)
        + hr.withChartVersion(chartTag)]
])
