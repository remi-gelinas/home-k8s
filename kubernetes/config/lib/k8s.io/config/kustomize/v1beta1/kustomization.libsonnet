local common = import 'common.libsonnet';

local apiVersion = 'kustomize.config.k8s.io/%s' % common.version;
local kind = 'Kustomization';

local pickIfObject(arr) = std.isObject(arr[1]);

local _genResource(resource) =
  if std.isArray(resource) && std.length(resource) > 1 then
    resource[0] + '.yaml'
  else if std.isString(resource) then
    resource;

local addGenResourceArray(arr) =
  {
    [resource[0]]: resource[1]
    for resource in arr
    if (std.isArray(resource) && std.length(resource) > 1) && std.isObject(resource[1])
  };

{
  new: {
    kustomization+: {
      apiVersion: apiVersion,
      kind: kind,
    },
  },
  withNamespace(namespace): {
    kustomization+: {
      namespace: namespace,
    },
  },
  withResources(resourceArr): {
    kustomization+: {
      resources: [
        _genResource(resource)
        for resource in resourceArr
      ],
    },
  } + addGenResourceArray(resourceArr),
}
