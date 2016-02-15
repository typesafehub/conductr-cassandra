# conductr-cassandra

## Overview

This project provides a [ConductR](http://conductr.typesafe.com) unit of deployment (bundle) for [Apache Cassandra](http://cassandra.apache.org/). By using this bundle you can deploy Cassandra over many nodes and it will scale automatically.

The bundle will form a cluster with the name associated with the bundle's `system` property (which is the project name by default). The default system name is `cassandra`. It is expected that you provide an overriding bundle configuration that re-defines the system name. In addition, because Cassandra expects its storage port to be the same across the cluster, the expectation is that you override this port. By default the storage port is set to 7000. Expressing application/service specific configurations is discussed next.

## Configuring for your application/service

There is a `sample-config` folder containing another folder named "cassandra-myservice". This folder represents the entire configuration for a fictitious service named `cassandra-myservice`. To use it with ConductR you first "shazar" it (you'll need the [ConductR CLI](https://github.com/typesafehub/conductr-cli#command-line-interface-cli-for-typesafe-conductr)), and then load it along with the Cassandra bundle. 

To shazar from this project's directory:

```
shazar sample-config/cassandra-myservice
```

This will generate a file named something like `cassandra-myservice-d2a3b64e75a916118ed26ed880f7263162c9cf429cd905210cf6129a1de9572a.zip` - the shazar tool will tell you the exact name.

Once generated you can upload the configuration along with the Cassandra bundle from this project that we've published on bintray:

```
conduct load conductr-cassandra ./cassandra-myservice-d2a3b64e75a916118ed26ed880f7263162c9cf429cd905210cf6129a1de9572a.zip
```

This will return a bundle id to you, something like: "3f8b3f7-d2a3b64". This id uniquely represents the combination of the Cassandra bundle and the configuration that you provided.

### Modifying configuration

The only file that you typically modify is the `cassandra-myservce/bundle.conf`. You typically address each one of the properties in there so that they do not clash with other Cassandra clusters.

The sample `casssandra-myservice` folder provides a `cassandra-conf` folder containing all of the files that Cassandra uses for configuration. You can modify any of the files as needed, bearing in mind that the following cassandra.yaml configuration is handled by the bundle automatically:

Property               | Description
-----------------------|------------
cluster_name           | Set to the bundle.conf's system property
listen_address         | Set to the bind address that ConductR provides
rpc_address            | As per `listen_address`
native_transport_port  | As per your bundle.conf's cas_native port setting
rpc_port               | As per your bundle.conf's cas_rpc port setting
storage_port           | As per your bundle.conf's cas_storage port setting
seeds                  | The seed IPs of the cas_storage host addresses
hints_directory        | /var/lib/cassandra/hints
data_file_directories  | /var/lib/cassandra/data
commitlog_directory    | /var/lib/cassandra/commitlog
saved_caches_directory | /var/lib/cassandra/saved_caches

## Development

The `build.sbt` declares the requisite Cassandra dependencies. Simply updating the version of the dependencies should be sufficient, at least for minor upgrades.

For more major upgrades, update the `src/universal` folders. Note that the `bin/cassandra` folder remains untouched and so you can drop-in replace it with the one from Cassandra's distribution. Similarly all of the `conf` and `lib/sigar-bin` folders takes files untouched from the regular Cassandra distribution. In fact the only two files that are custom to the ConductR build are the `bin/bootstrap` and `bin/conductr-cassandra.in.sh` files. The latter is a customization of the Cassandra distribution's `bin/cassandra.in.sh`.