## Introduction

### IP Schema

**Kibana:** `100.64.2.0,fd:0:0:0:fe:64:2::`
**Logstash:** `100.64.2.1,fd:0:0:0:fe:64:2:1`
**Elasticsearch:** `100.64.2.2,fd:0:0:0:fe:64:2:2`
**Filebeat:** `100.64.2.3,fd:0:0:0:fe:64:2:3`
**Metricbeat:** `100.64.2.4,fd:0:0:0:fe:64:2:4`
**APM Server:** `100.64.2.5,fd:0:0:0:fe:64:2:5`

### ZFS Dataset Creation

1. `zfs create storage/static-volumes/dingo.services/elastic.dingo.services`
2. `zfs create storage/static-volumes/dingo.services/elastic.dingo.services/elasticsearch.elastic.dingo.services`
3. `zfs create storage/static-volumes/dingo.services/elastic.dingo.services/logstash.elastic.dingo.services`

### File Permissions

```bash
chown -R 1000:1000 /storage/static-volumes/dingo.services/elastic.dingo.services/elasticsearch.elastic.dingo.services
chown -R 1000:1000 /storage/static-volumes/dingo.services/elastic.dingo.services/logstash.elastic.dingo.services
```

### NFS Exports

1. Append the following block to `/etc/exports`

   ```
    # NFS export for elasticsearch.elastic.dingo.services
    /storage/static-volumes/dingo.services/elastic.dingo.services/elasticsearch.elastic.dingo.services 10.0.0.0/14(rw,async,no_root_squash,no_wdelay,no_subtree_check)

    # NFS export for logstash.elastic.dingo.services
    /storage/static-volumes/dingo.services/elastic.dingo.services/logstash.elastic.dingo.services 10.0.0.0/14(rw,async,no_root_squash,no_wdelay,no_subtree_check)

   ```

2. Run the following command to export the newly added _elastic_ NFS mounts
   `exportfs -arv`

### Namespace & PV Initalisation

1. Create the namespace that the elasticstack will reside under.
   `kubectl create namespace elastic-dingo-services`
2. Switch kubectl's current working namespace to the namespace the elasticstack will reside under  
   `kubectl config set-context --current --namespace=elastic-dingo-services`
3. Copy the contents of the following `pv-elasticsearch-monitoring-dingo-services.yaml` and paste them into a new file.

   > [!NOTE]- pv-elasticsearch-monitoring-dingo-services.yaml
   >
   > ```yaml
   > apiVersion: v1
   > kind: PersistentVolume
   > metadata:
   >   name: pv-elasticsearch-monitoring-dingo-services
   > spec:
   >   storageClassName: "static"
   >   capacity:
   >     storage: 8Gi
   >   accessModes:
   >     - ReadWriteMany
   >   nfs:
   >     server: 10.0.0.1
   >     path: "/storage/static-volumes/dingo.services/elastic.dingo.services/elasticsearch.elastic.dingo.services"
   > ```

4. Copy the contents of the following `pv-logstash-monitoring-dingo-services.yaml` and paste them into a new file.

   > [!NOTE]- pv-logstash-monitoring-dingo-services.yaml
   >
   > ```yaml
   > apiVersion: v1
   > kind: PersistentVolume
   > metadata:
   >   name: pv-logstash-monitoring-dingo-services
   > spec:
   >   storageClassName: "static"
   >   capacity:
   >     storage: 1Gi
   >   accessModes:
   >     - ReadWriteMany
   >   nfs:
   >     server: 10.0.0.1
   >     path: "/storage/static-volumes/dingo.services/elastic.dingo.services/logstash.elastic.dingo.services"
   > ```

5. `kubectl apply -f pv-elasticsearch-monitoring-dingo-services.yaml`

6. `kubectl apply -f pv-logstash-monitoring-dingo-services.yaml`

### Helm Manifest Configuration

#### ElasticSearch

