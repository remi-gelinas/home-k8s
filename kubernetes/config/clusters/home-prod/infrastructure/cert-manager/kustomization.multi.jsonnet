local flux = import 'flux.libsonnet';
local k = import 'k.libsonnet';
local k8s = import 'k8s.io.libsonnet';

local kust = k8s.config.kustomize.v1beta1.kustomization;
local sec = k.core.v1.secret;

local encryptedSecretData = import 'secret.sops.json';

local ns = 'cert-manager';

kust.new + kust.withNamespace(ns) + kust.withResources([
  [
    'secret.sops',
    sec.new('cloudflare', data=encryptedSecretData.data)
    + sec.metadata.withNamespace(ns)
    + encryptedSecretData,
  ],
])
