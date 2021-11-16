local flux = import 'flux.libsonnet';
local k8s = import 'k8s.io.libsonnet';

local kust = k8s.config.kustomize.v1beta1.kustomization;
local fluxKust = flux.toolkit.kustomize.v1beta2.kustomization;

kust.new + kust.withNamespace('flux-system') + kust.withResources([
  [
    'cert-manager-common',
    fluxKust.new('cert-manager-common')
    + fluxKust.withPath('./kubernetes/_gen/common/infrastructure/cert-manager')
    + fluxKust.withPrune(true)
    + fluxKust.withWait(true)
    + fluxKust.withGitSource('home-k8s'),
  ],
  [
    'cert-manager',
    fluxKust.new('cert-manager')
    + fluxKust.withPath('./kubernetes/_gen/clusters/home-prod/infrastructure/cert-manager')
    + fluxKust.withPrune(true)
    + fluxKust.withWait(true)
    + fluxKust.withGitSource('home-k8s')
    + fluxKust.withDependencies(['cert-manager-common']),
  ],
])
