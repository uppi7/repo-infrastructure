#!/usr/bin/env bash
# repo-infrastructure/build-all.sh
#
# 使用方式：
#   ./build-all.sh             # 启动（构建方式由 .env 中 BUILD_MODE 决定）
#   ./build-all.sh --down      # 停止并清理

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PARENT_DIR="$(dirname "$SCRIPT_DIR")"
INFRA_DIR="$SCRIPT_DIR"

# ---- 停止模式 ----
if [[ "${1:-}" == "--down" ]]; then
    cd "$INFRA_DIR"
    docker compose down -v
    exit 0
fi

# ---- 读取 .env ----
if [[ ! -f "$INFRA_DIR/.env" ]]; then
    echo "错误：.env 不存在，请先执行 cp .env.example .env 并填写配置"
    exit 1
fi
set -a; source "$INFRA_DIR/.env"; set +a

BUILD_MODE="${BUILD_MODE:-local}"
REGISTRY="${REGISTRY:-ghcr.io/uppi7}"

echo "=================================================="
echo " BUILD_MODE=${BUILD_MODE}"
echo "=================================================="
echo ""

if [[ "$BUILD_MODE" == "local" ]]; then
    # ---- 本地构建四个子系统镜像 ----
    G1_DIR="$PARENT_DIR/repo-group1-base"
    G2_DIR="$PARENT_DIR/repo-group2-course"

    echo "[1/4] 构建 zjuse-backend-base ..."
    docker build -t zjuse-backend-base:latest "$G1_DIR/backend"

    echo "[2/4] 构建 zjuse-frontend-base ..."
    docker build -t zjuse-frontend-base:latest "$G1_DIR/frontend"
    docker run --rm zjuse-frontend-base:latest ls /dist

    echo "[3/4] 构建 zjuse-backend-course ..."
    docker build -t zjuse-backend-course:latest "$G2_DIR/backend"

    echo "[4/4] 构建 zjuse-frontend-course ..."
    docker build -t zjuse-frontend-course:latest "$G2_DIR/frontend"
    docker run --rm zjuse-frontend-course:latest ls /dist

    export IMAGE_PREFIX=""

elif [[ "$BUILD_MODE" == "registry" ]]; then
    echo "从 ${REGISTRY} 拉取镜像..."
    export IMAGE_PREFIX="${REGISTRY}/"

else
    echo "错误：BUILD_MODE 只能是 local 或 registry，当前值为 '${BUILD_MODE}'"
    exit 1
fi

# ---- 启动大盘 ----
cd "$INFRA_DIR"
docker compose up --build -d

echo ""
echo "等待服务就绪..."
for i in $(seq 1 30); do
    gw=$(curl -sf http://localhost:8080/health > /dev/null 2>&1 && echo ok || echo -)
    b1=$(curl -sf http://localhost:8080/api/base/health > /dev/null 2>&1 && echo ok || echo -)
    b2=$(curl -sf http://localhost:8080/api/course/health > /dev/null 2>&1 && echo ok || echo -)
    if [[ $gw == ok && $b1 == ok && $b2 == ok ]]; then
        echo ">>> 全部服务就绪！"
        break
    fi
    echo "  ($i/30)  gateway=$gw  backend-base=$b1  backend-course=$b2"
    sleep 3
done

echo ""
echo "=================================================="
echo " 验收测试"
echo "=================================================="

pass=0; fail=0
check() {
    if eval "$2" > /dev/null 2>&1; then
        echo "  PASS  $1"; ((pass++)) || true
    else
        echo "  FAIL  $1"; ((fail++)) || true
    fi
}

check "健康检查"                    "curl -sf http://localhost:8080/health"
check "group1 前端 /base/"         "curl -sf http://localhost:8080/base/"
check "group2 前端 /course/"       "curl -sf http://localhost:8080/course/"
check "group1 API: 查询教师 1001"  "curl -sf http://localhost:8080/api/base/teacher/1001"
check "group2 API: 排课（东西向）" "curl -sf http://localhost:8080/api/course/schedule/1001"

echo ""
echo "结果：$pass PASSED, $fail FAILED"
if [[ $fail -eq 0 ]]; then
    echo ""
    echo "  group1: http://localhost:8080/base/"
    echo "  group2: http://localhost:8080/course/"
else
    echo "  docker compose logs --tail=50"
fi