1. Copy the contents of the following `helm-elasticsearch-values.yaml` YAML manifest and paste the contents into a new file.

   > [!NOTE]- helm-elasticsearch-values.yaml
   >
   > ```yaml
   > clusterName: "elastic-dingo-services"
   > nodeGroup: "master"
   >
   > # The service that non master groups will try to connect to when joining the cluster
   > # This should be set to clusterName + "-" + nodeGroup for your master group
   > masterService: ""
   >
   > # Elasticsearch roles that will be applied to this nodeGroup
   > # These will be set as environment variables. E.g. node.master=true
   > roles:
   >   master: "true"
   >   ingest: "true"
   >   data: "true"
   >   remote_cluster_client: "true"
   >   ml: "true"
   >
   > replicas: 1
   > minimumMasterNodes: 1
   >
   > esMajorVersion: ""
   >
   > clusterDeprecationIndexing: "false"
   >
   > # Allows you to add any config files in /usr/share/elasticsearch/config/
   > # such as elasticsearch.yml and log4j2.properties
   > esConfig: {}
   > #  elasticsearch.yml: |
   > #    key:
   > #      nestedkey: value
   > #  log4j2.properties: |
   > #    key = value
   >
   > esJvmOptions: {}
   > #  processors.options: |
   > #    -XX:ActiveProcessorCount=3
   >
   > # Extra environment variables to append to this nodeGroup
   > # This will be appended to the current 'env:' key. You can use any of the kubernetes env
   > # syntax here
   > extraEnvs: []
   > #  - name: MY_ENVIRONMENT_VAR
   > #    value: the_value_goes_here
   >
   > # Allows you to load environment variables from kubernetes secret or config map
   > envFrom: []
   > # - secretRef:
   > #     name: env-secret
   > # - configMapRef:
   > #     name: config-map
   >
   > # A list of secrets and their paths to mount inside the pod
   > # This is useful for mounting certificates for security and for mounting
   > # the X-Pack license
   > secretMounts: []
   > #  - name: elastic-certificates
   > #    secretName: elastic-certificates
   > #    path: /usr/share/elasticsearch/config/certs
   > #    defaultMode: 0755
   >
   > hostAliases: []
   > #- ip: "127.0.0.1"
   > #  hostnames:
   > #  - "foo.local"
   > #  - "bar.local"
   >
   > image: "docker.elastic.co/elasticsearch/elasticsearch"
   > imageTag: "7.17.3"
   > imagePullPolicy: "IfNotPresent"
   >
   > podAnnotations:
   >   {}
   >   # iam.amazonaws.com/role: es-cluster
   >
   > # additionals labels
   > labels: {}
   >
   > esJavaOpts: "-Xmx1g -Xms1g" # example: "-Xmx1g -Xms1g"
   >
   > resources:
   >   requests:
   >     cpu: "1000m"
   >     memory: "2Gi"
   >   limits:
   >     cpu: "48"
   >     memory: "2Gi"
   >
   > initResources:
   >   {}
   >   # limits:
   >   #   cpu: "25m"
   >   #   # memory: "128Mi"
   >   # requests:
   >   #   cpu: "25m"
   >   #   memory: "128Mi"
   >
   > networkHost: "0.0.0.0"
   >
   > volumeClaimTemplate:
   >   volumeName: pv-elasticsearch-monitoring-dingo-services
   >   storageClassName: "static"
   >   accessModes: ["ReadWriteMany"]
   >   resources:
   >     requests:
   >       storage: 8Gi
   >
   > rbac:
   >   create: false
   >   serviceAccountAnnotations: {}
   >   serviceAccountName: ""
   >   automountToken: true
   >
   > podSecurityPolicy:
   >   create: false
   >   name: ""
   >   spec:
   >     privileged: true
   >     fsGroup:
   >       rule: RunAsAny
   >     runAsUser:
   >       rule: RunAsAny
   >     seLinux:
   >       rule: RunAsAny
   >     supplementalGroups:
   >       rule: RunAsAny
   >     volumes:
   >       - secret
   >       - configMap
   >       - persistentVolumeClaim
   >       - emptyDir
   >
   > persistence:
   >   enabled: true
   >   labels:
   >     # Add default labels for the volumeClaimTemplate of the StatefulSet
   >     enabled: false
   >   annotations: {}
   >
   > extraVolumes:
   >   []
   >   # - name: extras
   >   #   emptyDir: {}
   >
   > extraVolumeMounts:
   >   []
   >   # - name: extras
   >   #   mountPath: /usr/share/extras
   >   #   readOnly: true
   >
   > extraContainers:
   >   []
   >   # - name: do-something
   >   #   image: busybox
   >   #   command: ['do', 'something']
   >
   > extraInitContainers:
   >   []
   >   # - name: do-something
   >   #   image: busybox
   >   #   command: ['do', 'something']
   >
   > # This is the PriorityClass settings as defined in
   > # https://kubernetes.io/docs/concepts/configuration/pod-priority-preemption/#priorityclass
   > priorityClassName: ""
   >
   > # By default this will make sure two pods don't end up on the same node
   > # Changing this to a region would allow you to spread pods across regions
   > antiAffinityTopologyKey: "kubernetes.io/hostname"
   >
   > # Hard means that by default pods will only be scheduled if there are enough nodes for them
   > # and that they will never end up on the same node. Setting this to soft will do this "best effort"
   > antiAffinity: "hard"
   >
   > # This is the node affinity settings as defined in
   > # https://kubernetes.io/docs/concepts/configuration/assign-pod-node/#node-affinity-beta-feature
   > nodeAffinity: {}
   >
   > # The default is to deploy all pods serially. By setting this to parallel all pods are started at
   > # the same time when bootstrapping the cluster
   > podManagementPolicy: "Parallel"
   >
   > # The environment variables injected by service links are not used, but can lead to slow Elasticsearch boot times when
   > # there are many services in the current namespace.
   > # If you experience slow pod startups you probably want to set this to `false`.
   > enableServiceLinks: true
   >
   > protocol: http
   > httpPort: 9200
   > transportPort: 9300
   >
   > service:
   >   enabled: true
   >   labels: {}
   >   labelsHeadless: {}
   >   type: LoadBalancer
   >   # Consider that all endpoints are considered "ready" even if the Pods themselves are not
   >   # https://kubernetes.io/docs/reference/kubernetes-api/service-resources/service-v1/#ServiceSpec
   >   publishNotReadyAddresses: false
   >   nodePort: ""
   >   annotations:
   >     metallb.universe.tf/loadBalancerIPs: 100.64.2.2,fd:0:0:0:fe:64:2:2
   >   httpPortName: http
   >   transportPortName: transport
   >   loadBalancerIP: ""
   >   loadBalancerSourceRanges: []
   >   externalTrafficPolicy: ""
   >
   > updateStrategy: RollingUpdate
   >
   > # This is the max unavailable setting for the pod disruption budget
   > # The default value of 1 will make sure that kubernetes won't allow more than 1
   > # of your pods to be unavailable during maintenance
   > maxUnavailable: 1
   >
   > podSecurityContext:
   >   fsGroup: 1000
   >   runAsUser: 1000
   >
   > securityContext:
   >   capabilities:
   >     drop:
   >       - ALL
   >   # readOnlyRootFilesystem: true
   >   runAsNonRoot: true
   >   runAsUser: 1000
   >
   > # How long to wait for elasticsearch to stop gracefully
   > terminationGracePeriod: 120
   >
   > sysctlVmMaxMapCount: 262144
   >
   > readinessProbe:
   >   failureThreshold: 3
   >   initialDelaySeconds: 10
   >   periodSeconds: 10
   >   successThreshold: 3
   >   timeoutSeconds: 5
   >
   > # https://www.elastic.co/guide/en/elasticsearch/reference/7.17/cluster-health.html#request-params wait_for_status
   > clusterHealthCheckParams: "wait_for_status=green&timeout=1s"
   >
   > ## Use an alternate scheduler.
   > ## ref: https://kubernetes.io/docs/tasks/administer-cluster/configure-multiple-schedulers/
   > ##
   > schedulerName: ""
   >
   > imagePullSecrets: []
   > nodeSelector: {}
   > tolerations: []
   >
   > # Enabling this will publicly expose your Elasticsearch instance.
   > # Only enable this if you have security enabled on your cluster
   > ingress:
   >   enabled: false
   >   annotations: {}
   >   # kubernetes.io/ingress.class: nginx
   >   # kubernetes.io/tls-acme: "true"
   >   className: "nginx"
   >   pathtype: ImplementationSpecific
   >   hosts:
   >     - host: chart-example.local
   >       paths:
   >         - path: /
   >   tls: []
   >   #  - secretName: chart-example-tls
   >   #    hosts:
   >   #      - chart-example.local
   >
   > nameOverride: ""
   > fullnameOverride: ""
   > healthNameOverride: ""
   >
   > lifecycle:
   >   {}
   >   # preStop:
   >   #   exec:
   >   #     command: ["/bin/sh", "-c", "echo Hello from the postStart handler > /usr/share/message"]
   >   # postStart:
   >   #   exec:
   >   #     command:
   >   #       - bash
   >   #       - -c
   >   #       - |
   >   #         #!/bin/bash
   >   #         # Add a template to adjust number of shards/replicas
   >   #         TEMPLATE_NAME=my_template
   >   #         INDEX_PATTERN="logstash-*"
   >   #         SHARD_COUNT=8
   >   #         REPLICA_COUNT=1
   >   #         ES_URL=http://localhost:9200
   >   #         while [[ "$(curl -s -o /dev/null -w '%{http_code}\n' $ES_URL)" != "200" ]]; do sleep 1; done
   >   #         curl -XPUT "$ES_URL/_template/$TEMPLATE_NAME" -H 'Content-Type: application/json' -d'{"index_patterns":['\""$INDEX_PATTERN"\"'],"settings":{"number_of_shards":'$SHARD_COUNT',"number_of_replicas":'$REPLICA_COUNT'}}'
   >
   > sysctlInitContainer:
   >   enabled: true
   >
   > keystore: []
   >
   > networkPolicy:
   >   ## Enable creation of NetworkPolicy resources. Only Ingress traffic is filtered for now.
   >   ## In order for a Pod to access Elasticsearch, it needs to have the following label:
   >   ## {{ template "uname" . }}-client: "true"
   >   ## Example for default configuration to access HTTP port:
   >   ## elasticsearch-master-http-client: "true"
   >   ## Example for default configuration to access transport port:
   >   ## elasticsearch-master-transport-client: "true"
   >
   >   http:
   >     enabled: false
   >     ## if explicitNamespacesSelector is not set or set to {}, only client Pods being in the networkPolicy's namespace
   >     ## and matching all criteria can reach the DB.
   >     ## But sometimes, we want the Pods to be accessible to clients from other namespaces, in this case, we can use this
   >     ## parameter to select these namespaces
   >     ##
   >     # explicitNamespacesSelector:
   >     #   # Accept from namespaces with all those different rules (only from whitelisted Pods)
   >     #   matchLabels:
   >     #     role: frontend
   >     #   matchExpressions:
   >     #     - {key: role, operator: In, values: [frontend]}
   >     ## Additional NetworkPolicy Ingress "from" rules to set. Note that all rules are OR-ed.
   >     ##
   >     # additionalRules:
   >     #   - podSelector:
   >     #       matchLabels:
   >     #         role: frontend
   >     #   - podSelector:
   >     #       matchExpressions:
   >     #         - key: role
   >     #           operator: In
   >     #           values:
   >     #             - frontend
   >
   >   transport:
   >     ## Note that all Elasticsearch Pods can talk to themselves using transport port even if enabled.
   >     enabled: false
   >     # explicitNamespacesSelector:
   >     #   matchLabels:
   >     #     role: frontend
   >     #   matchExpressions:
   >     #     - {key: role, operator: In, values: [frontend]}
   >     # additionalRules:
   >     #   - podSelector:
   >     #       matchLabels:
   >     #         role: frontend
   >     #   - podSelector:
   >     #       matchExpressions:
   >     #         - key: role
   >     #           operator: In
   >     #           values:
   >     #             - frontend
   >
   > tests:
   >   enabled: true
   >
   > # Deprecated
   > # please use the above podSecurityContext.fsGroup instead
   > fsGroup: ""
   > ```

