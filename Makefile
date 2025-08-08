# Twitter Analyzer Makefile
SHELL := /bin/bash

.PHONY: help install test run clean docker-build docker-run

# Default target
help:
	@echo "Twitter Analyzer - Makefile"
	@echo ""
	@echo "Available commands:"
	@echo "  install     - Install all dependencies"
	@echo "  test        - Run all tests"
	@echo "  test-coverage - Run tests with coverage"
	@echo "  run         - Run the application"
	@echo "  run-backend - Run only backend"
	@echo "  run-frontend - Run only frontend"
	@echo "  clean       - Clean build artifacts"
	@echo "  docker-build - Build Docker containers"
	@echo "  docker-run  - Run with Docker Compose"
	@echo "  lint        - Run linting"
	@echo "  format      - Format code"
	@echo "  docs        - Generate documentation"
	@echo ""
	@echo "Linux Server Deployment:"
	@echo "  setup-linux - Setup Linux server with dependencies"
	@echo "  deploy-linux - Deploy to Linux server"
	@echo "  monitor     - Monitor application status"
	@echo "  monitor-logs - Show application logs"
	@echo "  monitor-health - Check application health"
	@echo "  monitor-metrics - Show system metrics"
	@echo "  cleanup     - Clean up old files"
	@echo "  check-system - Check system requirements"

# Installation
install: install-backend install-frontend

install-backend:
	@echo "Installing backend dependencies..."
	cd backend && python -m venv venv && \
	source venv/bin/activate && \
	pip install -r requirements.txt

install-frontend:
	@echo "Installing frontend dependencies..."
	cd frontend && npm install

# Testing
test: test-backend test-frontend

test-backend:
	@echo "Running backend tests..."
	cd backend && python -m pytest tests/ -v

test-frontend:
	@echo "Running frontend tests..."
	cd frontend && npm test -- --watchAll=false

test-coverage:
	@echo "Running tests with coverage..."
	cd backend && python -m pytest tests/ --cov=services --cov-report=html
	cd frontend && npm test -- --coverage --watchAll=false

# Running
run: run-backend run-frontend

run-backend:
	@echo "Starting backend server..."
	cd backend && python main.py

run-frontend:
	@echo "Starting frontend development server..."
	cd frontend && npm start

# Docker
docker-build:
	@echo "Building Docker containers..."
	docker-compose build

docker-run:
	@echo "Running with Docker Compose..."
	docker-compose up

docker-stop:
	@echo "Stopping Docker containers..."
	docker-compose down

# Code quality
lint: lint-backend lint-frontend

lint-backend:
	@echo "Linting backend code..."
	cd backend && flake8 services/ tests/ main.py
	cd backend && black --check services/ tests/ main.py

lint-frontend:
	@echo "Linting frontend code..."
	cd frontend && npm run lint

format: format-backend format-frontend

format-backend:
	@echo "Formatting backend code..."
	cd backend && black services/ tests/ main.py
	cd backend && isort services/ tests/ main.py

format-frontend:
	@echo "Formatting frontend code..."
	cd frontend && npm run format

# Documentation
docs:
	@echo "Generating documentation..."
	cd backend && pydoc-markdown --output docs/api.md
	@echo "Documentation generated in docs/api.md"

# Cleaning
clean:
	@echo "Cleaning build artifacts..."
	find . -type f -name "*.pyc" -delete
	find . -type d -name "__pycache__" -delete
	find . -type d -name "*.egg-info" -exec rm -rf {} +
	rm -rf backend/venv
	rm -rf frontend/node_modules
	rm -rf frontend/build
	rm -rf .coverage
	rm -rf htmlcov

# Development helpers
setup-dev: install
	@echo "Setting up development environment..."
	cp env_example.txt .env
	@echo "Please edit .env file with your configuration"

check-env:
	@echo "Checking environment variables..."
	@if [ ! -f .env ]; then \
		echo "Error: .env file not found. Run 'make setup-dev' first."; \
		exit 1; \
	fi
	@echo "Environment file found."

# Database
db-migrate:
	@echo "Running database migrations..."
	cd backend && alembic upgrade head

