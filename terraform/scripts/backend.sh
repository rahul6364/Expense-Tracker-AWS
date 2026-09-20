#!/bin/bash

# Update packages
apt update -y

# Install Docker
apt install docker.io -y

# Start Docker
systemctl start docker
systemctl enable docker

# Pull backend image
docker pull rahul6364/expense-tracker-api:latest

# Run backend container
docker run -d \
  --name backend \
  -p 4000:4000 \
  -e DB_HOST=${db_host} \
  -e DB_USER=${db_user} \
  -e DB_PASS=${db_password} \
  -e DB_NAME="expense_tracker" \
  -e DB_PORT=3306 \
  --restart unless-stopped \
  --log-driver=awslogs \
  --log-opt awslogs-region=us-east-1 \
  --log-opt awslogs-group=/expense-tracker/backend \
  --log-opt awslogs-stream=backend-$${HOSTNAME} \
  --log-opt awslogs-create-group=false \
  rahul6364/expense-tracker-api:latest