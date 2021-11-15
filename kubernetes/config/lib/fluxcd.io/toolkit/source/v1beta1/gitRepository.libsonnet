local common = import 'common.libsonnet';

local apiVersion = 'source.toolkit.fluxcd.io/%s' % common.version;
local kind = 'GitRepository';

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
                                      } + self.metadata.withName(name=name)
                                      + self.metadata.withNamespace(namespace)
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
  withIgnore(ignore): {
    spec+: {
      ignore: ignore,
    },
  },
  withBranch(branch): {
    spec+: {
      ref+: {
        branch: branch,
      },
    },
  },
  withTag(tag): {
    spec+: {
      ref+: {
        tag: tag,
      },
    },
  },
  withSemVer(semVer): {
    spec+: {
      ref+: {
        semver: semVer,
      },
    },
  },
  withCommit(commit): {
    spec+: {
      ref+: {
        commit: commit,
      },
    },
  },
  mixin: self,
}
