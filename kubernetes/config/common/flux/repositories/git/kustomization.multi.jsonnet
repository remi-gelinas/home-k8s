local flux = import 'flux.libsonnet';
local k8s = import 'k8s.io.libsonnet';

local k = k8s.config.kustomize.v1beta1.kustomization;
local gr = flux.toolkit.source.v1beta1.gitRepository;

// renovate: githubReleaseVar repo=fluxcd/flux2
local fluxRepoTag = 'v0.23.0';

k.new + k.withNamespace('flux-system') + k.withResources([
  ['flux', gr.new('flux')
           + gr.withTag(fluxRepoTag)
           + gr.withUrl('https://github.com/fluxcd/flux2')
           + gr.withIgnore(
             |||
               /*
               !/manifests
             |||
           )],
])
