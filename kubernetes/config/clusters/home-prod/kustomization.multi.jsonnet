local flux = import 'flux.libsonnet';
local k8s = import 'k8s.io.libsonnet';

local gr = flux.toolkit.source.v1beta1.gitRepository;
local kust = k8s.config.kustomize.v1beta1.kustomization;
local fluxKust = flux.toolkit.kustomize.v1beta2.kustomization;

kust.new + kust.withNamespace('flux-system') + kust.withResources([
  './flux/repositories/git/home-k8s.yaml',
  [
    'deploy-cluster',
    fluxKust.new('cluster-deployment')
    + fluxKust.withGitSource('home-k8s')
    + fluxKust.withPath('./kubernetes/_gen/clusters/home-prod/flux/deploy')
    + fluxKust.withPrune(true)
    + fluxKust.withWait(true),
  ],
])
