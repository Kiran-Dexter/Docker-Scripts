#!/bin/bash

# Docker image to pull
DOCKER_IMAGE=$1
RETRY_LIMIT=5

# Function to retry pulling a Docker image if a layer fails
pull_with_retry() {
    attempt=0
    success=false

    until [ $attempt -ge $RETRY_LIMIT ]; do
        echo "Attempting to pull Docker image: $DOCKER_IMAGE (Attempt $((attempt + 1))/$RETRY_LIMIT)"

        # Start pulling Docker image
        docker pull $DOCKER_IMAGE 2>&1 | tee docker_pull.log | while IFS= read -r line; do
            # Parse layer download progress and size
            if [[ $line == *"Downloading"* || $line == *"Extracting"* || $line == *"Pull complete"* || $line == *"Layer already exists"* ]]; then
                echo "$line"
            fi
        done &

        DOCKER_PID=$!

        # Wait for pull to complete
        wait $DOCKER_PID
        exit_code=$?

        # Check if the Docker pull was successful
        if [ $exit_code -eq 0 ]; then
            echo "✅ Docker image $DOCKER_IMAGE pulled successfully."
            success=true
            break
        else
            echo "❌ Docker pull failed. Checking logs for failed layer."
            attempt=$((attempt + 1))

            # Check logs to determine the failed layer
            failed_layer=$(grep -o 'Downloading.*[failed]' docker_pull.log | tail -n 1)
            echo "Failed layer: $failed_layer"

            if [ -z "$failed_layer" ]; then
                echo "Unable to determine the failed layer."
            else
                echo "Retrying layer: $failed_layer"
            fi

            echo "Retrying Docker pull..."
        fi
    done

    if [ "$success" = false ]; then
        echo "❌ Failed to pull Docker image $DOCKER_IMAGE after $RETRY_LIMIT attempts."
        exit 1
    fi
}

# Check if Docker image argument is passed
if [ -z "$DOCKER_IMAGE" ]; then
    echo "Usage: ./docker_pull_with_size.sh <docker_image>"
    exit 1
fi

# Pull Docker image with retries
pull_with_retry
