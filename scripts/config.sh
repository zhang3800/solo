#!/bin/bash

export APP_NAME="soloapp"
export PROJECT="solo"
export HARBOR="harbor.zrh.com/solo"
export IMAGE_REPO="${HARBOR}/dev/${APP_NAME}"

export MVN_CMD="mvn clean install -DskipTests -U"
