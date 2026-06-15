#!/bin/bash
set -e

source scripts/config.sh

TAG=${1:-$(date +%Y%m%d-%H%M%S)}
IMAGE="${IMAGE_REPO}:${TAG}"

echo "========== Docker Build =========="
echo "IMAGE: $IMAGE"

# 查找 target 目录下的 jar 或 war 文件（取第一个）
PRODUCT_FILE=$(ls target/*.jar target/*.war 2>/dev/null | head -1)
if [ -z "$PRODUCT_FILE" ]; then
    echo "❌ 未找到 target/*.jar 或 target/*.war 文件"
    exit 1
fi

cp "$PRODUCT_FILE" app.${PRODUCT_FILE##*.}   # 保持原后缀

# 根据后缀决定 Dockerfile
EXT=${PRODUCT_FILE##*.}
cat > Dockerfile <<EOF
FROM 192.168.10.14/jdk/jdk:jdk1.8.0_192
WORKDIR /app
COPY app.${EXT} app.${EXT}
ENTRYPOINT ["java","-jar","/app/app.${EXT}"]
EOF

docker build -t $IMAGE .
docker push $IMAGE

echo "IMAGE=$IMAGE" > image.env
echo "TAG=$TAG" >> image.env
echo "✅ Docker Build Done"
