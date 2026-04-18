#!/bin/bash

# source .env

# for local image
export IMAGE_PREFIX=""

cat ${INIT_SQL} | docker exec -i swarm-manager tee /tmp/init.sql

cat ${DOCKER_STACK} | docker exec -i swarm-manager sh -c "
    export MYSQL_ROOT_PASSWORD='$MYSQL_ROOT_PASSWORD'
    export BASE_INFO_API_URL='$BASE_INFO_API_URL'
    export IMAGE_PREFIX='$IMAGE_PREFIX'
    docker stack deploy -c - SSTS-test
"

docker exec swarm-manager docker stack services SSTS-test

echo "Done"
