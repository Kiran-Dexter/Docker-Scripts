#!/bin/bash

# Docker image to pull
DOCKER_IMAGE=$1  # Pass the Docker image as a script argument (e.g., ubuntu:latest)

# Function to list and select the network interface
select_interface() {
    # List all available network interfaces
    echo "Available network interfaces:"
    interfaces=$(ip -o link show | awk -F': ' '{print $2}')
    
    select INTERFACE in $interfaces; do
        if [[ -n "$INTERFACE" ]]; then
            echo "Selected interface: $INTERFACE"
            break
        else
            echo "Invalid selection. Please select a valid interface."
        fi
    done
}

# Function to monitor network bandwidth using ifstat
monitor_bandwidth() {
    echo "Monitoring network bandwidth on interface $INTERFACE during the Docker pull..."
    echo "=========================================="
    # Run ifstat while the Docker pull is still running
    while kill -0 $DOCKER_PID 2> /dev/null; do
        ifstat -i $INTERFACE 1 1
    done
    echo "=========================================="
}

# Check if the Docker image argument is provided
if [ -z "$DOCKER_IMAGE" ]; then
    echo "Usage: ./docker_bandwidth_monitor.sh <docker_image>"
    exit 1
fi

# Select the network interface interactively
select_interface

# Pull Docker image in the background
echo "Pulling Docker image: $DOCKER_IMAGE"
docker pull $DOCKER_IMAGE &

# Get the Docker pull process ID (PID)
DOCKER_PID=$!

# Start monitoring the network interface during the Docker pull
monitor_bandwidth

# Wait for Docker pull to complete
wait $DOCKER_PID

# Confirmation message
if [ $? -eq 0 ]; then
    echo "✅ Docker image $DOCKER_IMAGE pulled successfully."
else
    echo "❌ Failed to pull Docker image $DOCKER_IMAGE."
fi
