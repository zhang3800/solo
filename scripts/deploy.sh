#!/bin/bash
set -e

source image.env   # 假设该文件定义了 IMAGE 变量

NAMESPACE="dev"        # 你的命名空间
DEPLOYMENT="solo"           # 你的 Deployment 名称
CONTAINER="solo"            # 容器名称（可能与 deployment 同名）

echo "========== Deploy To K8s =========="
echo "Updating deployment ${DEPLOYMENT} in namespace ${NAMESPACE} with image: ${IMAGE}"

kubectl set image deployment/${DEPLOYMENT} ${CONTAINER}=${IMAGE} -n ${NAMESPACE} --record
kubectl rollout status deployment/${DEPLOYMENT} -n ${NAMESPACE}

echo "✅ Deploy Success"
