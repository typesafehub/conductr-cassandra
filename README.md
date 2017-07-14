# conductr-cassandra

## Overview

This project provides a [ConductR](http://conductr.typesafe.com) unit of deployment (bundle) for [Apache Cassandra](http://cassandra.apache.org/). By using this bundle you can deploy Cassandra over many nodes and it will scale automatically.

Quick start:

```
conduct load cassandra
conduct run cassandra --scale 3
```

The bundle will form a cluster with the name associated with the bundle's `system` and `compatibility-version` property.

> Disclaimer: Cassandra is a very sophisticated database. Although ConductR makes it easy to launch and scale Cassandra, you should still [learn about Cassandra](http://www.tutorialspoint.com/cassandra/).

### Working directories

By default, the Cassandra working directories reside inside of the bundle execution directory. Therefore, you don't need to manually cleanup certain directories. Each new Cassandra instance will start with an empty working directory.

The default bundle configuration is suited for development and integration testing purposes. For production, please use the provided `cassandra-prod` configuration as described in [Production configuration](#production-configuration) or use a custom configuration as described in [Custom configuration](#custom-configuration).

### Roles

The `cassandra` role is assigned to this bundle by default so make sure that the ConductR service on that node has that role. Note that on the ConductR sandbox, roles are disabled by default so you don't need to worry about it.

## Production configuration

When running Cassandra in production we recommend to use our production configuration:

```
conduct load cassandra cassandra-prod
```

This will load the cassandra bundle together with a [provided bundle configuration](https://github.com/typesafehub/conductr-cassandra/tree/master/src/bundle-configuration/cassandra-prod) that is suited for production purposes.

This bundle configuration changes the Cassandra working base directory to `/var/lib/cassandra`.

Please ensure that the directory is created and owned by the conductr user:

```
sudo mkdir /var/lib/cassandra
sudo chown conductr /var/lib/cassandra
```

## Custom configuration

It is also possible to provide a custom bundle configuration to the cassandra bundle. This way you can provide a custom Cassandra configuration and therefore override the following files:
- bin/conductr-cassandra.in.sh
- conf/cassandra.yaml
- conf/cassandra-env.sh
- conf/jvm.options
- conf/logback.xml

This project comes with a custom sample bundle configuration which is located in the [sample-config](https://github.com/typesafehub/conductr-cassandra/tree/master/sample-config) directory. This folder contains a fictious `cassandra-myservice` bundle configuration. To use it with ConductR you first "shazar" it (you'll need the [ConductR CLI](https://github.com/typesafehub/conductr-cli#command-line-interface-cli-for-typesafe-conductr)), and then load it along with the Cassandra bundle. 

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

After you have ensured that Cassandra has its directories created (`/var/lib/cassandra`) along with them being owned by the `conductr` user, you can then:

```
conduct run cassandra-myservice --scale 3
```

... which will run and cluster 3 instances of Cassandra.

### Modifying bundle configuration

To modify bundle configuration specifics change the `cassandra-myservice/bundle.conf` file. For example, if you want to run multiple Cassandra clusters in parallel you can change the cluster name and endpoints in here:

```
name   = "cassandra-myservice" <-- Change
system = "cassandra-myservice" <-- Change
components.cassandra = {
  endpoints = {
    "cas_native" = {
      bind-protocol = "tcp"
      bind-port     = 0
      services      = ["tcp://:9042/mynative"] <-- Change the port and path
    },
    "cas_rpc" = {
      bind-protocol = "tcp"
      bind-port     = 0
      services      = ["tcp://:9160/myrpc"] <-- Change the port and path
    },
    "cas_storage" = {
      bind-protocol = "tcp"
      bind-port     = 7000 <-- Change the port
      services      = []
    }
  }
}
```

### Modifying Cassandra configuration

The sample `casssandra-myservice` directory provides a `cassandra-conf` directory containing all of the files that Cassandra uses for configuration. You can modify any of the files as needed, bearing in mind that the following cassandra.yaml configuration is handled by the bundle automatically:

Property               | Description
-----------------------|------------
cluster_name           | Set to the bundle.conf's system property along with its system version property
listen_address         | Set to the bind address that ConductR provides
rpc_address            | As per `listen_address`
native_transport_port  | As per your bundle.conf's cas_native port setting
rpc_port               | As per your bundle.conf's cas_rpc port setting
storage_port           | As per your bundle.conf's cas_storage port setting
seeds                  | The seed IPs of the cas_storage host addresses

It is also possible to provide your custom `cassandra.in.sh` script. To do that place the script into the `cassandra-myservice` directory and export the path in the `runtime-config.sh` script:

```
export CASSANDRA_INCLUDE="$BUNDLE_CONFIG_DIR/my-cassandra.in.sh"
```

## JMX

By default, both local and remote JMX connections are disabled for this bundle. To enable JMX, provide a `cassandra-conf/cassandra-env.sh` in your custom bundle configuration and add the JMX settings into it.

## Development

The `build.sbt` declares the requisite Cassandra dependencies. Simply updating the version of the dependencies should be sufficient, at least for minor upgrades.

For more major upgrades, update the `src/universal` folders with the files from the Cassandra distribution. Note that the following files have been customized and cannot be replaced with a Cassandra distribution file:

```
- bin/cassandra
- bin/conductr-cassandra.in.sh
- conf/cassandra-env.sh
```

To publish the bundle and `cassandra-prod` bundle configuration to Bintray use:

```
sbt bundle:publish
sbt configuration:publish
```
