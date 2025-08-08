# Twitter Analyzer - Linux Server Deployment Guide

Цей гід допоможе вам розгорнути Twitter Analyzer на Linux сервері.

## 📋 Вимоги

- Linux сервер (Ubuntu 20.04+, CentOS 7+, або Debian 10+)
- Мінімум 2GB RAM
- Мінімум 10GB вільного місця
- Доступ до інтернету
- SSH доступ до сервера

## 🚀 Швидкий старт

### 1. Підготовка сервера

```bash
# Завантажте проект на сервер
git clone <your-repository-url>
cd twitter-analyzer

# Зробіть скрипти виконуваними
chmod +x setup-server.sh
chmod +x deploy.sh

# Запустіть налаштування сервера
./setup-server.sh
```

### 2. Налаштування змінних середовища

```bash
# Створіть файл .env
cp env_example.txt .env

# Відредагуйте .env файл
nano .env
```

**Обов'язкові змінні:**
```bash
OPENAI_API_KEY=your_openai_api_key_here
SECRET_KEY=your_secret_key_here
JWT_SECRET_KEY=your_jwt_secret_key_here
CORS_ORIGINS=https://your-domain.com
REACT_APP_API_URL=https://your-domain.com/api/v1
```

### 3. Запуск додатку

```bash
# Запустіть в production режимі
./deploy.sh production

# Або використовуйте systemd сервіс
sudo systemctl start twitter-analyzer
sudo systemctl enable twitter-analyzer
```

## 📁 Структура файлів

```
twitter-analyzer/
├── backend/                 # Python FastAPI backend
├── frontend/               # React frontend
├── docker-compose.yml      # Development configuration
├── docker-compose.production.yml  # Production configuration
├── deploy.sh              # Deployment script
├── setup-server.sh        # Server setup script
├── nginx.production.conf  # Nginx configuration
├── .env                   # Environment variables
└── logs/                  # Application logs
```

## 🔧 Детальна інструкція

### Крок 1: Підключення до сервера

```bash
ssh user@your-server-ip
```

### Крок 2: Встановлення залежностей

Скрипт `setup-server.sh` автоматично встановить:
- Docker та Docker Compose
- Nginx
- Firewall (UFW або firewalld)
- Системні пакети
- Systemd сервіс

### Крок 3: Налаштування домену

1. Налаштуйте DNS записи для вашого домену
2. Отримайте SSL сертифікати (Let's Encrypt)
3. Оновіть `nginx.production.conf` з вашим доменом

### Крок 4: Конфігурація

#### SSL сертифікати

Для production використовуйте Let's Encrypt:

```bash
# Встановіть certbot
sudo apt-get install certbot python3-certbot-nginx

# Отримайте сертифікат
sudo certbot --nginx -d your-domain.com

# Автоматичне оновлення
sudo crontab -e
# Додайте: 0 12 * * * /usr/bin/certbot renew --quiet
```

#### База даних (опціонально)

Для production рекомендується PostgreSQL:

```bash
# Додайте PostgreSQL до docker-compose.production.yml
postgres:
  image: postgres:13
  environment:
    POSTGRES_DB: twitter_analyzer
    POSTGRES_USER: user
    POSTGRES_PASSWORD: password
  volumes:
    - postgres_data:/var/lib/postgresql/data
```

### Крок 5: Моніторинг

#### Перевірка статусу

```bash
# Статус сервісів
sudo systemctl status twitter-analyzer
docker-compose ps

# Логи
docker-compose logs -f
tail -f logs/app.log

# Health check
curl https://your-domain.com/api/v1/health
```

#### Налаштування моніторингу

```bash
# Встановіть Prometheus та Grafana
# Додайте до docker-compose.production.yml:

prometheus:
  image: prom/prometheus
  ports:
    - "9090:9090"
  volumes:
    - ./prometheus.yml:/etc/prometheus/prometheus.yml

grafana:
  image: grafana/grafana
  ports:
    - "3001:3000"
  environment:
    - GF_SECURITY_ADMIN_PASSWORD=admin
```

## 🔒 Безпека

### Firewall

```bash
# Перевірте статус firewall
sudo ufw status

# Додайте додаткові правила якщо потрібно
sudo ufw allow from your-ip-address
```

### Оновлення

```bash
# Оновлення додатку
git pull origin main
./deploy.sh production

# Оновлення системи
sudo apt-get update && sudo apt-get upgrade -y
```

### Backup

```bash
# Створення backup
tar -czf backup-$(date +%Y%m%d).tar.gz \
    --exclude=node_modules \
    --exclude=venv \
    --exclude=.git \
    .

# Відновлення
tar -xzf backup-YYYYMMDD.tar.gz
```

## 🐛 Вирішення проблем

### Проблеми з Docker

```bash
# Перезапуск Docker
sudo systemctl restart docker

# Очищення Docker
docker system prune -a
```

### Проблеми з Nginx

```bash
# Перевірка конфігурації
sudo nginx -t

# Перезапуск Nginx
sudo systemctl restart nginx

# Перегляд логів
sudo tail -f /var/log/nginx/error.log
```

### Проблеми з пам'яттю

```bash
# Перевірка використання пам'яті
free -h
docker stats

# Очищення невикористовуваних ресурсів
docker system prune -a
```

## 📊 Моніторинг та логування

### Логи

```bash
# Логи додатку
tail -f logs/app.log

# Логи Docker
docker-compose logs -f backend
docker-compose logs -f frontend

# Логи Nginx
sudo tail -f /var/log/nginx/access.log
sudo tail -f /var/log/nginx/error.log
```

### Метрики

```bash
# Health check
curl https://your-domain.com/api/v1/health

# Метрики (якщо налаштовані)
curl https://your-domain.com/api/v1/metrics
```

## 🔄 CI/CD

### GitHub Actions

Створіть `.github/workflows/deploy.yml`:

```yaml
name: Deploy to Server

on:
  push:
    branches: [ main ]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v2
    
    - name: Deploy to server
      uses: appleboy/ssh-action@v0.1.4
      with:
        host: ${{ secrets.HOST }}
        username: ${{ secrets.USERNAME }}
        key: ${{ secrets.KEY }}
        script: |
          cd /opt/twitter-analyzer
          git pull origin main
          ./deploy.sh production
```

## 📞 Підтримка

Якщо виникли проблеми:

1. Перевірте логи: `docker-compose logs -f`
2. Перевірте статус сервісів: `sudo systemctl status twitter-analyzer`
3. Перевірте конфігурацію: `docker-compose config`
4. Перезапустіть сервіси: `sudo systemctl restart twitter-analyzer`

## 📝 Корисні команди

```bash
# Швидкі команди
make help                    # Показати всі команди
make status                  # Статус додатку
make logs                    # Показати логи
make restart                 # Перезапустити додаток

# Docker команди
docker-compose ps            # Статус контейнерів
docker-compose logs -f       # Логи в реальному часі
docker-compose down          # Зупинити контейнери
docker-compose up -d         # Запустити контейнери

# Системні команди
sudo systemctl status twitter-analyzer
sudo systemctl restart twitter-analyzer
sudo journalctl -u twitter-analyzer -f
```
