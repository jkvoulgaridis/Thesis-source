package example

import org.apache.spark.sql.SparkSession
import org.apache.spark.TaskContext
import org.apache.spark.scheduler.TaskInfo

import Array._

import org.apache.spark.ml.clustering.KMeans
import org.apache.spark.ml.evaluation.ClusteringEvaluator

class appCode{
  def app3(): Unit = {
    val spark: SparkSession = SparkSession.builder()
      .appName("app-3")
      .getOrCreate()

    // Loads data.
    val dataset = spark.read.format("libsvm").load("data/mllib/sample_kmeans_data.txt")

    // Trains a k-means model.
    val start = System.nanoTime()
    val kmeans = new KMeans().setK(2).setSeed(1L)
    val model = kmeans.fit(dataset)
    // Make predictions
    val predictions = model.transform(dataset)
    // Evaluate clustering by computing Silhouette score
    val evaluator = new ClusteringEvaluator()
    val silhouette = evaluator.evaluate(predictions)
    println(s"Silhouette with squared euclidean distance = $silhouette")
    // Shows the result.
    println("Cluster Centers: ")
    model.clusterCenters.foreach(println)
    val end = System.nanoTime()
    val duration = (end-start) / 1e9d
    println(s"DURATIONS ${duration} seconds")
  }
}


object myApp {
  def main(args: Array[String]){
    val app = new appCode
    app.app3()
  }
}