#### Logstash

1. Copy the contents of the following `helm-logstash-values.yaml` YAML manifest and paste the contents into a new file.
   > [!NOTE]- helm-logstash-values.yaml
   >
   > ```yaml
   > replicas: 1
   >
   > # Allows you to add any config files in /usr/share/logstash/config/
   > # such as logstash.yml and log4j2.properties
   > #
   > # Note that when overriding logstash.yml, `http.host: 0.0.0.0` should always be included
   > # to make default probes work.
   > logstashConfig: {}
   > #  logstash.yml: |
   > #    key:
   > #      nestedkey: value
   > #  log4j2.properties: |
   > #    key = value
   >
   > # Allows you to add any pipeline files in /usr/share/logstash/pipeline/
   > ### ***warn*** there is a hardcoded logstash.conf in the image, override it first
   > logstashPipeline: {}
   > #  logstash.conf: |
   > #    input {
   > #      exec {
   > #        command => "uptime"
   > #        interval => 30
   > #      }
   > #    }
   > #    output { stdout { } }
   >
   > # Allows you to add any pattern files in your custom pattern dir
   > logstashPatternDir: "/usr/share/logstash/patterns/"
   > logstashPattern: {}
   > #    pattern.conf: |
   > #      DPKG_VERSION [-+~<>\.0-9a-zA-Z]+
   >
   > # Extra environment variables to append to this nodeGroup
   > # This will be appended to the current 'env:' key. You can use any of the kubernetes env
   > # syntax here
   > extraEnvs: []
   > #  - name: MY_ENVIRONMENT_VAR
   > #    value: the_value_goes_here
   >
   > # Allows you to load environment variables from kubernetes secret or config map
   > envFrom: []
   > # - secretRef:
   > #     name: env-secret
   > # - configMapRef:
   > #     name: config-map
   >
   > # Add sensitive data to k8s secrets
   > secrets: []
   > #  - name: "env"
   > #    value:
   > #      ELASTICSEARCH_PASSWORD: "LS1CRUdJTiBgUFJJVkFURSB"
   > #      api_key: ui2CsdUadTiBasRJRkl9tvNnw
   > #  - name: "tls"
   > #    value:
   > #      ca.crt: |
   > #        LS0tLS1CRUdJT0K
   > #        LS0tLS1CRUdJT0K
   > #        LS0tLS1CRUdJT0K
   > #        LS0tLS1CRUdJT0K
   > #      cert.crt: "LS0tLS1CRUdJTiBlRJRklDQVRFLS0tLS0K"
   > #      cert.key.filepath: "secrets.crt" # The path to file should be relative to the `values.yaml` file.
   >
   > # A list of secrets and their paths to mount inside the pod
   > secretMounts: []
   >
   > hostAliases: []
   > #- ip: "127.0.0.1"
   > #  hostnames:
   > #  - "foo.local"
   > #  - "bar.local"
   >
   > image: "docker.elastic.co/logstash/logstash"
   > imageTag: "7.17.3"
   > imagePullPolicy: "IfNotPresent"
   > imagePullSecrets: []
   >
   > podAnnotations: {}
   >
   > # additionals labels
   > labels: {}
   >
   > logstashJavaOpts: "-Xmx1g -Xms1g"
   >
   > resources:
   >   requests:
   >     cpu: "100m"
   >     memory: "1536Mi"
   >   limits:
   >     cpu: "1000m"
   >     memory: "1536Mi"
   >
   > volumeClaimTemplate:
   >   volumeName: pv-logstash-monitoring-dingo-services
   >   storageClassName: "static"
   >   accessModes: ["ReadWriteMany"]
   >   resources:
   >     requests:
   >       storage: 1Gi
   >
   > rbac:
   >   create: false
   >   serviceAccountAnnotations: {}
   >   serviceAccountName: ""
   >   annotations:
   >     {}
   >     #annotation1: "value1"
   >     #annotation2: "value2"
   >     #annotation3: "value3"
   >
   > podSecurityPolicy:
   >   create: false
   >   name: ""
   >   spec:
   >     privileged: false
   >     fsGroup:
   >       rule: RunAsAny
   >     runAsUser:
   >       rule: RunAsAny
   >     seLinux:
   >       rule: RunAsAny
   >     supplementalGroups:
   >       rule: RunAsAny
   >     volumes:
   >       - secret
   >       - configMap
   >       - persistentVolumeClaim
   >
   > persistence:
   >   enabled: true
   >   annotations: {}
   >
   > extraVolumes:
   >   []
   >   # - name: extras
   >   #   emptyDir: {}
   >
   > extraVolumeMounts:
   >   []
   >   # - name: extras
   >   #   mountPath: /usr/share/extras
   >   #   readOnly: true
   >
   > extraContainers:
   >   []
   >   # - name: do-something
   >   #   image: busybox
   >   #   command: ['do', 'something']
   >
   > extraInitContainers:
   >   []
   >   # - name: do-something
   >   #   image: busybox
   >   #   command: ['do', 'something']
   >
   > # This is the PriorityClass settings as defined in
   > # https://kubernetes.io/docs/concepts/configuration/pod-priority-preemption/#priorityclass
   > priorityClassName: ""
   >
   > # By default this will make sure two pods don't end up on the same node
   > # Changing this to a region would allow you to spread pods across regions
   > antiAffinityTopologyKey: "kubernetes.io/hostname"
   >
   > # Hard means that by default pods will only be scheduled if there are enough nodes for them
   > # and that they will never end up on the same node. Setting this to soft will do this "best effort"
   > antiAffinity: "hard"
   >
   > # This is the node affinity settings as defined in
   > # https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/#node-affinity
   > nodeAffinity: {}
   >
   > # This is inter-pod affinity settings as defined in
   > # https://kubernetes.io/docs/concepts/scheduling-eviction/assign-pod-node/#inter-pod-affinity-and-anti-affinity
   > podAffinity: {}
   >
   > # The default is to deploy all pods serially. By setting this to parallel all pods are started at
   > # the same time when bootstrapping the cluster
   > podManagementPolicy: "Parallel"
   >
   > httpPort: 9600
   >
   > # Custom ports to add to logstash
   > extraPorts:
   >   []
   >   # - name: beats
   >   #   containerPort: 5001
   >
   > updateStrategy: RollingUpdate
   >
   > # This is the max unavailable setting for the pod disruption budget
   > # The default value of 1 will make sure that kubernetes won't allow more than 1
   > # of your pods to be unavailable during maintenance
   > maxUnavailable: 1
   >
   > podSecurityContext:
   >   fsGroup: 1000
   >   runAsUser: 1000
   >
   > securityContext:
   >   capabilities:
   >     drop:
   >       - ALL
   >   # readOnlyRootFilesystem: true
   >   runAsNonRoot: true
   >   runAsUser: 1000
   >
   > # How long to wait for logstash to stop gracefully
   > terminationGracePeriod: 120
   >
   > # Probes
   > # Default probes are using `httpGet` which requires that `http.host: 0.0.0.0` is part of
   > # `logstash.yml`. If needed probes can be disabled or overridden using the following syntaxes:
   > #
   > # disable livenessProbe
   > # livenessProbe: null
   > #
   > # replace httpGet default readinessProbe by some exec probe
   > # readinessProbe:
   > #   httpGet: null
   > #   exec:
   > #     command:
   > #       - curl
   > #      - localhost:9600
   >
   > livenessProbe:
   >   httpGet:
   >     path: /
   >     port: http
   >   initialDelaySeconds: 300
   >   periodSeconds: 10
   >   timeoutSeconds: 5
   >   failureThreshold: 3
   >   successThreshold: 1
   >
   > readinessProbe:
   >   httpGet:
   >     path: /
   >     port: http
   >   initialDelaySeconds: 60
   >   periodSeconds: 10
   >   timeoutSeconds: 5
   >   failureThreshold: 3
   >   successThreshold: 3
   >
   > ## Use an alternate scheduler.
   > ## ref: https://kubernetes.io/docs/tasks/administer-cluster/configure-multiple-schedulers/
   > ##
   > schedulerName: ""
   >
   > nodeSelector: {}
   > tolerations: []
   >
   > nameOverride: ""
   > fullnameOverride: ""
   >
   > lifecycle:
   >   {}
   >   # preStop:
   >   #   exec:
   >   #     command: ["/bin/sh", "-c", "echo Hello from the postStart handler > /usr/share/message"]
   >   # postStart:
   >   #   exec:
   >   #     command: ["/bin/sh", "-c", "echo Hello from the postStart handler > /usr/share/message"]
   >
   > service:
   >   annotations:
   >     metallb.universe.tf/loadBalancerIPs: 100.64.2.1,fd:0:0:0:fe:64:2:1
   >   type: LoadBalancer
   >   loadBalancerIP: ""
   >   ports:
   >     - name: syslog-tcp
   >       port: 514
   >       protocol: TCP
   >       targetPort: 1514
   >     - name: syslog-udp
   >       port: 514
   >       protocol: UDP
   >       targetPort: 1514
   >     - name: beats
   >       port: 5044
   >       protocol: TCP
   >       targetPort: 5044
   >     - name: http
   >       port: 8080
   >       protocol: TCP
   >       targetPort: 8080
   >
   > ingress:
   >   enabled: false
   >   annotations:
   >     {}
   >     # kubernetes.io/tls-acme: "true"
   >   className: "nginx"
   >   pathtype: ImplementationSpecific
   >   hosts:
   >     - host: logstash-example.local
   >       paths:
   >         - path: /beats
   >           servicePort: 5044
   >         - path: /http
   >           servicePort: 8080
   >   tls: []
   >   #  - secretName: logstash-example-tls
   >   #    hosts:
   >   #      - logstash-example.local
   > ```

