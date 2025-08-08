#!/bin/bash

# System Check Script for Twitter Analyzer
# Usage: ./check-system.sh

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔍 System Check for Twitter Analyzer${NC}"
echo -e "${BLUE}====================================${NC}"

# Function to check command exists
check_command() {
    if command -v $1 &> /dev/null; then
        echo -e "${GREEN}✅ $1 is installed${NC}"
        return 0
    else
        echo -e "${RED}❌ $1 is not installed${NC}"
        return 1
    fi
}

# Function to check port availability
check_port() {
    if netstat -tuln | grep -q ":$1 "; then
        echo -e "${RED}❌ Port $1 is already in use${NC}"
        return 1
    else
        echo -e "${GREEN}✅ Port $1 is available${NC}"
        return 0
    fi
}

# Function to check disk space
check_disk_space() {
    local required_space=$1
    local available_space=$(df -BG . | awk 'NR==2 {print $4}' | sed 's/G//')
    
    if [ "$available_space" -ge "$required_space" ]; then
        echo -e "${GREEN}✅ Sufficient disk space: ${available_space}G available${NC}"
        return 0
    else
        echo -e "${RED}❌ Insufficient disk space: ${available_space}G available, ${required_space}G required${NC}"
        return 1
    fi
}

# Function to check memory
check_memory() {
    local required_memory=$1
    local available_memory=$(free -m | awk 'NR==2{print $2}')
    
    if [ "$available_memory" -ge "$required_memory" ]; then
        echo -e "${GREEN}✅ Sufficient memory: ${available_memory}MB available${NC}"
        return 0
    else
        echo -e "${RED}❌ Insufficient memory: ${available_memory}MB available, ${required_memory}MB required${NC}"
        return 1
    fi
}

# Function to check internet connectivity
check_internet() {
    if curl -s --max-time 10 https://www.google.com > /dev/null; then
        echo -e "${GREEN}✅ Internet connectivity is working${NC}"
        return 0
    else
        echo -e "${RED}❌ No internet connectivity${NC}"
        return 1
    fi
}

# Function to check Docker daemon
check_docker_daemon() {
    if docker info > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Docker daemon is running${NC}"
        return 0
    else
        echo -e "${RED}❌ Docker daemon is not running${NC}"
        return 1
    fi
}

# Function to check user permissions
check_permissions() {
    if [ -w . ]; then
        echo -e "${GREEN}✅ Current directory is writable${NC}"
        return 0
    else
        echo -e "${RED}❌ Current directory is not writable${NC}"
        return 1
    fi
}

# Function to check environment file
check_env_file() {
    if [ -f .env ]; then
        echo -e "${GREEN}✅ .env file exists${NC}"
        
        # Check required variables
        local missing_vars=()
        
        if ! grep -q "OPENAI_API_KEY=" .env; then
            missing_vars+=("OPENAI_API_KEY")
        fi
        
        if ! grep -q "SECRET_KEY=" .env; then
            missing_vars+=("SECRET_KEY")
        fi
        
        if ! grep -q "JWT_SECRET_KEY=" .env; then
            missing_vars+=("JWT_SECRET_KEY")
        fi
        
        if [ ${#missing_vars[@]} -eq 0 ]; then
            echo -e "${GREEN}✅ All required environment variables are set${NC}"
            return 0
        else
            echo -e "${YELLOW}⚠️  Missing environment variables: ${missing_vars[*]}${NC}"
            return 1
        fi
    else
        echo -e "${YELLOW}⚠️  .env file not found${NC}"
        return 1
    fi
}

# Function to check Docker Compose file
check_docker_compose() {
    if [ -f docker-compose.production.yml ]; then
        echo -e "${GREEN}✅ Production Docker Compose file exists${NC}"
        
        # Validate Docker Compose file
        if docker-compose -f docker-compose.production.yml config > /dev/null 2>&1; then
            echo -e "${GREEN}✅ Docker Compose configuration is valid${NC}"
            return 0
        else
            echo -e "${RED}❌ Docker Compose configuration is invalid${NC}"
            return 1
        fi
    else
        echo -e "${RED}❌ Production Docker Compose file not found${NC}"
        return 1
    fi
}

# Function to check SSL certificates
check_ssl_certificates() {
    if [ -f ssl/cert.pem ] && [ -f ssl/key.pem ]; then
        echo -e "${GREEN}✅ SSL certificates exist${NC}"
        
        # Check certificate validity
        if openssl x509 -checkend 86400 -noout -in ssl/cert.pem > /dev/null 2>&1; then
            echo -e "${GREEN}✅ SSL certificate is valid${NC}"
            return 0
        else
            echo -e "${YELLOW}⚠️  SSL certificate is expired or will expire soon${NC}"
            return 1
        fi
    else
        echo -e "${YELLOW}⚠️  SSL certificates not found (will be generated automatically)${NC}"
        return 0
    fi
}

# Main check function
main() {
    local all_checks_passed=true
    
    echo -e "${YELLOW}🔧 Checking system requirements...${NC}"
    echo ""
    
    # Check basic commands
    echo -e "${BLUE}📦 Required software:${NC}"
    check_command "docker" || all_checks_passed=false
    check_command "docker-compose" || all_checks_passed=false
    check_command "curl" || all_checks_passed=false
    check_command "git" || all_checks_passed=false
    
    echo ""
    
    # Check system resources
    echo -e "${BLUE}💻 System resources:${NC}"
    check_disk_space 10 || all_checks_passed=false
    check_memory 2048 || all_checks_passed=false
    
    echo ""
    
    # Check network
    echo -e "${BLUE}🌐 Network connectivity:${NC}"
    check_internet || all_checks_passed=false
    
    echo ""
    
    # Check Docker
    echo -e "${BLUE}🐳 Docker status:${NC}"
    check_docker_daemon || all_checks_passed=false
    
    echo ""
    
    # Check ports
    echo -e "${BLUE}🔌 Port availability:${NC}"
    check_port 80 || all_checks_passed=false
    check_port 443 || all_checks_passed=false
    check_port 8000 || all_checks_passed=false
    check_port 3000 || all_checks_passed=false
    
    echo ""
    
    # Check permissions
    echo -e "${BLUE}🔐 Permissions:${NC}"
    check_permissions || all_checks_passed=false
    
    echo ""
    
    # Check configuration files
    echo -e "${BLUE}📁 Configuration files:${NC}"
    check_env_file || all_checks_passed=false
    check_docker_compose || all_checks_passed=false
    check_ssl_certificates || all_checks_passed=false
    
    echo ""
    
    # Summary
    echo -e "${BLUE}📋 Summary:${NC}"
    if [ "$all_checks_passed" = true ]; then
        echo -e "${GREEN}🎉 All checks passed! System is ready for deployment.${NC}"
        echo ""
        echo -e "${BLUE}🚀 Next steps:${NC}"
        echo -e "  1. Run: ./deploy.sh production"
        echo -e "  2. Or: sudo systemctl start twitter-analyzer"
        echo -e "  3. Check status: ./monitoring.sh status"
        return 0
    else
        echo -e "${RED}❌ Some checks failed. Please fix the issues before deployment.${NC}"
        echo ""
        echo -e "${BLUE}🔧 Common fixes:${NC}"
        echo -e "  - Install missing software: ./setup-server.sh"
        echo -e "  - Configure .env file: cp env_example.txt .env && nano .env"
        echo -e "  - Free up disk space or memory"
        echo -e "  - Stop services using required ports"
        return 1
    fi
}

# Run main function
main "$@"
