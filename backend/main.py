#!/usr/bin/env python3
"""
Twitter Analyzer - Main Application Entry Point
"""

import os
import logging
from contextlib import asynccontextmanager
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.middleware.trustedhost import TrustedHostMiddleware
from fastapi.responses import JSONResponse
from pydantic import BaseSettings

from app.api.routes import twitter, health
from app.services.twitter_scraper import TwitterScraper
from app.services.gpt_service import GPTService
from app.utils.logger import setup_logging

# Налаштування логування
setup_logging()
logger = logging.getLogger(__name__)

class Settings(BaseSettings):
    """Налаштування додатку"""
    app_name: str = "Twitter Analyzer"
    version: str = "1.0.0"
    debug: bool = False
    host: str = "0.0.0.0"
    port: int = 8000
    
    # OpenAI налаштування
    openai_api_key: str
    openai_model: str = "gpt-4o-mini"
    openai_max_tokens: int = 500
    openai_temperature: float = 0.7
    
    # CORS налаштування
    cors_origins: str = "http://localhost:3000"
    
    # Rate limiting
    rate_limit: str = "100/hour"
    
    class Config:
        env_file = ".env"
        case_sensitive = False

settings = Settings()

@asynccontextmanager
async def lifespan(app: FastAPI):
    """Життєвий цикл додатку"""
    # Startup
    logger.info("Starting Twitter Analyzer application...")
    
    # Ініціалізація сервісів
    app.state.twitter_scraper = TwitterScraper()
    app.state.gpt_service = GPTService(
        api_key=settings.openai_api_key,
        model=settings.openai_model,
        max_tokens=settings.openai_max_tokens,
        temperature=settings.openai_temperature
    )
    
    logger.info("Application startup completed")
    
    yield
    
    # Shutdown
    logger.info("Shutting down Twitter Analyzer application...")

# Створення FastAPI додатку
app = FastAPI(
    title=settings.app_name,
    version=settings.version,
    description="Додаток для аналізу Twitter-постів та генерації коментарів",
    docs_url="/docs" if settings.debug else None,
    redoc_url="/redoc" if settings.debug else None,
    lifespan=lifespan
)

# Налаштування middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins.split(","),
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.add_middleware(
    TrustedHostMiddleware,
    allowed_hosts=["*"]  # В продакшні вкажіть конкретні хости
)

# Підключення роутів
app.include_router(health.router, prefix="/api/v1", tags=["health"])
app.include_router(twitter.router, prefix="/api/v1", tags=["twitter"])

@app.exception_handler(Exception)
async def global_exception_handler(request, exc):
    """Глобальний обробник помилок"""
    logger.error(f"Unhandled exception: {exc}", exc_info=True)
    return JSONResponse(
        status_code=500,
        content={"detail": "Internal server error", "status": "error"}
    )

@app.get("/")
async def root():
    """Кореневий endpoint"""
    return {
        "message": "Twitter Analyzer API",
        "version": settings.version,
        "status": "running"
    }

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(
        "main:app",
        host=settings.host,
        port=settings.port,
        reload=settings.debug,
        log_level="info"
    )
