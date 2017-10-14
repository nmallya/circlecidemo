#!/bin/bash

echo "Reached the smoketest automation section"

echo "This script will do the following:"
echo "1: Deploy the latest container image to a cyan deployment"
echo "2: Smoketest will ALWAYS point to cyan"
echo "3: It will also check the current production deployment color AND deploy the image to the OTHER color blue<->green"

echo ${PRODUCTION_ACCT_AUTH} | base64 -d > ${HOME}/gcp-key.json
gcloud auth activate-service-account --key-file ${HOME}/gcp-key.json
gcloud config set project s4-core-prod
gcloud container clusters get-credentials sema4-production-cluster --zone us-central1-b --project s4-core-prod

kubectl set image deployment db-updater db-updater=gcr.io/s4-core-prod/sema4app:$CIRCLE_SHA1 --record

# IMPORTANT: uncomment this ONLY if there are new secrets to be added
# FIRST ENSURE THAT app-secrets-production-no-workers.yml has the latest base64 encoded secrets
# and that they are also declared in the web-deployment-production-*.yml files
# echo 'Updating secrets'
# kubectl delete secret app-secrets
# kubectl create -f "${PWD}/kube/staging/secrets/app-secrets-production.yml"
# echo 'Secrets updated'


echo 'Updating web-worker with the latest version'
kubectl set image deployment web-worker web-worker=gcr.io/s4-core-prod/sema4app:$CIRCLE_SHA1 --record
kubectl rollout status deployment web-worker


# ALWAYS deploy to cyan
echo 'Updating web deployment image'
echo "Pushing image: web=gcr.io/s4-core-prod/sema4app:$CIRCLE_SHA1"
kubectl set image deployment webserver-no-worker-cyan web=gcr.io/s4-core-prod/sema4app:$CIRCLE_SHA1 --record
kubectl rollout status deployment webserver-no-worker-cyan
echo 'Web deployment image updated'

echo 'Invoking kubectl describe...'
kubectl describe service webserver-production > webserver.txt

# Alternate between blue and green deployments.
# ONLY switch webserver-production to this color AFTER SMOKETEST looks good
if grep -q 'color=blue' webserver.txt;
then
	echo "Current deployment is blue"
	echo "Switching to green deployment"
	kubectl set image deployment webserver-no-worker-green web=gcr.io/s4-core-prod/sema4app:$CIRCLE_SHA1 --record
	kubectl rollout status deployment webserver-no-worker-green
	echo "Deployed gcr.io/s4-core-prod/sema4app:$CIRCLE_SHA1 to a green deployment"
else
	echo "Current deployment is green"
	echo "Switching to blue deployment"
	kubectl set image deployment webserver-no-worker-blue web=gcr.io/s4-core-prod/sema4app:$CIRCLE_SHA1 --record
	kubectl rollout status deployment webserver-no-worker-blue
	echo "Deployed gcr.io/s4-core-prod/sema4app:$CIRCLE_SHA1 to a blue deployment"
fi


echo "Completed smoketest deployment."

echo "Pub/Sub Consumer sanity checks ----------- BEGIN"
echo "Sending invalid PWN approval notification"
curl "https://smoketest.sema4genomics.com/api/pwn/notifications?id=345345345&status=approved&token=2a15eaf6f46cfa9bb6b938cd8d624a0d18b95e6f2f13d522a18c00ae161255da" -k
echo "Running invalid PWN rejection notification"
curl "https://smoketest.sema4genomics.com/api/pwn/notifications?id=345345345&status=rejected&token=2a15eaf6f46cfa9bb6b938cd8d624a0d18b95e6f2f13d522a18c00ae161255da" -k
echo "Pub/Sub Consumer sanity checks ----------- END"
