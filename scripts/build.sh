#!/bin/bash
# This script is used to build local images
# including:
# nginx(gateway)
# backend_base
# backend_course

# build
echo "Building images..."
# docker pull mysql:8.0
docker build -t backend_base:latest $BACKEND_BASE 
docker build -t backend_course:latest $BACKEND_COURSE
docker build -t frontend_base:latest $FRONTEND_BASE 
docker build -t frontend_course:latest $FRONTEND_COURSE
docker build --build-arg IMAGE_PREFIX=$IMAGE_PREFIX -t gateway:latest $GATEWAY

echo "Done!"
