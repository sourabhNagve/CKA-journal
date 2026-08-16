# Metrics Server

The **Metrics Server** is a lightweight Kubernetes component that collects **CPU and memory usage** from nodes and Pods and exposes the data through the **Kubernetes Metrics API**.

It is mainly used by **HPA and other autoscaling features** to make scaling decisions.

## What It Provides

- Current CPU and memory usage for nodes.
- Current CPU and memory usage for Pods.
- Metrics used by autoscaling.

## Commands

    kubectl top nodes
    kubectl top pods

## What It Does Not Do

- It does **not** store historical metrics.
- It is **not a full monitoring system** like Prometheus.

### Remember

    Metrics Server → Current resource usage
    Prometheus    → Monitoring + historical metrics