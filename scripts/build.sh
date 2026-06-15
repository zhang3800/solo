#!/bin/bash
export JAVA_HOME=/usr/local/jdk_1.8   # 请确认路径
export PATH=$JAVA_HOME/bin:$PATH
set -e

echo "========== Maven Build Start =========="

rm -rf target

# 确保 MVN_CMD 存在
if [ -z "$MVN_CMD" ]; then
  echo "❌ MVN_CMD 未定义"
  exit 1
fi

echo "使用命令: $MVN_CMD"
$MVN_CMD

# 查找 jar（兼容多模块）
JAR_FILE=$(find . -type f -name "*.jar" | grep target | head -n 1)

if [ -z "$JAR_FILE" ]; then
  echo "❌ 没有生成 jar 包"
  find . -name "*.jar"
  exit 1
fi

echo "✅ Build Success: $JAR_FILE"
export JAR_FILE
