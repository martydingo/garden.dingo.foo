## Introduction

## Preparation

### ZFS Dataset Creation

1. `zfs create storage/static-volumes`

2. `zfs create storage/static-volumes/dingo.services`

3. `zfs create storage/static-volumes/dingo.services/nic.dingo.services`

4. `zfs create storage/static-volumes/dingo.services/nic.dingo.services/dns.nic.dingo.services`

5. `zfs create storage/static-volumes/dingo.services/nic.dingo.services/dns.nic.dingo.services/core.dns.nic.dingo.services`

6. `zfs create storage/static-volumes/dingo.services/nic.dingo.services/dns.nic.dingo.services/front-end.dns.nic.dingo.services`

7. `zfs create storage/static-volumes/dingo.services/nic.dingo.services/dns.nic.dingo.services/front-end.dns.nic.dingo.services/ns-a.front-end.dns.nic.dingo.services`

8. `zfs create storage/static-volumes/dingo.services/nic.dingo.services/dns.nic.dingo.services/front-end.dns.nic.dingo.services/ns-b.front-end.dns.nic.dingo.services`

### Database Directories

1. Create _core nameserver_ database directory, and apply permissions

   1. `mkdir /storage/static-volumes/dingo.services/nic.dingo.services/dns.nic.dingo.services/core.dns.nic.dingo.services/db`
   2. `chown 999:999 /storage/static-volumes/dingo.services/nic.dingo.services/dns.nic.dingo.services/core.dns.nic.dingo.services/db`

2. Create _nameserver a_ database directory, and apply permissions

   1. `mkdir /storage/static-volumes/dingo.services/nic.dingo.services/dns.nic.dingo.services/front-end.dns.nic.dingo.services/ns-a.front-end.dns.nic.dingo.services/db`
   2. `chown 999:999 /storage/static-volumes/dingo.services/nic.dingo.services/dns.nic.dingo.services/front-end.dns.nic.dingo.services/ns-a.front-end.dns.nic.dingo.services/db`

3. Create _nameserver b_ database directory, and apply permissions
   1. `mkdir /storage/static-volumes/dingo.services/nic.dingo.services/dns.nic.dingo.services/front-end.dns.nic.dingo.services/ns-b.front-end.dns.nic.dingo.services/db`
   2. `chown 999:999 /storage/static-volumes/dingo.services/nic.dingo.services/dns.nic.dingo.services/front-end.dns.nic.dingo.services/ns-b.front-end.dns.nic.dingo.services/db`

### NFS Exports

1. Append to `/etc/exports`

   ```
   # NFS exports for core.dns.nic.dingo.services
   /storage/static-volumes/dingo.services/nic.dingo.services/dns.nic.dingo.services/core.dns.nic.dingo.services 10.0.0.0/14(rw,async,no_root_squash,no_wdelay,no_subtree_check)

   # NFS exports for ns-a.front-end.dns.nic.dingo.services
   /storage/static-volumes/dingo.services/nic.dingo.services/dns.nic.dingo.services/front-end.dns.nic.dingo.services/ns-a.front-end.dns.nic.dingo.services 10.0.0.0/14(rw,async,no_root_squash,no_wdelay,no_subtree_check)

   # NFS exports for ns-b.front-end.dns.nic.dingo.services
   /storage/static-volumes/dingo.services/nic.dingo.services/dns.nic.dingo.services/front-end.dns.nic.dingo.services/ns-b.front-end.dns.nic.dingo.services 10.0.0.0/14(rw,async,no_root_squash,no_wdelay,no_subtree_check)
   ```

2. `exportfs -arv`

## PowerDNS Deployment

### Core

#### PV Manifest

1. Create the following kubernetes manifest and paste the following contents into the file:

   pv-core.dns.nic.dingo.services.yaml

   ```yaml
   apiVersion: v1
   kind: PersistentVolume
   metadata:
     name: pv-core-nic-dns-dingo-services
   spec:
     capacity:
       storage: 1Gi
     accessModes:
       - ReadWriteMany
     nfs:
       server: 10.0.0.1
       path: "/storage/static-volumes/dingo.services/nic.dingo.services/dns.nic.dingo.services/core.dns.nic.dingo.services"
   ```

2. `kubectl create namespace dns.nic.dingo.services`

3. `kubectl apply -f pv-core.dns.nic.dingo.services.yaml`

#### Helm

1. `helm repo add helm-powerdns-authoritative https://martydingo.github.io/helm-powerdns-authoritative/`

