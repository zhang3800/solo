#!/bin/bash
set -e

echo "========== Maven Build Start =========="

rm -rf target
${MVN_CMD}

JAR_FILE=$(ls target/*.jar | head -n 1)

if [[ ! -f "$JAR_FILE" ]]; then
  echo "❌ JAR构建失败"
  exit 1
fi

echo "✅ Build Success: $JAR_FILE"
export JAR_FILE
