# 🎢 Guest Management Login Microservice

This repository contains a mock **Guest Management Login** microservice designed to simulate an amusement park guest login experience.

It’s a playground for learning and experimenting with:

- Kubernetes autoscaling using **Karpenter** (node autoscaling) and **KEDA** (event-driven pod autoscaling)
- Configuration management using **ConfigMaps**
- Cluster-wide logging and monitoring using **DaemonSets**
- Real-world Kubernetes debugging scenarios

---

## 📁 Project Structure

                       ┌──────────────────────────┐
                       │       GitHub             │
                       │     Actions CI/CD        │
                       └──────────┬───────────────┘
                                  │
                          Webhook Triggers
                                  │
              ┌──────────────────────────────────────┐
              │   Self-hosted Runner on EC2          │
              │ - Runs in isolated environment       │
              │ - Accesses EKS cluster (kubectl etc) │
              └────────────────┬─────────────────────┘
                               │
                          kubectl apply / helm install
                               │
              ┌──────────────────────────────────────┐
              │              EKS Cluster             │
              │ - Apps deployed via Helm             │
              │ - Autoscaling via KEDA               │
              │ - Logging with SigNoz or Datadog     │
              └──────────────────────────────────────┘



---

## 🚀 Getting Started

### Prerequisites
- A Kubernetes cluster (EKS preferred)
- `kubectl` configured for your cluster
- Helm (for installing Karpenter and KEDA)

### Usage

1. **Build and push** the Docker image for the app  
2. **Apply Kubernetes manifests** in `k8s/`  
3. **Install Karpenter and KEDA** in your cluster  
4. **Test autoscaling** by simulating guest login traffic  
5. **Explore logs** collected by DaemonSets  
6. **Practice debugging** with the provided debug manifests

---

## 🧩 Learning Goals

- Understand how to implement **node and pod autoscaling** in Kubernetes  
- Learn how to use **ConfigMaps** to manage app configuration dynamically  
- Get hands-on with **DaemonSets** for cluster-wide agents like logging  
- Build confidence troubleshooting and debugging real Kubernetes issues

---

## 🤝 Contributing

Feel free to fork, open issues, or submit pull requests to improve this learning project!

---

## 📜 License

MIT License

---

*Created by Preethy Venkat  
