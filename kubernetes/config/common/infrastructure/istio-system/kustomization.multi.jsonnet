local flux = import 'flux.libsonnet';
local k = import 'k.libsonnet';
local k8s = import 'k8s.io.libsonnet';

local ns = k.core.v1.namespace;
local kust = k8s.config.kustomize.v1beta1.kustomization;
local gr = flux.toolkit.source.v1beta1.gitRepository;
local fluxKust = flux.toolkit.kustomize.v1beta2.kustomization;

local nsName = (import 'config.libsonnet').namespace;

// renovate: githubReleaseVar repo=istio/istio
local versionTag = '1.13.0';

kust.new + kust.withNamespace(nsName) + kust.withResources([
  ['namespace', ns.new(nsName)],
  ['install', {
    apiVersion: 'install.istio.io/v1alpha1',
    kind: 'IstioOperator',
    metadata: {
      namespace: nsName,
      name: 'istio-control-plane',
    },
    spec: {
      profile: 'empty',
      hub: 'docker.io/istio',
      tag: versionTag,
      components: {
        base: {
          enabled: true,
        },
        pilot: {
          enabled: true,
        },
      },
      values: {
        pilot: {
          env: {
            PILOT_ENABLE_WORKLOAD_ENTRY_AUTOREGISTRATION: true,
            PILOT_ENABLE_WORKLOAD_ENTRY_HEALTHCHECKS: true,
          },
        },
      },
    },
  }],
])