2. Create the following file and paste the following contents into the file, making sure to configure the parameters within the configuration file after pasting, namely the `api-key` and database settings:

   helm-pdns-auth-core-values.yml

   ```yaml
   # Declare variables to be passed into the helm chart.

   # nameOverride: ""
   # fullnameOverride: ""
   imagePullSecrets: []

   storage:
     volumeClaimTemplate:
       accessMode: ReadWriteMany
       storageClassName: ""
       # If not using dynamic persistent storage, a persistentVolume configuration will need to be configured, and the pvName configured below.
       volumeName: "pv-core-dns-nic-dingo-services"
       resources:
         requests:
           storage: 1Gi

   mariadb:
     replicaCount: 1
     configuration:
       # A randomized root password will be configured, if rootPassword is declared undefined, and will be dumped to the database pods stdout (kubectl logs <db_pod>)
       rootPassword: 
       database: pdns
       user: pdns
       password: 
     image:
       repository: mariadb
       imagePullPolicy: IfNotPresent
       # This is set as such, as when mariadb doesn't exit cleanly, and a new container is pulled, the database fails to start
       # This is due to the fact that you can't upgrade a database that hasn't exited cleanly.
       tag: "10.7"
     resources:
       # Arbitrary resource values as resource requirements differ between use cases. Please reconfigure if this doesn't meet your requirements
       requests:
         memory: 128Mi
         cpu: 125m
       limits:
         memory: 512Mi
         cpu: 8000m
     service:
       type: ClusterIP
       clusterIP: "None"
       ipFamilyPolicy: PreferDualStack
       # Affects service and pdns configuration
       ports:
         db: 3306

   pdns:
     replicaCount: 1
     image:
       repository: powerdns/pdns-auth-master
       imagePullPolicy: IfNotPresent
       tag: "20220225"
     resources:
       # Arbitrary resource values as resource requirements differ between use cases. Please reconfigure if this doesn't meet your requirements
       requests:
         memory: 128Mi
         cpu: 125m
       limits:
         memory: 512Mi
         cpu: 8000m
     service:
       # Only affects the created kubernetes service
       type: LoadBalancer
       annotations:
         metallb.universe.tf/loadBalancerIPs: 100.66.0.1,fd:0:0:0:fe:66::1
       ipFamilyPolicy: PreferDualStack
       ports:
         dns: 53
         api: 8081
     configuration:
       # All values from https://doc.powerdns.com/authoritative/settings.html can be removed/added here as \<key\>: \<value\> pairs.
       # See usage of 'pdnsutil hash-password' for more information on webserver passwords & API keys - kubectl exec -it <pdns_pod_name> -- pdnsutil hash-password
       # and https://doc.powerdns.com/authoritative/settings.html#setting-webserver-password
       # ---
       api-key: 
       version-string: anonymous
       webserver: yes
       webserver-address: 0.0.0.0
       webserver-allow-from: 0.0.0.0/0
       primary: yes
       api: yes
       dnsupdate: yes
       allow-dnsupdate-from: 10.0.0.0/14
       allow-axfr-ips: 10.0.0.0/14
       also-notify: 100.66.2.1, 100.66.3.1
       default-soa-edit: EPOCH
       default-soa-content: core.dns.nic.dingo.services abuse.dns.nic.@ 0 10800 3600 604800 3600
       default-ttl: 60
       default-ksk-algorithm: ed25519
       svc-autohints: yes
   ```

3. `helm install -n dns-nic-dingo-services core-dns-nic-dingo-services helm-powerdns-authoritative/helm-powerdns-authoritative -f helm-pdns-auth-core-values.yml`

That should now result in a fully functional core nameserver.

### Front-End Nameservers

#### Nameserver A

##### Persistent Volume Configuration

1. Create the following kubernetes manifest and paste the following contents into the file:
   pv-ns-a.front-end.dns.nic.dingo.services.yml
   
   ```yaml
   apiVersion: v1
   kind: PersistentVolume
   metadata:
     name: pv-ns-a-front-end-dns-nic-dingo-services
   spec:
     capacity:
       storage: 1Gi
     accessModes:
       - ReadWriteMany
     nfs:
       server: 10.0.0.1
       path: "/storage/static-volumes/dingo.services/nic.dingo.services/dns.nic.dingo.services/front-end.dns.nic.dingo.services/ns-a.front-end.dns.nic.dingo.services"
   ```
2. `kubectl apply -f pv-ns-a.front-end.dns.nic.dingo.services.yml`

##### Installation via Helm

1. `helm repo add helm-powerdns-authoritative https://martydingo.github.io/helm-powerdns-authoritative/`

