#!/usr/bin/env bash
# repo-infrastructure/build-all.sh
#
# 【本地验证脚本】
# 假设三个仓库在同一父目录下，目录名为 repo-group1-base 和 repo-group2-course
#
# 使用方式：
#   chmod +x build-all.sh
#   ./build-all.sh             # 构建 + 启动
#   ./build-all.sh --down      # 停止并清理

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PARENT_DIR="$(dirname "$SCRIPT_DIR")"

G1_DIR="$PARENT_DIR/repo-group1-base"
G2_DIR="$PARENT_DIR/repo-group2-course"
INFRA_DIR="$SCRIPT_DIR"

# ---- 停止模式 ----
if [[ "${1:-}" == "--down" ]]; then
    echo ">>> 停止并清理大盘环境..."
    cd "$INFRA_DIR"
    docker compose down -v
    echo ">>> 完成"
    exit 0
fi

echo "=================================================="
echo " 大盘本地全量构建脚本"
echo "=================================================="
echo ""

# ---- Step 1: 构建 group1 后端镜像 ----
echo "[1/5] 构建 zjuse-backend-base:latest ..."
docker build -t zjuse-backend-base:latest "$G1_DIR/backend"
echo "      OK"

# ---- Step 2: 构建 group1 前端镜像 ----
echo "[2/5] 构建 zjuse-frontend-base:latest（多阶段，含 npm build）..."
docker build -t zjuse-frontend-base:latest "$G1_DIR/frontend"
echo "      OK"
echo "      dist 内容："
docker run --rm zjuse-frontend-base:latest ls /dist

# ---- Step 3: 构建 group2 后端镜像 ----
echo "[3/5] 构建 zjuse-backend-course:latest ..."
docker build -t zjuse-backend-course:latest "$G2_DIR/backend"
echo "      OK"

# ---- Step 4: 构建 group2 前端镜像 ----
echo "[4/5] 构建 zjuse-frontend-course:latest（多阶段，含 npm build）..."
docker build -t zjuse-frontend-course:latest "$G2_DIR/frontend"
echo "      OK"
echo "      dist 内容："
docker run --rm zjuse-frontend-course:latest ls /dist

# ---- Step 5: 构建 gateway 并启动大盘 ----
echo "[5/5] 构建 gateway 镜像并启动全部服务..."
cd "$INFRA_DIR"

# 确保 .env 存在
if [[ ! -f ".env" ]]; then
    echo "错误：$INFRA_DIR/.env 不存在！"
    echo "请先创建 .env 文件（参考 MANUAL_VERIFICATION.md）"
    exit 1
fi

docker compose up --build -d

echo ""
echo "=================================================="
echo " 等待服务就绪（最多 60s）..."
echo "=================================================="

# 等待三层全部就绪：gateway + 两个后端（后端就绪意味着 MySQL 也已初始化完成）
for i in $(seq 1 30); do
    gw=$(curl -sf http://localhost:8080/health > /dev/null 2>&1 && echo ok || echo -)
    b1=$(curl -sf http://localhost:8080/api/base/health > /dev/null 2>&1 && echo ok || echo -)
    b2=$(curl -sf http://localhost:8080/api/course/health > /dev/null 2>&1 && echo ok || echo -)
    if [[ $gw == ok && $b1 == ok && $b2 == ok ]]; then
        echo ">>> 全部服务就绪！"
        break
    fi
    echo "  等待中... ($i/30)  gateway=$gw  backend-base=$b1  backend-course=$b2"
    sleep 3
done

echo ""
echo "=================================================="
echo " 自动验收测试"
echo "=================================================="

pass=0
fail=0

check() {
    local desc="$1"
    local cmd="$2"
    if eval "$cmd" > /dev/null 2>&1; then
        echo "  PASS  $desc"
        ((pass++)) || true
    else
        echo "  FAIL  $desc"
        ((fail++)) || true
    fi
}

check "健康检查 /health"                       "curl -sf http://localhost:8080/health"
check "group1 前端可访问 /base/"               "curl -sf http://localhost:8080/base/"
check "group2 前端可访问 /course/"             "curl -sf http://localhost:8080/course/"
check "group1 API: 查询教师 1001"              "curl -sf http://localhost:8080/api/base/teacher/1001"
check "group2 API: 排课（含东西向调用）"        "curl -sf http://localhost:8080/api/course/schedule/1001"

echo ""
echo "结果：$pass PASSED, $fail FAILED"
echo ""
if [[ $fail -eq 0 ]]; then
    echo ">>> 全部通过！访问："
    echo "    group1 前端：http://localhost:8080/base/"
    echo "    group2 前端：http://localhost:8080/course/"
else
    echo ">>> 有失败项，查看日志："
    echo "    docker compose logs --tail=50"
fi
