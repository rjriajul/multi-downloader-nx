# VPS Deployment Guide for Multi-Downloader NX

This guide will walk you through deploying multi-downloader-nx to a Virtual Private Server (VPS) so you can access it remotely via a web browser.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Deployment Methods](#deployment-methods)
  - [Method 1: Docker Deployment (Recommended)](#method-1-docker-deployment-recommended)
  - [Method 2: Manual Deployment from Source](#method-2-manual-deployment-from-source)
- [Reverse Proxy Setup (nginx)](#reverse-proxy-setup-nginx)
- [Running as a System Service](#running-as-a-system-service)
- [Security Best Practices](#security-best-practices)
- [Accessing Your Deployment](#accessing-your-deployment)
- [Troubleshooting](#troubleshooting)

## Prerequisites

Before you begin, ensure you have:

- A VPS running Ubuntu 20.04+ or Debian 11+ (or similar Linux distribution)
- SSH access to your VPS with sudo privileges
- A domain name (optional, but recommended for SSL/HTTPS access)
- At least 2GB RAM and 10GB available disk space
- Basic familiarity with the Linux command line

## Deployment Methods

### Method 1: Docker Deployment (Recommended)

Docker deployment is the easiest and most reliable method.

#### Step 1: Install Docker

```bash
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

# Verify installation
sudo docker --version
```

#### Step 2: Clone the Repository

```bash
# Clone the repository
git clone https://github.com/anidl/multi-downloader-nx.git
cd multi-downloader-nx
```

#### Step 3: Prepare CDM Files (Required for DRM Content)

Before building, you need to add your CDM (Content Decryption Module) files:

```bash
# Create CDM directories if they don't exist
mkdir -p widevine playready

# Copy your Widevine CDM files (if you have them)
# Place device_client_id_blob.bin (or client_id.bin) and device_private_key.pem (or private_key.pem)
# into the ./widevine/ directory

# Copy your PlayReady CDM files (if you have them)
# Place bgroupcert.dat and zgpriv.dat into the ./playready/ directory
```

**Note:** You must source CDM files yourself for legal reasons. The application will show an error if no valid CDM is detected.

#### Step 4: Build the Docker Image

```bash
# Build the Docker image
sudo docker build -t multi-downloader-nx .
```

This process will take several minutes as it installs dependencies and builds the application.

#### Step 5: Run the Container

```bash
# Create a directory for downloads on your host system
mkdir -p ~/anidl-downloads

# Run the container
sudo docker run -d \
  --name anidl \
  -p 3000:3000 \
  -v ~/anidl-downloads:/app/videos \
  -v ~/anidl-config:/app/config \
  --restart unless-stopped \
  multi-downloader-nx
```

**Explanation of flags:**
- `-d`: Run in detached mode (background)
- `--name anidl`: Name the container "anidl"
- `-p 3000:3000`: Map port 3000 from container to host
- `-v ~/anidl-downloads:/app/videos`: Mount downloads directory
- `-v ~/anidl-config:/app/config`: Persist configuration
- `--restart unless-stopped`: Automatically restart on server reboot

#### Step 6: Verify the Container is Running

```bash
# Check container status
sudo docker ps

# View logs
sudo docker logs anidl

# Follow logs in real-time
sudo docker logs -f anidl
```

You should see output indicating the GUI server has started on port 3000.

#### Managing the Docker Container

```bash
# Stop the container
sudo docker stop anidl

# Start the container
sudo docker start anidl

# Restart the container
sudo docker restart anidl

# Remove the container (to rebuild)
sudo docker rm -f anidl

# View resource usage
sudo docker stats anidl
```

### Method 2: Manual Deployment from Source

If you prefer not to use Docker, you can deploy directly from source.

#### Step 1: Install Node.js and pnpm

```bash
# Install Node.js 22.x (required by multi-downloader-nx)
curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
sudo apt-get install -y nodejs

# Verify Node.js version (should be 22.x or higher)
node --version

# Install pnpm globally
sudo npm install -g pnpm

# Verify pnpm installation
pnpm --version
```

#### Step 2: Install Dependencies

```bash
# Install ffmpeg and mkvtoolnix
sudo apt-get update
sudo apt-get install -y ffmpeg mkvtoolnix

# Install mp4decrypt (Bento4 SDK)
cd /tmp
wget https://www.bok.net/Bento4/binaries/Bento4-SDK-1-6-0-641.x86_64-unknown-linux.zip
unzip Bento4-SDK-1-6-0-641.x86_64-unknown-linux.zip
sudo cp Bento4-SDK-1-6-0-641.x86_64-unknown-linux/bin/mp4decrypt /usr/local/bin/
sudo chmod +x /usr/local/bin/mp4decrypt

# Verify installations
ffmpeg -version
mkvmerge --version
mp4decrypt --version
```

#### Step 3: Clone and Build the Application

```bash
# Create application directory
sudo mkdir -p /opt/anidl
sudo chown $USER:$USER /opt/anidl

# Clone the repository
cd /opt/anidl
git clone https://github.com/anidl/multi-downloader-nx.git .

# Install dependencies
pnpm install

# Build the GUI version
pnpm run build-linux-x64-gui

# The built application will be in lib/_builds/multi-downloader-nx-linux-x64-gui/
```

#### Step 4: Configure the Application

```bash
# Extract the built application
cd /opt/anidl
cp -r lib/_builds/multi-downloader-nx-linux-x64-gui/* .

# Update bin-path.yml for Linux
cat > config/bin-path.yml << EOF
ffmpeg: 'ffmpeg'
mkvmerge: 'mkvmerge'
ffprobe: 'ffprobe'
mp4decrypt: 'mp4decrypt'
shaka: 'shaka-packager'
EOF

# Configure GUI port (optional, default is 3000)
cat > config/gui.yml << EOF
port: 3000
EOF

# Create downloads directory
mkdir -p videos

# Add your CDM files
mkdir -p widevine playready
# Copy your CDM files to these directories
```

#### Step 5: Test the Application

```bash
# Run the application
cd /opt/anidl
./aniDL --help

# Start the GUI server
./aniDL &

# Check if it's running
ps aux | grep aniDL

# Test by accessing http://YOUR_VPS_IP:3000 in a browser
```

#### Step 6: Set Up as a System Service (see below)

## Reverse Proxy Setup (nginx)

Using a reverse proxy with SSL is highly recommended for secure remote access.

### Step 1: Install nginx

```bash
sudo apt-get update
sudo apt-get install -y nginx
```

### Step 2: Configure nginx

Create a new nginx configuration file:

```bash
sudo nano /etc/nginx/sites-available/anidl
```

Add the following configuration (replace `your-domain.com` with your actual domain):

```nginx
server {
    listen 80;
    server_name your-domain.com;

    # Redirect HTTP to HTTPS (after SSL is set up)
    # return 301 https://$server_name$request_uri;

    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # WebSocket support
        proxy_read_timeout 86400;
    }
    
    # Increase max upload size for large file uploads if needed
    client_max_body_size 100M;
}
```

Enable the site and test the configuration:

```bash
# Create symbolic link to enable the site
sudo ln -s /etc/nginx/sites-available/anidl /etc/nginx/sites-enabled/

# Test nginx configuration
sudo nginx -t

# Reload nginx
sudo systemctl reload nginx
```

### Step 3: Set Up SSL with Let's Encrypt (Recommended)

```bash
# Install certbot
sudo apt-get install -y certbot python3-certbot-nginx

# Obtain and install SSL certificate
sudo certbot --nginx -d your-domain.com

# Certbot will automatically configure HTTPS and set up auto-renewal
```

Test automatic renewal:

```bash
sudo certbot renew --dry-run
```

### Step 4: Configure Firewall

```bash
# If using UFW (Ubuntu Firewall)
sudo ufw allow 'Nginx Full'
sudo ufw allow OpenSSH
sudo ufw enable

# Check status
sudo ufw status
```

## Running as a System Service

To ensure the application starts automatically on boot and restarts if it crashes, set up a systemd service.

### For Docker Deployment

Docker's `--restart unless-stopped` flag handles this automatically. To manage via systemd:

```bash
# Enable Docker to start on boot
sudo systemctl enable docker

# The container will automatically start with Docker
```

### For Manual Deployment

Create a systemd service file:

```bash
sudo nano /etc/systemd/system/anidl.service
```

Add the following content:

```ini
[Unit]
Description=Multi-Downloader NX GUI Server
After=network.target

[Service]
Type=simple
User=YOUR_USERNAME
WorkingDirectory=/opt/anidl
ExecStart=/opt/anidl/aniDL
Restart=always
RestartSec=10
StandardOutput=append:/var/log/anidl/output.log
StandardError=append:/var/log/anidl/error.log

# Security settings
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/opt/anidl/videos /opt/anidl/config /opt/anidl/widevine /opt/anidl/playready

[Install]
WantedBy=multi-user.target
```

**Important:** Replace `YOUR_USERNAME` with your actual username.

Set up and start the service:

```bash
# Create log directory
sudo mkdir -p /var/log/anidl
sudo chown YOUR_USERNAME:YOUR_USERNAME /var/log/anidl

# Reload systemd
sudo systemctl daemon-reload

# Enable service to start on boot
sudo systemctl enable anidl

# Start the service
sudo systemctl start anidl

# Check status
sudo systemctl status anidl

# View logs
sudo journalctl -u anidl -f
```

Manage the service:

```bash
# Start
sudo systemctl start anidl

# Stop
sudo systemctl stop anidl

# Restart
sudo systemctl restart anidl

# View status
sudo systemctl status anidl

# View logs
sudo journalctl -u anidl -n 100 --no-pager
```

## Security Best Practices

1. **Use Strong Passwords**: If the GUI has password protection, use a strong password.

2. **Firewall Configuration**: Only open necessary ports
   ```bash
   # For Docker deployment with nginx
   sudo ufw allow 80/tcp    # HTTP
   sudo ufw allow 443/tcp   # HTTPS
   sudo ufw allow OpenSSH   # SSH
   # Don't expose port 3000 directly if using nginx
   ```

3. **Use HTTPS**: Always use SSL/TLS certificates (Let's Encrypt is free)

4. **Regular Updates**: Keep your system and application updated
   ```bash
   # System updates
   sudo apt-get update && sudo apt-get upgrade -y
   
   # For Docker deployment, rebuild periodically
   cd /path/to/multi-downloader-nx
   git pull
   sudo docker build -t multi-downloader-nx .
   sudo docker stop anidl
   sudo docker rm anidl
   # Then run the container again (see Step 5 in Docker section)
   ```

5. **Limit Access**: Consider using IP whitelisting or VPN access

6. **Monitor Logs**: Regularly check logs for suspicious activity
   ```bash
   # Docker logs
   sudo docker logs anidl --tail 100
   
   # Systemd logs
   sudo journalctl -u anidl -n 100
   
   # nginx logs
   sudo tail -f /var/log/nginx/access.log
   sudo tail -f /var/log/nginx/error.log
   ```

7. **Backup CDM Files**: Keep secure backups of your CDM files in a safe location

8. **Use Non-Root User**: Never run the application as root

## Accessing Your Deployment

Once deployed, you can access your Multi-Downloader NX instance:

- **Without Domain/SSL**: `http://YOUR_VPS_IP:3000`
- **With nginx (no SSL)**: `http://your-domain.com`
- **With nginx and SSL**: `https://your-domain.com` (Recommended)

### First-Time Setup

1. Open your browser and navigate to your deployment URL
2. You may be prompted to set up a password on first launch
3. Authenticate with your streaming service (Crunchyroll, Hidive, or ADN)
4. Start downloading!

## Troubleshooting

### Port 3000 Already in Use

```bash
# Check what's using port 3000
sudo lsof -i :3000

# Kill the process or change the port in config/gui.yml
```

### Cannot Connect to GUI

```bash
# Check if the application is running
# For Docker:
sudo docker ps | grep anidl
sudo docker logs anidl

# For systemd:
sudo systemctl status anidl
sudo journalctl -u anidl -n 50

# Check firewall
sudo ufw status

# Test locally on the VPS
curl http://localhost:3000
```

### CDM Not Detected

```bash
# Check CDM files exist
ls -la widevine/
ls -la playready/

# Check file permissions
chmod 644 widevine/*
chmod 644 playready/*
```

### Download Fails

```bash
# Check if ffmpeg and mkvmerge are installed
which ffmpeg
which mkvmerge
which mp4decrypt

# Check disk space
df -h

# Check logs for error messages
# Docker:
sudo docker logs anidl --tail 100

# Systemd:
sudo journalctl -u anidl -n 100
```

### nginx Shows 502 Bad Gateway

```bash
# Check if the application is running on port 3000
curl http://localhost:3000

# Check nginx error logs
sudo tail -f /var/log/nginx/error.log

# Restart nginx
sudo systemctl restart nginx
```

### SSL Certificate Issues

```bash
# Renew certificate manually
sudo certbot renew

# Check certificate status
sudo certbot certificates

# Test nginx configuration
sudo nginx -t
```

### Out of Disk Space

```bash
# Check disk usage
df -h

# Clean up old downloads
rm -rf ~/anidl-downloads/old_files

# For Docker, clean up old images
sudo docker system prune -a
```

### Application Won't Start After Update

```bash
# For Docker deployment:
sudo docker logs anidl

# Try rebuilding
cd /path/to/multi-downloader-nx
git pull
sudo docker build -t multi-downloader-nx .
sudo docker stop anidl && sudo docker rm anidl
# Run container again

# For manual deployment:
cd /opt/anidl
git pull
pnpm install
pnpm run build-linux-x64-gui
```

## Additional Resources

- [Main Documentation](./DOCUMENTATION.md)
- [Getting Started Guide](./GET-STARTED.md)
- [Official Repository](https://github.com/anidl/multi-downloader-nx)
- [GitHub Issues](https://github.com/anidl/multi-downloader-nx/issues)
- [Discord Community](https://discord.gg/qEpbWen5vq)

## Need Help?

If you encounter issues not covered in this guide:

1. Check the [GitHub Issues](https://github.com/anidl/multi-downloader-nx/issues) page
2. Join the [Discord Community](https://discord.gg/qEpbWen5vq) for support
3. Review the application logs for error messages
4. Search online for VPS-specific Linux issues (many problems are OS-level, not application-specific)

---

**Legal Disclaimer**: This application enables downloading videos for offline viewing, which may be forbidden by law in your country or violate Terms of Service. Use responsibly and at your own risk.