2. Create the following helm values file and paste the following contents into the file, making sure to configure the parameters within the configuration file after pasting, namely the `api-key` and database settings:

   helm-pdns-auth-front-end-ns-a-values.yml
   
   ```yaml
   # Declare variables to be passed into the helm chart.

   # nameOverride: ""
   # fullnameOverride: ""
   imagePullSecrets: []

   storage:
     volumeClaimTemplate:
       accessMode: ReadWriteMany
       storageClassName: ""
       # If not using dynamic persistent storage, a persistentVolume configuration will need to be configured, and the pvName configured below.
       volumeName: "pv-ns-a-front-end-dns-nic-dingo-services"
       resources:
         requests:
           storage: 1Gi

   mariadb:
     replicaCount: 1
     configuration:
       # A randomized root password will be configured, if rootPassword is declared undefined, and will be dumped to the database pods stdout (kubectl logs <db_pod>)
       rootPassword: 
       database: pdns
       user: pdns
       password: 
     image:
       repository: mariadb
       imagePullPolicy: IfNotPresent
       # This is set as such, as when mariadb doesn't exit cleanly, and a new container is pulled, the database fails to start
       # This is due to the fact that you can't upgrade a database that hasn't exited cleanly.
       tag: "10.7"
     resources:
       # Arbitrary resource values as resource requirements differ between use cases. Please reconfigure if this doesn't meet your requirements
       requests:
         memory: 128Mi
         cpu: 125m
       limits:
         memory: 512Mi
         cpu: 8000m
     service:
       type: ClusterIP
       clusterIP: "None"
       ipFamilyPolicy: PreferDualStack
       # Affects service and pdns configuration
       ports:
         db: 3306

   pdns:
     replicaCount: 1
     image:
       repository: powerdns/pdns-auth-master
       imagePullPolicy: IfNotPresent
       tag: "20220225"
     resources:
       # Arbitrary resource values as resource requirements differ between use cases. Please reconfigure if this doesn't meet your requirements
       requests:
         memory: 128Mi
         cpu: 125m
       limits:
         memory: 512Mi
         cpu: 8000m
     service:
       # Only affects the created kubernetes service
       annotations:
         metallb.universe.tf/loadBalancerIPs: 100.66.1.1,fd:0:0:0:fe:66:1:1
       type: LoadBalancer
       ipFamilyPolicy: PreferDualStack
       ports:
         dns: 53
         api: 8081
     configuration:
       # All values from https://doc.powerdns.com/authoritative/settings.html can be removed/added here as \<key\>: \<value\> pairs.
       # See usage of 'pdnsutil hash-password' for more information on webserver passwords & API keys - kubectl exec -it <pdns_pod_name> -- pdnsutil hash-password
       # and https://doc.powerdns.com/authoritative/settings.html#setting-webserver-password
       # ---
       api-key: 
       version-string: anonymous
       webserver: yes
       webserver-address: 0.0.0.0
       webserver-allow-from: 0.0.0.0/0
       secondary: yes
       autosecondary: yes
       api: yes
       dnsupdate: yes
       allow-dnsupdate-from: 10.1.0.0/16
   ```

3. `helm install -n dns-nic-dingo-services ns-a-front-end-dns-nic-dingo-services helm-powerdns-authoritative/helm-powerdns-authoritative -f helm-pdns-auth-front-end-ns-a-values.yml`

#### Nameserver B

##### Persistent Volume Configuration

1. Create the following kubernetes manifest and paste the following contents into the file:
   > [!NOTE]- pv-ns-b.front-end.dns.nic.dingo.services.yml
   >
   > ```yaml
   > apiVersion: v1
   > kind: PersistentVolume
   > metadata:
   >   name: pv-ns-b-front-end-dns-nic-dingo-services
   > spec:
   >   capacity:
   >     storage: 1Gi
   >   accessModes:
   >     - ReadWriteMany
   >   nfs:
   >     server: 10.0.0.1
   >     path: "/storage/static-volumes/dingo.services/nic.dingo.services/dns.nic.dingo.services/front-end.dns.nic.dingo.services/ns-b.front-end.dns.nic.dingo.services"
   > ```
2. `kubectl apply -f pv-ns-b.front-end.dns.nic.dingo.services.yml`

##### Installation via Helm

1. `helm repo add helm-powerdns-authoritative https://martydingo.github.io/helm-powerdns-authoritative/`

