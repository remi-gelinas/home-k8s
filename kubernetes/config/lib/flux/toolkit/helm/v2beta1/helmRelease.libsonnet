local chartSpec(obj) = {
    spec+: {
        chart+: {
            spec+: obj
        }
    }
};

{
    metadata: {
        withAnnotations(annotations): { metadata+: { annotations: annotations } },
        withName(name): { metadata+: { name: name } },
        withNamespace(namespace): { metadata+: { namespace: namespace } },
    },
    new(name): {
        apiVersion: 'helm.toolkit.fluxcd.io/v2beta1',
        kind: 'HelmRelease',
    } + self.metadata.withName(name=name),
    withHelmSource(name, namespace='flux-system'): chartSpec({
        sourceRef: {
            kind: 'HelmRepository',
            name: name,
            namespace: namespace
        }
    }),
    withChartName(name): chartSpec({
        chart: name
    }),
    withChartVersion(version): chartSpec({
        version: version
    }),
    mixin: self
}