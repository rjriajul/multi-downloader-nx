#!/bin/bash
# Quick deployment script for multi-downloader-nx on VPS
# This script automates the Docker-based deployment

set -e

echo "=================================="
echo "Multi-Downloader NX VPS Deployment"
echo "=================================="
echo ""

# Check if running as root
if [ "$EUID" -eq 0 ]; then 
    echo "Please do not run this script as root"
    exit 1
fi

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "Docker is not installed. Installing Docker..."
    
    # Update package list
    sudo apt-get update
    
    # Install dependencies
    sudo apt-get install -y ca-certificates curl gnupg lsb-release
    
    # Add Docker's official GPG key
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    
    # Add Docker repository
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # Install Docker
    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    
    # Add current user to docker group
    sudo usermod -aG docker $USER
    
    echo "Docker installed successfully!"
    echo "Please log out and log back in for group changes to take effect, then run this script again."
    exit 0
else
    echo "✓ Docker is already installed"
fi

# Check if docker compose is available
if ! docker compose version &> /dev/null; then
    echo "✗ docker compose plugin not found"
    exit 1
else
    echo "✓ docker compose is available"
fi

echo ""
echo "Building Multi-Downloader NX Docker image..."
echo "This may take several minutes..."
echo ""

# Build the Docker image
sudo docker build -t multi-downloader-nx .

if [ $? -ne 0 ]; then
    echo "✗ Docker build failed"
    exit 1
fi

echo ""
echo "✓ Docker image built successfully"
echo ""

# Create required directories
echo "Creating directories..."
mkdir -p downloads config widevine playready fonts

echo ""
echo "=================================="
echo "Setup Complete!"
echo "=================================="
echo ""
echo "Next steps:"
echo ""
echo "1. Add your CDM files:"
echo "   - Place Widevine CDM files in ./widevine/"
echo "   - Place PlayReady CDM files in ./playready/"
echo ""
echo "2. Start the application:"
echo "   docker compose up -d"
echo ""
echo "3. View logs:"
echo "   docker compose logs -f"
echo ""
echo "4. Access the GUI:"
echo "   http://YOUR_SERVER_IP:3000"
echo ""
echo "For more information, see docs/VPS-DEPLOYMENT.md"
echo ""
