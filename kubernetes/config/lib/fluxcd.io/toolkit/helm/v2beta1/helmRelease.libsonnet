local fluxlib = import 'flux.libsonnet';
local helmRepo = fluxlib.toolkit.source.v1beta1.helmRepository;
local common = import 'common.libsonnet';

local apiVersion = 'helm.toolkit.fluxcd.io/%s' % common.version;
local kind = 'HelmRelease';

local chartSpec(obj) = {
  spec+: {
    chart+: {
      spec+: obj,
    },
  },
};

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
  } + self.metadata.withName(name=name) + self.withInterval('10m0s'),
  withHelmSource(name, namespace='flux-system'): chartSpec({
    sourceRef: {
      kind: helmRepo.kind,
      name: name,
      namespace: namespace,
    },
  }),
  withChartName(name): chartSpec({
    chart: name,
  }),
  withChartVersion(version): chartSpec({
    version: version,
  }),
  withInterval(interval): {
    spec+: {
      interval: interval,
    },
  },
  mixin: self,
}
