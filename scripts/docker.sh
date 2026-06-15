#!/bin/bash
set -e

source scripts/config.sh

TAG=${1:-$(date +%Y%m%d-%H%M%S)}
IMAGE="${IMAGE_REPO}:${TAG}"

echo "========== Docker Build =========="
echo "IMAGE: $IMAGE"

cp target/*.jar app.jar

cat > Dockerfile <<EOF
FROM 192.168.10.14/jdk/jdk:jdk1.8.0_192

WORKDIR /app
COPY app.jar app.jar

ENTRYPOINT ["java","-jar","/app/app.jar"]
EOF

docker build -t $IMAGE .
docker push $IMAGE

echo "IMAGE=$IMAGE" > image.env
echo "TAG=$TAG" >> image.env

echo "✅ Docker Build Done"
