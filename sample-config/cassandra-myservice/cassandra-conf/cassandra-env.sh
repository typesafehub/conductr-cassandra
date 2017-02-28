# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Determine the sort of JVM we'll be running on.
java_ver_output=`"${JAVA:-java}" -version 2>&1`
jvmver=`echo "$java_ver_output" | grep '[openjdk|java] version' | awk -F'"' 'NR==1 {print $2}' | cut -d\- -f1`
JVM_VERSION=${jvmver%_*}
JVM_PATCH_VERSION=${jvmver#*_}

if [ "$JVM_VERSION" \< "1.8" ] ; then
    echo "Cassandra 3.0 and later require Java 8u40 or later."
    exit 1;
fi

if [ "$JVM_VERSION" \< "1.8" ] && [ "$JVM_PATCH_VERSION" -lt 40 ] ; then
    echo "Cassandra 3.0 and later require Java 8u40 or later."
    exit 1;
fi

jvm=`echo "$java_ver_output" | grep -A 1 'java version' | awk 'NR==2 {print $1}'`
case "$jvm" in
    OpenJDK)
        JVM_VENDOR=OpenJDK
        # this will be "64-Bit" or "32-Bit"
        JVM_ARCH=`echo "$java_ver_output" | awk 'NR==3 {print $2}'`
        ;;
    "Java(TM)")
        JVM_VENDOR=Oracle
        # this will be "64-Bit" or "32-Bit"
        JVM_ARCH=`echo "$java_ver_output" | awk 'NR==3 {print $3}'`
        ;;
    *)
        # Help fill in other JVM values
        JVM_VENDOR=other
        JVM_ARCH=unknown
        ;;
esac

#GC log path has to be defined here because it needs to access CASSANDRA_HOME
mkdir -p $CASSANDRA_HOME/logs
touch $CASSANDRA_HOME/logs/gc.log
JVM_OPTS="$JVM_OPTS -Xloggc:${CASSANDRA_HOME}/logs/gc.log"

# Here we create the arguments that will get passed to the jvm when
# starting cassandra.

# Read user-defined JVM options from jvm.options file
JVM_OPTS_FILE=$CASSANDRA_CONF/jvm.options
for opt in `grep "^-" $JVM_OPTS_FILE`
do
  JVM_OPTS="$JVM_OPTS $opt"
done

# Check what parameters were defined on jvm.options file to avoid conflicts
echo $JVM_OPTS | grep -q Xmn
DEFINED_XMN=$?
echo $JVM_OPTS | grep -q Xmx
DEFINED_XMX=$?
echo $JVM_OPTS | grep -q Xms
DEFINED_XMS=$?
echo $JVM_OPTS | grep -q UseConcMarkSweepGC
USING_CMS=$?
echo $JVM_OPTS | grep -q UseG1GC
USING_G1=$?

if [ "x$MALLOC_ARENA_MAX" = "x" ] ; then
    export MALLOC_ARENA_MAX=4
fi

# provides hints to the JIT compiler
JVM_OPTS="$JVM_OPTS -XX:CompileCommandFile=$CASSANDRA_CONF/hotspot_compiler"

# add the jamm javaagent
JVM_OPTS="$JVM_OPTS -javaagent:$CASSANDRA_HOME/lib/com.github.jbellis.jamm-0.3.0.jar"

# set jvm HeapDumpPath with CASSANDRA_HEAPDUMP_DIR
if [ "x$CASSANDRA_HEAPDUMP_DIR" != "x" ]; then
    JVM_OPTS="$JVM_OPTS -XX:HeapDumpPath=$CASSANDRA_HEAPDUMP_DIR/cassandra-`date +%s`-pid$$.hprof"
fi

# Cassandra uses SIGAR to capture OS metrics CASSANDRA-7838
# for SIGAR we have to set the java.library.path
# to the location of the native libraries.
JVM_OPTS="$JVM_OPTS -Djava.library.path=$CASSANDRA_HOME/lib/sigar-bin"

JVM_OPTS="$JVM_OPTS $JVM_EXTRA_OPTS"