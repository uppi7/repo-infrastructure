# 基建仓库（infrastructure）

大组维护的合并部署仓库。本仓库不含任何业务源码，通过镜像名引用各子组的 CI 产出，用 Nginx 网关将它们统一对外暴露。

## 运行时拓扑

```
浏览器 :8080
    │
    ▼
  Nginx (gateway)
    ├── /base/*         静态文件（来自 zjuse-frontend-base 镜像）
    ├── /course/*       静态文件（来自 zjuse-frontend-course 镜像）
    ├── /api/base/*  → backend-base:8081
    └── /api/course/* → backend-course:8082
                              │
                              │ api调用（Docker 内网直连）
                              ▼
                        backend-base:8081

    backend-base, backend-course → mysql:3306
                                    ├── db_base
                                    └── db_course
```

南北向流量（浏览器 → 后端）经过 Nginx；东西向流量（后端 → 后端）走 Docker 内网。

---

## 部署流程

### 前置：确认子组镜像已就绪

```bash
docker pull ghcr.io/uppi7/zjuse-backend-base:latest
docker pull ghcr.io/uppi7/zjuse-frontend-base:latest
docker pull ghcr.io/uppi7/zjuse-backend-course:latest
docker pull ghcr.io/uppi7/zjuse-frontend-course:latest
```

如果镜像仓库需要认证，先登录：

```bash
echo "<github-token>" | docker login ghcr.io -u <username> --password-stdin
```

### 1. 克隆本仓库

```bash
git clone git@github.com:uppi7/repo-infrastructure.git
cd repo-infrastructure
```

### 2. 创建 `.env`

```bash
cp .env.example .env
```

### 3. 更新镜像引用

将 `docker-compose.yml` 中的镜像名改为 ghcr.io 路径：

```bash
sed -i \
  -e 's|image: zjuse-backend-base:latest|image: ghcr.io/uppi7/zjuse-backend-base:latest|' \
  -e 's|image: zjuse-backend-course:latest|image: ghcr.io/uppi7/zjuse-backend-course:latest|' \
  docker-compose.yml
```

### 4. 启动全部服务

```bash
docker compose up --build -d
```

`--build` 只影响 gateway（本地构建 Nginx 配置），后端镜像直接拉取不重新构建。

gateway 的 Dockerfile 用 `COPY --from` 从两个前端镜像中取出 `/dist`，无需子组源码：

```dockerfile
COPY --from=ghcr.io/uppi7/zjuse-frontend-base:latest   /dist /usr/share/nginx/html/base
COPY --from=ghcr.io/uppi7/zjuse-frontend-course:latest /dist /usr/share/nginx/html/course
```

### 5. 验收测试

```bash
# 等待 MySQL 初始化
curl http://localhost:8080/health

curl http://localhost:8080/api/base/teacher/1001
# 期望：{"id": 1001, "name": "张三"}

curl http://localhost:8080/api/course/schedule/1001
# 期望：{"teacher_name": "张三", "course": "软件工程导论", ...}

curl -I http://localhost:8080/base/
curl -I http://localhost:8080/course/
```

全部通过后，浏览器访问 `http://localhost:8080/base/` 和 `http://localhost:8080/course/`。

---

## 本地构建
```bash
# 要求三个仓库在同一父目录下
./build-all.sh          # 构建全部镜像 + 启动 + 自动验收
./build-all.sh --down   # 停止并清理
```

---

## 问题排查

```bash
# 查看某服务日志
docker compose logs backend-course --tail=50

# 验证东西向连通性
docker compose exec backend-course wget -qO- http://backend-base:8081/api/base/health

# 重置数据库（删除 volume 后 init.sql 会重新执行）
docker compose down -v && docker compose up -d
```

> `init.sql` 只在 MySQL 数据目录为空时执行。如果数据库表结构或测试数据有问题，需要先 `down -v` 清除 volume。

---

## 接入新子系统

当有新的子组（group3 等）加入时，大组需要修改三处：

1. **`docker-compose.yml`**：添加新后端服务，配置 `DB_NAME`、网络等
2. **`gateway/nginx.conf`**：添加新的 `location /api/groupN/` 代理规则和前端静态路径
3. **`gateway/Dockerfile`**：添加 `COPY --from=zjuse-frontend-groupN:latest /dist /usr/share/nginx/html/groupN`
4. **`init.sql`**：添加新逻辑库的建库语句

