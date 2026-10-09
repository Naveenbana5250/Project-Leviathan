# Lightweight Spark ETL

Spark is deliberately **on-demand** to save RAM. Run:

```bash
kubectl apply -f gitops/data/spark/spark-etl-job.yaml
kubectl -n kafka logs -f job/leviathan-spark-etl
```

This starter job validates Spark execution without keeping a Spark cluster resident.
The Kafka -> Spark -> Neo4j production-grade pipeline will be completed during the
integration phase; keeping Spark resident on the single low-cost node would waste memory.
