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
  --log-driver=awslogs \
  --log-opt awslogs-region=us-east-1 \
  --log-opt awslogs-group=/expense-tracker/frontend \
  --log-opt awslogs-stream=frontend-${HOSTNAME} \
  --log-opt awslogs-create-group=false \
  rahul6364/expense-tracker-web:latest