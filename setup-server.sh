#!/bin/bash

# Linux Server Setup Script for Twitter Analyzer
# This script installs all necessary dependencies on a fresh Linux server

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🐧 Linux Server Setup for Twitter Analyzer${NC}"
echo -e "${BLUE}==========================================${NC}"

# Detect OS
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$NAME
    VER=$VERSION_ID
else
    echo -e "${RED}❌ Cannot detect OS${NC}"
    exit 1
fi

echo -e "${YELLOW}📋 Detected OS: $OS $VER${NC}"

# Function to install packages based on OS
install_packages() {
    if [[ "$OS" == *"Ubuntu"* ]] || [[ "$OS" == *"Debian"* ]]; then
        echo -e "${YELLOW}📦 Installing packages for Ubuntu/Debian...${NC}"
        sudo apt-get update
        sudo apt-get install -y \
            curl \
            wget \
            git \
            unzip \
            software-properties-common \
            apt-transport-https \
            ca-certificates \
            gnupg \
            lsb-release \
            openssl \
            nginx \
            ufw
    elif [[ "$OS" == *"CentOS"* ]] || [[ "$OS" == *"Red Hat"* ]]; then
        echo -e "${YELLOW}📦 Installing packages for CentOS/RHEL...${NC}"
        sudo yum update -y
        sudo yum install -y \
            curl \
            wget \
            git \
            unzip \
            openssl \
            nginx \
            firewalld
    else
        echo -e "${RED}❌ Unsupported OS: $OS${NC}"
        exit 1
    fi
}

# Install Docker
install_docker() {
    echo -e "${YELLOW}🐳 Installing Docker...${NC}"
    
    if command -v docker &> /dev/null; then
        echo -e "${GREEN}✅ Docker is already installed${NC}"
        return
    fi
    
    if [[ "$OS" == *"Ubuntu"* ]] || [[ "$OS" == *"Debian"* ]]; then
        # Add Docker's official GPG key
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
        
        # Add Docker repository
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
        
        # Install Docker
        sudo apt-get update
        sudo apt-get install -y docker-ce docker-ce-cli containerd.io
    elif [[ "$OS" == *"CentOS"* ]] || [[ "$OS" == *"Red Hat"* ]]; then
        # Install Docker for CentOS/RHEL
        sudo yum install -y yum-utils
        sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
        sudo yum install -y docker-ce docker-ce-cli containerd.io
    fi
    
    # Start and enable Docker
    sudo systemctl start docker
    sudo systemctl enable docker
    
    # Add current user to docker group
    sudo usermod -aG docker $USER
    
    echo -e "${GREEN}✅ Docker installed successfully${NC}"
}

# Install Docker Compose
install_docker_compose() {
    echo -e "${YELLOW}🐳 Installing Docker Compose...${NC}"
    
    if command -v docker-compose &> /dev/null; then
        echo -e "${GREEN}✅ Docker Compose is already installed${NC}"
        return
    fi
    
    # Install Docker Compose
    sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    sudo chmod +x /usr/local/bin/docker-compose
    
    echo -e "${GREEN}✅ Docker Compose installed successfully${NC}"
}

# Configure firewall
configure_firewall() {
    echo -e "${YELLOW}🔥 Configuring firewall...${NC}"
    
    if [[ "$OS" == *"Ubuntu"* ]] || [[ "$OS" == *"Debian"* ]]; then
        # Configure UFW
        sudo ufw --force enable
        sudo ufw allow ssh
        sudo ufw allow 80/tcp
        sudo ufw allow 443/tcp
        sudo ufw allow 22/tcp
        echo -e "${GREEN}✅ UFW configured${NC}"
    elif [[ "$OS" == *"CentOS"* ]] || [[ "$OS" == *"Red Hat"* ]]; then
        # Configure firewalld
        sudo systemctl start firewalld
        sudo systemctl enable firewalld
        sudo firewall-cmd --permanent --add-service=ssh
        sudo firewall-cmd --permanent --add-service=http
        sudo firewall-cmd --permanent --add-service=https
        sudo firewall-cmd --reload
        echo -e "${GREEN}✅ Firewalld configured${NC}"
    fi
}

# Create application directory
setup_app_directory() {
    echo -e "${YELLOW}📁 Setting up application directory...${NC}"
    
    # Create app directory
    sudo mkdir -p /opt/twitter-analyzer
    sudo chown $USER:$USER /opt/twitter-analyzer
    
    echo -e "${GREEN}✅ Application directory created${NC}"
}

# Create systemd service
create_systemd_service() {
    echo -e "${YELLOW}⚙️  Creating systemd service...${NC}"
    
    cat << EOF | sudo tee /etc/systemd/system/twitter-analyzer.service
[Unit]
Description=Twitter Analyzer Application
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/opt/twitter-analyzer
ExecStart=/usr/local/bin/docker-compose -f docker-compose.production.yml up -d
ExecStop=/usr/local/bin/docker-compose -f docker-compose.production.yml down
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
EOF

    sudo systemctl daemon-reload
    sudo systemctl enable twitter-analyzer.service
    
    echo -e "${GREEN}✅ Systemd service created${NC}"
}

# Setup monitoring
setup_monitoring() {
    echo -e "${YELLOW}📊 Setting up monitoring...${NC}"
    
    # Create log rotation
    cat << EOF | sudo tee /etc/logrotate.d/twitter-analyzer
/opt/twitter-analyzer/logs/*.log {
    daily
    missingok
    rotate 7
    compress
    delaycompress
    notifempty
    create 644 $USER $USER
}
EOF

    echo -e "${GREEN}✅ Monitoring configured${NC}"
}

# Main installation
main() {
    echo -e "${YELLOW}🚀 Starting server setup...${NC}"
    
    # Update system
    echo -e "${YELLOW}📦 Updating system packages...${NC}"
    if [[ "$OS" == *"Ubuntu"* ]] || [[ "$OS" == *"Debian"* ]]; then
        sudo apt-get update && sudo apt-get upgrade -y
    elif [[ "$OS" == *"CentOS"* ]] || [[ "$OS" == *"Red Hat"* ]]; then
        sudo yum update -y
    fi
    
    # Install packages
    install_packages
    
    # Install Docker
    install_docker
    
    # Install Docker Compose
    install_docker_compose
    
    # Configure firewall
    configure_firewall
    
    # Setup app directory
    setup_app_directory
    
    # Create systemd service
    create_systemd_service
    
    # Setup monitoring
    setup_monitoring
    
    echo -e "${GREEN}🎉 Server setup completed successfully!${NC}"
    echo -e "${BLUE}📋 Next steps:${NC}"
    echo -e "${BLUE}   1. Copy your project files to /opt/twitter-analyzer${NC}"
    echo -e "${BLUE}   2. Configure .env file with your settings${NC}"
    echo -e "${BLUE}   3. Run: ./deploy.sh production${NC}"
    echo -e "${BLUE}   4. Or start with: sudo systemctl start twitter-analyzer${NC}"
    echo -e "${BLUE}   5. Check status: sudo systemctl status twitter-analyzer${NC}"
    echo -e "${YELLOW}⚠️  Please log out and log back in for Docker group changes to take effect${NC}"
}

# Run main function
main
