"""
Twitter Analysis Routes
"""

from fastapi import APIRouter, Request, HTTPException
from fastapi.responses import JSONResponse
from pydantic import BaseModel, HttpUrl
from typing import List, Dict, Any, Optional
import logging
import time

from app.services.twitter_scraper import TwitterPost
from app.services.gpt_service import CommentRequest, CommentResponse

logger = logging.getLogger(__name__)
router = APIRouter()

class AnalyzeRequest(BaseModel):
    """Модель запиту для аналізу Twitter-посту"""
    twitter_url: HttpUrl
    comment_count: Optional[int] = 5

class AnalyzeResponse(BaseModel):
    """Модель відповіді з результатами аналізу"""
    post: Dict[str, Any]
    comments: List[str]
    analysis: Dict[str, Any]
    processing_time: float
    status: str

@router.post("/analyze")
async def analyze_twitter_post(request: AnalyzeRequest, app_request: Request):
    """Аналіз Twitter-посту та генерація коментарів"""
    start_time = time.time()
    
    try:
        logger.info(f"Starting analysis of Twitter post: {request.twitter_url}")
        
        # Перевірка доступності сервісів
        if not hasattr(app_request.app.state, 'twitter_scraper'):
            raise HTTPException(status_code=500, detail="Twitter scraper not available")
        
        if not hasattr(app_request.app.state, 'gpt_service'):
            raise HTTPException(status_code=500, detail="GPT service not available")
        
        # Парсинг Twitter-посту
        twitter_scraper = app_request.app.state.twitter_scraper
        post = await twitter_scraper.scrape_post(str(request.twitter_url))
        
        if not post:
            raise HTTPException(status_code=400, detail="Failed to scrape Twitter post")
        
        # Підготовка даних для GPT
        gpt_request = CommentRequest(
            post_text=post.text,
            author=post.author,
            comment_count=request.comment_count,
            engagement_stats={
                "likes": post.likes_count,
                "retweets": post.retweets_count,
                "replies": post.replies_count
            }
        )
        
        # Додавання інформації про медіа
        if post.images:
            gpt_request.images_description = f"Пост містить {len(post.images)} зображень"
        
        if post.video_url:
            gpt_request.video_description = "Пост містить відео"
        
        # Генерація коментарів
        gpt_service = app_request.app.state.gpt_service
        comment_response = await gpt_service.generate_comments(gpt_request)
        
        # Формування відповіді
        processing_time = time.time() - start_time
        
        response_data = {
            "post": {
                "url": str(post.url),
                "text": post.text,
                "author": post.author,
                "images": post.images,
                "video_url": post.video_url,
                "engagement": {
                    "likes": post.likes_count,
                    "retweets": post.retweets_count,
                    "replies": post.replies_count
                }
            },
            "comments": comment_response.comments,
            "analysis": comment_response.analysis,
            "processing_time": round(processing_time, 2),
            "status": "success"
        }
        
        logger.info(f"Analysis completed in {processing_time:.2f}s")
        
        return AnalyzeResponse(**response_data)
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error analyzing Twitter post: {e}")
        processing_time = time.time() - start_time
        
        return JSONResponse(
            status_code=500,
            content={
                "status": "error",
                "error": str(e),
                "processing_time": round(processing_time, 2)
            }
        )

@router.get("/post/{post_id}")
async def get_post_info(post_id: str, app_request: Request):
    """Отримання інформації про Twitter-пост"""
    try:
        # Формування URL з ID посту
        twitter_url = f"https://twitter.com/i/status/{post_id}"
        
        if not hasattr(app_request.app.state, 'twitter_scraper'):
            raise HTTPException(status_code=500, detail="Twitter scraper not available")
        
        twitter_scraper = app_request.app.state.twitter_scraper
        post = await twitter_scraper.scrape_post(twitter_url)
        
        if not post:
            raise HTTPException(status_code=404, detail="Post not found")
        
        return {
            "post_id": post_id,
            "url": str(post.url),
            "text": post.text,
            "author": post.author,
            "images": post.images,
            "video_url": post.video_url,
            "engagement": {
                "likes": post.likes_count,
                "retweets": post.retweets_count,
                "replies": post.replies_count
            }
        }
        
    except HTTPException:
        raise
    except Exception as e:
        logger.error(f"Error getting post info: {e}")
        raise HTTPException(status_code=500, detail=str(e))

@router.post("/validate-url")
async def validate_twitter_url(request: AnalyzeRequest, app_request: Request):
    """Валідація Twitter URL"""
    try:
        if not hasattr(app_request.app.state, 'twitter_scraper'):
            raise HTTPException(status_code=500, detail="Twitter scraper not available")
        
        twitter_scraper = app_request.app.state.twitter_scraper
        is_valid = twitter_scraper.validate_twitter_url(str(request.twitter_url))
        
        return {
            "url": str(request.twitter_url),
            "is_valid": is_valid,
            "status": "success"
        }
        
    except Exception as e:
        logger.error(f"Error validating URL: {e}")
        return JSONResponse(
            status_code=500,
            content={
                "status": "error",
                "error": str(e)
            }
        )

@router.get("/metrics")
async def get_metrics():
    """Отримання метрик сервера"""
    return {
        "requests_total": 0,  # TODO: Implement metrics collection
        "requests_per_minute": 0,
        "average_response_time": 0,
        "error_rate": 0,
        "uptime": time.time()
    }
