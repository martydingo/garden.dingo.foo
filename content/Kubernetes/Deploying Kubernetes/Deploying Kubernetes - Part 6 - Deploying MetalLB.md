---
date: 2022-08-22
---
Welcome to the fifth part of our series on deploying Kubernetes! In this installment, we will be covering how to deploy MetalLB, a load-balancer implementation for bare metal Kubernetes clusters.

## What is MetalLB?

[MetalLB](https://metallb.universe.tf/) is a load-balancer implementation for bare metal Kubernetes clusters. In a cloud environment, load balancing is usually provided by the cloud provider, but in a bare metal cluster, you are responsible for setting it up yourself. This is where MetalLB comes in - it allows you to use the same LoadBalancer service type in your bare metal cluster as you would in a cloud environment, providing your applications with the same level of accessibility.

## Setting up MetalLB

To set up MetalLB, you will need to first create a helm configuration file called `helm-metallb-values.yaml`. Copy the following configuration into this file:
      
```yaml

imagePullSecrets: []
nameOverride: ""
fullnameOverride: ""
loadBalancerClass: ""

# To configure MetalLB, you must specify ONE of the following two
# options.

rbac:
  # create specifies whether to install and use RBAC rules.
  create: true

psp:
  # create specifies whether to install and use Pod Security Policies.
  create: true

prometheus:
  serviceMonitor:
    enabled: true
  # scrape annotations specifies whether to add Prometheus metric
  # auto-collection annotations to pods. See
  # https://github.com/prometheus/prometheus/blob/release-2.1/documentation/examples/prometheus-kubernetes.yml
  # for a corresponding Prometheus configuration. Alternatively, you
  # may want to use the Prometheus Operator
  # (https://github.com/coreos/prometheus-operator) for more powerful
  # monitoring configuration. If you use the Prometheus operator, this
  # can be left at false.
  scrapeAnnotations: false

  # port both controller and speaker will listen on for metrics
  metricsPort: 7472

  # the service account used by prometheus
  # required when .Values.prometheus.podMonitor.enabled == true
  serviceAccount: "prometheus-operator"

  # the namespace where prometheus is deployed
  # required when .Values.prometheus.podMonitor.enabled == true
  namespace: "monitoring-dingo-services"

  # Prometheus Operator PodMonitors
  podMonitor:

    # enable support for Prometheus Operator
    enabled: true

    # optional additionnal labels for podMonitors
    additionalLabels: {}

    # optional annotations for podMonitors
    annotations: {}

    # Job label for scrape target
    jobLabel: "app.kubernetes.io/name"

    # Scrape interval. If not set, the Prometheus default scrape interval is used.
    interval:

    # 	metric relabel configs to apply to samples before ingestion.
    metricRelabelings: []
    # - action: keep
    #   regex: 'kube_(daemonset|deployment|pod|namespace|node|statefulset).+'
    #   sourceLabels: [__name__]

    # 	relabel configs to apply to samples before ingestion.
    relabelings: []
    # - sourceLabels: [__meta_kubernetes_pod_node_name]
    #   separator: ;
    #   regex: ^(.*)$
    #   target_label: nodename
    #   replacement: $1
    #   action: replace

  # Prometheus Operator alertmanager alerts
  prometheusRule:

    # enable alertmanager alerts
    enabled: true

    # optional additionnal labels for prometheusRules
    additionalLabels: {}

    # optional annotations for prometheusRules
    annotations: {}

    # MetalLBStaleConfig
    staleConfig:
      enabled: true
      labels:
        severity: warning

    # MetalLBConfigNotLoaded
    configNotLoaded:
      enabled: true
      labels:
        severity: warning

    # MetalLBAddressPoolExhausted
    addressPoolExhausted:
      enabled: true
      labels:
        severity: alert

    addressPoolUsage:
      enabled: true
      thresholds:
        - percent: 75
          labels:
            severity: warning
        - percent: 85
          labels:
            severity: warning
        - percent: 95
          labels:
            severity: alert

    # MetalLBBGPSessionDown
    bgpSessionDown:
      enabled: true
      labels:
        severity: alert

    extraAlerts: []

# controller contains configuration specific to the MetalLB cluster
# controller.
controller:
  enabled: true
  # -- Controller log level. Must be one of: `all`, `debug`, `info`, `warn`, `error` or `none`
  logLevel: info
  image:
    repository: quay.io/metallb/controller
    tag:
    pullPolicy:
  serviceAccount:
    # Specifies whether a ServiceAccount should be created
    create: true
    # The name of the ServiceAccount to use. If not set and create is
    # true, a name is generated using the fullname template
    name: ""
    annotations: {}
  securityContext:
    runAsNonRoot: true
    # nobody
    runAsUser: 65534
    fsGroup: 65534
  resources: {}
    # limits:
      # cpu: 100m
      # memory: 100Mi
  nodeSelector: {}
  tolerations: []
  priorityClassName: ""
  runtimeClassName: ""
  affinity: {}
  podAnnotations: {}
  livenessProbe:
    enabled: true
    failureThreshold: 3
    initialDelaySeconds: 10
    periodSeconds: 10
    successThreshold: 1
    timeoutSeconds: 1
  readinessProbe:
    enabled: true
    failureThreshold: 3
    initialDelaySeconds: 10
    periodSeconds: 10
    successThreshold: 1
    timeoutSeconds: 1

# speaker contains configuration specific to the MetalLB speaker
# daemonset.
speaker:
  enabled: true
  # -- Speaker log level. Must be one of: `all`, `debug`, `info`, `warn`, `error` or `none`
  logLevel: info
  tolerateMaster: true
  memberlist:
    enabled: true
    mlBindPort: 7946
  image:
    repository: quay.io/metallb/speaker
    tag:
    pullPolicy:
  serviceAccount:
    # Specifies whether a ServiceAccount should be created
    create: true
    # The name of the ServiceAccount to use. If not set and create is
    # true, a name is generated using the fullname template
    name: ""
    annotations: {}
  ## Defines a secret name for the controller to generate a memberlist encryption secret
  ## By default secretName: {{ "metallb.fullname" }}-memberlist
  ##
  # secretName:
  resources: {}
    # limits:
      # cpu: 100m
      # memory: 100Mi
  nodeSelector: {}
  tolerations: []
  priorityClassName: ""
  affinity: {}
  ## Selects which runtime class will be used by the pod.
  runtimeClassName: ""
  podAnnotations: {}
  livenessProbe:
    enabled: true
    failureThreshold: 3
    initialDelaySeconds: 10
    periodSeconds: 10
    successThreshold: 1
    timeoutSeconds: 1
  readinessProbe:
    enabled: true
    failureThreshold: 3
    initialDelaySeconds: 10
    periodSeconds: 10
    successThreshold: 1
    timeoutSeconds: 1
  # frr contains configuration specific to the MetalLB FRR container,
  # for speaker running alongside FRR.
  frr:
    enabled: true
    image:
      repository: frrouting/frr
      tag: v7.5.1
      pullPolicy: IfNotPresent

crds:
  enabled: true
```
 

Next, create a namespace for MetalLB to use:

`kubectl create ns metallb`

Then, add the MetalLB Helm repository and install MetalLB using Helm:

`helm rDeploying Kubernetes - Part 5 - Deploying MetalLBepo add metallb https://metallb.github.io/metallb helm install -n metallb metallb metallb/metallb -f helm-metallb-values.yaml`

That's it! You should now have MetalLB up and running in your Kubernetes cluster.

## Using MetalLB

To use MetalLB, simply create a LoadBalancer service in your Kubernetes cluster as you would normally. MetalLB will automatically bind a free IP address to the service, and traffic will be balanced across the available pods for that service.

## Conclusion

In this tutorial, we covered how to deploy MetalLB, a load-balancer implementation for bare metal Kubernetes clusters. By following these simple steps, you should now be able to use the LoadBalancer service type in your bare metal cluster just as you would in a cloud environment.