### Helm Installation

1. `helm repo add elastic https://helm.elastic.co/`
2. `helm install -n elastic-dingo-services elasticsearch-elastic-dingo-services elastic/elasticsearch -f helm-elasticsearch-values.yaml`
3. `helm install -n elastic-dingo-services logstash-elastic-dingo-services elastic/logstash -f helm-logstash-values.yaml`
4. `helm install -n elastic-dingo-services kibana-elastic-dingo-services elastic/kibana -f helm-kibana-values.yaml`

```
helm upgrade -n elastic-dingo-services elasticsearch-dingo-services elastic/elasticsearch -f elasticsearch.elastic.dingo.services/helm-elasticsearch-values.yaml

helm upgrade -n elastic-dingo-services logstash-elastic-dingo-services elastic/logstash -f logstash.elastic.dingo.services/helm-logstash-values.yaml

helm upgrade -n elastic-dingo-services kibana-elastic-dingo-services elastic/kibana -f kibana.elastic.dingo.services/helm-kibana-values.yaml
```

### Patch ElasticSearch for 8.3.3

1. `kubectl edit statefulsets elastic-dingo-services-master`

   Removal all node.\* entries under env, append the following

   ```
        - name: xpack.security.enabled
          value: "false"
        - name: node.roles
          value: master, data
   ```

### Patch Services for IPv6 Support

1. `kubectl patch --patch '{ "spec": { "ipFamilyPolicy" : "PreferDualStack" } }' svc elastic-dingo-services-master`
1. `kubectl patch --patch '{ "spec": { "ipFamilyPolicy" : "PreferDualStack" } }' svc logstash-elastic-dingo-services-logstash`
1. `kubectl patch --patch '{ "spec": { "ipFamilyPolicy" : "PreferDualStack" } }' svc kibana-elastic-dingo-services-kibana`
