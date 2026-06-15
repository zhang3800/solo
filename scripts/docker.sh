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

EXT=${PRODUCT_FILE##*.}
cp "$PRODUCT_FILE" "app.${EXT}"

# 根据后缀生成 Dockerfile
if [ "$EXT" = "jar" ]; then
    cat > Dockerfile <<EOF
FROM 192.168.10.14/jdk/jdk:jdk1.8.0_192
WORKDIR /app
COPY app.jar app.jar
ENTRYPOINT ["java", "-jar", "/app/app.jar"]
EOF
elif [ "$EXT" = "war" ]; then
    # 使用 Tomcat 9 + JDK 8 镜像（可改为你的私有 Tomcat 镜像）
    cat > Dockerfile <<EOF
FROM tomcat:9.0-jdk8-openjdk
# 删除默认的 ROOT 应用
RUN rm -rf /usr/local/tomcat/webapps/ROOT
# 将 war 包复制为 ROOT.war（根路径访问）
COPY app.war /usr/local/tomcat/webapps/ROOT.war
EXPOSE 8080
CMD ["catalina.sh", "run"]
EOF
else
    echo "❌ 不支持的文件类型: $EXT"
    exit 1
fi

docker build -t $IMAGE .
docker push $IMAGE

echo "IMAGE=$IMAGE" > image.env
echo "TAG=$TAG" >> image.env
echo "✅ Docker Build Done"
