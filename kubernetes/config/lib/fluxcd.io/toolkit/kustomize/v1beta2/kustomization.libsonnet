local fluxlib = import 'flux.libsonnet';
local gitRepo = fluxlib.toolkit.source.v1beta1.gitRepository;

local apiVersion = 'kustomize.toolkit.fluxcd.io/v1beta2';
local kind = 'Kustomization';

{
    apiVersion: apiVersion,
    kind: kind,
  metadata: {
    withAnnotations(annotations): { metadata+: { annotations: annotations } },
    withName(name): { metadata+: { name: name } },
    withNamespace(namespace): { metadata+: { namespace: namespace } },
  },
  new(name, namespace='flux-system'): {
    apiVersion: apiVersion,
    kind: kind,
  } + self.metadata.withName(name) + self.metadata.withNamespace(namespace),
  withInterval(interval): {
    spec+: { interval: interval }
  },
  withPrune(prune): {
    spec+: { prune: prune }
  },
  withWait(wait): {
    spec+: { wait: wait }
  },
  withGitSource(name): {
    spec+: {
        sourceRef: {
            kind: gitRepo.kind,
            name: name
        }
    }
  }
}