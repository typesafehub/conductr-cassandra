# conductr-cassandra

## Overview

This project provides a [ConductR](http://conductr.typesafe.com) unit of deployment (bundle) for [Apache Cassandra](http://cassandra.apache.org/). By using this bundle you can deploy Cassandra over many nodes and it will scale automatically.

The bundle will form a cluster with the name associated with the bundle's `system` property (which is the project name by default). The default system name is `cassandra`. It is expected that you provide an overriding bundle configuration that re-defines the system name. In addition, because Cassandra expects its storage port to be the same across the cluster, the expectation is that you override this port. By default the storage port is set to 7000.

## Development

The `build.sbt` declares the requisite Cassandra dependencies. Simply updating the version of the dependencies should be sufficient, at least for minor upgrades.

For more major upgrades, update the `src/universal` folders. Note that the `bin/cassandra` folder remains untouched and so you can drop-in replace it with the one from Cassandra's distribution. Similarly all of the `conf` and `lib/sigar-bin` folders takes files untouched from the regular Cassandra distribution. In fact the only two files that are custom to the ConductR build are the `bin/bootstrap` and `bin/conductr-cassandra.in.sh` files. The latter is a customization of the Cassandra distribution's `bin/cassandra.in.sh`.