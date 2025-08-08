FROM python:3.11-slim

# Встановлення системних залежностей
RUN apt-get update && apt-get install -y \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Встановлення робочої директорії
WORKDIR /app

# Копіювання файлів залежностей
COPY requirements.txt .

# Встановлення Python залежностей
RUN pip install --no-cache-dir -r requirements.txt

# Копіювання коду додатку
COPY . .

# Створення директорії для логів
RUN mkdir -p logs

# Відкриття порту
EXPOSE 8000

# Команда запуску
CMD ["python", "main.py"]
