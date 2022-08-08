package example

import org.apache.spark.sql.SparkSession
import org.apache.spark.TaskContext
import org.apache.spark.scheduler.TaskInfo

import Array._
import scala.util.Properties.envOrElse

import scala.util.Try

class appCode{
  def app4(): Unit = {
    val spark: SparkSession = SparkSession.builder()
      .appName("app-4")
      .getOrCreate()
    val sc = spark.sparkContext
    val fileLocation: String = envOrElse("PWD", "")
    var filename: String = ""
    if (fileLocation.contains("john")) {
      filename= s"/home/john/personal/spark-docker/data/fifa.csv"
    } else if(fileLocation.contains("/opt")) {
      filename = "hdfs://spark-master:5432/data/fifa.csv"
    } else{
      filename = "hdfs://clone9:5432/data/fifa.csv"
    }
//    val res = sc.textFile("hdfs://spark-master:5432/data/query.txt")
    val start = System.nanoTime()
    val res = sc.textFile(filename,10)
    .map(x => x.split(','))
    .map(line => Try(line(5)))
    .map(x => (x,1))
    .reduceByKey(_+_)
    .sortBy(_._2, false)
    .collect
    res.foreach(println)
    val end = System.nanoTime()
    val duration = (end-start) / 1e9d
    println(s"DURATIONS ${duration} seconds")
  }
  
}


object myApp {
  def main(args: Array[String]){
    val app = new appCode
    app.app4()
  }
}

