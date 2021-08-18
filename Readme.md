# Vitess Bootstrap

Follow this to get a working Vitess setup on a def k8s cluster.  The repo contains the resources to:

* Get a local kubernetes working
* Install the vitess operator
* Create some keyspaces
* Set up port-forwarding so you can start working with & monitoring vitess

This is not a vitess [tutorial](https://vitess.io/docs/overview/)

⚠️ This is not a production-ready template - do not use it as such!

Once you have finished this tutorial, you'll have access to a locally hosted vitess cluster with two keyspaces:
* `configuration` - non-sharded, used for id-generation
* `usercontent` - sharded, with three tables - `channel`, `post`, `comment`


## Get Kubernetes on your box 
You have 2 options - docker-desktop or minikube

### K8s on Docker-desktop
This works without any additional components, but you will need to set up the k8s dashboard

1. Make sure you allocate docker enough resources - when you create multiple shards & replicas, memory use can grow quickly

![Provision k8s resources](/res/k8s-resources.png)

2. Ensure kubernetes is enabled.

![Enable k8s](/res/k8s-enabled.png)

You will get a new kubeconfig which you'll need to add to your `KUBECONFIG` in your `.bash_profile` or your `.zshrc`
 
3. Install the [kubernetes dashboard]():

```sh
kubectl apply -f kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.3.1/aio/deploy/recommended.yaml
```

4. Set up some secutiry stuff to run the dashboard.  In a terminal (in the root of this repo) run 

```sh
kubectl apply -f k8s/user-stuff.yaml
```

5. In a new terminal, run `kubectl proxy` to allow access to the k8s api (where the dashboard is served from)


7. Get a token to acces your k8s-ui. n.b. if you aren't on a mac, you'll need to remove the ` | pbcopy` and copy the output to the clipboard yourself

```sh
kubectl -n kubernetes-dashboard get secret $(kubectl -n kubernetes[0].name}") -o go-template="{{.data.token | base64decode}}" | pbcopy
```

8. You should be able to log into the k8s ui [here](http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:https/proxy/.), using the token in your clipboard


### Minikube
Minikube will set up a dashboard for you.  If you want to use it, 

1. Install [minikube](https://minikube.sigs.k8s.io/docs/start/)

2. Start Minikube

```sh
minikube start --kubernetes-version=v1.21.2 --cpus=8 --memory=11000 --disk-size=30g
```

3. Launch the UI
```
minikube dashboard 
```

## Set up vitess

1. Install the Vitess operator - this will let you apply vitess resource definitions as yaml files
```sh
kubectl apply -f k8s/operator.yaml
```

2. Install the vitess operator into your k8s cluster
```sh
kubectl apply -f k8s/initial_cluster.yaml
```

3. Ensure you have the vitess client.  Once you have it, you'll need to add it to your path (if it isn't added automatically):

```sh
go get vitess.io/vitess/go/cmd/vtctlclient
```

By default, the client will be foud at `/usr/local/bin/vtctlclient`

4. In a new terminal, run the following script.  It will set up vitess support in k8s, and bootstrap some keyspaces for you

```
./init.sh &
```

This will:
* Set up UI access to [vtctld](http://127.0.0.1:15000)
* Set up UI access to [vtgate](http://127.0.0.1:15001)
* Set up UI access to a random [vttablet](http://127.0.0.1:15002)
* Forward port 3306 to vtgate
* Create a `mysql` alias that will automatically log you into vitess
* Create a `vtctlclient` alias that points to your new vitess cluster
* Seed your vitess cluster with a mini schema and vschema