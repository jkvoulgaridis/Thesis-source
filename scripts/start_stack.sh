# load spark Env
#### IMPORTANT VARIABLE ########
SPARK_MASTER_HOSTNAME=clone9
###############################
LOAD_FILES_HDFS="false"
SPARK_LOCAL_HOSTNAME=$HOSTNAME

HOME_DIR=/home/users/gvoulgar
SPARK_HOME=$HOME_DIR/spark

PATH_TO_HADOOP=$HOME_DIR/hadoop
JAVA_DIRECTORY=$HOME_DIR/jdk-11
SPARK_MASTER_PORT=9000
SPARK_MASTER_WEBUI_PORT=8080
HADOOP_HDFS_PORT=5432

LOGS_BASE=$HOME_DIR/logs
SPARK_MASTER_LOG=$HOME_DIR/spark-master.out
SPARK_WORKER_LOG=$HOME_DIR/spark-worker.out
USER_RUNNING=gvoulgar

. "$SPARK_HOME/bin/load-spark-env.sh"

#export JAVA_HOME=$JAVA_DIRECTORY/
if [ $# -eq 1 ] &&  [ "$SPARK_LOCAL_HOSTNAME" == "$SPARK_MASTER_HOSTNAME" ];
then
  echo "will load files to hdfs"
  LOAD_FILES_HDFS="true"
elif [ $# -eq 0 ] &&  [ "$SPARK_LOCAL_HOSTNAME" == "$SPARK_MASTER_HOSTNAME" ];
then
  echo "Starting master"
elif [ $# -eq 1 ] && [ "$SPARK_LOCAL_HOSTNAME" != "$SPARK_MASTER_HOSTNAME" ];
then
  echo "String worker"
  MASTER_URL=$1
else
  echo "Needed MASTER_URL argument"
  exit 1
fi

start_hadoop_namenode() {
  #ssh-keygen -t rsa -P '' -f ~/.ssh/id_rsa  && echo "generating pub/private rsa keys"
  #cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
  #/etc/init.d/ssh start && echo "started ssh service on container"
  $HADOOP_INSTALL/sbin/stop-dfs.sh && echo "stopping namenode to format"
  $HADOOP_INSTALL/bin/hadoop namenode -format	&& echo "formated namenode"
  $HADOOP_INSTALL/sbin/start-dfs.sh  && echo "started the hdfs"
}

start_spark_master() {
    echo "setting up spark master..."
    cd $SPARK_HOME/sbin && ./stop-master.sh && echo "Stopping master to restart!"
    cd $SPARK_HOME/sbin && ./start-master.sh --host $SPARK_MASTER_HOSTNAME --port $SPARK_MASTER_PORT --webui-port $SPARK_MASTER_WEBUI_PORT
#    $SPARK_HOME/bin/spark-class org.apache.spark.deploy.master.Master --ip $SPARK_MASTER_HOSTNAME --port $SPARK_MASTER_PORT --webui-port $SPARK_MASTER_WEBUI_PORT
}

start_spark_worker() {
  echo "setting up worker..."
  #ssh-keygen -t rsa -P '' -f ~/.ssh/id_rsa && echo "creating pub/private rsa keys"
#  cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
  $HADOOP_INSTALL/sbin/hadoop-daemon.sh start datanode && echo "starting data node"
  cd $SPARK_HOME/sbin && ./stop-slave.sh && echo "Stopping slave to restart!"
  cd $SPARK_HOME/sbin && ./start-slave.sh --host $SPARK_LOCAL_HOSTNAME --webui-port 8085 $MASTER_URL
#  $SPARK_HOME/bin/spark-class org.apache.spark.deploy.worker.Worker --host $SPARK_LOCAL_HOSTNAME --port 9000 --webui-port 8085 $MASTER_URL
}

configure_hadoop_env_vars () {
	cd ~
	## Export environmental variables.
	echo "setting up hadoop at dir $PATH_TO_HADOOP"
	echo "export JAVA_HOME=$JAVA_HOME" >> ~/.bashrc
	echo "export HADOOP_INSTALL=$PATH_TO_HADOOP" >> ~/.bashrc
	echo "export PATH=$PATH:$PATH_TO_HADOOP/bin" >> ~/.bashrc
	echo "export PATH=$PATH:$PATH_TO_HADOOP/sbin" >> ~/.bashrc
	echo "export HADOOP_HOME=$PATH_TO_HADOOP" >> ~/.bashrc
	echo "export HADOOP_COMMON_HOME=$PATH_TO_HADOOP" >> ~/.bashrc
	echo "export HADOOP_HDFS_HOME=$PATH_TO_HADOOP" >> ~/.bashrc
	echo "export HADOOP_CONF_DIR=$PATH_TO_HADOOP/etc/hadoop" >> ~/.bashrc
	echo "export HDFS_NAMENODE_USER=$USER_RUNNING" >> ~/.bashrc
	echo "export HDFS_SECONDARYNAMENODE_USER=$USER_RUNNING" >> ~/.bashrc
	echo "Java Home is: $JAVA_HOME"
	source ~/.bashrc
}

configure_spark_env_vars_worker() {
  echo "export SPARK_LOCAL_IP=$SPARK_MASTER_HOSTNAME" >> ~/.bashrc
  echo "setting up worker $SPARK_LOCAL_HOSTNAME"
  echo "export SPARK_MASTER=spark://$SPARK_MASTER_HOSTNAME:$SPARK_MASTER_PORT" >> ~/.bashrc
  echo "export SPARK_WORKER_CORES=2" >> ~/.bashrc
  echo "export SPARK_WORKER_MEMORY=1G" >> ~/.bashrc
  echo "export SPARK_DRIVER_MEMORY=1G" >> ~/.bashrc
  echo "export SPARK_EXECUTOR_MEMORY=1G" >> ~/.bashrc
  echo "export SPARK_LOCAL_IP=$SPARK_LOCAL_HOSTNAME" >> ~/.bashrc
}

configure_spark_env_vars_master() {
  echo "export SPARK_LOCAL_IP=$SPARK_MASTER_HOSTNAME" >> ~/.bashrc
  echo "export SPARK_MASTER=spark://$SPARK_MASTER_HOSTNAME:$SPARK_MASTER_PORT" >> ~/.bashrc
  echo "export SPARK_WORKER_CORES=2" >> ~/.bashrc
  echo "export SPARK_WORKER_MEMORY=1G" >> ~/.bashrc
  echo "export SPARK_DRIVER_MEMORY=1G" >> ~/.bashrc
  echo "export SPARK_EXECUTOR_MEMORY=1G" >> ~/.bashrc
  source ~/.bashrc
}

configure_hadoop () {
    ## Edit core-site.xml to set hdfs default path to hdfs://master:9000
		CORE_SITE_CONTENT="\t<property>\n\t\t<name>fs.default.name</name>\n\t\t<value>hdfs://$SPARK_MASTER_HOSTNAME:$HADOOP_HDFS_PORT</value>\n\t</property>"
		INPUT_CORE_SITE_CONTENT=$(echo $CORE_SITE_CONTENT | sed 's/\//\\\//g')
		sed -i "/<\/configuration>/ s/.*/${INPUT_CORE_SITE_CONTENT}\n&/" ${PATH_TO_HADOOP}/etc/hadoop/core-site.xml
    ## Edit hdfs-site.xml to set hadoop file system parameters
		HDFS_SITE_CONTENT="\t<property>\n\t\t<name>dfs.replication</name>\n\t\t<value>1</value>\n\t\t<description>Default block replication.</description>\n\t</property>"
		HDFS_SITE_CONTENT="${HDFS_SITE_CONTENT}\n\t<property>\n\t\t<name>dfs.namenode.name.dir</name>\n\t\t<value>$HOME_DIR/hdfsname</value>\n\t</property>"
		HDFS_SITE_CONTENT="${HDFS_SITE_CONTENT}\n\t<property>\n\t\t<name>dfs.datanode.data.dir</name>\n\t\t<value>$HOME_DIR/hdfsdata</value>\n\t</property>"
		HDFS_SITE_CONTENT="${HDFS_SITE_CONTENT}\n\t<property>\n\t\t<name>dfs.blocksize</name>\n\t\t<value>64m</value>\n\t\t<description>Block size</description>\n\t</property>"
		HDFS_SITE_CONTENT="${HDFS_SITE_CONTENT}\n\t<property>\n\t\t<name>dfs.webhdfs.enabled</name>\n\t\t<value>true</value>\n\t</property>"
		HDFS_SITE_CONTENT="${HDFS_SITE_CONTENT}\n\t<property>\n\t\t<name>dfs.support.append</name>\n\t\t<value>true</value>\n\t</property>"
		INPUT_HDFS_SITE_CONTENT=$(echo $HDFS_SITE_CONTENT | sed 's/\//\\\//g')
		sed -i "/<\/configuration>/ s/.*/${INPUT_HDFS_SITE_CONTENT}\n&/" $HADOOP_INSTALL/etc/hadoop/hdfs-site.xml
		echo "$SPARK_LOCAL_HOSTNAME" > $HADOOP_INSTALL/etc/hadoop/workers
		#echo "slave" >> /home/user/hadoop/etc/hadoop/slaves
		sed -i "/export JAVA\_HOME/c\export JAVA\_HOME=$JAVA_DIRECTORY" $HADOOP_INSTALL/etc/hadoop/hadoop-env.sh
}

if [ $LOAD_FILES_HDFS == "true" ];
then
  $HADOOP_INSTALL/bin/hadoop fs -mkdir hdfs://$SPARK_MASTER_HOSTNAME:5432/data/  && echo "created /data directory"
#  $HADOOP_INSTALL/bin/hadoop fs -put $HOME_DIR/data/query.txt hdfs://$SPARK_MASTER_HOSTNAME:5432/data/query.txt && echo "uploaded a test file"
  $HADOOP_INSTALL/bin/hadoop fs -put $HOME_DIR/data/edges.csv hdfs://$SPARK_MASTER_HOSTNAME:5432/data/edges.csv && echo "uploaded twitter data"
#  $HADOOP_INSTALL/bin/hadoop fs -put $HOME_DIR/data/iris.data hdfs://$SPARK_MASTER_HOSTNAME:5432/data/iris.data && echo "uploaded iris.data"
#  $HADOOP_INSTALL/bin/hadoop fs -put $HOME_DIR/data/fifa.csv hdfs://$SPARK_MASTER_HOSTNAME:5432/data/fifa.csv && echo "uploaded fifa data"
  echo "Uploaded files to HDFS" && exit 0
fi

if [ "$SPARK_LOCAL_HOSTNAME" == "$SPARK_MASTER_HOSTNAME" ];
then
    echo "starting master on $SPARK_LOCAL_HOSTNAME"
    source ~/.bashrc
    configure_spark_env_vars_master
    source ~/.bashrc
    configure_hadoop_env_vars
    source ~/.bashrc
    configure_hadoop
    source ~/.bashrc
    start_hadoop_namenode
    start_spark_master
else
    echo "starting worker on $SPARK_LOCAL_HOSTNAME"
    configure_spark_env_vars_worker
    configure_hadoop_env_vars
    start_spark_worker
fi
