 #!/bin/bash


if [ "$#" -eq  "0" ]; then
  echo "No arguments supplied. Please enter namespace to install Thanos"
  exit 1
fi

NAMESPACE=$1

echo "Installing Thanos to ${NAMESPACE} namespace"

kubectl -n ${NAMESPACE} create secret generic thanos-objectstorage --from-file=thanos-s3.yaml
kubectl -n ${NAMESPACE} label secrets thanos-objectstorage part-of=thanos

kubectl -n ${NAMESPACE} apply -f thanos-receiver-hashring-configmap-base.yaml
kubectl -n ${NAMESPACE} apply -f thanos-receive-controller.yaml

kubectl -n ${NAMESPACE} apply -f thanos-receive-default.yaml
kubectl -n ${NAMESPACE} apply -f thanos-receive-service.yaml

kubectl -n ${NAMESPACE} apply -f thanos-store-shard-0.yaml

kubectl -n ${NAMESPACE} apply -f thanos-query.yaml

