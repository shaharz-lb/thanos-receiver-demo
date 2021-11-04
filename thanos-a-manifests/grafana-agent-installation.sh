 #!/bin/bash


if [ "$#" -eq  "0" ]; then
  echo "No arguments supplied. Please enter namespace to install Grafana-Agent"
  exit 1
fi

NAMESPACE=$1

echo "Installing Grafana-Agent to ${NAMESPACE} namespace"

kubectl -n ${NAMESPACE} create configmap grafana-agent --from-file=agent.yaml

MANIFEST_URL=https://raw.githubusercontent.com/grafana/agent/main/production/kubernetes/agent-bare.yaml /bin/sh -c "$(curl -fsSL https://raw.githubusercontent.com/grafana/agent/release/production/kubernetes/install-bare.sh)" | kubectl apply -f -


