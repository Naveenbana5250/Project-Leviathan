# Leviathan Spark Security ETL

Spark provides the analytics stage of the Leviathan automated defense pipeline.

Current flow:

Falco -> Kafka -> Spark -> Neo4j -> n8n -> Kubernetes -> Cilium quarantine

The ETL runs as a Kubernetes CronJob every minute.

It:

- consumes Falco events from the `falco-alerts` Kafka topic
- filters Leviathan runtime security events
- assigns risk scores
- stores graph evidence in Neo4j
- checks Neo4j-backed containment state to prevent duplicate responses
- sends new actionable events with risk >= 70 to n8n
- n8n applies the Kubernetes quarantine label
- Cilium isolates the affected workload

`concurrencyPolicy: Forbid` prevents overlapping Spark executions.

For the MVP, Kafka history is re-read on each run and Neo4j provides event
idempotency. A persistent Kafka consumer group / streaming Spark deployment
would be the next production optimization.
