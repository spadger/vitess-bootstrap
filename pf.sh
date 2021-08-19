#!/bin/sh

kubectl port-forward --address localhost "$(kubectl get service --selector="planetscale.com/component=vtctld" -o name | head -n1)" 15000 15999 &
process_id1=$!
kubectl port-forward --address localhost "$(kubectl get service --selector="planetscale.com/component=vtgate" -o name | head -n1)" 15001:15000 3306:3306 &
process_id2=$!


kubectl port-forward --address localhost "$(kubectl get pod --selector="planetscale.com/component=vttablet,planetscale.com/cluster=example,planetscale.com/keyspace=configuration" -o name | head -n1)" 15002:15000 3316:3306 &
process_id3=$!
kubectl port-forward --address localhost "$(kubectl get pod --selector="planetscale.com/component=vttablet,planetscale.com/cluster=example,planetscale.com/keyspace=usercontent,planetscale.com/shard=x-80" -o name | head -n1)" 15003:15000 3326:3306 &
process_id4=$!
kubectl port-forward --address localhost "$(kubectl get pod --selector="planetscale.com/component=vttablet,planetscale.com/cluster=example,planetscale.com/keyspace=usercontent,planetscale.com/shard=80-x" -o name | head -n1)" 15004:15000 3336:3306 &
process_id5=$!



sleep 2
# echo "You may point your browser to http://localhost:15000, use the following aliases as shortcuts:"
echo 'alias vtctlclient="vtctlclient -server=localhost:15999 -logtostderr"'
echo 'alias mysql="mysql -h 127.0.0.1 -P 3306 -u user"'
# echo "Hit Ctrl-C to stop the port forwards"
wait $process_id1
wait $process_id2
wait $process_id3
wait $process_id4
wait $process_id5