2. Create the following helm values file and paste the following contents into the file, making sure to configure the parameters within the configuration file after pasting, namely the `api-key` and database settings.

   helm-pdns-auth-front-end-ns-b-values.yml
   
   ```yaml
   # Declare variables to be passed into the helm chart.
   
   # nameOverride: ""
   # fullnameOverride: ""
   imagePullSecrets: []
   
   storage:
   volumeClaimTemplate:
      accessMode: ReadWriteMany
      storageClassName: ""
      # If not using dynamic persistent storage, a persistentVolume configuration will need to be configured, and the pvName configured below.
      volumeName: "pv-ns-b-front-end-dns-nic-dingo-services"
      resources:
         requests:
         storage: 1Gi
   
   mariadb:
     replicaCount: 1
     configuration:
      # A randomized root password will be configured, if rootPassword is declared undefined, and will be dumped to the database pods stdout (kubectl logs <db_pod>)
       rootPassword: 
       database: pdns
       user: pdns
       password: 
   image:
      repository: mariadb
      imagePullPolicy: IfNotPresent
      # This is set as such, as when mariadb doesn't exit cleanly, and a new container is pulled, the database fails to start
      # This is due to the fact that you can't upgrade a database that hasn't exited cleanly.
      tag: "10.7"
   resources:
      # Arbitrary resource values as resource requirements differ between use cases. Please reconfigure if this doesn't meet your requirements
      requests:
         memory: 128Mi
         cpu: 125m
      limits:
         memory: 512Mi
         cpu: 8000m
   service:
      type: ClusterIP
      clusterIP: "None"
      ipFamilyPolicy: PreferDualStack
      # Affects service and pdns configuration
      ports:
         db: 3306
   
   pdns:
   replicaCount: 1
   image:
      repository: powerdns/pdns-auth-master
      imagePullPolicy: IfNotPresent
      tag: "20220225"
   resources:
      # Arbitrary resource values as resource requirements differ between use cases. Please reconfigure if this doesn't meet your requirements
      requests:
         memory: 128Mi
         cpu: 125m
      limits:
         memory: 512Mi
         cpu: 8000m
   service:
      # Only affects the created kubernetes service
      type: LoadBalancer
      annotations:
         metallb.universe.tf/loadBalancerIPs: 100.66.2.1,fd:0:0:0:fe:66:2:1
      ipFamilyPolicy: PreferDualStack
      ports:
         dns: 53
         api: 8081
   configuration:
      # All values from https://doc.powerdns.com/authoritative/settings.html can be removed/added here as \<key\>: \<value\> pairs.
      # See usage of 'pdnsutil hash-password' for more information on webserver passwords & API keys - kubectl exec -it <pdns_pod_name> -- pdnsutil hash-password
      # and https://doc.powerdns.com/authoritative/settings.html#setting-webserver-password
      # ---
      api-key: 
      version-string: anonymous
      webserver: yes
      webserver-address: 0.0.0.0
      webserver-allow-from: 0.0.0.0/0
      secondary: yes
      autosecondary: yes
      api: yes
      dnsupdate: yes
      allow-dnsupdate-from: 10.1.0.0/16
   ```

3. `helm install -n dns-nic-dingo-services ns-b-front-end-dns-nic-dingo-services helm-powerdns-authoritative/helm-powerdns-authoritative -f helm-pdns-auth-front-end-ns-b-values.yml`

That should now result in a two functional front-end nameservers, ready to be connected to the core nameserver.

## PowerDNS Maintenance

Here's a script that updates the autoprimaries IP address, and the zone(s) primary nameserver IP address, within the front-end nameservers. This may need to happen each time a new core nameserver container is built, as the IP of the core nameserver changes with every deployment.

This ensures zone additions and updates undertaken on the core nameserver, notify the child front-end nameservers.

update-master-ip.sh
```bash
#!/bin/bash

echo "Fetching new core primary pod IP..."
echo "---"
export NEW_MASTER_IP=`kubectl get pods -n dns-nic-dingo-services -o json | jq -r ".items[] | select(select(.metadata.name | test(\"^$1\")).metadata.name | test(\"-db\") | not).status.podIP"`
echo "New core primary pod IP fetched! Found podIP $NEW_MASTER_IP"
echo "---"

echo "Fetching database secret from live deployment..."
echo "---"
export ROOT_DB_SECRET=`kubectl get deployment $1-db -o json | jq -r '.spec.template.spec.containers[0].env[] | select(.name | test("ROOT_PASSWORD")).value'`
echo "Database secret from live deployment fetched! Found secret $ROOT_DB_SECRET"
echo "---"

for EXT_NS_DB in `kubectl get pods -n dns-nic-dingo-services -o json | jq -r '.items[] | select(select(.metadata.name | test("ns")).metadata.name | test("-db")).metadata.name'`;
do
    echo "Updating Master IP on $EXT_NS_DB" to $NEW_MASTER_IP;
    echo "---"
    kubectl exec -n dns-nic-dingo-services -it $EXT_NS_DB -- mysql -D pdns -c -e "update supermasters set ip = '$NEW_MASTER_IP'; update domains set master = '$NEW_MASTER_IP'" -p$ROOT_DB_SECRET
done

echo "All external nameserver databases updated! unsettings environment variables"
echo "---"
unset NEW_MASTER_IP
unset ROOT_DB_SECRET
echo "---"
echo "Environment variables unset! All done!"
echo "---"
```
