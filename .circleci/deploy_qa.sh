#!/bin/bash
echo ${GOOGLE_AUTH} | base64 -d > ${HOME}/gcp-key.json
gcloud auth activate-service-account --key-file ${HOME}/gcp-key.json
gcloud config set project circle-agent
gcloud container clusters get-credentials circlecicluster --zone us-central1-a --project circle-agent



echo 'kubectl proxy '
kubectl proxy --address 0.0.0.0 --accept-hosts '.*' &
sleep 6

echo 'curling now...'
curl http://localhost:8001/api/v1
