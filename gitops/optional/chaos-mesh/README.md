# Optional Chaos Mesh layer

Chaos Mesh is part of the original Leviathan resilience concept, but is intentionally
not auto-synced in the low-memory Friday MVP. Install it only after the core platform
is healthy.

For EKS/AL2023 containerd nodes, use the official Chaos Mesh Helm chart and containerd
runtime/socket settings. Keep the dashboard optional and the controller replica count
minimal for the lab.

This separation prevents Chaos Mesh from consuming resources or introducing extra
privileged daemon workloads while the primary Zero Trust/detection path is being
brought online.
