# load spark Env
#### IMPORTANT VARIABLE ########
SPARK_MASTER_HOSTNAME=clone9
###############################
LOAD_FILES_HDFS="false"
SPARK_LOCAL_HOSTNAME=$HOSTNAME

HOME_DIR=/home/users/gvoulgar
SPARK_HOME=$HOME_DIR/spark-original

PATH_TO_HADOOP=$HOME_DIR/hadoop
JAVA_DIRECTORY=$HOME_DIR/jdk-11
SPARK_MASTER_PORT=7077
SPARK_MASTER_WEBUI_PORT=8080
HADOOP_HDFS_PORT=5432

LOGS_BASE=$HOME_DIR/logs
SPARK_MASTER_LOG=$HOME_DIR/spark-master.out
SPARK_WORKER_LOG=$HOME_DIR/spark-worker.out
USER_RUNNING=gvoulgar

APP_DIR=${HOME_DIR}/apps
SCRIPTS_DIR=${HOME_DIR}/scripts
DATA_DIR=${HOME_DIR}/data

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
#  echo "export SPARK_LOCAL_IP=$SPARK_MASTER_HOSTNAME" >> ~/.bashrc
  echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
  echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
  echo "setting up worker"
  echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
  echo "++++++++++++++++++++++++++++++++++++++++++++++++++++++++"
#  echo "export SPARK_MASTER=spark://$SPARK_MASTER_HOSTNAME:$SPARK_MASTER_PORT" >> ~/.bashrc
  echo "export SPARK_WORKER_CORES=2" >> ~/.bashrc
  echo "export SPARK_WORKER_MEMORY=1G" >> ~/.bashrc
  echo "export SPARK_DRIVER_MEMORY=1G" >> ~/.bashrc
  echo "export SPARK_EXECUTOR_MEMORY=1G" >> ~/.bashrc
#  echo "export SPARK_LOCAL_IP=$SPARK_LOCAL_HOSTNAME" >> ~/.bashrc
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
#		echo "$SPARK_LOCAL_HOSTNAME" > $HADOOP_INSTALL/etc/hadoop/workers
		#echo "slave" >> /home/user/hadoop/etc/hadoop/slaves
		sed -i "/export JAVA\_HOME/c\export JAVA\_HOME=$JAVA_DIRECTORY" $HADOOP_INSTALL/etc/hadoop/hadoop-env.sh
}

setup_cluster_workers_list() {
  SPARK_HOME_IN=${HOME_DIR}$1
  CLUSTER_SIZE=$2
  if [ $2 -eq 3 ]; then
    CLUSTER="clone10\nclone11\nclone12\n"
  elif [ $2 -eq 4 ]; then
    CLUSTER="clone10\nclone11\nclone12\nclone8\n"
  elif [ $2 -eq 5 ]; then
    CLUSTER="clone8\nclone7\nclone10\nclone11\nclone12\n"
  else
    echo "Too large cluster!" && exit 3
  fi

  printf ${CLUSTER} > ${SPARK_HOME_IN}/conf/slaves
  printf "${CLUSTER}${SPARK_MASTER_HOSTNAME}\n" > ${HADOOP_INSTALL}/etc/hadoop/workers
}

up_and_run_cluster() {
  #$SPARK_HOME/sbin/stop-master.sh && echo "Stopping master to restart!"
  #cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
  SIG=$1
  SZ=$2
  ITER=$3
  SPARK_HOME_IN=${HOME_DIR}/${SIG}
  . "${SPARK_HOME_IN}/bin/load-spark-env.sh"

  echo $SPARK_HOME
  configure_spark_env_vars_worker
  source ~/.bashrc
  configure_hadoop_env_vars
  source ~/.bashrc
  configure_hadoop
  source ~/.bashrc
  echo "SIG = ${SIG}"
  ${HADOOP_INSTALL}/bin/hadoop namenode -format	&& echo "formated hdfs namenode"
  ${SPARK_HOME_IN}/sbin/start-all.sh && echo "Started spark cluster"
  ${HADOOP_INSTALL}/sbin/start-all.sh  && echo "started hdfs"
  sleep 15
  echo "=================================================================="
  $HADOOP_INSTALL/bin/hadoop fs -mkdir hdfs://$SPARK_MASTER_HOSTNAME:$HADOOP_HDFS_PORT/data/  && echo "created /data directory" || (exit 3 && echo "abort")
  $HADOOP_INSTALL/bin/hadoop fs -put $HOME_DIR/data/query.txt hdfs://$SPARK_MASTER_HOSTNAME:5432/data/query.txt && echo "uploaded a test file"  || (exit 3 && echo "abort")
  $HADOOP_INSTALL/bin/hadoop fs -put $HOME_DIR/data/edges.csv hdfs://$SPARK_MASTER_HOSTNAME:$HADOOP_HDFS_PORT/data/edges.csv && echo "uploaded twitter data" || (exit 3 && echo "abort")
  $HADOOP_INSTALL/bin/hadoop fs -put $HOME_DIR/data/iris.data hdfs://$SPARK_MASTER_HOSTNAME:5432/data/iris.data && echo "uploaded iris.data" || (exit 3 && echo "abort")
  $HADOOP_INSTALL/bin/hadoop fs -put $HOME_DIR/data/fifa.csv hdfs://$SPARK_MASTER_HOSTNAME:5432/data/fifa.csv && echo "uploaded fifa data" || (exit 3 && echo "abort")
  sleep 10
  MASTER=spark://${SPARK_MASTER_HOSTNAME}:${SPARK_MASTER_PORT}

#  EXE="${APP_DIR}/app-4/target/scala-2.12/my-spark-app_2.12-0.1.0-SNAPSHOT.jar"
#  ${SPARK_HOME_IN}/bin/spark-submit  --name "app-4-${SIG}-${SZ}-${ITER}" --master ${MASTER}  ${EXE} > ${HOME_DIR}/results/app-4-${SIG}-${SZ}-${ITER}.res

  EXE="${APP_DIR}/app-6/target/scala-2.12/my-spark-app_2.12-0.1.0-SNAPSHOT.jar"
  ${SPARK_HOME_IN}/bin/spark-submit  --name "app-6-${SIG}-${SZ}-${ITER}" --master ${MASTER}  ${EXE}  > ${HOME_DIR}/results/app-6-${SIG}-${SZ}-${ITER}.res

  EXE="${APP_DIR}/app-7/target/scala-2.12/my-spark-app_2.12-0.1.0-SNAPSHOT.jar"
  ${SPARK_HOME_IN}/bin/spark-submit --name "app-7-${SIG}-${SZ}-${ITER}" --master ${MASTER}  ${EXE} > ${HOME_DIR}/results/app-7-${SIG}-${SZ}-${ITER}.res
}

