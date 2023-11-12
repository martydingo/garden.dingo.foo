## Introduction

## ZFS Datasets

1. `zfs create storage/static-volumes/dingo.management`
2. `zfs create storage/static-volumes/dingo.management/projects.dingo.management`
3. `zfs create storage/static-volumes/dingo.management/projects.dingo.management/vikunja`
4. `zfs create storage/static-volumes/dingo.management/projects.dingo.management/vikunja/postgres`
5. `zfs create storage/static-volumes/dingo.management/projects.dingo.management/vikunja/data`

## NFS Shares

```
## projects.dingo.management

# NFS export for postgres-projects.dingo.management
/storage/static-volumes/dingo.management/projects.dingo.management/vikunja/postgres 10.0.0.0/14(rw,async,no_root_squash,no_wdelay,no_subtree_check)

# NFS export for data-projects.dingo.management
/storage/static-volumes/dingo.management/projects.dingo.management/vikunja/data 10.0.0.0/14(rw,async,no_root_squash,no_wdelay,no_subtree_check)
```

## Kubernetes

### Namespace Initalisation

`kubectl create namespace projects-dingo-management`

### PV Initalisation

#### Postgres

```yaml
####
## Persistent Volume YAML
####

#####
### pv-postgres-projects-dingo-management
#####
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-postgres-projects-dingo-management
  namespace: projects-dingo-management
spec:
  capacity:
    storage: 1Gi
  accessModes:
    - ReadWriteMany
  nfs:
    server: 10.0.0.1
    path: "/storage/static-volumes/dingo.management/projects.dingo.management/vikunja/postgres"

####
## Persistent Volume Claim YAML
####

#####
### pvc-postgres-projects-dingo-management
#####
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-postgres-projects-dingo-management
  namespace: projects-dingo-management
spec:
  accessModes:
    - ReadWriteMany
  storageClassName: ""
  volumeName: pv-postgres-projects-dingo-management
  resources:
    requests:
      storage: 1Gi
```

#### Vikunja

```yaml
####
## Persistent Volume YAML
####

#####
### pv-data-vikunja-dingo-management
#####
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: pv-data-vikunja-dingo-management
  namespace: vikunja-dingo-management
spec:
  capacity:
    storage: 1Gi
  accessModes:
    - ReadWriteMany
  nfs:
    server: 10.0.0.1
    path: "/storage/static-volumes/dingo.management/projects.dingo.management/vikunja/data"

####
## Persistent Volume Claim YAML
####

#####
### pvc-data-vikunja-dingo-management
#####
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: pvc-data-vikunja-dingo-management
  namespace: vikunja-dingo-management
spec:
  accessModes:
    - ReadWriteMany
  storageClassName: ""
  volumeName: pv-data-vikunja-dingo-management
  resources:
    requests:
      storage: 1Gi
```

### Vikunja Postgres Deployment

#### Deployment 

```yaml
###
# Postgres Deployment YAML Configuration - "postgres.vikunja.dingo.management"
###

apiVersion: apps/v1
kind: Deployment
metadata:
  name: postgres-projects-dingo-management
  labels:
    app: postgres-projects-dingo-management
spec:
  replicas: 1
  selector:
    matchLabels:
      app: postgres-projects-dingo-management
  template:
    metadata:
      labels:
        app: postgres-projects-dingo-management
    spec:
      containers:
      - image: postgres:14
        name: postgres
        ports:
          - containerPort: 5432
            protocol: TCP
            name: postgres
        volumeMounts:
          - mountPath: /var/lib/postgresql/data
            name: vol-postgres-projects-dingo-management
        env:
         - name: POSTGRES_DB
           value: "vikunja"
         - name: POSTGRES_USER
           value: "vikunja"
         - name: POSTGRES_PASSWORD
           value: "xjM4qVgcuAhE6JagsZq2BZMVkUjnXqUseNEGYnZ7H7wN2FMVAsvQNrA4wggB6kbj"
        resources:
          requests:
            memory: "128Mi"
            cpu: "125m"
          limits:
            memory: "512Mi"
            cpu: "8000m"
      volumes:
        - name: vol-postgres-projects-dingo-management
          persistentVolumeClaim:
            claimName: pvc-postgres-projects-dingo-management
```

#### Service

```yaml
apiVersion: v1
kind: Service
metadata:
  name: service-postgres-projects-dingo-management
  namespace: projects-dingo-management
spec:
  selector:
    app: postgres-projects-dingo-management
  ports:
    - protocol: TCP
      port: 5432
      targetPort: 5432
      name: postgres
  type: ClusterIP
```

### Vikunja Deployment

#### ConfigMap

```yaml
kind: ConfigMap
metadata:
  name: projects-dingo-management-config
  namespace: projects-dingo-management
apiVersion: v1
data:
  Caddyfile: |-
    {
      admin off
      auto_https off
    }
    :8080 {
        log {
            output stdout
        }
        @api {
            path /api/*
            path /.well-known/*
            path /dav/*
        }
        header {
            # Remove Server header
            -Server
        }
        # API
        handle @api {
            reverse_proxy localhost:3456
        }
        # Filtron
        handle {
            reverse_proxy localhost:80
        }
    }
  Vikunja.yaml: |-
    service:
      jwtsecret: "zeJAQYV9UvbmvC99RmLsnu"
      enableregistration: 'True'
    mailer: 
      enabled: false
      host: mail.dingo.services
      port: 587
      authtype: login
      username: projects@dingo.management
      password: 6s78r6fvBg6UV2428zMgHke8KeyLPCgYfMuKWD5YdmKPCDJ4S6NpcxJzTKZkBsRk
      fromemail: projects@dingo.management
```

#### Helm

`helm install -n projects-dingo-management vikunja-projects-dingo-management k8s-at-home/vikunja -f helm-vikunja-values.yaml`