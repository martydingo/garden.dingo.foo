---
date: 2022-08-31
---

## Introduction

## System Preperation

1. On all systems, run the following:
	1. `sudo dnf install -y cifs-utils`

## Helm
### Repo

1. `helm repo add csi-driver-smb https://raw.githubusercontent.com/kubernetes-csi/csi-driver-smb/master/charts`
2. `helm install -n kube-system csi-driver-smb csi-driver-smb/csi-driver-smb -f helm-csi-driver-smb-values.yaml`

## Kubernetes
### Secret

1. `kubectl create secret generic -n home-dingo-services secret-smb-home-dingo-services --from-literal username=<username> --from-literal password="<password>"`