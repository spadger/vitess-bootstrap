# Vitess Bootstrap

Follow this to configure your dev machine to run a sharded Vitess cluster on a local kubernetes cluster.  The repo contains the resources to:

* Get a local kubernetes working
* Install the vitess operator
* Create some keyspaces
* Set up port-forwarding so you can start working with & monitoring vitess

This is not a vitess [tutorial](https://vitess.io/docs/overview/)

⚠️ This is not a production-ready template - do not use it as such!

Once you have finished this tutorial, you'll have access to a locally hosted vitess cluster with two keyspaces:
* `configuration` - non-sharded, used for id-generation
* `usercontent` - sharded, with three tables - `channel`, `post`, `comment`

Inside usercontent, the tables are sharded such that a given `channel`'s `posts` and `comments` will all reside on the same shard as the `post`


## Get Kubernetes running on your machine
This section will get k8s running on your box using minikube.  If you'd prefer to use docker desktop's version see [here](res/k8s-on-docker-desktop.md)

1. Install [minikube](https://minikube.sigs.k8s.io/docs/start/)
```sh
brew install minikube
minikube start --kubernetes-version=v1.21.2 --cpus=8 --memory=11000 --disk-size=30g
minikube dashboard 
```

## Set up vitess into an initial state

1. Install the Vitess operator - this will let you apply vitess resource definitions as yaml files
```sh
kubectl apply -f k8s/operator.yaml
```

2. Install the vitess operator into your k8s cluster
```sh
kubectl apply -f k8s/initial_cluster.yaml
```

Wait until all of the pods have initialised; it will take a around 5 minutes.  All pods should report `1/1` or `3/3`


```sh
watch kubectl get po
```

3. Ensure you have the vitess client.  Once you have it, you'll need to add it to your path (if it isn't added automatically):

```sh
go get vitess.io/vitess/go/cmd/vtctlclient
```

By default, the client will be foud at `/usr/local/bin/vtctlclient`

4. In a new terminal, run the following script.  It will set up vitess support in k8s, and bootstrap some keyspaces for you

```
source ./init.sh &
alias vtctlclient="vtctlclient -server=localhost:15999 -logtostderr"
alias mysql="mysql -h 127.0.0.1 -P 3306 -u user"
```

This will:
* Set up UI access to the following
  * [vtctld](http://127.0.0.1:15000)
  * [vtgate](http://127.0.0.1:15001)
  * [the configuration tablet](http://127.0.0.1:15002)
  * [usercontent left-shard tablet](http://127.0.0.1:15003)
  * [usercontent right-shard tablet](http://127.0.0.1:15004)

* Set up the following mysql port mappings:
  * 3306 - vtgate (password is `user`)
  * 3316 - configuration tablet (password is `dev`)
  * 3326 - usercontent left-shard tablet (password is `dev`)
  * 3336 - usercontent right-shard tablet (password is `dev`)

* Create a `mysql` alias that will automatically log you into vtgate
* Create a `vtctlclient` alias that points to your new vitess cluster
* Seed your vitess cluster with a mini schema and vschema


## Allow Vitess to easily select a post given its id

At this point, all records you insert into `channel` or `post` will by physically sharded by `channel_id`, but if you `select * from post where id=123`, vitess will not know which shard to query for that post.  It overcomes this issue using a scatter/gather query (all tablets are queried), but this is inefficient.

Instead, we can now create a secondary vindex (not index) for `post.id`, so vitess can determine where a post with a given id resides

```sh
vtctlclient CreateLookupVindex -tablet_types=REPLICA usercontent "$(cat schemas/post_id-secondary-vindex.json)"
```

This will create a lookup table named `id_post_idx`, which will contain a row for each `id` in the `post` table, with a mapping of `post-id` -> the sharding key of the post's channel_id.  It will backfill the mapping table with any preexisting posts in the database, and will manage this table going forward.

⚠️ Important!
Running `CreateLookupVindex` updates the VSchema, so you will need to get the latest from Vitess:

```sh
vtctlclient GetVSchema usercontent > schemas/v2-usercontent-vschema.json
```

If you diff the [original](schemas/initial-usercontent-vschema.json) and [new](schemas/v2-usercontent-vschema.json) vindexes, you will see the following additions:
 * A new vindex definition named `id_post_idx`
 * Post has a secondary vindex referencing `id_post_idx`
 * The `id_post_idx` mapping table is now defined in the vindex, because it is sharded itself

 ## Sharding comments correctly
 At this point, `channel`'s are sharded by `channel.id`, and `post`s are sharded by `post.channel_id`, which means they will be colocated on the same shard, but what about `post`s?

 A `post` does not have a `channel_id` column, but it does have a `post_id` column, and we already have a mapping between `post.id` -> the parent `channel`'s keyspace id.  This means we can reuse the same `id_post_idx` lookup vindex use use for finding a `post`'s shard given its id!
 