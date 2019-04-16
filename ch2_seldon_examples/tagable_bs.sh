#!/usr/bin/env bash
#tag::createTrainingWorkflow[]
cd $EXAMPLE_SELDON/workflows
argo submit training-sk-mnist-workflow.yaml -n kubeflow
#end::createTrainingWorkflow[]
#tag::cliTrainingCheck[]
kubectl get pods -n kubeflow | grep sk-train
#Should yeild something like this:
#kubeflow-sk-train-wnbgj-1046465934                        0/1     Completed   0          5m11s
#sk-train-kmpcr                                            0/1     Completed   0          4m31s
#
# Or
argo list -n kubeflow
# Should yield something like:
# kubeflow-sk-train-wnbgj   Succeeded   18h   4m
#
#end::cliTrainingCheck[]
#tag::getAmbassadorPort[]
kubectl get svc -n kubeflow | grep "ambassador "
# Should yield:
# ambassador                                           NodePort    10.152.183.112   <none>        80:30134/TCP
#end::getAmbassadorPort[]
#tag::submitSeldon[]
argo submit serving-sk-mnist-workflow.yaml -n kubeflow -p deploy-model=true
#end::submitSeldon[]
#tag::loadTest[]
kubectl label nodes $(kubectl get nodes -o jsonpath='{.items[0].metadata.name}') role=locust
helm install seldon-core-loadtesting --name loadtest  \
    --namespace kubeflow \
    --repo https://storage.googleapis.com/seldon-charts \
    --set locust.script=mnist_rest_locust.py \
    --set locust.host=http://mnist-classifier:8000 \
    --set oauth.enabled=false \
    --set oauth.key=oauth-key \
    --set oauth.secret=oauth-secret \
    --set locust.hatchRate=1 \
    --set locust.clients=1 \
    --set loadtest.sendFeedback=1 \
    --set locust.minWait=0 \
    --set locust.maxWait=0 \
    --set replicaCount=1 \
    --set data.size=784
#end::loadTest[]
