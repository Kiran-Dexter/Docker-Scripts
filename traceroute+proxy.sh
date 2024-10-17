#!/bin/bash

# Variables
proxy="http://<proxy-ip>:<proxy-port>"
target="http://www.google.com"
log_file="proxy_traceroute_log.txt"

# Check if the proxy and target are set correctly
if [ -z "$proxy" ] || [ -z "$target" ]; then
    echo "Proxy or target not set. Exiting."
    exit 1
fi

# Start logging
echo "Traceroute for HTTP Proxy: $proxy" > $log_file
echo "Target: $target" >> $log_file
echo "-----------------------------------" >> $log_file

# Function to perform curl request through the proxy and measure the time
perform_request() {
    echo "Performing request to $target via proxy $proxy" | tee -a $log_file
    start=$(date +%s%N)  # Capture the start time in nanoseconds

    # Perform the request through the proxy
    curl -x $proxy -o /dev/null -s -w "%{http_code}\n" $target

    # Capture the end time in nanoseconds
    end=$(date +%s%N)

    # Calculate the duration in milliseconds
    duration=$(( (end - start) / 1000000 ))
    echo "Request completed in $duration ms" | tee -a $log_file
    echo "-----------------------------------" >> $log_file
}

# Perform multiple requests to simulate a "traceroute"
for i in {1..5}; do
    perform_request
done

echo "Traceroute simulation complete. Check $log_file for results."
