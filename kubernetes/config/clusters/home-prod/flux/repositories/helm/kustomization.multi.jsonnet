local k8s = import 'k8s.io.libsonnet';
local kust = k8s.config.kustomize.v1beta1.kustomization;

kust.new + kust.withNamespace('flux-system') + kust.withResources([
  '../../../../../common/flux/repositories/helm',
])