db-rollback:
	@echo "Rolling back database..."
	cd backend && alembic downgrade -1

# Monitoring
logs:
	@echo "Showing application logs..."
	tail -f logs/app.log

metrics:
	@echo "Showing application metrics..."
	curl http://localhost:8000/api/v1/metrics

health:
	@echo "Checking application health..."
	curl http://localhost:8000/api/v1/health

# Security
security-check:
	@echo "Running security checks..."
	cd backend && bandit -r services/
	cd frontend && npm audit

# Performance
benchmark:
	@echo "Running performance benchmarks..."
	cd backend && python -m pytest tests/test_performance.py -v

# Deployment
deploy-staging:
	@echo "Deploying to staging..."
	docker-compose -f docker-compose.staging.yml up -d

deploy-production:
	@echo "Deploying to production..."
	docker-compose -f docker-compose.production.yml up -d

deploy-linux:
	@echo "Deploying to Linux server..."
	./deploy.sh production

setup-linux:
	@echo "Setting up Linux server..."
	./setup-server.sh

monitor:
	@echo "Monitoring application..."
	./monitoring.sh status

monitor-logs:
	@echo "Showing application logs..."
	./monitoring.sh logs

monitor-health:
	@echo "Checking application health..."
	./monitoring.sh health

monitor-metrics:
	@echo "Showing system metrics..."
	./monitoring.sh metrics

cleanup:
	@echo "Cleaning up old files..."
	./monitoring.sh cleanup

check-system:
	@echo "Checking system requirements..."
	./check-system.sh

# Backup
backup:
	@echo "Creating backup..."
	tar -czf backup-$(shell date +%Y%m%d-%H%M%S).tar.gz \
		--exclude=node_modules \
		--exclude=venv \
		--exclude=.git \
		.

# Quick start
quick-start: setup-dev check-env run
	@echo "Application started! Visit http://localhost:3000"

# Help for specific targets
help-backend:
	@echo "Backend specific commands:"
	@echo "  install-backend - Install Python dependencies"
	@echo "  test-backend   - Run Python tests"
	@echo "  run-backend    - Start FastAPI server"
	@echo "  lint-backend   - Lint Python code"
	@echo "  format-backend - Format Python code"

help-frontend:
	@echo "Frontend specific commands:"
	@echo "  install-frontend - Install Node.js dependencies"
	@echo "  test-frontend   - Run React tests"
	@echo "  run-frontend    - Start React dev server"
	@echo "  lint-frontend   - Lint JavaScript code"
	@echo "  format-frontend - Format JavaScript code"

help-docker:
	@echo "Docker commands:"
	@echo "  docker-build - Build containers"
	@echo "  docker-run   - Start with Docker Compose"
	@echo "  docker-stop  - Stop containers"

# Environment specific
dev: check-env
	@echo "Starting development environment..."
	docker-compose -f docker-compose.dev.yml up

prod: check-env
	@echo "Starting production environment..."
	docker-compose -f docker-compose.prod.yml up -d

# Utility targets
status:
	@echo "Checking application status..."
	@echo "Backend: $(shell curl -s http://localhost:8000/api/v1/health | grep -o '"status":"[^"]*"' || echo "Not running")"
	@echo "Frontend: $(shell curl -s http://localhost:3000 > /dev/null && echo "Running" || echo "Not running")"

restart: docker-stop docker-run
	@echo "Application restarted"

update: git-pull install
	@echo "Application updated"

git-pull:
	@echo "Pulling latest changes..."
	git pull origin main

# Development workflow
dev-workflow: format lint test
	@echo "Development workflow completed"

# CI/CD helpers
ci-install: install-backend install-frontend
	@echo "CI installation completed"

ci-test: test-backend test-frontend
	@echo "CI tests completed"

ci-build: docker-build
	@echo "CI build completed"

# Show current configuration
config:
	@echo "Current configuration:"
	@echo "Python version: $(shell python --version)"
	@echo "Node version: $(shell node --version)"
	@echo "NPM version: $(shell npm --version)"
	@echo "Docker version: $(shell docker --version)"
	@echo "Docker Compose version: $(shell docker-compose --version)"
