#!/bin/bash

echo "Removing old fleet-app images..."
docker rmi localhost:5000/fleet-app:latest 2>/dev/null || true
docker rmi fleet-app:latest 2>/dev/null || true

echo "Building fleet-app container for local registry..."
docker build --no-cache -t localhost:5000/fleet-app:latest .

echo "Pushing to local registry..."
docker push localhost:5000/fleet-app:latest

echo "Fleet app container built and pushed successfully!"
echo "Image: localhost:5000/fleet-app:latest"

# Show the image
docker images | grep fleet-app
