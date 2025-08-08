#!/bin/bash

# Twitter Analyzer Deployment Script for Linux Server
# Usage: ./deploy.sh [production|staging]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
ENVIRONMENT=${1:-production}
PROJECT_NAME="twitter-analyzer"
DOMAIN=${DOMAIN:-"your-domain.com"}

echo -e "${GREEN}🚀 Starting deployment for $ENVIRONMENT environment${NC}"

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   echo -e "${RED}❌ This script should not be run as root${NC}"
   exit 1
fi

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo -e "${RED}❌ Docker is not installed. Please install Docker first.${NC}"
    exit 1
fi

# Check if Docker Compose is installed
if ! command -v docker-compose &> /dev/null; then
    echo -e "${RED}❌ Docker Compose is not installed. Please install Docker Compose first.${NC}"
    exit 1
fi

# Create necessary directories
echo -e "${YELLOW}📁 Creating necessary directories...${NC}"
mkdir -p logs
mkdir -p ssl
mkdir -p backups

# Check if .env file exists
if [ ! -f .env ]; then
    echo -e "${YELLOW}⚠️  .env file not found. Creating from template...${NC}"
    cp env_example.txt .env
    echo -e "${YELLOW}📝 Please edit .env file with your configuration before continuing${NC}"
    echo -e "${YELLOW}   Required variables: OPENAI_API_KEY, SECRET_KEY, JWT_SECRET_KEY${NC}"
    read -p "Press Enter after editing .env file..."
fi

# Load environment variables
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
fi

# Generate SSL certificates if not exist
if [ ! -f ssl/cert.pem ] || [ ! -f ssl/key.pem ]; then
    echo -e "${YELLOW}🔐 Generating self-signed SSL certificates...${NC}"
    mkdir -p ssl
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout ssl/key.pem \
        -out ssl/cert.pem \
        -subj "/C=UA/ST=Kyiv/L=Kyiv/O=TwitterAnalyzer/CN=$DOMAIN"
fi

# Backup current deployment
if [ -d "backups" ]; then
    echo -e "${YELLOW}💾 Creating backup...${NC}"
    tar -czf "backups/backup-$(date +%Y%m%d-%H%M%S).tar.gz" \
        --exclude=node_modules \
        --exclude=venv \
        --exclude=.git \
        --exclude=backups \
        .
fi

# Stop existing containers
echo -e "${YELLOW}🛑 Stopping existing containers...${NC}"
docker-compose down || true

# Pull latest changes if git repository
if [ -d ".git" ]; then
    echo -e "${YELLOW}📥 Pulling latest changes...${NC}"
    git pull origin main || echo "Git pull failed, continuing with local files"
fi

# Build and start containers
echo -e "${YELLOW}🔨 Building containers...${NC}"
if [ "$ENVIRONMENT" = "production" ]; then
    docker-compose -f docker-compose.production.yml build
    echo -e "${YELLOW}🚀 Starting production environment...${NC}"
    docker-compose -f docker-compose.production.yml up -d
else
    docker-compose build
    echo -e "${YELLOW}🚀 Starting development environment...${NC}"
    docker-compose up -d
fi

# Wait for services to be ready
echo -e "${YELLOW}⏳ Waiting for services to be ready...${NC}"
sleep 30

# Health check
echo -e "${YELLOW}🏥 Performing health checks...${NC}"
if curl -f http://localhost/api/v1/health > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Backend is healthy${NC}"
else
    echo -e "${RED}❌ Backend health check failed${NC}"
fi

if curl -f http://localhost > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Frontend is healthy${NC}"
else
    echo -e "${RED}❌ Frontend health check failed${NC}"
fi

# Show running containers
echo -e "${YELLOW}📊 Container status:${NC}"
docker-compose ps

# Show logs
echo -e "${YELLOW}📋 Recent logs:${NC}"
docker-compose logs --tail=20

echo -e "${GREEN}🎉 Deployment completed successfully!${NC}"
echo -e "${GREEN}🌐 Application is available at: https://$DOMAIN${NC}"
echo -e "${GREEN}📊 Monitor logs with: docker-compose logs -f${NC}"
echo -e "${GREEN}🛑 Stop with: docker-compose down${NC}"
