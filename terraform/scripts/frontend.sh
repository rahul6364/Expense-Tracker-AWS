#!/bin/bash

# Update packages
apt update -y

# Install Docker
apt install docker.io -y

# Start Docker
systemctl start docker
systemctl enable docker

# Pull frontend image
docker pull rahul6364/expense-tracker-web:latest

# Run frontend container
docker run -d \
  --name frontend \
  -p 80:80 \
  --restart unless-stopped \
  rahul6364/expense-tracker-web:latest