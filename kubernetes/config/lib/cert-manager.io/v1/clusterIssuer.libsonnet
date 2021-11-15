local common = import 'common.libsonnet';

local apiVersion = 'cert-manager.io/%s' % common.version;
local kind = 'ClusterIssuer';

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
  } + self.metadata.withName(name),
  withACMEConfig(email, server, accountKeySecretName, solvers): {
    spec+: {
      acme: {
        email: email,
        server: server,
        privateKeySecretRef: {
          name: accountKeySecretName,
        },
      },
    },
  },
}
