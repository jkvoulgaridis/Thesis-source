package example

import org.apache.spark.sql.SparkSession
import org.apache.spark.TaskContext
import org.apache.spark.scheduler.TaskInfo

import Array._

class appCode{
  def app2(){
    val spark:SparkSession = SparkSession.builder()
      .appName("app2")
      .getOrCreate()
    val sc = spark.sparkContext
    val res = sc.parallelize(range(1,1000), 4)
      .filter(x => x % 2 == 0)
      .map(x => x*x).sum()
    val start = System.nanoTime()
    println(s"final result : ${res}")
    val end = System.nanoTime()
    val duration = (end-start) / 1e9d
    println(s"DURATIONS ${duration} seconds")
  }
}


object myApp {
  def main(args: Array[String]){
    val app = new appCode
    app.app2()
  }
}

