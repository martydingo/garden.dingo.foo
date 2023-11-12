### ZFS Datasets

1. `zfs create storage/static-volumes/dingo.services/home.dingo.services/mosquitto`
2. `zfs create storage/static-volumes/dingo.services/home.dingo.services/mosquitto/config`
3. `zfs create storage/static-volumes/dingo.services/home.dingo.services/mosquitto/data`

### NFS Exports

```
## mosquitto-home.dingo.services

# NFS Export for config-mosquitto-home.dingo.services
/storage/static-volumes/dingo.services/home.dingo.services/mosquitto/config 10.0.0.0/14(rw,async,no_root_squash,no_wdelay,no_subtree_check)

# NFS Export for data-mosquitto-home.dingo.services
/storage/static-volumes/dingo.services/home.dingo.services/mosquitto/data 10.0.0.0/14(rw,async,no_root_squash,no_wdelay,no_subtree_check)
```

`chown -R 1883:1883 /storage/static-volumes/dingo.services/home.dingo.services/mosquitto`

`exportfs -arv`

### PV Initialisation

`kubectl apply -f storage-mosquitto-home.dingo.services.yaml`

```yaml
###
# Kubernetes Storage Manifest - "mosquitto-home.dingo.services"
###

####
## Persistent Volume YAML
####

#####
### pv-data-mqtt-home-services
#####
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-data-mosquitto-home-dingo-services
  namespace: home-dingo-services
spec:
  capacity:
    storage: 1Gi
  accessModes:
    - ReadWriteMany
  nfs:
    server: 10.0.0.1
    path: "/storage/static-volumes/dingo.services/home.dingo.services/mosquitto/data"


#####
### pv-config-mqtt-home-services
#####
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-config-mosquitto-home-dingo-services
  namespace: home-dingo-services
spec:
  capacity:
    storage: 1Gi
  accessModes:
    - ReadWriteMany
  nfs:
    server: 10.0.0.1
    path: "/storage/static-volumes/dingo.services/home.dingo.services/mosquitto/config"

####
## Persistent Volume Claim YAML
####

#####
### pvc-data-mosquitto-home-dingo-services
#####
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-data-mosquitto-home-dingo-services
  namespace: home-dingo-services
spec:
  accessModes:
    - ReadWriteMany
  storageClassName: ""
  volumeName: pv-data-mosquitto-home-dingo-services
  resources:
    requests:
      storage: 1Gi

#####
### pvc-config-mosquitto-home-dingo-services
#####
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-config-mosquitto-home-dingo-services
  namespace: home-dingo-services
spec:
  accessModes:
    - ReadWriteMany
  storageClassName: ""
  volumeName: pv-config-mosquitto-home-dingo-services
  resources:
    requests:
      storage: 1Gi

```

### Mosquitto Configurations

#### mosquitto.conf

```conf
log_dest stdout
log_type error
log_type warning
log_type notice
log_type information

password_file /mosquitto/configinc/passwd
acl_file /mosquitto/configinc/acl
```

Further details on how to configure mosquitto can be found [here](mosquitto_website)
Be sure to use the older hash algorithim when using mosquitto's passwd tool (`-H sha512`, not `--H sha512-pbkdf2`)



### Helm 
[k8s-at-home](https://docs.k8s-at-home.com/)

1. Fetch the `values.yml` file for `k8s-at-home/homeassistant`, and save this to `helm-homeassistant-values.yaml`
```
helm show values k8s-at-home/homeassistant > helm-mosquitto-values.yaml
```

2. Edit the configuration parameters within `helm-mosquitto-values.yaml` to your liking. [Here is the `values.yml` file I'm using](Link Me To Spacebook).

3. `helm install -n home-dingo-services mosquitto-home-dingo-services k8s-at-home/mosquitto -f helm-mosquitto-values.yaml` 
4. (Optional) Patch the service for IPv6 support. 
   `kubectl patch --patch '{ "spec": { "ipFamilyPolicy" : "PreferDualStack" } }' svc mosquitto-home-dingo-services`

Accessing the Mosquitto container can be done by executing the following command:
`kubectl exec -it <pod_name> -- ash`
e.g 
`kubectl exec -it mosquitto-home-dingo-services-6db5d546fb-wf54z -- ash`

To create a new user, run 

`mosquitto_passwd  -b -H sha512 /mosquitto/configinc/passwd <user> <password>`

`mosquitto_passwd -b -H sha512 /mosquitto/configinc/passwd enviroplus zSJmZuEcWAN836EU`
