### Helm Chart Values

`helm show values k8s-at-home/esphome`

### ZFS Datasets

1. `zfs create storage/static-volumes/dingo.services/home.dingo.services`
2. `zfs create storage/static-volumes/dingo.services/home.dingo.services/homeassistant`
3. `zfs create storage/static-volumes/dingo.services/home.dingo.services/homeassistant/config`
5. `zfs create storage/static-volumes/dingo.services/home.dingo.services/homeassistant/postgres`
4. `zfs create storage/static-volumes/dingo.services/home.dingo.services/homeassistant/influxdb`

### NFS Exports

```
## home.dingo.services

# NFS export for config-home.dingo.services
/storage/static-volumes/dingo.services/home.dingo.services/homeassistant/config 10.0.0.0/14(rw,async,no_root_squash,no_wdelay,no_subtree_check)

# NFS export for postgres-home.dingo.services
/storage/static-volumes/dingo.services/home.dingo.services/homeassistant/postgres 10.0.0.0/14(rw,async,no_root_squash,no_wdelay,no_subtree_check)

# NFS export for influxdb-home.dingo.services
/storage/static-volumes/dingo.services/home.dingo.services/homeassistant/influxdb 10.0.0.0/14(rw,async,no_root_squash,no_wdelay,no_subtree_check)
```

`exportfs -arv`

`chown 1001:1001 /storage/static-volumes/dingo.services/home.dingo.services/homeassistant/postgres`
`chown 1001:1001 /storage/static-volumes/dingo.services/home.dingo.services/homeassistant/influxdb`

## Namespace & Persistent Volume Initialistion

1. `kubectl create namespace home-dingo-services`
2. Switch into namespace
3. `kubectl apply -f storage-home.dingo.services.yaml`

```yaml
###
# HOME ASSISTANT YAML Configuration - "home.dingo.services"
###

####
## Persistent Volume YAML
####

#####
### pv-config-home-services
#####
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-config-home-dingo-services
  namespace: home-dingo-services
spec:
  capacity:
    storage: 4Gi
  accessModes:
    - ReadWriteMany
  nfs:
    server: 10.0.0.1
    path: "/storage/static-volumes/dingo.services/home.dingo.services/homeassistant/config"

#####
### pv-postgres-home-dingo-services
#####

---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-postgres-home-dingo-services
  namespace: home-dingo-services
spec:
  capacity:
    storage: 4Gi
  accessModes:
    - ReadWriteMany
  nfs:
    server: 10.0.0.1
    path: "/storage/static-volumes/dingo.services/home.dingo.services/homeassistant/postgres"

#####
### pv-influxdb-home-dingo-services
#####

---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-influxdb-home-dingo-services
  namespace: home-dingo-services
spec:
  capacity:
    storage: 4Gi
  accessModes:
    - ReadWriteMany
  nfs:
    server: 10.0.0.1
    path: "/storage/static-volumes/dingo.services/home.dingo.services/homeassistant/influxdb"


####
## Persistent Volume Claim YAML
####

#####
### pvc-config-home-services
#####
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-config-home-dingo-services
  namespace: home-dingo-services
spec:
  accessModes:
    - ReadWriteMany
  storageClassName: ""
  volumeName: pv-config-home-dingo-services
  resources:
    requests:
      storage: 4Gi

#####
### pvc-postgres-home-services
#####

---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-postgres-home-dingo-services
  namespace: home-dingo-services
spec:
  accessModes:
    - ReadWriteMany
  storageClassName: ""
  volumeName: pv-postgres-home-dingo-services
  resources:
    requests:
      storage: 4Gi

#####
### pvc-influxdb-home-services
#####

---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-influxdb-home-dingo-services
  namespace: home-dingo-services
spec:
  accessModes:
    - ReadWriteMany
  storageClassName: ""
  volumeName: pv-influxdb-home-dingo-services
  resources:
    requests:
      storage: 4Gi
```

## Helm Repository

[k8s-at-home](https://docs.k8s-at-home.com/)

1. Add the repository to *Helm*
```
helm repo add k8s-at-home https://k8s-at-home.com/charts/
```

2. Fetch the `values.yml` file for `k8s-at-home/homeassistant`, and save this to `helm-homeassistant-values.yaml`
```
helm show values k8s-at-home/homeassistant > helm-homeassistant-values.yaml
```

3. Edit the configuration parameters within `helm-homeassistant-values.yaml` to your liking. [Here is the `values.yml` file I'm using](Link Me To Spacebook).

4. Install *Home Assistant* using Helm
   `helm install -n home-dingo-services homeassistant-home-dingo-services k8s-at-home/home-assistant -f helm-home-assistant-values.yaml `

5. Configure Home Assistant, and Login
6. Create a long lived token, then run the following command. 
   `kubectl create secret generic --from-literal prometheus=<token>`
7. Uninstall Home Assistant, then re-install after switching the `serviceMonitor` and `prometheusRule` enabled flags to true within the helm chart `values.yml` file. 
   `helm uninstall homeassistant-home-dingo-services`
   `helm install homeassistant-home-dingo-services k8s-at-home/home-assistant -f helm-home-assistant-values.yaml` 

Monitoring should now be active 

## InfluxDB
Fetch admin password
kubectl get secrets homeassistant-home-dingo-services-influxdb -o jsonpath={.data.admin-user-password} | base64 -d

Log in
Create Organisation & Bucket
Create API Token 
Configure Home Assistant

