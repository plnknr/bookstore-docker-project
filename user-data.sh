#!/bin/bash
# Update all packages to the latest version
dnf update -y

# Install git
dnf install -y git

# Install Docker
dnf install -y docker

# Start the Docker service
systemctl start docker

# Enable Docker to start on boot
systemctl enable docker

# Add the ec2-user to the docker group
usermod -a -G docker ec2-user

# Apply the new group membership (docker) without logout/login
newgrp docker

# Download Docker Compose binary from the specified URL
curl -SL https://github.com/docker/compose/releases/download/v2.20.3/docker-compose-linux-x86_64 -o /usr/local/bin/docker-compose

# Make the Docker Compose binary executable
chmod +x /usr/local/bin/docker-compose

# Change directory to the home directory of ec2-user
cd /home/ec2-user

# Set the GitHub token and username from user data (assumed to be provided in the environment)
TOKEN=${user-data-git-token}
USER=${user-data-git-name}

# Clone the GitHub repository using the token and username
git clone https://$TOKEN@github.com/$USER/bookstore-api-repo.git

# Change directory to the cloned repository
cd /home/ec2-user/bookstore-api-repo

# Build the Docker image with the tag 'bookstoreapi:latest'
docker build -t bookstoreapi:latest .

# Start the services defined in the docker-compose.yml file in detached mode
docker-compose up -d