drop_all() {
  ${HOME_DIR}/spark-original/sbin/stop-all.sh
  ${HOME_DIR}/spark/sbin/stop-all.sh
  ${HOME_DIR}/hadoop/sbin/stop-all.sh
  rm -r hdfsname/ hdfsdata/
  rm ${HOME_DIR}/spark/logs/*
  rm ${HOME_DIR}/spark-original/logs/*
}

echo "Stopping any running provesses..."
drop_all

for iter in {1..3..1}; do

  setup_cluster_workers_list /spark 3 ${iter}
  up_and_run_cluster spark 3  ${iter}
  drop_all

  setup_cluster_workers_list /spark-original 3 ${iter}
  up_and_run_cluster spark-original 3 ${iter}
  drop_all

  setup_cluster_workers_list /spark-original 4 ${iter}
  up_and_run_cluster spark-original 4 ${iter}
  drop_all

  setup_cluster_workers_list /spark 4 ${iter}
  up_and_run_cluster spark 4 ${iter}
  drop_all

  setup_cluster_workers_list /spark-original 5 ${iter}
  up_and_run_cluster  spark-original 5 ${iter}
  drop_all


  setup_cluster_workers_list /spark 5 ${iter}
  up_and_run_cluster spark 5 ${iter}
  drop_all

done


echo "DONE" && exit 0
#
#up_and_run_cluster_functionality_store_backup(){
#  #$SPARK_HOME/sbin/stop-master.sh && echo "Stopping master to restart!"
#  #cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
#  SIG=$1
#  SZ=$2
#  configure_spark_env_vars_worker
#  source ~/.bashrc
#  configure_hadoop_env_vars
#  source ~/.bashrc
#  configure_hadoop
#  source ~/.bashrc
#  ${HADOOP_INSTALL}/bin/hadoop namenode -format	&& echo "formated hdfs namenode"
#  ${SPARK_HOME}/sbin/start-all.sh && echo "Started spark cluster"
#  ${HADOOP_INSTALL}/sbin/start-all.sh && echo "started hdfs"
#  echo "=================================================================="
#  sleep 12
#  ($HADOOP_INSTALL/bin/hadoop fs -mkdir hdfs://$SPARK_MASTER_HOSTNAME:$HADOOP_HDFS_PORT/data/  && echo "created /data directory") || (echo "ABORTED" && exit 3)
#  ($HADOOP_INSTALL/bin/hadoop fs -put $HOME_DIR/data/query.txt hdfs://$SPARK_MASTER_HOSTNAME:5432/data/query.txt && echo "uploaded a test file") || (echo "ABORTED" && exit 3)
#  ($HADOOP_INSTALL/bin/hadoop fs -put $HOME_DIR/data/edges.csv hdfs://$SPARK_MASTER_HOSTNAME:$HADOOP_HDFS_PORT/data/edges.csv && echo "uploaded twitter data" || (echo "ABORTED" && exit 3)
#  ($HADOOP_INSTALL/bin/hadoop fs -put $HOME_DIR/data/iris.data hdfs://$SPARK_MASTER_HOSTNAME:5432/data/iris.data && echo "uploaded iris.data") || (echo "ABORTED" && exit 3)
#  ($HADOOP_INSTALL/bin/hadoop fs -put $HOME_DIR/data/fifa.csv hdfs://$SPARK_MASTER_HOSTNAME:5432/data/fifa.csv && echo "uploaded fifa data") || (echo "ABORTED" && exit 3)
#  MASTER=spark://${SPARK_MASTER_HOSTNAME}:${SPARK_MASTER_PORT}
#
#  EXE="${APP_DIR}/app-4/target/scala-2.12/my-spark-app_2.12-0.1.0-SNAPSHOT.jar"
#  ${SPARK_HOME}/bin/spark-submit  --name "app-4-${SIG}-${SZ}" --master ${MASTER}  ${EXE} > ${HOME_DIR}/results/app-4-${SIG}-${SZ}.res
#
#  EXE="${APP_DIR}/app-6/target/scala-2.12/my-spark-app_2.12-0.1.0-SNAPSHOT.jar"
#  ${SPARK_HOME}/bin/spark-submit  --name "app-6-${SIG}-${SZ}" --master ${MASTER}  ${EXE}  > ${HOME_DIR}/results/app-6-${SIG}-${SZ}.res
#
#  EXE="${APP_DIR}/app-7/target/scala-2.12/my-spark-app_2.12-0.1.0-SNAPSHOT.jar"
#  ${SPARK_HOME}/bin/spark-submit --name "app-7-${SIG}-${SZ}" --master ${MASTER}  ${EXE} > ${HOME_DIR}/results/app-7-${SIG}-${SZ}.res
#}