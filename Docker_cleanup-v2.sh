#!/bin/bash
LOGFILE="/tmp/$(date +'%d%m%y').log"

echo "Cleanup script started at $(date)" >> "$LOGFILE"
if ! command -v docker &> /dev/null; then
    echo "Docker is not installed or not found in PATH. Exiting." >> "$LOGFILE"
    exit 1
fi

if ! docker info > /dev/null 2>&1; then
    echo "Docker daemon is not running. Exiting." >> "$LOGFILE"
    exit 1
fi
echo "Removing stopped containers..." >> "$LOGFILE"
docker container prune -f >> "$LOGFILE" 2>&1
echo "Removing unused images..." >> "$LOGFILE"
docker image prune -f >> "$LOGFILE" 2>&1 || echo "No unused images found." >> "$LOGFILE"

echo "Removing dead containers..." >> "$LOGFILE"
DEAD_CONTAINERS=$(docker ps -a -f status=exited -q)
if [ -n "$DEAD_CONTAINERS" ]; then
    docker rm $DEAD_CONTAINERS >> "$LOGFILE" 2>&1
else
    echo "No dead containers found." >> "$LOGFILE"
fi
echo "Removing unused volumes..." >> "$LOGFILE"
docker volume prune -f >> "$LOGFILE" 2>&1 || echo "No unused volumes found." >> "$LOGFILE"
echo "Cleanup completed at $(date)" >> "$LOGFILE"
exit 0
