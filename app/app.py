"""Simple Flask application for the DevOps CI/CD project."""
import os

from flask import Flask, jsonify

app = Flask(__name__)

APP_NAME = "devops-project"
# Optional value injected from a Kubernetes ConfigMap (bonus task).
APP_ENV = os.getenv("APP_ENV", "development")


@app.route("/")
def home():
    return "Hello, Welcome to DevOps CI/CD Project"


@app.route("/health")
def health():
    return jsonify(status="healthy", application=APP_NAME)


if __name__ == "__main__":
    # 0.0.0.0 so the app is reachable from outside the container.
    app.run(host="0.0.0.0", port=5000)
