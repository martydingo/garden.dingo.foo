## Storage Preparation

### ZFS Dataset Creation

1. `zfs create storage/static-volumes/dingo.services/monitoring.dingo.services/elastiflow.monitoring.dingo.services`

### NFS 

1. Append the following to `/etc/exports`
   ```
   # NFS export for elastiflow.monitoring.dingo.services
   /storage/static-volumes/dingo.services/monitoring.dingo.services/elastiflow.monitoring.dingo.services 10.0.0.0/14(rw,async,no_root_squash,no_wdelay,no_subtree_check)
   ```

## Kubernetes

1. Add Namespace
   `kubectl create ns elastiflow-monitoring-dingo-services`

2. Configure Storage (PV & PVC Manifests) and apply it.
   ```yaml
   ####
   ## Persistent Volume YAML
   ####
   
   #####
   ### pv-elastiflow-monitoring-dingo-services
   #####
   ---
   apiVersion: v1
   kind: PersistentVolume
   metadata:
     name: pv-elastiflow-monitoring-dingo-services
     namespace: elastiflow-monitoring-dingo-services
   spec:
     capacity:
       storage: 10Gi
     accessModes:
       - ReadWriteMany
     nfs:
       server: 10.0.0.1
       path: "/storage/static-volumes/dingo.services/monitoring.dingo.services/elastiflow.monitoring.dingo.services/"
   
   ####
   ## Persistent Volume Claim YAML
   ####
   
   #####
   ### pvc-elastiflow-monitoring-dingo-services
   #####
   ---
   apiVersion: v1
   kind: PersistentVolumeClaim
   metadata:
     name: pvc-elastiflow-monitoring-dingo-services
     namespace: elastiflow-monitoring-dingo-services
   spec:
     accessModes:
       - ReadWriteMany
     storageClassName: ""
     volumeName: pv-elastiflow-monitoring-dingo-services
     resources:
       requests:
         storage: 10Gi
   ```
