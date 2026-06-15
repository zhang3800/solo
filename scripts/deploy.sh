#!/bin/bash
set -e

# 加载镜像信息（由 docker.sh 生成）
source image.env

# 参数解析
RESOURCE_TYPE=${1:-deployment}      # deployment, statefulset, daemonset
RESOURCE_NAME=${2:-solo}             # 资源名称
NAMESPACE=${3:-solo-dev}             # 命名空间
CONTAINER_NAME=${4:-solo}            # 容器名称
IMAGE=${5:-${IMAGE}}                 # 新镜像（优先使用参数，否则从 image.env 获取）
SERVICE_ENABLE=${6:-false}           # 是否创建/更新 Service: true/false
SERVICE_TYPE=${7:-ClusterIP}         # ClusterIP, NodePort, LoadBalancer
SERVICE_PORT=${8:-8080}              # Service 暴露的端口
TARGET_PORT=${9:-8080}               # 容器端口

echo "========== Deploy To K8s =========="
echo "Resource: ${RESOURCE_TYPE}/${RESOURCE_NAME}"
echo "Namespace: ${NAMESPACE}"
echo "Container: ${CONTAINER_NAME} -> Image: ${IMAGE}"
echo "Service: ${SERVICE_ENABLE} (type=${SERVICE_TYPE}, port=${SERVICE_PORT} -> ${TARGET_PORT})"

# 检查资源是否存在
resource_exists() {
    kubectl get ${RESOURCE_TYPE} -n ${NAMESPACE} ${RESOURCE_NAME} &>/dev/null
}

# 创建资源（根据类型生成 YAML）
create_resource() {
    echo "Creating ${RESOURCE_TYPE}/${RESOURCE_NAME}..."
    local yaml
    case ${RESOURCE_TYPE} in
        deployment)
            yaml=$(cat <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: ${RESOURCE_NAME}
  namespace: ${NAMESPACE}
spec:
  replicas: 1
  selector:
    matchLabels:
      app: ${RESOURCE_NAME}
  template:
    metadata:
      labels:
        app: ${RESOURCE_NAME}
    spec:
      containers:
      - name: ${CONTAINER_NAME}
        image: ${IMAGE}
        ports:
        - containerPort: ${TARGET_PORT}
EOF
)
            ;;
        statefulset)
            yaml=$(cat <<EOF
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: ${RESOURCE_NAME}
  namespace: ${NAMESPACE}
spec:
  replicas: 1
  serviceName: ${RESOURCE_NAME}
  selector:
    matchLabels:
      app: ${RESOURCE_NAME}
  template:
    metadata:
      labels:
        app: ${RESOURCE_NAME}
    spec:
      containers:
      - name: ${CONTAINER_NAME}
        image: ${IMAGE}
        ports:
        - containerPort: ${TARGET_PORT}
EOF
)
            ;;
        daemonset)
            yaml=$(cat <<EOF
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: ${RESOURCE_NAME}
  namespace: ${NAMESPACE}
spec:
  selector:
    matchLabels:
      app: ${RESOURCE_NAME}
  template:
    metadata:
      labels:
        app: ${RESOURCE_NAME}
    spec:
      containers:
      - name: ${CONTAINER_NAME}
        image: ${IMAGE}
        ports:
        - containerPort: ${TARGET_PORT}
EOF
)
            ;;
        *)
            echo "Unsupported resource type: ${RESOURCE_TYPE}"
            exit 1
            ;;
    esac
    echo "$yaml" | kubectl apply -f -
}

# 更新镜像
update_image() {
    echo "Updating image for ${RESOURCE_TYPE}/${RESOURCE_NAME}..."
    kubectl set image ${RESOURCE_TYPE}/${RESOURCE_NAME} ${CONTAINER_NAME}=${IMAGE} -n ${NAMESPACE}
    if [ "${RESOURCE_TYPE}" != "daemonset" ]; then
        kubectl rollout status ${RESOURCE_TYPE}/${RESOURCE_NAME} -n ${NAMESPACE}
    fi
}

# 主逻辑
if resource_exists; then
    update_image
else
    create_resource
fi

# 处理 Service
if [ "${SERVICE_ENABLE}" = "true" ]; then
    SERVICE_NAME=${RESOURCE_NAME}
    if kubectl get service -n ${NAMESPACE} ${SERVICE_NAME} &>/dev/null; then
        echo "Service ${SERVICE_NAME} already exists, checking type..."
        CURRENT_TYPE=$(kubectl get service ${SERVICE_NAME} -n ${NAMESPACE} -o jsonpath='{.spec.type}')
        if [ "${CURRENT_TYPE}" != "${SERVICE_TYPE}" ]; then
            kubectl patch service ${SERVICE_NAME} -n ${NAMESPACE} -p "{\"spec\":{\"type\":\"${SERVICE_TYPE}\"}}"
            echo "Service type updated to ${SERVICE_TYPE}"
        else
            echo "Service type matches, no change."
        fi
        # 端口更新略（需要更复杂逻辑，可后续扩展）
    else
        echo "Creating Service ${SERVICE_NAME}..."
        cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: ${SERVICE_NAME}
  namespace: ${NAMESPACE}
spec:
  type: ${SERVICE_TYPE}
  selector:
    app: ${RESOURCE_NAME}
  ports:
  - port: ${SERVICE_PORT}
    targetPort: ${TARGET_PORT}
EOF
    fi
fi

echo "✅ Deploy Success"
