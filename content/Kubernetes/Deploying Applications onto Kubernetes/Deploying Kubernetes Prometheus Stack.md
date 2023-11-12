Welcome to another *Deploying Applications onto Kubernetes* guide. In this article, we'll be deploying Kubernetes Prometheus stack to monitor our Kubernetes platform (as well as the applications deployed on aforementioned platform, of course.)

## ZFS Dataset Creation

Before we begin, we need to create some ZFS datasets for the monitoring system. To do this, follow these steps:

1.  `zfs create storage/static-volumes/dingo.services/monitoring.dingo.services`
2.  `zfs create storage/static-volumes/dingo.services/monitoring.dingo.services/prometheus.monitoring.dingo.services`
3.  `zfs create storage/static-volumes/dingo.services/monitoring.dingo.services/alert-manager.monitoring.dingo.services`
4.  `zfs create storage/static-volumes/dingo.services/monitoring.dingo.services/grafana.monitoring.dingo.services`

## NFS Exports

Next, we need to set up some NFS exports so that the monitoring system can access the ZFS datasets we just created.

1.  Append the following block to `/etc/exports`:

`# NFS export for prometheus.monitoring.dingo.services  /storage/static-volumes/dingo.services/monitoring.dingo.services/prometheus.monitoring.dingo.services 10.0.0.0/14(rw,async,no_root_squash,no_wdelay,no_subtree_check)  # NFS export for alert-manager.monitoring.dingo.services  /storage/static-volumes/dingo.services/monitoring.dingo.services/alert-manager.monitoring.dingo.services 10.0.0.0/14(rw,async,no_root_squash,no_wdelay,no_subtree_check)  # NFS export for grafana.monitoring.dingo.services  /storage/static-volumes/dingo.services/monitoring.dingo.services/grafana.monitoring.dingo.services 10.0.0.0/14(rw,async,no_root_squash,no_wdelay,no_subtree_check)`

2.  Update the exports: `exportfs -arv`
3.  Set the correct permissions: `chown -R 472:472 /storage/static-volumes/dingo.services/monitoring.dingo.services/grafana.monitoring.dingo.services/`

Namespace & PV Initalisation

Next, we need to create a namespace for the monitoring system and set up some Persistent Volumes (PVs).

1.  `kubectl create namespace monitoring-dingo-services`
2.  `kubectl config set-context --current --namespace=monitoring-dingo-services`
3.  `kubectl apply -f pv-alertmanager-monitoring-dingo-services.yaml`
4.  `kubectl apply -f pv-prometheus-monitoring-dingo-services.yaml`
5.  `kubectl apply -f storage-grafana-monitoring-dingo-services.yaml`

Helm Manifest Configuration

Next, we will now configure the Helm manifest for the Kubernetes Prometheus stack.

Helm Installation

Now that the manifest is configured, we can proceed with the installation of the Kubernetes Prometheus stack using Helm.

1.  Add the Prometheus community Helm repository: `helm repo add prometheus-community https://prometheus-community.github.io/helm-charts`
2.  Install the stack: `helm install -n monitoring-dingo-services kube-prometheus-stack prometheus-community/kube-prometheus-stack -f helm-kube-prometheus-stack-values.yaml`

Patch Services for IPv6 Support

To support IPv6, we need to patch the services for the Prometheus stack.

1.  `kubectl patch --patch '{ "spec": { "ipFamilyPolicy" : "PreferDualStack" } }' svc kube-prometheus-stack-prometheus`
2.  `kubectl patch --patch '{ "spec": { "ipFamilyPolicy" : "PreferDualStack" } }' svc kube-prometheus-stack-alertmanager`

Patch etcd as so it's metrics are available on the control node IP address

We also need to patch etcd so that its metrics are available on the control node IP address. Note that this requires a reboot of the control plane to take effect when configured.

1.  Edit `/etc/kubernetes/manifests/etcd.yaml` and configure `--listen-metrics-urls=http://127.0.0.1:2381` to `--listen-metrics-urls=http://127.0.0.1:2381,http://<control-node_ip>:2381`
2.  Reboot the control plane.

Verification

To verify that everything is working correctly, we can check the logs of the pods in the monitoring namespace.

Copy code

`kubectl logs -f <pod-name>`

For example, to check the logs of the Prometheus pod, you would run:

Copy code

`kubectl logs -f kube-prometheus-stack-prometheus-0`

You can also access the Grafana dashboard by running:

Copy code

`kubectl port-forward service/kube-prometheus-stack-grafana 3000:80`

This will forward the local port 3000 to the Grafana service's port 80, allowing you to access the dashboard at `http://localhost:3000`.

## Conclusion

In this guide, we have set up a monitoring system using the Kubernetes Prometheus stack. We created ZFS datasets and set up NFS exports, initialized a namespace and PVs, configured the Helm manifest, and installed the stack using Helm. We also patched the services for IPv6 support and etcd for metrics availability. Finally, we verified the installation by checking the logs and accessing the Grafana dashboard.

I hope this guide has been helpful in setting up a monitoring system for your Kubernetes cluster. If you have any questions or encounter any issues, don't hesitate to ask.