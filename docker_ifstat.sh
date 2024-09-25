#!/bin/bash

# Docker image to pull
DOCKER_IMAGE=$1  # Pass the Docker image as a script argument (e.g., ubuntu:latest)
INTERFACE=$2     # Network interface to monitor (e.g., eth0)

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

# Check if the network interface is valid
if ! ip link show | grep "$INTERFACE" > /dev/null; then
    echo "❌ Error: Network interface $INTERFACE does not exist!"
    exit 1
fi

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
