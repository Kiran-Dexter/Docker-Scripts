#!/bin/bash

# Define the environment variables to add
ENV_VARS=(
  "export http_proxy=http://your-http-proxy:port"
  "export https_proxy=http://your-https-proxy:port"
  "export ftp_proxy=http://your-ftp-proxy:port"
  "export no_proxy=localhost,127.0.0.1,.example.com"
  "export JAVA_HOME=/usr/lib/jvm/java-11-openjdk"
  "export PATH=\$PATH:/custom/bin"
  "export APP_ENV=production"
  "export LOG_LEVEL=debug"
  "export DB_HOST=db.example.com"
  "export DB_PORT=3306"
)

# Target file for persistent storage
TARGET_FILE="$HOME/.bashrc"

echo "Adding environment variables to $TARGET_FILE..."

# Backup the existing file
cp "$TARGET_FILE" "$TARGET_FILE.bak"

# Append the environment variables to the file if not already present
for VAR in "${ENV_VARS[@]}"; do
  if ! grep -qxF "$VAR" "$TARGET_FILE"; then
    echo "$VAR" >> "$TARGET_FILE"
  else
    echo "Variable already exists in $TARGET_FILE: $VAR"
  fi
done

# Apply the environment variables immediately for the current session
echo "Applying environment variables to the current session..."
for VAR in "${ENV_VARS[@]}"; do
  eval "$VAR"
done

echo "Environment variables added successfully."
echo "To persist these changes, please restart your terminal or run: source $TARGET_FILE"
