"""
Twitter Scraper Service
Парсинг Twitter-постів без використання офіційного API
"""

import re
import logging
import asyncio
from typing import Optional, Dict, List, Any
from urllib.parse import urlparse
import httpx
from bs4 import BeautifulSoup
from pydantic import BaseModel, HttpUrl

logger = logging.getLogger(__name__)

class TwitterPost(BaseModel):
    """Модель Twitter-посту"""
    url: HttpUrl
    text: str
    author: str
    timestamp: Optional[str] = None
    images: List[str] = []
    video_url: Optional[str] = None
    likes_count: Optional[int] = None
    retweets_count: Optional[int] = None
    replies_count: Optional[int] = None

class TwitterScraper:
    """Сервіс для парсингу Twitter-постів"""
    
    def __init__(self):
        self.session = httpx.AsyncClient(
            timeout=30.0,
            headers={
                "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36",
                "Accept": "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8",
                "Accept-Language": "en-US,en;q=0.5",
                "Accept-Encoding": "gzip, deflate",
                "Connection": "keep-alive",
                "Upgrade-Insecure-Requests": "1",
            },
            follow_redirects=True
        )
    
    async def __aenter__(self):
        return self
    
    async def __aexit__(self, exc_type, exc_val, exc_tb):
        await self.session.aclose()
    
    def validate_twitter_url(self, url: str) -> bool:
        """Валідація Twitter URL"""
        try:
            parsed = urlparse(url)
            if parsed.netloc not in ["twitter.com", "x.com", "www.twitter.com", "www.x.com"]:
                return False
            
            # Перевірка формату URL
            pattern = r"/([^/]+)/status/(\d+)"
            return bool(re.search(pattern, parsed.path))
        except Exception:
            return False
    
    async def scrape_post(self, url: str) -> Optional[TwitterPost]:
        """Парсинг Twitter-посту"""
        try:
            if not self.validate_twitter_url(url):
                raise ValueError("Invalid Twitter URL format")
            
            logger.info(f"Scraping Twitter post: {url}")
            
            # Отримання HTML сторінки
            response = await self.session.get(url)
            response.raise_for_status()
            
            soup = BeautifulSoup(response.text, 'html.parser')
            
            # Вилучення даних
            post_data = await self._extract_post_data(soup, url)
            
            if not post_data:
                raise ValueError("Could not extract post data")
            
            return TwitterPost(**post_data)
            
        except httpx.HTTPStatusError as e:
            logger.error(f"HTTP error while scraping {url}: {e}")
            raise ValueError(f"Failed to access Twitter post: {e}")
        except Exception as e:
            logger.error(f"Error scraping {url}: {e}")
            raise ValueError(f"Failed to scrape Twitter post: {e}")
    
    async def _extract_post_data(self, soup: BeautifulSoup, url: str) -> Optional[Dict[str, Any]]:
        """Вилучення даних з HTML"""
        try:
            # Базові дані
            post_data = {
                "url": url,
                "text": "",
                "author": "",
                "images": [],
                "video_url": None,
                "likes_count": None,
                "retweets_count": None,
                "replies_count": None
            }
            
            # Вилучення тексту посту
            # Спробуємо різні селектори для пошуку тексту
            text_selectors = [
                'div[data-testid="tweetText"]',
                'div[lang]',
                'p[dir="ltr"]',
                'div[data-text="true"]'
            ]
            
            for selector in text_selectors:
                text_elements = soup.select(selector)
                if text_elements:
                    # Беремо перший елемент з текстом
                    text_element = text_elements[0]
                    post_data["text"] = text_element.get_text(strip=True)
                    break
            
            # Вилучення автора
            author_selectors = [
                'a[data-testid="User-Name"]',
                'a[href^="/"]',
                'span[dir="ltr"]'
            ]
            
            for selector in author_selectors:
                author_elements = soup.select(selector)
                if author_elements:
                    # Шукаємо елемент з @username
                    for element in author_elements:
                        text = element.get_text(strip=True)
                        if text.startswith('@'):
                            post_data["author"] = text
                            break
                    if post_data["author"]:
                        break
            
            # Вилучення зображень
            image_selectors = [
                'img[alt*="Image"]',
                'img[src*="pbs.twimg.com"]',
                'img[data-testid="tweetPhoto"]'
            ]
            
            for selector in image_selectors:
                img_elements = soup.select(selector)
                for img in img_elements:
                    src = img.get('src')
                    if src and 'pbs.twimg.com' in src:
                        # Отримуємо повний URL зображення
                        if src.startswith('//'):
                            src = 'https:' + src
                        elif src.startswith('/'):
                            src = 'https://twitter.com' + src
                        post_data["images"].append(src)
            
            # Вилучення відео
            video_selectors = [
                'video[src]',
                'video source[src]'
            ]
            
            for selector in video_selectors:
                video_elements = soup.select(selector)
                if video_elements:
                    video_src = video_elements[0].get('src')
                    if video_src:
                        post_data["video_url"] = video_src
                    break
            
            # Вилучення статистики (лайки, ретвіти, коментарі)
            # Це може бути складніше через динамічний контент
            stats_selectors = {
                'likes': '[data-testid="like"]',
                'retweets': '[data-testid="retweet"]',
                'replies': '[data-testid="reply"]'
            }
            
            for stat_type, selector in stats_selectors.items():
                elements = soup.select(selector)
                if elements:
                    # Спробуємо знайти число поруч з іконкою
                    for element in elements:
                        parent = element.parent
                        if parent:
                            text = parent.get_text(strip=True)
                            # Шукаємо число в тексті
                            numbers = re.findall(r'\d+', text)
                            if numbers:
                                count = int(numbers[0])
                                if stat_type == 'likes':
                                    post_data["likes_count"] = count
                                elif stat_type == 'retweets':
                                    post_data["retweets_count"] = count
                                elif stat_type == 'replies':
                                    post_data["replies_count"] = count
                                break
            
            # Якщо не знайшли текст, спробуємо альтернативні методи
            if not post_data["text"]:
                # Шукаємо текст в мета-тегах
                meta_description = soup.find('meta', {'name': 'description'})
                if meta_description:
                    post_data["text"] = meta_description.get('content', '')
                
                # Якщо все ще немає тексту, спробуємо знайти будь-який текст
                if not post_data["text"]:
                    # Шукаємо текст в body
                    body = soup.find('body')
                    if body:
                        # Видаляємо скрипти та стилі
                        for script in body(["script", "style"]):
                            script.decompose()
                        
                        text = body.get_text()
                        # Очищаємо текст
                        lines = (line.strip() for line in text.splitlines())
                        chunks = (phrase.strip() for line in lines for phrase in line.split("  "))
                        text = ' '.join(chunk for chunk in chunks if chunk)
                        
                        # Беремо перші 500 символів як текст посту
                        post_data["text"] = text[:500]
            
            logger.info(f"Extracted post data: {post_data['text'][:100]}...")
            return post_data
            
        except Exception as e:
            logger.error(f"Error extracting post data: {e}")
            return None
    
    async def get_post_summary(self, url: str) -> Dict[str, Any]:
        """Отримання короткого опису посту"""
        post = await self.scrape_post(url)
        if not post:
            raise ValueError("Failed to scrape post")
        
        return {
            "url": str(post.url),
            "text": post.text,
            "author": post.author,
            "has_images": len(post.images) > 0,
            "has_video": post.video_url is not None,
            "image_count": len(post.images),
            "engagement": {
                "likes": post.likes_count,
                "retweets": post.retweets_count,
                "replies": post.replies_count
            }
        }
