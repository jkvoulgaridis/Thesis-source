package example

import org.apache.spark.sql.SparkSession
import org.apache.spark.TaskContext
import org.apache.spark.scheduler.TaskInfo

import org.apache.spark.ml.clustering.KMeans
import org.apache.spark.ml.evaluation.ClusteringEvaluator
import org.apache.spark.ml.linalg.Vectors
import org.apache.spark.ml.evaluation.MulticlassClassificationEvaluator
import org.apache.spark.ml.feature.LabeledPoint
import org.apache.spark.ml.feature.VectorAssembler
import org.apache.spark.ml.linalg.Vectors
import org.apache.spark.ml.tuning.{CrossValidator, ParamGridBuilder}
import org.apache.spark.sql.SparkSession
import Array._
import org.apache.spark.sql.types._


class appCode{
  def app4(): Unit = {
    val spark: SparkSession = SparkSession.builder()
      .appName("k-means")
      .getOrCreate()


    val sc = spark.sparkContext
    val sqlContext= new org.apache.spark.sql.SQLContext(sc)
    import sqlContext.implicits._
    // Loads data.
    val customSchema = StructType(Array(
      StructField("_c0", DoubleType, true),
      StructField("_c1", DoubleType, true),
      StructField("_c2", DoubleType, true),
      StructField("_c3", DoubleType, true))
    )
    val data = spark.read.format("csv").schema(customSchema).load("hdfs://clone9:5432/data/iris.data")

    val assembler = new VectorAssembler()
      .setInputCols(Array("_c0", "_c1", "_c2", "_c3"))
      .setOutputCol("features")

    val dataset = assembler.transform(data)
    dataset.show()

    // Trains a k-means model.
    val start = System.nanoTime()
    val kmeans = new KMeans().setK(3).setSeed(1L)
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
    app.app4()
  }
}

