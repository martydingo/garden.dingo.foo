---
title: Prelude
date: 2022-08-20
---


# Deploying Kubernetes

Welcome!
 
This is the prelude to a multi-part series on deploying Kubernetes. 

Many articles only cover the initial installation, usually stopping following the installation of the CNI (Container Networking Interface) plugin, however there is still so much more to configure from this point, from file storage, to more advanced network configurations that leverages BGP (e.g. `MetalLB`).

This series aims to rectify that by (*hopefully*) delivering the reader knowledge on not just how to install Kubernetes, but also on the installation of the required infrastructure to which we'll deploy Kubernetes onto, as well as operating Kubernetes, and the relevant services that are commonly considered as required as apart of any Kubernetes deployment (e.g. `ingress-ngix`, `cert-manager`, etc)

Helpfully, this series will be written while underling a fresh rebuild of a Kubernetes cluster, so these articles will reflect the configuration of the cluster that the very blog resides on. 


