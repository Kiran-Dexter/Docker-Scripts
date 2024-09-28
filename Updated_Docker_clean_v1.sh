#!/bin/bash
cleanup_containers() {
    echo "Cleaning up stopped containers..."
    stopped_containers=$(docker ps -a -q -f status=exited)
    if [ -n "$stopped_containers" ]; then
        docker rm -f $stopped_containers
        echo "Stopped containers removed."
    else
        echo "No stopped containers to remove."
    fi
}
cleanup_images() {
    echo "Cleaning up dangling images..."
    dangling_images=$(docker images -f "dangling=true" -q)
    if [ -n "$dangling_images" ]; then
        docker rmi -f $dangling_images
        echo "Dangling images removed."
    else
        echo "No dangling images to remove."
    fi
}
cleanup_unused_images() {
    echo "Cleaning up unused images..."
    docker image prune -a --force
    echo "Unused images removed."
}
cleanup_volumes() {
    echo "Cleaning up unused volumes..."
    docker volume prune --force
    echo "Unused volumes removed."
}
cleanup_networks() {
    echo "Cleaning up unused networks..."
    docker network prune --force
    echo "Unused networks removed."
}
cleanup_build_cache() {
    echo "Cleaning up build cache..."
    docker builder prune --force
    echo "Build cache removed."
}
cleanup_everything() {
    echo "Cleaning up all unused Docker resources..."
    docker system prune -a --volumes --force
    echo "All unused Docker resources removed."
}
echo "Non-Interactive Docker Cleanup Script"
echo "Starting cleanup of Docker resources..."
cleanup_containers
cleanup_images
cleanup_unused_images
cleanup_volumes
cleanup_networks
cleanup_build_cache

echo "Docker cleanup completed."
