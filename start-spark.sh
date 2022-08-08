. "/opt/spark/bin/load-spark-env.sh"
/opt/scripts/installers/install_hadoop.sh

# When the spark work_load is master run class org.apache.spark.deploy.master.Master
if [ "$SPARK_WORKLOAD" == "master" ];
then
  echo "setting up master..."
  export SPARK_MASTER_HOST="spark-master"
  ssh-keygen -t rsa -P '' -f ~/.ssh/id_rsa  && echo "generating pub/private rsa keys"
  cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
  /etc/init.d/ssh start && echo "started ssh service on container"
  hadoop namenode -format	&& echo "formated namenode"
  /opt/hadoop/sbin/start-dfs.sh  && echo "started the hdfs"
  hadoop fs -mkdir hdfs://spark-master:5432/data/  && echo "created /data directory"
  hadoop fs -put /opt/scripts/query.txt hdfs://spark-master:5432/data/query.txt && echo "uploaded a test file"
  hadoop fs -put /opt/spark-data/iris.data hdfs://spark-master:5432/data/iris.data && echo "uploaded iris file"
  (hadoop fs -put /opt/spark-data/fifa.csv hdfs://spark-master:5432/data/fifa.csv && echo "uploaded fifa file") || echo 'FIFA FAILED'
  cd /opt/spark/bin && ./spark-class org.apache.spark.deploy.master.Master --ip $SPARK_MASTER_HOST --port $SPARK_MASTER_PORT --webui-port $SPARK_MASTER_WEBUI_PORT >> $SPARK_MASTER_LOG

elif [ "$SPARK_WORKLOAD" == "worker" ];
then
  echo "setting up worker..."
  ssh-keygen -t rsa -P '' -f ~/.ssh/id_rsa && echo "creating pub/private rsa keys"
  cat ~/.ssh/id_rsa.pub >> ~/.ssh/authorized_keys
  /opt/hadoop/sbin/hadoop-daemon.sh start datanode && echo "starting data node"
  cd /opt/spark/bin && ./spark-class org.apache.spark.deploy.worker.Worker --webui-port $SPARK_WORKER_WEBUI_PORT $SPARK_MASTER >> $SPARK_WORKER_LOG

elif [ "$SPARK_WORKLOAD" == "submit" ];
then
    echo "SPARK SUBMIT"
else
    echo "Undefined Workload Type $SPARK_WORKLOAD, must specify: master, worker, submit"
fi
