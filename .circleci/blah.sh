#!/bin/bash
gcloud container clusters get-credentials circlecicluster --zone us-central1-a --project circle-agent

# echo 'kubectl config view'
# kubectl config view

echo 'kubectl proxy '
kubectl proxy --address 0.0.0.0 --accept-hosts '.*' &
sleep 6

echo 'curling now...'
curl http://localhost:8001/api/v1
