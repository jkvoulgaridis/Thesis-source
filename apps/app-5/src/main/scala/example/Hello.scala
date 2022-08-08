package example

import org.apache.spark.sql.SparkSession
import org.apache.spark.TaskContext
import org.apache.spark.scheduler.TaskInfo
import scala.util.Properties.envOrElse
import math.max
import scala.util.Try
import Array._



class appCode{
  def app2(){
    println("*************START**********************")
    val spark:SparkSession = SparkSession.builder()
      .appName("boooks")
      .getOrCreate()
    val sc = spark.sparkContext
    val fileLocation: String = envOrElse("PWD", "")
    var filename: String = ""
    if (fileLocation.contains("john")) {
      filename= s"/home/john/personal/spark-docker/data/books.csv"
    } else{
      filename = "hdfs://clone9:5432/data/books.csv"
    }
    val res = sc.textFile(filename,10)
      .map(x => x.split(','))
      .map(line => Try(line(9)))
      .map(x => (x,1))
      .reduceByKey(_+_)
      .sortBy(_._2, false)
      .filter(x=>x._2 > 100)
      .collect
    res.foreach(println)
    println("lib logs")
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

