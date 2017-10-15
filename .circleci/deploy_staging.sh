#!/bin/bash
echo ${GOOGLE_AUTH} | base64 -d > ${HOME}/gcp-key.json
gcloud auth activate-service-account --key-file ${HOME}/gcp-key.json
gcloud config set project circle-agent
gcloud container clusters get-credentials circlecistagingcluster --zone us-central1-a --project circle-agent


echo 'Updating web deployment image'
echo "Pushing image: web=gcr.io/circle-agent/helloworldapp:$CIRCLE_SHA1"
kubectl set image deployment web web=gcr.io/circle-agent/helloworldapp:$CIRCLE_SHA1 --record
kubectl rollout status deployment web
echo 'Web deployment image updated'


# echo 'kubectl proxy '
# kubectl proxy --address 0.0.0.0 --accept-hosts '.*' &
# sleep 6
#
# echo 'curling now...'
# curl http://localhost:8001/api/v1
