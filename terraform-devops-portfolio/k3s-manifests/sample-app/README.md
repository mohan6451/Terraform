# Portfolio Dashboard — Flask App

A real-time dashboard showing live pod, cluster, and system stats.
Deployed on K3s running on AWS EC2 (free tier), provisioned by Terraform.

## Endpoints

| Endpoint | Description |
|---|---|
| `/` | Live dashboard UI |
| `/health` | Health check — used by K8s liveness/readiness probes |
| `/api/stats` | Raw JSON stats — pod, system, cluster info |

## Run locally

```bash
pip install -r requirements.txt
python app.py
# open http://localhost:5000
```

## Build Docker image

```bash
docker build -t portfolio-dashboard .
docker run -p 5000:5000 portfolio-dashboard
```

## Deploy to K3s

```bash
# Replace image name in k8s-manifest.yaml with your Docker Hub username first
kubectl apply -f k8s-manifest.yaml
kubectl get pods
kubectl get svc
# Access at http://<master_public_ip>:30080
```

## What the dashboard shows

- Pod hostname and IP — refreshes every 10s, shows load balancing across 2 replicas
- CPU, memory, disk usage with live progress bars
- Uptime since last deploy
- Infrastructure details (region, K8s version, provisioning tool)
- `/health` and `/api/stats` endpoints for probes and monitoring
