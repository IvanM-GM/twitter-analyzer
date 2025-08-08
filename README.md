# Twitter Analyzer

Аналізатор Twitter постів з використанням штучного інтелекту для аналізу настроїв та контенту.

## 🚀 Швидкий старт

### Для локальної розробки

```bash
# Клонування репозиторію
git clone <repository-url>
cd twitter-analyzer

# Встановлення залежностей
make install

# Запуск додатку
make run
```

### Для Linux сервера

```bash
# Клонування репозиторію
git clone <repository-url>
cd twitter-analyzer

# Налаштування сервера
./setup-server.sh

# Перевірка системи
./check-system.sh

# Налаштування змінних середовища
cp env_example.txt .env
nano .env

# Deployment
./deploy.sh production
```

## 📋 Вимоги

### Локальна розробка
- Python 3.11+
- Node.js 18+
- Docker та Docker Compose

### Linux сервер
- Ubuntu 20.04+, CentOS 7+, або Debian 10+
- Мінімум 2GB RAM
- Мінімум 10GB вільного місця

## 🏗️ Архітектура

```
twitter-analyzer/
├── backend/                 # Python FastAPI backend
│   ├── app/
│   │   ├── api/            # API endpoints
│   │   ├── services/       # Business logic
│   │   └── utils/          # Utilities
│   ├── Dockerfile          # Backend container
│   └── requirements.txt    # Python dependencies
├── frontend/               # React frontend
│   ├── src/
│   │   ├── components/     # React components
│   │   └── services/       # API services
│   ├── Dockerfile          # Frontend container
│   └── package.json        # Node.js dependencies
├── docker-compose.yml      # Development setup
├── docker-compose.production.yml  # Production setup
├── deploy.sh              # Deployment script
├── setup-server.sh        # Server setup script
├── monitoring.sh          # Monitoring script
├── check-system.sh        # System check script
└── README_LINUX.md        # Linux deployment guide
```

## 🔧 Налаштування

### Змінні середовища

Створіть файл `.env` на основі `env_example.txt`:

```bash
# OpenAI Configuration
OPENAI_API_KEY=your_openai_api_key_here
OPENAI_MODEL=gpt-4o-mini

# Security
SECRET_KEY=your_secret_key_here
JWT_SECRET_KEY=your_jwt_secret_key_here

# CORS
CORS_ORIGINS=https://your-domain.com

# API URL
REACT_APP_API_URL=https://your-domain.com/api/v1
```

## 🚀 Deployment

### Локальний запуск

```bash
# Development
make run

# Docker
make docker-run

# Production
make deploy-production
```

### Linux сервер

```bash
# Налаштування сервера
make setup-linux

# Перевірка системи
make check-system

# Deployment
make deploy-linux

# Моніторинг
make monitor
```

## 📊 Моніторинг

### Основні команди

```bash
# Статус додатку
make monitor

# Логи
make monitor-logs

# Health check
make monitor-health

# Системні метрики
make monitor-metrics

# Очищення
make cleanup
```

### Детальний моніторинг

```bash
# Перегляд логів в реальному часі
docker-compose logs -f

# Статус контейнерів
docker-compose ps

# Системні ресурси
./monitoring.sh metrics
```

## 🛠️ Розробка

### Команди для розробки

```bash
# Встановлення залежностей
make install

# Тестування
make test

# Лінтінг
make lint

# Форматування коду
make format

# Документація
make docs
```

### Структура проекту

- **Backend**: FastAPI з Python
- **Frontend**: React з TypeScript
- **База даних**: PostgreSQL (опціонально)
- **Кеш**: Redis
- **Проксі**: Nginx
- **Контейнеризація**: Docker

## 🔒 Безпека

### Production налаштування

- SSL сертифікати (Let's Encrypt)
- Firewall (UFW/firewalld)
- Rate limiting
- Security headers
- Input validation

### Моніторинг безпеки

```bash
# Перевірка безпеки
make security-check

# Аудит залежностей
npm audit
pip-audit
```

## 📈 Масштабування

### Горизонтальне масштабування

```bash
# Збільшення кількості воркерів
docker-compose up --scale backend=3

# Load balancer
# Додайте nginx з upstream
```

### Вертикальне масштабування

```bash
# Збільшення ресурсів в docker-compose.production.yml
services:
  backend:
    deploy:
      resources:
        limits:
          memory: 2G
          cpus: '2'
```

## 🐛 Вирішення проблем

### Загальні проблеми

1. **Додаток не запускається**
   ```bash
   ./monitoring.sh logs
   ./deploy.sh production
   ```

2. **Проблеми з пам'яттю**
   ```bash
   ./monitoring.sh metrics
   ./monitoring.sh cleanup
   ```

3. **Проблеми з мережею**
   ```bash
   netstat -tuln | grep -E ':(80|443|8000|3000)'
   sudo ufw status
   ```

### Логи та діагностика

```bash
# Логи додатку
tail -f logs/app.log

# Логи Docker
docker-compose logs -f backend

# Логи Nginx
sudo tail -f /var/log/nginx/error.log
```

## 📚 Документація

- [Linux Deployment Guide](README_LINUX.md) - Детальний гід для Linux сервера
- [Quick Start Linux](QUICK_START_LINUX.md) - Швидкий старт для Linux
- [Архітектурні схеми](Архітектурні_схеми.md) - Архітектура системи
- [Технічне завдання](Технічне_завдання_Twitter_аналіз.md) - Детальні вимоги

## 🤝 Внесок

1. Fork репозиторію
2. Створіть feature branch (`git checkout -b feature/amazing-feature`)
3. Commit зміни (`git commit -m 'Add amazing feature'`)
4. Push до branch (`git push origin feature/amazing-feature`)
5. Відкрийте Pull Request

## 📄 Ліцензія

Цей проект ліцензований під MIT License - дивіться файл [LICENSE](LICENSE) для деталей.

## 📞 Підтримка

Якщо у вас виникли питання або проблеми:

1. Перевірте [документацію](README_LINUX.md)
2. Перегляньте [логі](QUICK_START_LINUX.md#вирішення-проблем)
3. Створіть [issue](https://github.com/your-repo/issues)

## 🎯 Roadmap

- [ ] Додавання бази даних PostgreSQL
- [ ] Інтеграція з Prometheus/Grafana
- [ ] CI/CD pipeline
- [ ] Мобільний додаток
- [ ] API для сторонніх розробників
