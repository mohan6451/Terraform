import os
import socket
import platform
import psutil
import datetime
from flask import Flask, jsonify, render_template

app = Flask(__name__)

START_TIME = datetime.datetime.utcnow()

def get_stats():
    uptime = datetime.datetime.utcnow() - START_TIME
    hours, remainder = divmod(int(uptime.total_seconds()), 3600)
    minutes, seconds = divmod(remainder, 60)

    return {
        "app": {
            "name": "Mohan's DevOps Portfolio",
            "version": "1.0.0",
            "environment": os.getenv("APP_ENV", "dev"),
            "uptime": f"{hours}h {minutes}m {seconds}s",
        },
        "pod": {
            "hostname": socket.gethostname(),
            "ip": socket.gethostbyname(socket.gethostname()),
            "node": os.getenv("NODE_NAME", "unknown"),
            "namespace": os.getenv("POD_NAMESPACE", "default"),
        },
        "cluster": {
            "k8s_version": os.getenv("K8S_VERSION", "K3s v1.28"),
            "region": os.getenv("AWS_REGION", "ap-south-1"),
            "infra": "Terraform + GitHub Actions",
        },
        "system": {
            "cpu_percent": psutil.cpu_percent(interval=0.5),
            "memory_used_mb": round(psutil.virtual_memory().used / 1024 / 1024, 1),
            "memory_total_mb": round(psutil.virtual_memory().total / 1024 / 1024, 1),
            "memory_percent": psutil.virtual_memory().percent,
            "disk_percent": psutil.disk_usage("/").percent,
            "python_version": platform.python_version(),
        },
    }

@app.route("/")
def index():
    return render_template("index.html", stats=get_stats())

@app.route("/health")
def health():
    return jsonify({"status": "healthy", "timestamp": datetime.datetime.utcnow().isoformat()})

@app.route("/api/stats")
def api_stats():
    return jsonify(get_stats())

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=5000, debug=False)
