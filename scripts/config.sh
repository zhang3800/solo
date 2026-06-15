#!/bin/bash

export APP_NAME="soloapp"
export PROJECT="solo"
export HARBOR="192.168.10.14/solo"
export IMAGE_REPO="${HARBOR}/dev/${APP_NAME}"

export MVN_CMD="mvn clean install -Dmaven.test.skip=true -U"

#定义k8s创建
export DEPLOY_NAMESPACE="solo-dev"
export DEPLOY_NAME="solo"
export CONTAINER_NAME="solo"
export ENABLE_SERVICE="true"
export SERVICE_TYPE="NodePort"
