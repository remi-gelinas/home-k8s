local flux = import 'flux.libsonnet';
local k8s = import 'k8s.io.libsonnet';

local kust = k8s.config.kustomize.v1beta1.kustomization;
local fluxKust = flux.toolkit.kustomize.v1beta2.kustomization;

kust.new + kust.withNamespace('flux-system') + kust.withResources([
  [
    'cluster-repositories',
    fluxKust.new('cluster-repositories')
    + fluxKust.withPath('./kubernetes/_gen/clusters/home-prod/flux/repositories')
    + fluxKust.withPrune(true)
    + fluxKust.withWait(true)
    + fluxKust.withGitSource('home-k8s'),
  ],
  [
    'manage-flux',
    fluxKust.new('cluster-flux')
    + fluxKust.withPath('./manifests/install')
    + fluxKust.withPrune(true)
    + fluxKust.withWait(true)
    + fluxKust.withGitSource('flux'),
  ],
  [
    'cluster-orchestration',
    fluxKust.new('cluster-orchestration')
    + fluxKust.withPath('./kubernetes/_gen/clusters/home-prod/flux/orchestration')
    + fluxKust.withPrune(true)
    + fluxKust.withWait(true)
    + fluxKust.withGitSource('home-k8s')
    + fluxKust.withDecryption()
    + fluxKust.withDependencies([
      { name: 'cluster-repositories' },
      { name: 'cluster-flux' },
    ]),
  ],
])
