#!/bin/bash
echo ${GOOGLE_AUTH} | base64 -d > ${HOME}/gcp-key.json
gcloud auth activate-service-account --key-file ${HOME}/gcp-key.json
gcloud config set project circle-agent
gcloud container clusters get-credentials circlecicluster --zone us-central1-a --project circle-agent

echo 'kubectl config view'
kubectl config view

echo 'kubectl proxy '
kubectl proxy --port=8080 &

echo 'curling now...'
curl http://localhost:8080/api/v1
