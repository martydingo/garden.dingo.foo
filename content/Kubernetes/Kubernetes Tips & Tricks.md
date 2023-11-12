## Label all worker nodes as workers

```sh
for WORKER_NODE in `kubectl get nodes -o name --no-headers=true | grep -v control`
do 
  kubectl label $WORKER_NODE node-role.kubernetes.io/worker=worker
done
```

## Clean all unhealthy pods

```bash
kubectl get pods -A \ 
grep -E "OutOfcpu\|Evicted\|Completed\|OOMKilled\|Error\|ContainerStatusUnknown\|Unknown\|Terminating" | \
awk '{ print $1, $2 }' | \
xargs -l bash -c 'kubectl delete pod -n $0 $1 --force'
```