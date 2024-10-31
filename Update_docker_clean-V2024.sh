#!/bin/bash

log() {
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $1"
}

get_docker_root_dir() {
    log "Fetching Docker root directory..."
    docker_root_dir=$(docker info --format '{{.DockerRootDir}}' 2>/dev/null)
    if [ -z "$docker_root_dir" ]; then
        log "Error: Unable to determine Docker root directory. Ensure Docker is running."
        exit 1
    fi
    log "Docker root directory: $docker_root_dir"
}

check_docker_running() {
    log "Checking if Docker is running..."
    if ! systemctl is-active --quiet docker; then
        log "Error: Docker is not running. Please start Docker before running this script."
        exit 1
    fi
    log "Docker is running."
}

restart_services_with_retry() {
    service=$1
    log "Attempting to stop $service..."
    if ! systemctl stop "$service"; then
        log "Warning: Failed to stop $service, retrying..."
        sleep 3
        systemctl stop "$service" || { log "Error: Failed to stop $service after retry"; exit 1; }
    fi
    sleep 2
    log "$service stopped successfully."

    log "Attempting to start $service..."
    if ! systemctl start "$service"; then
        log "Warning: Failed to start $service, retrying..."
        sleep 3
        systemctl start "$service" || { log "Error: Failed to start $service after retry"; exit 1; }
    fi
    sleep 2
    log "$service started successfully."
}

cleanup_overlay2_layerdb_sha256() {
    get_docker_root_dir
    overlay_dir="${docker_root_dir}/overlay2"
    current_date=$(date +"%d%m%Y")
    backup_dir="${docker_root_dir}/overlay2_${current_date}"

    if [ -d "$overlay_dir" ]; then
        log "Stopping Docker and containerd services before renaming overlay2..."
        restart_services_with_retry docker
        restart_services_with_retry containerd

        log "Renaming overlay2 directory to overlay2_${current_date}..."
        if ! mv "$overlay_dir" "$backup_dir"; then
            log "Error: Failed to rename $overlay_dir. Exiting."
            exit 1
        fi
        log "Directory renamed to $backup_dir."

        log "Cleaning up previous overlay2 backups..."
        find "${docker_root_dir}" -maxdepth 1 -name "overlay2_*" ! -name "overlay2_${current_date}" -exec rm -rf {} \;
        log "Old backups removed."

        log "Starting Docker and containerd services to recreate overlay2 directory..."
        restart_services_with_retry docker
        restart_services_with_retry containerd
    else
        log "Warning: overlay2 directory $overlay_dir not found, skipping rename."
    fi
}

cleanup_containers() {
    log "Cleaning up stopped containers..."
    stopped_containers=$(docker ps -a -q -f status=exited)
    if [ -n "$stopped_containers" ]; then
        if docker rm -f $stopped_containers; then
            log "Stopped containers removed."
        else
            log "Error: Failed to remove stopped containers."
        fi
    else
        log "No stopped containers to remove."
    fi
}

cleanup_images() {
    log "Cleaning up dangling images..."
    dangling_images=$(docker images -f "dangling=true" -q)
    if [ -n "$dangling_images" ]; then
        if docker rmi -f $dangling_images; then
            log "Dangling images removed."
        else
            log "Error: Failed to remove dangling images."
        fi
    else
        log "No dangling images to remove."
    fi
}

cleanup_unused_images() {
    log "Cleaning up unused images..."
    if docker image prune -a --force; then
        log "Unused images removed."
    else
        log "Error: Failed to clean up unused images."
    fi
}

cleanup_volumes() {
    log "Cleaning up unused volumes..."
    if docker volume prune --force; then
        log "Unused volumes removed."
    else
        log "Error: Failed to clean up unused volumes."
    fi
}

cleanup_networks() {
    log "Cleaning up unused networks..."
    if docker network prune --force; then
        log "Unused networks removed."
    else
        log "Error: Failed to clean up unused networks."
    fi
}

cleanup_build_cache() {
    log "Cleaning up build cache..."
    if docker builder prune --force; then
        log "Build cache removed."
    else
        log "Error: Failed to clean up build cache."
    fi
}

cleanup_buildx_cache() {
    log "Cleaning up Buildx cache..."
    if docker buildx prune --force; then
        log "Buildx cache removed."
    else
        log "Error: Failed to clean up Buildx cache."
    fi
}

cleanup_temp_files() {
    get_docker_root_dir
    log "Cleaning up Docker temporary files..."
    rm -rf "${docker_root_dir}/tmp/*"
    log "Temporary files cleaned."
}

cleanup_logs() {
    get_docker_root_dir
    log "Cleaning up Docker logs..."
    find "${docker_root_dir}/containers/" -name "*-json.log" -exec truncate -s 0 {} \;
    log "Docker logs truncated."
}

check_disk_usage() {
    log "Checking disk usage..."
    df -h | grep "$docker_root_dir"
}

pull_ubi8_image() {
    log "Pulling UBI 8 image..."
    if docker pull regi/ubi8/ubi; then
        log "UBI 8 image pulled successfully."
    else
        log "Error: Failed to pull UBI 8 image."
        exit 1
    fi
}

log "Non-Interactive Docker Cleanup Script Starting..."
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

cleanup_overlay2_layerdb_sha256

pull_ubi8_image

log "Final Docker disk usage:"
docker system df -v

log "Docker cleanup and verification completed."
