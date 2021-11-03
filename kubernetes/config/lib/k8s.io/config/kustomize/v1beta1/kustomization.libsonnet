{
    new: {
        kustomization+: {
            apiVersion: 'kustomize.config.k8s.io/v1beta1',
            kind: 'Kustomization'
        }
    },
    withNamespace(namespace): {
        kustomization+: {
            namespace: namespace
        }
    },
    withResources(resourceObj): resourceObj
}