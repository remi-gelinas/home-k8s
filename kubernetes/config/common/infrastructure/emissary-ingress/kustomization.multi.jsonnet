local flux = import 'flux.libsonnet';
local k = import 'k.libsonnet';
local k8s = import 'k8s.io.libsonnet';

local ns = k.core.v1.namespace;
local kust = k8s.config.kustomize.v1beta1.kustomization;
local gr = flux.toolkit.source.v1beta1.gitRepository;
local hr = flux.toolkit.helm.v2beta1.helmRelease;
local fluxKust = flux.toolkit.kustomize.v1beta2.kustomization;

local chartName = 'emissary-ingress';
local sourceName = 'emissary-ingress-source';

// renovate: helmChartVar registryUrl=https://app.getambassador.io chart=emissary-ingress
local chartTag = '8.6.0';

kust.new + kust.withNamespace('flux-system') + kust.withResources([
  ['crd-source', gr.new(sourceName)
                 + gr.withInterval('30m')
                 + gr.withTag('chart-v%s' % chartTag)
                 + gr.withUrl('https://github.com/emissary-ingress/emissary.git')
                 + gr.withIgnore(
                   |||
                     /*
                     !/charts/emissary-ingress/crds
                   |||
                 )],
  ['crds', fluxKust.new('emissary-ingress-crds')
           + fluxKust.withInterval('15m')
           + fluxKust.withPrune(false)
           + fluxKust.withWait(true)
           + fluxKust.withGitSource(sourceName)],
  ['namespace', ns.new('emissary')],
  ['helm-release', hr.new(chartName)
                   + hr.metadata.withNamespace('emissary')
                   + hr.withHelmSource('datawire')
                   + hr.withChartName(chartName)
                   + hr.withChartVersion(chartTag)],
])
