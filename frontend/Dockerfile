FROM node:18-alpine

# Встановлення робочої директорії
WORKDIR /app

# Копіювання файлів залежностей
COPY package*.json ./

# Встановлення залежностей
RUN npm install

# Копіювання коду додатку
COPY . .

# Відкриття порту
EXPOSE 3000

# Команда запуску
CMD ["npm", "start"]
