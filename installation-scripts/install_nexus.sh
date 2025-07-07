#!/bin/bash

# Install dependencies
sudo apt update && sudo apt install -y wget openjdk-17-jdk

# Nexus variables
NEXUS_VERSION="3.77.1-01"
NEXUS_DIR="nexus-${NEXUS_VERSION}"
NEXUS_TAR="${NEXUS_DIR}-unix.tar.gz"
NEXUS_URL="https://download.sonatype.com/nexus/3/${NEXUS_TAR}"

# Setup directories
sudo mkdir -p /opt/nexus/
cd /tmp
sudo rm -rf /tmp/nexus-install && sudo mkdir /tmp/nexus-install
cd /tmp/nexus-install

# Download and extract Nexus
sudo wget "$NEXUS_URL" -O nexus.tar.gz
sudo tar -xzf nexus.tar.gz
sudo mv "$NEXUS_DIR" /opt/nexus

# Create nexus user
sudo useradd -r -M -s /sbin/nologin nexus

# Set permissions
sudo chown -R nexus:nexus /opt/nexus

# Configure nexus.rc
echo 'run_as_user="nexus"' | sudo tee /opt/nexus/$NEXUS_DIR/bin/nexus.rc

# Create systemd service
cat <<EOT | sudo tee /etc/systemd/system/nexus.service
[Unit]
Description=Nexus Repository Manager
After=network.target

[Service]
Type=forking
LimitNOFILE=65536
ExecStart=/opt/nexus/$NEXUS_DIR/bin/nexus start
ExecStop=/opt/nexus/$NEXUS_DIR/bin/nexus stop
User=nexus
Restart=on-abort

[Install]
WantedBy=multi-user.target
EOT

# Enable and start Nexus
sudo systemctl daemon-reload
sudo systemctl enable nexus
sudo systemctl start nexus