"""
Logging Configuration
"""

import logging
import logging.handlers
import os
import sys
from pathlib import Path

def setup_logging(
    log_level: str = "INFO",
    log_format: str = "json",
    log_file: str = "logs/app.log"
):
    """Налаштування логування"""
    
    # Створення директорії для логів
    log_dir = Path(log_file).parent
    log_dir.mkdir(parents=True, exist_ok=True)
    
    # Налаштування рівня логування
    numeric_level = getattr(logging, log_level.upper(), logging.INFO)
    
    # Форматування логів
    if log_format.lower() == "json":
        formatter = logging.Formatter(
            '{"timestamp": "%(asctime)s", "level": "%(levelname)s", "module": "%(name)s", "message": "%(message)s"}'
        )
    else:
        formatter = logging.Formatter(
            '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
        )
    
    # Налаштування кореневого логера
    root_logger = logging.getLogger()
    root_logger.setLevel(numeric_level)
    
    # Очищення існуючих хендлерів
    for handler in root_logger.handlers[:]:
        root_logger.removeHandler(handler)
    
    # Консольний хендлер
    console_handler = logging.StreamHandler(sys.stdout)
    console_handler.setFormatter(formatter)
    root_logger.addHandler(console_handler)
    
    # Файловий хендлер з ротацією
    file_handler = logging.handlers.RotatingFileHandler(
        log_file,
        maxBytes=10*1024*1024,  # 10MB
        backupCount=5
    )
    file_handler.setFormatter(formatter)
    root_logger.addHandler(file_handler)
    
    # Налаштування логерів для зовнішніх бібліотек
    logging.getLogger("httpx").setLevel(logging.WARNING)
    logging.getLogger("urllib3").setLevel(logging.WARNING)
    logging.getLogger("openai").setLevel(logging.WARNING)
    
    # Логування початку роботи
    logger = logging.getLogger(__name__)
    logger.info("Logging system initialized")

def get_logger(name: str) -> logging.Logger:
    """Отримання логера з вказаним ім'ям"""
    return logging.getLogger(name)
