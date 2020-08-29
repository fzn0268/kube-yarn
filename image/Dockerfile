FROM adoptopenjdk/openjdk8-openj9:jre

# Add native libs
ARG HADOOP_VERSION=
ADD hadoop-${HADOOP_VERSION}.tar.gz /usr/local
ADD hadoop-native-${HADOOP_VERSION}.tar /usr/local/hadoop-${HADOOP_VERSION}/lib/native

ENV HADOOP_HOME=/usr/local/hadoop \
    HADOOP_COMMON_HOME=/usr/local/hadoop \
    HADOOP_HDFS_HOME=/usr/local/hadoop \
    HADOOP_MAPRED_HOME=/usr/local/hadoop \
    HADOOP_YARN_HOME=/usr/local/hadoop \
    HADOOP_CONF_DIR=/usr/local/hadoop/etc/hadoop \
    YARN_CONF_DIR=/usr/local/hadoop/etc/hadoop \
    PATH=${PATH}:/usr/local/hadoop/bin

RUN \
  sed -i -E -e 's/(archive|security)\.ubuntu\.com/mirrors\.tuna\.tsinghua\.edu\.cn/g' /etc/apt/sources.list && \
  apt-get update && \
  apt-get install -y libssl-dev libzstd1 zstd libsnappy1v5 libsnappy-java bzip2 fuse libisal2 libsasl2-2 && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
  cd /usr/local && ln -s ./hadoop-${HADOOP_VERSION} hadoop && \
  rm -f ${HADOOP_HOME}/logs/*

WORKDIR $HADOOP_HOME

# Hdfs ports
# port of dfs.datanode.address
EXPOSE 9866 \
# port of dfs.datanode.ipc.address
       9867 \
# port of dfs.namenode.http-address
       9870 \
# port of dfs.datanode.http.address
       9864 \
# port of dfs.namenode.secondary.http-address
       9868 \
# port of dfs.namenode.rpc-address
       8020 \
# port of fs.defaultFS, in core-site.xml
       9000
# Mapred ports
# port of mapreduce.jobhistory.webapp.address
EXPOSE 19888
# Yarn ports
# port of yarn.resourcemanager.scheduler.address
EXPOSE 8030 \
# port of yarn.resourcemanager.resource-tracker.address
       8031 \
# port of yarn.resourcemanager.address
       8032 \
# port of yarn.resourcemanager.admin.address
       8033 \
# port of yarn.nodemanager.localizer.address
       8040 \
# port of yarn.nodemanager.webapp.address
       8042 \
# port of yarn.resourcemanager.webapp.address
       8088
# Other ports
EXPOSE 49707 2122
