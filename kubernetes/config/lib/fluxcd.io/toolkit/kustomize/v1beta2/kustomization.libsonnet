local fluxlib = import 'flux.libsonnet';
local gitRepo = fluxlib.toolkit.source.v1beta1.gitRepository;
local common = import 'common.libsonnet';

local apiVersion = 'kustomize.toolkit.fluxcd.io/%s' % common.version;
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
  } + self.metadata.withName(name) + self.metadata.withNamespace(namespace) + self.withInterval('10m0s'),
  withInterval(interval): {
    spec+: { interval: interval },
  },
  withPrune(prune): {
    spec+: { prune: prune },
  },
  withWait(wait): {
    spec+: { wait: wait },
  },
  withPath(path): {
    spec+: { path: path },
  },
  withGitSource(name): {
    spec+: {
      sourceRef: {
        kind: gitRepo.kind,
        name: name,
      },
    },
  },
  withDecryption(provider='sops', secretName='sops-age'): {
    spec+: {
      decryption: {
        provider: provider,
        secretRef: {
          name: secretName,
        },
      },
    },
  },
  withDependencies(deps): {
    spec+: {
      dependsOn+: deps,
    },
  },
  withPatch(patch, target): {
    spec+: {
      patches+: [{
        patch: patch,
        target: target,
      }],
    },
  },
}
