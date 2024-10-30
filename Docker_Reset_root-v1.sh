##############################################
#GREAT POWER COMES WITH GREAT RESPONSIBLITY  #
# THINK YOU KNOW DOCKER AND WHAT YOUR RUNNIG #
#THIS SCRIPT WILL DELETE AND RESET THE DOCKER#
#=============================================#
#!/bin/bash

current_date=$(date +"%Y%m%d_%H%M%S")

stop_services() {
    echo "Stopping Docker services..."
    systemctl stop docker.service
    systemctl stop docker.socket
    systemctl stop containerd.service
}

rename_overlay2() {
    docker_root_dir=$(docker info --format '{{.DockerRootDir}}')
    overlay2_dir="${docker_root_dir}/overlay2"
    new_overlay2_dir="${docker_root_dir}/overlay2_${current_date}"

    echo "Renaming overlay2 directory to $new_overlay2_dir..."
    if [ -d "$overlay2_dir" ]; then
        if mv "$overlay2_dir" "$new_overlay2_dir"; then
            echo "Overlay2 directory renamed successfully."
        else
            echo "Error: Failed to rename overlay2 directory."
            exit 1
        fi
    else
        echo "Overlay2 directory not found. Proceeding without renaming."
    fi
}

cleanup_docker_resources() {
    echo "Cleaning up Docker resources..."
    
    rm -rf /var/lib/docker
    rm -rf /etc/docker
    rm -rf /var/run/docker.sock
    rm -rf /var/lib/containerd

    if [ ! -d /var/lib/docker ] && [ ! -d /var/lib/containerd ]; then
        echo "Docker resources and configurations cleaned successfully."
    else
        echo "Warning: Some directories were not cleaned properly."
    fi
}

restart_services() {
    echo "Starting services in sequence..."

    systemctl start containerd.service
    if ! systemctl is-active --quiet containerd.service; then
        echo "Error: Failed to start containerd. Exiting."
        exit 1
    fi

    systemctl start docker.socket
    if ! systemctl is-active --quiet docker.socket; then
        echo "Error: Failed to start docker.socket. Exiting."
        exit 1
    fi

    systemctl start docker.service
    if ! systemctl is-active --quiet docker.service; then
        echo "Error: Docker service failed to start. Exiting."
        exit 1
    fi

    echo "All services started successfully."
}

check_docker_image() {
    echo "Pulling Ubuntu image to validate Docker..."
    retry_count=0
    max_retries=3

    while [ $retry_count -lt $max_retries ]; do
        if docker pull ubuntu; then
            echo "Ubuntu image pulled successfully."
            break
        else
            echo "Error: Failed to pull Ubuntu image. Retrying... ($((retry_count+1))/$max_retries)"
            retry_count=$((retry_count + 1))
            sleep 5
        fi
    done

    if [ $retry_count -eq $max_retries ]; then
        echo "Error: Failed to pull Ubuntu image after $max_retries attempts. Exiting."
        exit 1
    fi
}

check_docker_status() {
    echo "Running docker system df -v to verify clean state..."
    docker system df -v
}

remove_old_overlay2() {
    echo "Removing old overlay2 directory..."
    if rm -rf "$new_overlay2_dir"; then
        echo "Old overlay2 directory removed successfully."
    else
        echo "Error: Failed to remove old overlay2 directory."
    fi
}

echo "Starting complete Docker reset and cleanup process..."

stop_services
rename_overlay2
cleanup_docker_resources
restart_services
check_docker_image
check_docker_status
remove_old_overlay2

echo "Docker reset completed successfully."
