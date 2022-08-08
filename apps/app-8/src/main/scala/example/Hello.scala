package example

import org.apache.spark.sql.SparkSession
import org.apache.spark.TaskContext
import org.apache.spark.scheduler.TaskInfo
import scala.util.Properties.envOrElse
import math.max
import scala.util.Try
import Array._
import scala.util.Properties.envOrElse

class appCode{
  def app2(){
    println("*************START**********************")
    val samples = envOrElse("SAMPLES", "0.1").toDouble;
    val spark:SparkSession = SparkSession.builder()
      .appName("twitter")
      .getOrCreate()
    val sc = spark.sparkContext
    val fileLocation: String = envOrElse("PWD", "")
    var filename1: String = ""
    var filename2: String = ""
    if (fileLocation.contains("john")) {
      filename1 = s"/home/john/personal/spark-docker/data/movies_metadata.csv"
      filename2 = s"/home/john/personal/spark-docker/data/ratings.csv"
    } else{
      filename1 = "hdfs://clone9:5432/data/movies_metadata.csv"
      filename2 = "hdfs://clone9:5432/data/ratings.csv"
    }
    val tmp_res_1 = sc.textFile(filename1,10)
      .map(x => x.split(','))
      .map(x => (x(0), x) )

    val tmp_res_2 = sc.textFile(filename2,10)
      .map(x => x.split(','))
      .map(x => (x(1) , 1) )
      .reduceByKey(_+_)

    val res = tmp_res_2.join(tmp_res_1)
      .map(x => (x._2._2(3), 1) )
      .reduceByKey(_+_)
      .sortBy(_._2, false)
      .collect

    res.foreach(println)
    println(res.size)
  }
}

object myApp {
  def main(args: Array[String]){
    val app = new appCode
    val start = System.nanoTime()
    app.app2()
    val end = System.nanoTime()
    val duration = (end-start) / 1e9d
    println(s"DURATIONS ${duration} seconds")
  }
}

