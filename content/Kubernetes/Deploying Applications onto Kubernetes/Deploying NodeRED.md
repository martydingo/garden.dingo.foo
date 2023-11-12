### Helm

`helm show values k8s-at-home/node-red`

### ZFS Datasets

1. `zfs create storage/static-volumes/dingo.services/home.dingo.services/node-red`
2. `zfs create storage/static-volumes/dingo.services/home.dingo.services/node-red/data`

### NFS Exports

```
## node-red-home.dingo.services

# NFS Export for data-mosquitto-home.dingo.services
/storage/static-volumes/dingo.services/home.dingo.services/node-red/data 10.0.0.0/14(rw,async,no_root_squash,no_wdelay,no_subtree_check)
```

`chown -R 1000:1000 /storage/static-volumes/dingo.services/home.dingo.services/node-red`

`exportfs -arv`

### PV Initialisation 

```yaml
###
# node-red YAML datauration - "node-red.home.dingo.services"
###

####
## Persistent Volume YAML
####

#####
### pv-data-home-services
#####
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-data-node-red-home-dingo-services
  namespace: node-red-home-dingo-services
spec:
  capacity:
    storage: 1Gi
  accessModes:
    - ReadWriteMany
  nfs:
    server: 10.0.0.1
    path: "/storage/static-volumes/dingo.services/home.dingo.services/node-red/data"

####
## Persistent Volume Claim YAML
####

#####
### pvc-data-home-services
#####
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-data-node-red-home-dingo-services
  namespace: node-red-home-dingo-services
spec:
  accessModes:
    - ReadWriteMany
  storageClassName: ""
  volumeName: pv-data-node-red-home-dingo-services
  resources:
    requests:
      storage: 1Gi
```

### Kubernetes

1. `kubectl create namespace node-red-home-dingo-services`
2. Switch into Namespace
3. `kubectl apply -f storage-node-red.home.dingo.services.yaml`

### Helm

`helm install -n node-red-home-dingo-services node-red-home-dingo-services k8s-at-home/node-red -f helm-node-red-values.yaml`

### Node-Red Configuration

1. `kubectl exec -it <node-red-pod> -- bash`
2. `node-red admin hash-pw`
3. Copy the hash, and in `settings.js`:
	1. Uncomment `adminAuth`
	2. Replace the hash within `adminAuth.password` with the new generated hash