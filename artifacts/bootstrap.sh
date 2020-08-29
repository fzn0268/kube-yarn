#!/bin/bash

: ${HADOOP_HOME:=/usr/local/hadoop}

. $HADOOP_HOME/etc/hadoop/hadoop-env.sh

# Directory to find config artifacts
CONFIG_DIR="/tmp/hadoop-config"

# Copy config files from volume mount

for f in workers core-site.xml hdfs-site.xml mapred-site.xml yarn-site.xml; do
  if [[ -e ${CONFIG_DIR}/$f ]]; then
    cp ${CONFIG_DIR}/$f $HADOOP_HOME/etc/hadoop/$f
  else
    echo "ERROR: Could not find $f in $CONFIG_DIR"
    exit 1
  fi
done

# installing libraries if any - (resource urls added comma separated to the ACP system variable)
cd $HADOOP_HOME/share/hadoop/common ; for cp in ${ACP//,/ }; do  echo == $cp; curl -LO $cp ; done; cd -

if [[ "${HOSTNAME}" =~ "hdfs-nn" ]]; then
  mkdir -p /root/hdfs/namenode
  $HADOOP_HOME/bin/hdfs namenode -format -force -nonInteractive
  sed -i s/hdfs-nn/0.0.0.0/ /usr/local/hadoop/etc/hadoop/core-site.xml
  $HADOOP_HOME/bin/hdfs namenode
fi

if [[ "${HOSTNAME}" =~ "hdfs-dn" ]]; then
  mkdir -p /root/hdfs/datanode
  #  wait up to 30 seconds for namenode
  count=0 && while [[ $count -lt 15 && -z `curl -sf http://hdfs-nn:9870` ]]; do echo "Waiting for hdfs-nn" ; ((count=count+1)) ; sleep 2; done
  [[ $count -eq 15 ]] && echo "Timeout waiting for hdfs-nn, exiting." && exit 1
  $HADOOP_HOME/bin/hdfs datanode
fi

if [[ "${HOSTNAME}" =~ "yarn-rm" ]]; then
  sed -i s/yarn-rm/0.0.0.0/ $HADOOP_HOME/etc/hadoop/yarn-site.xml
  cp ${CONFIG_DIR}/start-yarn-rm.sh $HADOOP_HOME/sbin/
  cd $HADOOP_HOME/sbin
  chmod +x start-yarn-rm.sh
  ./start-yarn-rm.sh
fi

if [[ "${HOSTNAME}" =~ "yarn-nm" ]]; then
  sed -i '/<\/configuration>/d' $HADOOP_HOME/etc/hadoop/yarn-site.xml
  cat >> $HADOOP_HOME/etc/hadoop/yarn-site.xml <<- EOM
  <property>
    <name>yarn.nodemanager.resource.memory-mb</name>
    <value>${MY_MEM_LIMIT:-2048}</value>
  </property>

  <property>
    <name>yarn.nodemanager.resource.cpu-vcores</name>
    <value>${MY_CPU_LIMIT:-2}</value>
  </property>
EOM
  echo '</configuration>' >> $HADOOP_HOME/etc/hadoop/yarn-site.xml
  cp ${CONFIG_DIR}/start-yarn-nm.sh $HADOOP_HOME/sbin/
  cd $HADOOP_HOME/sbin
  chmod +x start-yarn-nm.sh

  #  wait up to 30 seconds for resourcemanager
  count=0 && while [[ $count -lt 15 && -z `curl -sf http://yarn-rm:8088/ws/v1/cluster/info` ]]; do echo "Waiting for yarn-rm" ; ((count=count+1)) ; sleep 2; done
  [[ $count -eq 15 ]] && echo "Timeout waiting for hdfs-nn, exiting." && exit 1

  ./start-yarn-nm.sh
fi

if [[ $1 == "-d" ]]; then
  until find ${HADOOP_HOME}/logs -mmin -1 | egrep -q '.*'; echo "`date`: Waiting for logs..." ; do sleep 2 ; done
  tail -F ${HADOOP_HOME}/logs/* &
  while true; do sleep 1000; done
fi

if [[ $1 == "-bash" ]]; then
  /bin/bash
fi
