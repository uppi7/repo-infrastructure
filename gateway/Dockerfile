# 通过 COPY --from 语法，从各子系统前端镜像拉取编译产物

FROM nginx:1.27-alpine

# 移除默认配置
RUN rm /etc/nginx/conf.d/default.conf

# 注入大盘 Nginx 路由配置
COPY nginx.conf /etc/nginx/nginx.conf

# 从 group1 前端镜像拉取 dist，放到 /base/ 子路径
# 镜像 tag 在 CI/CD 或 docker-compose build 时通过 --build-arg 注入，此处用 latest 演示
COPY --from=zjuse-frontend-base:latest   /dist /usr/share/nginx/html/base

# 从 group2 前端镜像拉取 dist，放到 /course/ 子路径
COPY --from=zjuse-frontend-course:latest /dist /usr/share/nginx/html/course

EXPOSE 80
