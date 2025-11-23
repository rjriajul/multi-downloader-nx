# Quick Start: VPS Deployment

This is a quick reference for deploying multi-downloader-nx to a VPS. For detailed instructions, see [docs/VPS-DEPLOYMENT.md](docs/VPS-DEPLOYMENT.md).

## Option 1: One-Line Docker Deployment

```bash
# Clone, build, and prepare for deployment
git clone https://github.com/anidl/multi-downloader-nx.git
cd multi-downloader-nx
chmod +x deploy-vps.sh
./deploy-vps.sh
```

After the script completes:

1. Add your CDM files to `widevine/` and `playready/` directories
2. Run: `docker compose up -d`
3. Access at: `http://YOUR_SERVER_IP:3000`

## Option 2: Manual Docker Deployment

```bash
# Clone repository
git clone https://github.com/anidl/multi-downloader-nx.git
cd multi-downloader-nx

# Add CDM files (required for DRM content)
# Place your CDM files in widevine/ and playready/ directories

# Build and run
docker build -t multi-downloader-nx .
docker compose up -d

# View logs
docker compose logs -f
```

## Option 3: Manual Installation (Without Docker)

See the detailed guide in [docs/VPS-DEPLOYMENT.md](docs/VPS-DEPLOYMENT.md#method-2-manual-deployment-from-source) for step-by-step instructions.

## Setting Up Reverse Proxy with SSL

For secure HTTPS access, see the [Reverse Proxy Setup](docs/VPS-DEPLOYMENT.md#reverse-proxy-setup-nginx) section in the full guide.

## Common Issues

**Port 3000 already in use:**
- Change the port in `config/gui.yml`
- Or update the port mapping in `docker-compose.yml`

**CDM not detected:**
- Ensure CDM files are in `widevine/` or `playready/` directories
- Check file permissions: `chmod 644 widevine/* playready/*`

**Cannot access GUI:**
- Check if the container is running: `docker ps`
- Check firewall: `sudo ufw allow 3000/tcp`
- Check logs: `docker logs anidl`

## Need Help?

- 📖 Full documentation: [docs/VPS-DEPLOYMENT.md](docs/VPS-DEPLOYMENT.md)
- 💬 Discord: https://discord.gg/qEpbWen5vq
- 🐛 Issues: https://github.com/anidl/multi-downloader-nx/issues
