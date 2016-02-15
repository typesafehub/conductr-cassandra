import ByteConversions._

organization := "com.typesafe.conductr"
name := "cassandra"
version := "3.0.2"

licenses := Seq("Apache-2.0" -> url("http://www.apache.org/licenses/LICENSE-2.0"))

libraryDependencies += "org.apache.cassandra" % "cassandra-all" % "3.0.2"

// Bundle configuration

BundleKeys.nrOfCpus := 2.0
BundleKeys.memory := 1.GiB
BundleKeys.diskSpace := 100.MB
BundleKeys.roles := Set("cassandra")

BundleKeys.endpoints := Map(
  "cas_native" ->  Endpoint("tcp", services = Set(uri("tcp://:9042/native"))),
  "cas_rpc" ->     Endpoint("tcp", services = Set(uri("tcp://:9160/rpc"))),
  "cas_storage" -> Endpoint("tcp", 7000)
)

BundleKeys.executableScriptPath in Bundle := (file((normalizedName in Bundle).value) / "bin" / "bootstrap").getPath
BundleKeys.checks := Seq(
  uri("$CAS_STORAGE_HOST?retry-count=10&retry-delay=3")
)

javaOptions in Bundle := Seq.empty

// Bundle publishing configuration

inConfig(Bundle)(Seq(
  bintrayVcsUrl := Some("https://github.com/typesafehub/conductr-cassandra"),
  bintrayOrganization := Some("typesafe")
))

//

lazy val root = project.in(file(".")).enablePlugins(JavaServerAppPackaging)