#!/usr/bin/env bash
# deploy-local.sh - local CD: deploy the app to Minikube with Helm.
#
# Usage: DOCKERHUB_USERNAME=<user> ./scripts/deploy-local.sh [production|staging] [image_tag]
#   production -> namespace devops-app,         release devops-app
#   staging    -> namespace devops-app-staging, release devops-app
# image_tag defaults to "latest". CI tags images with the full git commit SHA.

set -euo pipefail

ENVIRONMENT="${1:-production}"
IMAGE_TAG="${2:-latest}"
: "${DOCKERHUB_USERNAME:?Set DOCKERHUB_USERNAME (e.g. export DOCKERHUB_USERNAME=myuser)}"

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CHART="$ROOT/helm/devops-app"

case "$ENVIRONMENT" in
  production) NAMESPACE="devops-app";         EXTRA_VALUES=() ;;
  staging)    NAMESPACE="devops-app-staging"; EXTRA_VALUES=(-f "$CHART/values-staging.yaml") ;;
  *) echo "Unknown environment: $ENVIRONMENT (use production or staging)" >&2; exit 1 ;;
esac

for tool in kubectl helm; do
  command -v "$tool" >/dev/null || { echo "$tool is not installed" >&2; exit 1; }
done

echo ">> Deploying $DOCKERHUB_USERNAME/devops-project:$IMAGE_TAG to namespace $NAMESPACE"

# --force-conflicts: Helm 4 uses server-side apply. If someone ran `kubectl scale`, kubectl owns
# .spec.replicas and the upgrade would fail with a field conflict; this lets Helm take it back.
helm upgrade --install devops-app "$CHART" \
  --namespace "$NAMESPACE" --create-namespace \
  --force-conflicts \
  ${EXTRA_VALUES[@]+"${EXTRA_VALUES[@]}"} \
  --set image.repository="$DOCKERHUB_USERNAME/devops-project" \
  --set image.tag="$IMAGE_TAG" \
  --wait --timeout 120s

kubectl get pods,svc -n "$NAMESPACE"
echo ">> Done. Open the app with: minikube service devops-app-service -n $NAMESPACE --url"
