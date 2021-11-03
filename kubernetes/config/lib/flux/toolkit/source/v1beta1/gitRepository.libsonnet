{
    metadata: {
        withAnnotations(annotations): { metadata+: { annotations: annotations } },
        withName(name): { metadata+: { name: name } },
        withNamespace(namespace): { metadata+: { namespace: namespace } },
    },
    new(name): {
        apiVersion: 'source.toolkit.fluxcd.io/v1beta1',
        kind: 'GitRepository',
    } + self.metadata.withName(name=name),
    mixin: self
}