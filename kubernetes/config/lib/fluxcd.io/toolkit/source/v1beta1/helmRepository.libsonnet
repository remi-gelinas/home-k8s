local versionRepo = './main.libsonnet';

local apiVersion = 'source.toolkit.fluxcd.io/v1beta1';
local kind = 'HelmRepository';

{
    apiVersion: apiVersion,
    kind: kind,
  metadata: {
    withAnnotations(annotations): { metadata+: { annotations: annotations } },
    withName(name): { metadata+: { name: name } },
    withNamespace(namespace): { metadata+: { namespace: namespace } },
  },
  new(name): {
  apiVersion: apiVersion,
  kind: kind,
             } + self.metadata.withName(name=name)
             + self.withInterval(),
  withInterval(interval='10m0s'): {
    spec+: {
      interval: interval,
    },
  },
  withUrl(url): {
    spec+: {
      url: url,
    },
  },
  mixin: self,
}
