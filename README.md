# conductr-cassandra

## Overview

This project provides a [ConductR](http://conductr.typesafe.com) unit of deployment (bundle) for [Apache Cassandra](http://cassandra.apache.org/). By using this bundle you can deploy Cassandra over many nodes and it will scale automatically.

Quick start:

```
conduct load cassandra
conduct run cassandra --scale 3
```

The bundle will form a cluster with the name associated with the bundle's `system` property (which is the project name by default). The default system name is `cassandra`. It is expected that you provide an overriding bundle configuration that re-defines the system name. In addition, because Cassandra expects its storage port to be the same across the cluster, the expectation is that you override this port. By default the storage port is set to 7000. Expressing application/service specific configurations is discussed next.

> Disclaimer: Cassandra is a very sophisticated database. Although ConductR makes it easy to launch and scale Cassandra, you should still [learn about Cassandra](http://www.tutorialspoint.com/cassandra/).

### Working directories

The bundle will assume that the Cassandra working directories reside outside of the bundle itself. The location of the Cassandra working directories are depending on:

- Operation system
- Bundle name and Bundle compatibility version
- Cassandra node address

On Linux, the base directory is `/var/lib`. On macOS, the base directory is `/usr/local/var/lib`.

Cassandra's convention is to use `cassandra` as the sub directory e.g. `/var/lib/cassandra`. This bundle will substitute the `$BUNDLE_NAME-v$BUNDLE_COMPATIBILITY_VERSION` environment vars in place of `cassandra` e.g. `/var/lib/cassandra-v3` (the compatibility version has been set to 3 by default in order to signify Cassandra v.3).

You must ensure that the nodes where Cassandra bundles will run have these directories established and owned by the conductr user e.g.:

```
sudo mkdir /var/lib/cassandra-v3
sudo chown conductr /var/lib/cassandra-v3
```

Note when using the sandbox, the directories are created automatically.

To support several Cassandra instances on a single host, each bundle instance will create a sub directory based on the node address, e.g.
 
```
/var/lib/cassandra/v3/192.168.10.1
/var/lib/cassandra/v3/192.168.10.2
/var/lib/cassandra/v3/192.168.10.3
```

### Roles

The `cassandra` role is assigned to this bundle by default so make sure that the ConductR service on that node has that role. Note that on the sandbox, roles are disabled by default so you don't need to worry about it.

## Configuring for your application/service

There is a `sample-config` folder containing another folder named "cassandra-myservice". This folder represents the entire configuration for a fictitious service named `cassandra-myservice`. To use it with ConductR you first "shazar" it (you'll need the [ConductR CLI](https://github.com/typesafehub/conductr-cli#command-line-interface-cli-for-typesafe-conductr)), and then load it along with the Cassandra bundle. 

To shazar from this project's directory:

```
shazar sample-config/cassandra-myservice
```

This will generate a file named something like `cassandra-myservice-d2a3b64e75a916118ed26ed880f7263162c9cf429cd905210cf6129a1de9572a.zip` - the shazar tool will tell you the exact name.

Once generated you can upload the configuration along with the Cassandra bundle:

```
conduct load cassandra ./cassandra-myservice-d2a3b64e75a916118ed26ed880f7263162c9cf429cd905210cf6129a1de9572a.zip
```

This will return a bundle id to you, something like: "3f8b3f7-d2a3b64". This id uniquely represents the combination of the Cassandra bundle and the configuration that you provided.

After you have ensured that Cassandra has its directories created (`/var/lib/cassandra-myservice-v3`) along with them being owned by the `conductr` user (again, you won't need to for the sandbox), you can then:

```
conduct run cassandra-myservice --scale 3
```

... which will run and cluster 3 instances of Cassandra.

### Modifying configuration

The only file that you typically modify is the `cassandra-myservice/bundle.conf`. You  address each one of the properties in there so that they do not clash with other Cassandra clusters i.e.:

```
name   = "cassandra-myservice" <-- Change
system = "cassandra-myservice" <-- Change
components.cassandra = {
  endpoints = {
    "cas_native" = {
      bind-protocol = "tcp"
      bind-port     = 0
      services      = ["tcp://:9043/mynative"] <-- Change the port and path
    },
    "cas_rpc" = {
      bind-protocol = "tcp"
      bind-port     = 0
      services      = ["tcp://:9161/myrpc"] <-- Change the port and path
    },
    "cas_storage" = {
      bind-protocol = "tcp"
      bind-port     = 7001 <-- Change the port
      services      = []
    }
  }
}
```

For advanced configuration, the sample `casssandra-myservice` folder provides a `cassandra-conf` folder containing all of the files that Cassandra uses for configuration. You can modify any of the files as needed, bearing in mind that the following cassandra.yaml configuration is handled by the bundle automatically:

Property               | Description
-----------------------|------------
cluster_name           | Set to the bundle.conf's system property along with its system version property
listen_address         | Set to the bind address that ConductR provides
rpc_address            | As per `listen_address`
native_transport_port  | As per your bundle.conf's cas_native port setting
rpc_port               | As per your bundle.conf's cas_rpc port setting
storage_port           | As per your bundle.conf's cas_storage port setting
seeds                  | The seed IPs of the cas_storage host addresses
hints_directory        | /var/lib/cassandra/hints where "cassandra" is your bundle.conf's bundle name and bundle compatibility version
data_file_directories  | /var/lib/cassandra/data where "cassandra" is your bundle.conf's bundle name and bundle compatibility version
commitlog_directory    | /var/lib/cassandra/commitlog where "cassandra" is your bundle.conf's bundle name and bundle compatibility version
saved_caches_directory | /var/lib/cassandra/saved_caches where "cassandra" is your bundle.conf's bundle name and bundle compatibility version

## JMX

By default, both local and remote JMX connections are disabled for this bundle. To enable JMX, provide a `cassandra-conf/cassandra-env.sh` in your custom bundle configuration and add the JMX settings into it.

## Development

The `build.sbt` declares the requisite Cassandra dependencies. Simply updating the version of the dependencies should be sufficient, at least for minor upgrades.

For more major upgrades, update the `src/universal` folders. Note that the `bin/cassandra` folder remains untouched and so you can drop-in replace it with the one from Cassandra's distribution. Similarly all of the `conf` and `lib/sigar-bin` folders takes files untouched from the regular Cassandra distribution. In fact the only two files that are custom to the ConductR build are the `bin/bootstrap` and `bin/conductr-cassandra.in.sh` files. The latter is a customization of the Cassandra distribution's `bin/cassandra.in.sh`.

`sbt bundle:publish` will publish the bundle to bintray.
