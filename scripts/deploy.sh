#!/bin/bash
set -e

source image.env

echo "========== Deploy To Rancher =========="

rancherRedeploy \
  alwaysPull: true \
  credential: 'rke6' \
  images: "${IMAGE}" \
  workload: "/project/c-m-9nkxs2hn/workload/deployment:solo-dev:solo"

echo "✅ Deploy Success"
