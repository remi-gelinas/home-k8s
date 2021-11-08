local flux = import 'flux.libsonnet';
local k8s = import 'k8s.io.libsonnet';

local k = k8s.config.kustomize.v1beta1.kustomization;
local hr = flux.toolkit.source.v1beta1.helmRepository;

k.new + k.withNamespace('flux-system') + k.withResources([
  ['cilium-charts', hr.new('cilium')
                    + hr.metadata.withNamespace('flux-system')
                    + hr.withUrl('https://helm.cilium.io/')],
  ['datawire-charts', hr.new('datawire')
                      + hr.metadata.withNamespace('flux-system')
                      + hr.withUrl('https://app.getambassador.io')],
  ['istio-charts', hr.new('istio')
                   + hr.metadata.withNamespace('flux-system')
                   + hr.withUrl('https://istio-release.storage.googleapis.com/charts')],
  ['jetstack-charts', hr.new('jetstack')
                      + hr.metadata.withNamespace('flux-system')
                      + hr.withUrl('https://charts.jetstack.io')],
  ['kiali-charts', hr.new('kiali')
                   + hr.metadata.withNamespace('flux-system')
                   + hr.withUrl('https://kiali.org/helm-charts')],
])
