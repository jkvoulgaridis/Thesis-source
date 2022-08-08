APP_NAME=$1

#EXE_BASE=/opt/spark-apps
#MASTER=spark://spark-master:7077
#SP="/opt/spark"
#
#EXE_BASE=/home/users/gvoulgar/apps
#MASTER=spark://clone9:9000
#SP=/home/users/gvoulgar/spark-original
##
EXE_BASE=/home/john/personal/spark-docker/apps
SP=$EXE_BASE/../spark-original
#EXE=$EXE_BASE/$APP_NAME

#echo "Submitting app ${APP_NAME}"
EXE="${EXE_BASE}/${APP_NAME}/target/scala-2.12/my-spark-app_2.12-0.1.0-SNAPSHOT.jar"
#${SP}/bin/spark-submit --master local[4]  $EXE
#
#echo "Submitting app ${APP_NAME}"
#EXE="${EXE_BASE}/${APP_NAME}/target/scala-2.12/my-spark-app_2.12-0.1.0-SNAPSHOT.jar"
#${SP}/bin/spark-submit --master ${MASTER}  $EXE

echo "========================================================================================"
echo "Submitting locally"
${SP}/bin/spark-submit --master local[2]  $EXE
