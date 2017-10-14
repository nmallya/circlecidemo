#!/bin/bash


echo ${ACCT_AUTH} | base64 -d > ${HOME}/gcp-key.json
gcloud auth activate-service-account --key-file ${HOME}/gcp-key.json
gcloud config set project s4-core-staging
gcloud container clusters get-credentials sema4-staging-cluster --zone us-central1-b --project s4-core-staging

# kubectl set image job db-updater db-updater=gcr.io/s4-core-staging/sema4app:$CIRCLE_SHA1 --record


echo 'Updating secrets'
kubectl delete secret app-secrets
kubectl create -f "${PWD}/kube/staging/secrets/app-secrets-staging.yml"
echo 'Secrets updated'

echo 'Updating web deployment image'
echo "Pushing image: web=gcr.io/s4-core-staging/sema4app:$CIRCLE_SHA1"
kubectl set image deployment web web=gcr.io/s4-core-staging/sema4app:$CIRCLE_SHA1 --record
kubectl rollout status deployment web
echo 'Web deployment image updated'
