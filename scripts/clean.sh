#!/bin/bash
# This script is used to build local images
# including:
# nginx(gateway)
# backend_base
# backend_course

# clean
echo "Cleaning old containers and images..."
docker stop backend_base backend_course frontend_base frontend_course gateway 2>/dev/null || true
docker rm backend_base backend_course frontend_base frontend_course gateway 2>/dev/null || true
docker rmi backend_base:latest backend_course:latest frontend_base:latest frontend_course:latest gateway:latest 2>/dev/null || true

echo "Done!"
