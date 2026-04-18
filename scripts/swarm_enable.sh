docker network create --driver bridge swarm-net

docker run -d --privileged --name swarm-manager --network swarm-net --hostname swarm-manager -p 8080:8080 docker:dind
docker run -d --privileged --name swarm-worker1 --network swarm-net --hostname swarm-worker1 docker:dind
docker run -d --privileged --name swarm-worker2 --network swarm-net --hostname swarm-worker2 docker:dind

sleep 10

docker exec swarm-manager docker swarm init --advertise-addr eth0

WORKER_TOKEN=$(docker exec swarm-manager docker swarm join-token worker -q)
MANAGER_IP=$(docker inspect -f '{{range.NetworkSettings.Networks}}{{.IPAddress}}{{end}}' swarm-manager)

docker exec swarm-worker1 docker swarm join --token $WORKER_TOKEN $MANAGER_IP:2377
docker exec swarm-worker2 docker swarm join --token $WORKER_TOKEN $MANAGER_IP:2377

docker exec swarm-manager docker node ls
