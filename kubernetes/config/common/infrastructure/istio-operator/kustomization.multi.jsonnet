local flux = import 'flux.libsonnet';
local k = import 'k.libsonnet';
local k8s = import 'k8s.io.libsonnet';

local ns = k.core.v1.namespace;
local serviceAccount = k.core.v1.serviceAccount;
local service = k.core.v1.service;
local clusterRole = k.rbac.v1.clusterRole;
local clusterRoleBinding = k.rbac.v1.clusterRoleBinding;
local deployment = k.apps.v1.deployment;

local kust = k8s.config.kustomize.v1beta1.kustomization;

local clusterRoleRules = import 'clusterRoleRules.libsonnet';

local deploymentName = 'istio-operator';

// renovate: githubReleaseVar repo=istio/istio
local operatorVersionTag = '1.13.0';

kust.new + kust.withNamespace(deploymentName) + kust.withResources([
  ['namespace', ns.new(deploymentName) + ns.metadata.withLabels({
    'istio-operator-managed': 'Reconcile',
    'istio-injection': 'disabled',
  })],
  ['service_account', serviceAccount.new(deploymentName)],
  ['cluster_role', clusterRole.new(deploymentName) + clusterRole.withRules(clusterRoleRules)],
  ['cluster_role_binding', clusterRoleBinding.new(deploymentName) + clusterRoleBinding.withSubjects([
    {
      kind: 'ServiceAccount',
      name: deploymentName,
      namespace: deploymentName,
    },
  ]) + clusterRoleBinding.roleRef.withApiGroup('rbac.authorization.k8s.io') + clusterRoleBinding.roleRef.withKind('ClusterRole') + clusterRoleBinding.roleRef.withName(deploymentName)],
  [
    'service',
    service.new(
      deploymentName,
      selector={ name: deploymentName },
      ports=[
        {
          name: 'http-metrics',
          port: 8383,
          targetPort: 8383,
          protocol: 'TCP',
        },
      ]
    )
    + service.metadata.withLabels({ name: deploymentName }),
  ],
  [
    'deployment',
    deployment.new(deploymentName)
    + deployment.metadata.withNamespace(deploymentName)
    + deployment.spec.withReplicas(1)
    + deployment.spec.selector.withMatchLabels({ name: deploymentName })
    + deployment.spec.template.metadata.withLabels({ name: deploymentName })
    + deployment.spec.template.spec.withServiceAccountName(deploymentName)
    + deployment.spec.template.spec.withContainers({
      name: deploymentName,
      image: 'docker.io/querycapistio/operator:%s-distroless' % operatorVersionTag,
      command: ['operator', 'server'],
      securityContext: {
        allowPrivilegeEscalation: false,
        capabilities: {
          drop: [
            'ALL',
          ],
        },
        privileged: false,
        readOnlyRootFilesystem: true,
        runAsGroup: 1337,
        runAsUser: 1337,
        runAsNonRoot: true,
      },
      imagePullPolicy: 'IfNotPresent',
      resources: {
        limits: {
          cpu: '200m',
          memory: '256Mi',
        },
        requests: {
          cpu: '50m',
          memory: '128Mi',
        },
      },
      env: [
        {
          name: 'WATCH_NAMESPACE',
          value: (import '../istio-system/config.libsonnet').namespace,
        },
        {
          name: 'LEADER_ELECTION_NAMESPACE',
          value: deploymentName,
        },
        {
          name: 'POD_NAME',
          valueFrom: {
            fieldRef: {
              fieldPath: 'metadata.name',
            },
          },
        },
        {
          name: 'OPERATOR_NAME',
          value: deploymentName,
        },
        {
          name: 'WAIT_FOR_RESOURCES_TIMEOUT',
          value: '300s',
        },
        {
          name: 'REVISION',
          value: '',
        },
      ],
    }),
  ],
  'https://raw.githubusercontent.com/istio/istio/%s/manifests/charts/istio-operator/crds/crd-operator.yaml' % operatorVersionTag,
])
