# 🚀 Швидкий старт для Linux сервера

Цей гід допоможе вам швидко розгорнути Twitter Analyzer на Linux сервері.

## 📋 Передумови

- Linux сервер (Ubuntu 20.04+, CentOS 7+, або Debian 10+)
- SSH доступ до сервера
- Мінімум 2GB RAM та 10GB вільного місця

## ⚡ Швидкий старт (5 хвилин)

### 1. Підключення до сервера
```bash
ssh user@your-server-ip
```

### 2. Завантаження проекту
```bash
git clone <your-repository-url>
cd twitter-analyzer
```

### 3. Автоматичне налаштування
```bash
# Зробіть скрипти виконуваними
chmod +x setup-server.sh deploy.sh monitoring.sh

# Запустіть налаштування сервера
./setup-server.sh
```

### 4. Налаштування змінних середовища
```bash
# Створіть .env файл
cp env_example.txt .env

# Відредагуйте .env файл
nano .env
```

**Обов'язкові змінні в .env:**
```bash
OPENAI_API_KEY=your_openai_api_key_here
SECRET_KEY=your_secret_key_here
JWT_SECRET_KEY=your_jwt_secret_key_here
CORS_ORIGINS=https://your-domain.com
REACT_APP_API_URL=https://your-domain.com/api/v1
```

### 5. Запуск додатку
```bash
# Запустіть в production режимі
./deploy.sh production

# Або використовуйте systemd сервіс
sudo systemctl start twitter-analyzer
sudo systemctl enable twitter-analyzer
```

### 6. Перевірка роботи
```bash
# Перевірте статус
./monitoring.sh status

# Перевірте логи
./monitoring.sh logs

# Health check
curl http://localhost/api/v1/health
```

## 🌐 Доступ до додатку

Після успішного deployment додаток буде доступний:
- **HTTP**: http://your-server-ip
- **HTTPS**: https://your-domain.com (якщо налаштований SSL)

## 📊 Моніторинг

### Основні команди
```bash
./monitoring.sh status      # Статус додатку
./monitoring.sh logs        # Логи
./monitoring.sh health      # Health check
./monitoring.sh metrics     # Системні метрики
./monitoring.sh cleanup     # Очищення
```

### Перегляд логів в реальному часі
```bash
# Логи всіх контейнерів
docker-compose logs -f

# Логи конкретного сервісу
docker-compose logs -f backend
docker-compose logs -f frontend
```

## 🔧 Керування додатком

### Запуск/зупинка
```bash
# Запуск
sudo systemctl start twitter-analyzer
./deploy.sh production

# Зупинка
sudo systemctl stop twitter-analyzer
docker-compose down

# Перезапуск
sudo systemctl restart twitter-analyzer
./deploy.sh production
```

### Оновлення
```bash
# Отримання останніх змін
git pull origin main

# Перезапуск з оновленнями
./deploy.sh production
```

## 🛠️ Вирішення проблем

### Додаток не запускається
```bash
# Перевірте логи
./monitoring.sh logs

# Перевірте статус контейнерів
docker-compose ps

# Перезапустіть
./deploy.sh production
```

### Проблеми з пам'яттю
```bash
# Перевірте використання ресурсів
./monitoring.sh metrics

# Очистіть невикористовувані ресурси
./monitoring.sh cleanup
```

### Проблеми з мережею
```bash
# Перевірте порти
netstat -tuln | grep -E ':(80|443|8000|3000)'

# Перевірте firewall
sudo ufw status
```

## 🔒 Безпека

### Firewall
```bash
# Перевірте статус
sudo ufw status

# Додайте ваш IP для SSH
sudo ufw allow from your-ip-address to any port 22
```

### SSL сертифікати
```bash
# Встановіть certbot
sudo apt-get install certbot python3-certbot-nginx

# Отримайте сертифікат
sudo certbot --nginx -d your-domain.com
```

## 📈 Масштабування

### Збільшення ресурсів
```bash
# Оновіть docker-compose.production.yml
# Збільшіть limits для контейнерів
```

### Додавання моніторингу
```bash
# Додайте Prometheus та Grafana до docker-compose.production.yml
# Дивіться README_LINUX.md для деталей
```

## 📞 Підтримка

Якщо виникли проблеми:

1. **Перевірте логи**: `./monitoring.sh logs`
2. **Перевірте статус**: `./monitoring.sh status`
3. **Health check**: `./monitoring.sh health`
4. **Перезапустіть**: `./deploy.sh production`

## 📝 Корисні команди

```bash
# Швидкі команди
make help                    # Показати всі команди
make deploy-linux           # Deploy на Linux
make monitor                # Моніторинг
make monitor-logs           # Логи
make monitor-health         # Health check

# Docker команди
docker-compose ps           # Статус контейнерів
docker-compose logs -f      # Логи в реальному часі
docker-compose down         # Зупинити контейнери
docker-compose up -d        # Запустити контейнери

# Системні команди
sudo systemctl status twitter-analyzer
sudo systemctl restart twitter-analyzer
sudo journalctl -u twitter-analyzer -f
```

## 🎯 Наступні кроки

1. **Налаштуйте домен** та SSL сертифікати
2. **Додайте моніторинг** (Prometheus + Grafana)
3. **Налаштуйте backup** стратегію
4. **Налаштуйте CI/CD** (GitHub Actions)
5. **Додайте базу даних** (PostgreSQL)

Дивіться `README_LINUX.md` для детальних інструкцій.
