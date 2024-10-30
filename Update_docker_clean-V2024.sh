#!/bin/bash

check_docker_running() {
    echo "Checking if Docker is running..."
    if ! systemctl is-active --quiet docker; then
        echo "Error: Docker is not running. Please start Docker before running this script."
        exit 1
    fi
    echo "Docker is running."
}

get_docker_root_dir() {
    echo "Fetching Docker root directory..."
    docker_root_dir=$(docker info --format '{{.DockerRootDir}}' 2>/dev/null)
    if [ -z "$docker_root_dir" ]; then
        echo "Error: Unable to determine Docker root directory. Ensure Docker is running."
        exit 1
    fi
    echo "Docker root directory: $docker_root_dir"
}

cleanup_overlay2_layerdb_sha256() {
    get_docker_root_dir
    sha256_dir="${docker_root_dir}/overlay2/layerdb/sha256/"
    echo "Checking for the directory: $sha256_dir"
    if [ -d "$sha256_dir" ]; then
        echo "Directory found. Deleting files inside $sha256_dir..."
        if rm -rf "${sha256_dir}"*; then
            echo "Files inside $sha256_dir deleted."
        else
            echo "Error: Failed to delete files in $sha256_dir"
        fi
    else
        echo "Warning: Directory $sha256_dir does not exist or is not accessible."
    fi
}

cleanup_temp_files() {
    echo "Cleaning up Docker temporary files..."
    rm -rf /var/lib/docker/tmp/*
    echo "Temporary files cleaned."
}

cleanup_logs() {
    echo "Cleaning up Docker logs..."
    find /var/lib/docker/containers/ -name "*-json.log" -exec truncate -s 0 {} \;
    echo "Docker logs truncated."
}

check_disk_usage() {
    echo "Checking disk usage..."
    df -h | grep "/var/lib/docker"
}

cleanup_containers() {
    echo "Cleaning up stopped containers..."
    stopped_containers=$(docker ps -a -q -f status=exited)
    if [ -n "$stopped_containers" ]; then
        if docker rm -f $stopped_containers; then
            echo "Stopped containers removed."
        else
            echo "Error: Failed to remove stopped containers."
        fi
    else
        echo "No stopped containers to remove."
    fi
}

cleanup_images() {
    echo "Cleaning up dangling images..."
    dangling_images=$(docker images -f "dangling=true" -q)
    if [ -n "$dangling_images" ]; then
        if docker rmi -f $dangling_images; then
            echo "Dangling images removed."
        else
            echo "Error: Failed to remove dangling images."
        fi
    else
        echo "No dangling images to remove."
    fi
}

cleanup_unused_images() {
    echo "Cleaning up unused images..."
    if docker image prune -a --force; then
        echo "Unused images removed."
    else
        echo "Error: Failed to clean up unused images."
    fi
}

cleanup_volumes() {
    echo "Cleaning up unused volumes..."
    if docker volume prune --force; then
        echo "Unused volumes removed."
    else
        echo "Error: Failed to clean up unused volumes."
    fi
}

cleanup_networks() {
    echo "Cleaning up unused networks..."
    if docker network prune --force; then
        echo "Unused networks removed."
    else
        echo "Error: Failed to clean up unused networks."
    fi
}

cleanup_build_cache() {
    echo "Cleaning up build cache..."
    if docker builder prune --force; then
        echo "Build cache removed."
    else
        echo "Error: Failed to clean up build cache."
    fi
}

cleanup_buildx_cache() {
    echo "Cleaning up Buildx cache..."
    if docker buildx prune --force; then
        echo "Buildx cache removed."
    else
        echo "Error: Failed to clean up Buildx cache."
    fi
}

# Main script execution with fault tolerance and logging
echo "Non-Interactive Docker Cleanup Script"
echo "Starting cleanup of Docker resources..."

check_disk_usage
check_docker_running

cleanup_containers
cleanup_images
cleanup_unused_images
cleanup_volumes
cleanup_networks
cleanup_build_cache
cleanup_buildx_cache
cleanup_logs
cleanup_temp_files

# Cleanup the overlay2 layerdb/sha256 directory
cleanup_overlay2_layerdb_sha256

check_disk_usage

echo "Docker cleanup completed."
