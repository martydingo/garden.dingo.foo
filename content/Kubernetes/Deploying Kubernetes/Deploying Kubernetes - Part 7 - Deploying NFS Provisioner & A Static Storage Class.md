---
date: 2022-08-23
---
## Introduction

[nfs-subdir-external-provisioner](https://github.com/kubernetes-sigs/nfs-subdir-external-provisioner)

Welcome to the sixth part of our series on deploying Kubernetes! In this tutorial, we will be discussing how to deploy NFS provisioner for dynamic volume provisioning.

Dynamic volume provisioning allows us to automatically create storage volumes when persistent volume claims (PVCs) are made by our applications. This can be particularly useful in scenarios where we have a large number of PVCs that need to be dynamically created and bound to persistent volumes (PVs).

In this tutorial, we will be creating two dynamic volume provisioners, one for temporary persistent volumes and one for persistent persistent volumes, both of which will leverage NFS (Network File System). We will also create a static storage class so that we can bind non-dynamic PVCs to their respective PVs.

Before we get started, it is important to note that NFS provisioner requires an NFS server to be set up, which we did back in "Deploying Kubernetes Part 3 - Deploying the Network File Server"

In our benchmarks, we observe the following write performance: 

```bash
dd if=/dev/zero of=/storage/test1.img bs=5G count=4 oflag=dsync
---
8589918208 bytes (8.6 GB, 8.0 GiB) copied, 14.2745 s, 602 MB/s
```

Not too shabby at all!


## Preparing the NFS Server

1.  First, we will create the directories for our dynamic volumes on the NFS server:

	1. `zfs create storage/dynamic-volumes` 
	2. `zfs create storage/dynamic-volumes/persistent zfs create storage/dynamic-volumes/temporary`

2.  Next, we will change the ownership of these directories to `nobody`:

`chown -R nobody:nobody /storage/dynamic-volumes`

3.  Now, we will edit the `/etc/exports` file and append the following:

```bash
# NFS export for persistent-dynamic-volume-provisioner
/storage/dynamic-volumes/persistent 10.0.0.0/14(rw,async,no_root_squash,no_wdelay,no_subtree_check)  

# NFS export for temporary-dynamic-volume-provisioner
/storage/dynamic-volumes/temporary 10.0.0.0/14(rw,async,no_root_squash,no_wdelay,no_subtree_check)
```

4.  Finally, we will update the export list by running the following command:

`exportfs -arv`

### Installing NFS Utilities on All Kubernetes Nodes

In order to use NFS, we will need to install the `nfs-utils` package on all of our Kubernetes nodes (both control and worker nodes). We can do this by running the following command:

`dnf install nfs-utils -y`

## Deploying the Dynamic Volume Provisioners

Now that our NFS server is set up and our nodes have the necessary utilities installed, we can proceed to deploy our dynamic volume provisioners.

We will be using the `nfs-subdir-external-provisioner` Helm chart for this purpose. You can find more information about this chart at the following GitHub repository: [https://github.com/kubernetes-sigs/nfs-subdir-external-provisioner](https://github.com/kubernetes-sigs/nfs-subdir-external-provisioner).

### Deploying the Persistent Dynamic Volume Provisioner

1.  On the control node, create a file called `helm-nfs-subdir-external-provisioner-persistent-values.yaml`
   
2.  Paste the following contents into the file:

```yaml
replicaCount: 1
strategyType: Recreate

image:
  repository: k8s.gcr.io/sig-storage/nfs-subdir-external-provisioner
  tag: v4.0.2
  pullPolicy: IfNotPresent
imagePullSecrets: []

nfs:
  server: 10.0.0.1
  path: /storage/dynamic-volumes/persistent
  mountOptions:
  volumeName: persistent-dynamic-volumes
  # Reclaim policy for the main nfs volume
  reclaimPolicy: Retain

# For creating the StorageClass automatically:
storageClass:
  create: true

  # Set a provisioner name. If unset, a name will be generated.
  provisionerName: persistent-dynamic-volume-provisioner

  # Set StorageClass as the default StorageClass
  # Ignored if storageClass.create is false
  defaultClass: true

  # Set a StorageClass name
  # Ignored if storageClass.create is false
  name: persistent-dynamic-volume-provisioner

  # Allow volume to be expanded dynamically
  allowVolumeExpansion: true

  # Method used to reclaim an obsoleted volume
  reclaimPolicy: Retain

  # When set to false your PVs will not be archived by the provisioner upon deletion of the PVC.
  archiveOnDelete: true

  # If it exists and has 'delete' value, delete the directory. If it exists and has 'retain' value, save the directory.
  # Overrides archiveOnDelete.
  # Ignored if value not set.
  onDelete: retain

  # Specifies a template for creating a directory path via PVC metadata's such as labels, annotations, name or namespace.
  # Ignored if value not set.
  path: 

service:
  type: ClusterIP
  port: 2049

ingress:
  enabled: false
  annotations: {}
    # kubernetes.io/ingress.class: nginx
    # kubernetes.io/tls-acme: "true"
  hosts:
    - chart-example.local
  tls: []

resources: {}

nodeSelector: {}

tolerations: []

affinity: {}
```

3.  Run the following command to install the persistent dynamic volume provisioner using Helm:

`helm install nfs-subdir-external-provisioner persistent-dynamic-volume-provisioner -f helm-nfs-subdir-external-provisioner-persistent-values.yaml`

This will create a deployment and a service for the persistent dynamic volume provisioner, as well as a storage class called `persistent-dynamic-volume-provisioner`.

### Deploying the Temporary Dynamic Volume Provisioner

1.  On the control node, create a file called `helm-nfs-subdir-external-provisioner-temporary-values.yaml`.
    
2.  Paste the following contents into the file:
`
```yaml
 replicaCount: 1
 strategyType: Recreate
 
 image:
   repository: k8s.gcr.io/sig-storage/nfs-subdir-external-provisioner
   tag: v4.0.2
   pullPolicy: IfNotPresent
 imagePullSecrets: []
 
 nfs:
   server: 10.0.0.1
   path: /storage/dynamic-volumes/temporary
   mountOptions:
   volumeName: temporary-dynamic-volumes
   # Reclaim policy for the main nfs volume
   reclaimPolicy: Delete
 
 # For creating the StorageClass automatically:
 storageClass:
   create: true
 
   # Set a provisioner name. If unset, a name will be generated.
   provisionerName: temporary-dynamic-volume-provisioner
 
   # Set StorageClass as the default StorageClass
   # Ignored if storageClass.create is false
   defaultClass: false
 
   # Set a StorageClass name
   # Ignored if storageClass.create is false
   name: temporary-dynamic-volume-provisioner
 
   # Allow volume to be expanded dynamically
   allowVolumeExpansion: true
 
   # Method used to reclaim an obsoleted volume
   reclaimPolicy: Delete
 
   # When set to false your PVs will not be archived by the provisioner upon deletion of the PVC.
   archiveOnDelete: true
 
   # If it exists and has 'delete' value, delete the directory. If it exists and has 'retain' value, save the directory.
   # Overrides archiveOnDelete.
   # Ignored if value not set.
   onDelete: delete
 
   # Specifies a template for creating a directory path via PVC metadata's such as labels, annotations, name or namespace.
   # Ignored if value not set.
   pathPattern:
 
   # Set access mode - ReadWriteOnce, ReadOnlyMany or ReadWriteMany
   accessModes: ReadWriteMany
 
   # Storage class annotations
   annotations: {}
 
 leaderElection:
   # When set to false leader election will be disabled
   enabled: true
 
 ## For RBAC support:
 rbac:
   # Specifies whether RBAC resources should be created
   create: true
 
 # If true, create & use Pod Security Policy resources
 # https://kubernetes.io/docs/concepts/policy/pod-security-policy/
 podSecurityPolicy:
   enabled: false
 
 # Deployment pod annotations
 podAnnotations: {}
 
 ## Set pod priorityClassName
 # priorityClassName: ""
 
 podSecurityContext: {}
 
 securityContext: {}
 
 serviceAccount:
   # Specifies whether a ServiceAccount should be created
   create: true
 
   # Annotations to add to the service account
   annotations: {}
 
   # The name of the ServiceAccount to use.
   # If not set and create is true, a name is generated using the fullname template
   name:
 
 resources: {}
   # limits:
   #  cpu: 100m
   #  memory: 128Mi
   # requests:
   #  cpu: 100m
   #  memory: 128Mi
 
 nodeSelector: {}
 
 tolerations: []
 
 affinity: {}
 
 # Additional labels for any resource created
 labels: {}
```

3.  Run the following command to install the temporary dynamic volume provisioner using Helm:

`helm install nfs-subdir-external-provisioner temporary-dynamic-volume-provisioner -f helm-nfs-subdir-external-provisioner-temporary-values.yaml`

This will create a deployment and a service for the temporary dynamic volume provisioner, as well as a storage class called `temporary-dynamic-volume-provisioner`.

## Testing the Dynamic Volume Provisioners

Now that our dynamic volume provisioners are deployed, we can test them by creating PVCs and checking if they are bound to PVs as expected.

To create a PVC, we can use the following YAML file as a template:


```yaml
kind: PersistentVolumeClaim
apiVersion: v1
metadata:
  name: test-pvc
spec:
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 1Gi
  storageClassName: persistent-dynamic-volume-provisioner
```

Replace `persistent-dynamic-volume-provisioner` with `temporary-dynamic-volume-provisioner` if you want to create a PVC for the temporary dynamic volume provisioner.

To create the PVC, run the following command:

`kubectl apply -f pvc.yaml`

You should see output similar to the following:

`persistentvolumeclaim/test-pvc created`

To check if the PVC has been bound to a PV, run the following command:

Copy code

`kubectl get pvc`

You should see output similar to the following:

```
NAME       STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   AGE
test-pvc   Bound    pvc-892e48e2-9d29-11e9-8bce-525400bfd1e1   1Gi        RWO            standard       6s
```

This indicates that the PVC has been successfully bound to a PV.

## Conclusion

In this tutorial, we learned how to deploy NFS provisioner for dynamic volume provisioning in Kubernetes. We also learned how to create PVCs and verify that they are bound to PVs as expected. With these skills, you should be able to effectively manage storage in your Kubernetes cluster using dynamic volume provisioning.