local k8s = import 'k8s.io.libsonnet';
local flux = import 'flux.libsonnet';

local k = k8s.config.kustomize.v1beta1.kustomization;
local gr = flux.toolkit.source.v1beta1.gitRepository;

k.new + k.withNamespace('flux-system') + k.withResources({
    flux: gr.new('flux') + gr.metadata.withNamespace('flux-system')
})