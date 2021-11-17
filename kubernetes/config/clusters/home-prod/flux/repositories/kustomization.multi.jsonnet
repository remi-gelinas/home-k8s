local flux = import 'flux.libsonnet';
local k8s = import 'k8s.io.libsonnet';

local gr = flux.toolkit.source.v1beta1.gitRepository;
local kust = k8s.config.kustomize.v1beta1.kustomization;
local fluxKust = flux.toolkit.kustomize.v1beta2.kustomization;

kust.new + kust.withNamespace('flux-system') + kust.withResources([
  '../../../../../common/flux/repositories/git',
  [
    'home-k8s',
    gr.new('home-k8s')
    + gr.withInterval('1m0s')
    + gr.withUrl('https://github.com/remi-gelinas/home-k8s.git')
    + gr.withIgnore(
      |||
        /*
        !/kubernetes/_gen
      |||
    )
    + gr.withBranch('trunk'),
  ],
  '../../../../../common/flux/repositories/helm',
])
