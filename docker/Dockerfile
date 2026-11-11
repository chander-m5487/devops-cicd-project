# Build from the repository root:
#   docker build -f docker/Dockerfile -t YOUR_DOCKERHUB_USERNAME/devops-project:latest .

# ---- Stage 1: builder - install dependencies into an isolated prefix ----
FROM python:3.12-slim AS builder
WORKDIR /build
COPY app/requirements.txt .
RUN pip install --no-cache-dir --prefix=/install -r requirements.txt

# ---- Stage 2: runtime - small final image ----
FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

# Working directory inside the container
WORKDIR /app

# Dependencies from the builder stage, then application files
COPY --from=builder /install /usr/local
COPY app/ /app/

# Run as a non-root user
RUN useradd --create-home --uid 1000 appuser
USER appuser

# Document the port the app listens on
EXPOSE 5000

# Startup command (exec form so signals reach gunicorn)
CMD ["gunicorn", "--bind", "0.0.0.0:5000", "--workers", "2", "app:app"]
