#!/bin/bash

echo 'Updating secrets'
kubectl delete secret app-secrets
kubectl create -f "${PWD}/kube/qa/secrets/app-secrets-qa.yml"
echo 'Secrets updated'

echo 'Creating DB migration and seeds task'
kubectl set image deployment db-updater db-updater=gcr.io/s4-core-qa/sema4app:$CIRCLE_SHA1 --record
kubectl rollout status deployment db-updater

echo 'Updating web-worker with the latest version'
kubectl set image deployment web-worker web-worker=gcr.io/s4-core-qa/sema4app:$CIRCLE_SHA1 --record
kubectl rollout status deployment web-worker



echo 'Invoking kubectl describe...'
kubectl describe service webserver > webserver.txt

# Alternate between blue and green deployments
if grep -q 'color=blue' webserver.txt;
then
	echo "Current deployment is blue"
	echo "Switching to green deployment"
	kubectl set image deployment webserver-green web=gcr.io/s4-core-qa/sema4app:$CIRCLE_SHA1 --record
	kubectl rollout status deployment webserver-green
	kubectl patch service webserver --patch "$(cat ${PWD}/kube/qa/service/green-service-patch-file.yml)"
	echo "Switched to green deployment"
else
	echo "Current deployment is green"
	echo "Switching to blue deployment"
	kubectl set image deployment webserver-blue web=gcr.io/s4-core-qa/sema4app:$CIRCLE_SHA1 --record
	kubectl rollout status deployment webserver-blue
	kubectl patch service webserver --patch "$(cat ${PWD}/kube/qa/service/blue-service-patch-file.yml)"
	echo "Switched to blue deployment"
fi
