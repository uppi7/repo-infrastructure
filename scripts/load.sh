# This script is used to load image into
# dind

# 加载 MySQL 镜像
docker save mysql:8.0 | docker exec -i swarm-manager docker load
docker save mysql:8.0 | docker exec -i swarm-worker1 docker load
docker save mysql:8.0 | docker exec -i swarm-worker2 docker load

# 加载 backend_base 镜像
docker save backend_base:latest | docker exec -i swarm-manager docker load
docker save backend_base:latest | docker exec -i swarm-worker1 docker load
docker save backend_base:latest | docker exec -i swarm-worker2 docker load

# 加载 backend_course 镜像
docker save backend_course:latest | docker exec -i swarm-manager docker load
docker save backend_course:latest | docker exec -i swarm-worker1 docker load
docker save backend_course:latest | docker exec -i swarm-worker2 docker load

# 加载 gateway 镜像
docker save gateway:latest | docker exec -i swarm-manager docker load
docker save gateway:latest | docker exec -i swarm-worker1 docker load
docker save gateway:latest | docker exec -i swarm-worker2 docker load