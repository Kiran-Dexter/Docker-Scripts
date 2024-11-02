#!/bin/bash

# Function to log messages with timestamps
log() {
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $1"
}

# Function to retrieve Docker root directory dynamically
get_docker_root_dir() {
    log "Fetching Docker root directory..."
    docker_root_dir=$(docker info --format '{{.DockerRootDir}}' 2>/dev/null)
    if [ -z "$docker_root_dir" ]; then
        log "Error: Unable to determine Docker root directory. Ensure Docker is running."
        exit 1
    fi
    log "Docker root directory: $docker_root_dir"
}

# Function to check if Docker is running
check_docker_running() {
    log "Checking if Docker is running..."
    if ! systemctl is-active --quiet docker; then
        log "Error: Docker is not running. Please start Docker before running this script."
        exit 1
    fi
    log "Docker is running."
}

# Function to stop Docker-related services with a retry mechanism
stop_docker_services() {
    log "Attempting to stop Docker and containerd services..."
    if ! systemctl stop docker docker.socket containerd; then
        log "Warning: Failed to stop services, retrying..."
        sleep 3
        systemctl stop docker docker.socket containerd || { log "Error: Failed to stop services after retry"; exit 1; }
    fi
    log "Docker and containerd services stopped successfully."
}

# Function to start Docker service only
start_docker_service() {
    log "Attempting to start Docker service..."
    if ! systemctl start docker; then
        log "Warning: Failed to start Docker service, retrying..."
        sleep 3
        systemctl start docker || { log "Error: Failed to start Docker service after retry"; exit 1; }
    fi
    log "Docker service started successfully."
}

# Function to rename main directories in Docker root
rename_docker_directories() {
    get_docker_root_dir
    current_date=$(date +"%d%m%Y")

    # List of key directories to rename
    directories=("image" "volumes" "containers" "overlay2" "runtimes")

    log "Renaming Docker directories..."
    for dir in "${directories[@]}"; do
        dir_path="${docker_root_dir}/${dir}"
        backup_dir="${docker_root_dir}/${dir}_${current_date}"

        if [ -d "$dir_path" ]; then
            log "Renaming $dir_path to $backup_dir..."
            if mv "$dir_path" "$backup_dir"; then
                log "Directory $dir_path renamed to $backup_dir."
            else
                log "Error: Failed to rename $dir_path."
            fi
        else
            log "Warning: Directory $dir_path not found, skipping rename."
        fi
    done
}

# Function to perform Docker cleanup tasks
docker_cleanup() {
    log "Cleaning up unused networks..."
    if docker network prune --force; then
        log "Unused networks removed."
    else
        log "Error: Failed to clean up unused networks."
    fi

    log "Cleaning up Buildx cache..."
    if docker buildx prune --force; then
        log "Buildx cache removed."
    else
        log "Error: Failed to clean up Buildx cache."
    fi
}

# Function to delete renamed directories safely
cleanup_renamed_directories() {
    get_docker_root_dir
    current_date=$(date +"%d%m%Y")

    log "Removing renamed Docker directories from ${current_date}..."
    for dir in "image" "volumes" "containers" "overlay2" "runtimes"; do
        backup_dir="${docker_root_dir}/${dir}_${current_date}"
        
        if [ -d "$backup_dir" ]; then
            log "Deleting $backup_dir..."
            if rm -rf "$backup_dir"; then
                log "Directory $backup_dir deleted successfully."
            else
                log "Error: Failed to delete $backup_dir."
            fi
        else
            log "No backup directory $backup_dir found; skipping."
        fi
    done
}

# Main script execution
log "Non-Interactive Docker Directory Rename Script Starting..."
check_docker_running

# Stop Docker-related services
stop_docker_services

# Rename key Docker directories
rename_docker_directories

# Start Docker service only (no docker.socket)
start_docker_service

# Perform Docker cleanup tasks
docker_cleanup

# Display Docker disk usage summary
log "Displaying Docker disk usage summary..."
docker system df -v

# Clean up renamed directories
cleanup_renamed_directories

log "Docker directory renaming, cleanup, and final cleanup of backups completed."
