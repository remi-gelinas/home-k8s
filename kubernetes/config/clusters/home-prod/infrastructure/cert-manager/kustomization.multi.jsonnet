local flux = import 'flux.libsonnet';
local k = import 'k.libsonnet';
local k8s = import 'k8s.io.libsonnet';

local kust = k8s.config.kustomize.v1beta1.kustomization;
local sec = k.core.v1.secret;

local encryptedSecretData = import 'secret.sops.json';

kust.new + kust.withNamespace('flux-system') + kust.withResources([
  [
    'secret.sops',
    sec.new('cloudflare', data=encryptedSecretData.data)
    + sec.metadata.withNamespace('cert-manager')
    + encryptedSecretData,
  ],
])
