#!/bin/bash

# Twitter Analyzer Monitoring Script
# Usage: ./monitoring.sh [status|logs|health|metrics|cleanup]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
PROJECT_NAME="twitter-analyzer"
LOG_DIR="./logs"
BACKUP_DIR="./backups"

# Function to show status
show_status() {
    echo -e "${BLUE}📊 Application Status${NC}"
    echo -e "${BLUE}==================${NC}"
    
    # Docker containers status
    echo -e "${YELLOW}🐳 Docker Containers:${NC}"
    docker-compose ps
    
    echo ""
    
    # System resources
    echo -e "${YELLOW}💻 System Resources:${NC}"
    echo "CPU Usage: $(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)%"
    echo "Memory Usage: $(free -m | awk 'NR==2{printf "%.2f%%", $3*100/$2}')"
    echo "Disk Usage: $(df -h / | awk 'NR==2{print $5}')"
    
    echo ""
    
    # Application health
    echo -e "${YELLOW}🏥 Health Checks:${NC}"
    if curl -f http://localhost/api/v1/health > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Backend API: Healthy${NC}"
    else
        echo -e "${RED}❌ Backend API: Unhealthy${NC}"
    fi
    
    if curl -f http://localhost > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Frontend: Healthy${NC}"
    else
        echo -e "${RED}❌ Frontend: Unhealthy${NC}"
    fi
    
    if curl -f http://localhost/health > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Nginx: Healthy${NC}"
    else
        echo -e "${RED}❌ Nginx: Unhealthy${NC}"
    fi
}

# Function to show logs
show_logs() {
    echo -e "${BLUE}📋 Recent Logs${NC}"
    echo -e "${BLUE}==============${NC}"
    
    echo -e "${YELLOW}🐳 Docker Logs (last 20 lines):${NC}"
    docker-compose logs --tail=20
    
    echo ""
    
    if [ -f "$LOG_DIR/app.log" ]; then
        echo -e "${YELLOW}📝 Application Logs (last 20 lines):${NC}"
        tail -20 "$LOG_DIR/app.log"
    fi
    
    echo ""
    
    echo -e "${YELLOW}🌐 Nginx Access Logs (last 10 lines):${NC}"
    if [ -f "/var/log/nginx/access.log" ]; then
        sudo tail -10 /var/log/nginx/access.log
    else
        echo "Nginx access log not found"
    fi
}

# Function to show health details
show_health() {
    echo -e "${BLUE}🏥 Detailed Health Check${NC}"
    echo -e "${BLUE}======================${NC}"
    
    # Backend health
    echo -e "${YELLOW}🔧 Backend Health:${NC}"
    if curl -f http://localhost/api/v1/health > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Backend is responding${NC}"
        curl -s http://localhost/api/v1/health | jq . 2>/dev/null || curl -s http://localhost/api/v1/health
    else
        echo -e "${RED}❌ Backend is not responding${NC}"
    fi
    
    echo ""
    
    # Frontend health
    echo -e "${YELLOW}🎨 Frontend Health:${NC}"
    if curl -f http://localhost > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Frontend is responding${NC}"
    else
        echo -e "${RED}❌ Frontend is not responding${NC}"
    fi
    
    echo ""
    
    # Container health
    echo -e "${YELLOW}🐳 Container Health:${NC}"
    docker-compose ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}"
}

# Function to show metrics
show_metrics() {
    echo -e "${BLUE}📈 Application Metrics${NC}"
    echo -e "${BLUE}====================${NC}"
    
    # Docker stats
    echo -e "${YELLOW}🐳 Container Statistics:${NC}"
    docker stats --no-stream --format "table {{.Container}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}\t{{.BlockIO}}"
    
    echo ""
    
    # Disk usage
    echo -e "${YELLOW}💾 Disk Usage:${NC}"
    df -h
    
    echo ""
    
    # Memory usage
    echo -e "${YELLOW}🧠 Memory Usage:${NC}"
    free -h
    
    echo ""
    
    # Network connections
    echo -e "${YELLOW}🌐 Network Connections:${NC}"
    netstat -tuln | grep -E ':(80|443|8000|3000)' || echo "No active connections on monitored ports"
}

# Function to cleanup
cleanup() {
    echo -e "${BLUE}🧹 Cleanup Operations${NC}"
    echo -e "${BLUE}====================${NC}"
    
    # Clean Docker
    echo -e "${YELLOW}🐳 Cleaning Docker...${NC}"
    docker system prune -f
    docker volume prune -f
    
    # Clean logs
    echo -e "${YELLOW}📝 Cleaning old logs...${NC}"
    find "$LOG_DIR" -name "*.log" -mtime +7 -delete 2>/dev/null || true
    
    # Clean backups
    echo -e "${YELLOW}💾 Cleaning old backups...${NC}"
    find "$BACKUP_DIR" -name "*.tar.gz" -mtime +30 -delete 2>/dev/null || true
    
    echo -e "${GREEN}✅ Cleanup completed${NC}"
}

# Function to show help
show_help() {
    echo -e "${BLUE}📖 Monitoring Script Help${NC}"
    echo -e "${BLUE}========================${NC}"
    echo ""
    echo "Usage: ./monitoring.sh [command]"
    echo ""
    echo "Commands:"
    echo "  status   - Show application status and health"
    echo "  logs     - Show recent logs"
    echo "  health   - Detailed health check"
    echo "  metrics  - Show system metrics"
    echo "  cleanup  - Clean up old files and containers"
    echo "  help     - Show this help message"
    echo ""
    echo "Examples:"
    echo "  ./monitoring.sh status"
    echo "  ./monitoring.sh logs"
    echo "  ./monitoring.sh health"
}

# Main function
main() {
    case "${1:-status}" in
        "status")
            show_status
            ;;
        "logs")
            show_logs
            ;;
        "health")
            show_health
            ;;
        "metrics")
            show_metrics
            ;;
        "cleanup")
            cleanup
            ;;
        "help"|"-h"|"--help")
            show_help
            ;;
        *)
            echo -e "${RED}❌ Unknown command: $1${NC}"
            show_help
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
