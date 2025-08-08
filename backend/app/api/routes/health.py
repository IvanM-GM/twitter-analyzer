"""
Health Check Routes
"""

from fastapi import APIRouter, Request
from fastapi.responses import JSONResponse
import logging
import time

logger = logging.getLogger(__name__)
router = APIRouter()

@router.get("/health")
async def health_check(request: Request):
    """Перевірка здоров'я сервера"""
    try:
        # Перевірка доступності сервісів
        services_status = {
            "twitter_scraper": "unknown",
            "gpt_service": "unknown"
        }
        
        # Перевірка Twitter scraper
        if hasattr(request.app.state, 'twitter_scraper'):
            services_status["twitter_scraper"] = "available"
        
        # Перевірка GPT service
        if hasattr(request.app.state, 'gpt_service'):
            try:
                is_connected = await request.app.state.gpt_service.test_connection()
                services_status["gpt_service"] = "connected" if is_connected else "disconnected"
            except Exception as e:
                logger.error(f"GPT service check failed: {e}")
                services_status["gpt_service"] = "error"
        
        return {
            "status": "healthy",
            "timestamp": time.time(),
            "services": services_status,
            "version": "1.0.0"
        }
        
    except Exception as e:
        logger.error(f"Health check failed: {e}")
        return JSONResponse(
            status_code=500,
            content={
                "status": "unhealthy",
                "error": str(e),
                "timestamp": time.time()
            }
        )

@router.get("/status")
async def status_check():
    """Детальний статус сервера"""
    return {
        "status": "running",
        "uptime": time.time(),
        "version": "1.0.0",
        "environment": "development"
    }
