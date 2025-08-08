"""
GPT Service - Інтеграція з OpenAI API для генерації коментарів
"""

import logging
import asyncio
from typing import List, Dict, Any, Optional
from openai import AsyncOpenAI
from pydantic import BaseModel
import re
import json

logger = logging.getLogger(__name__)

class CommentRequest(BaseModel):
    """Модель запиту для генерації коментарів"""
    post_text: str
    author: str
    images_description: Optional[str] = None
    video_description: Optional[str] = None
    engagement_stats: Optional[Dict[str, int]] = None
    comment_count: int = 5

class CommentResponse(BaseModel):
    """Модель відповіді з коментарями"""
    comments: List[str]
    analysis: Dict[str, Any]
    generated_at: str

class GPTService:
    """Сервіс для роботи з GPT API"""
    
    def __init__(
        self,
        api_key: str,
        model: str = "gpt-4o-mini",
        max_tokens: int = 500,
        temperature: float = 0.7
    ):
        self.client = AsyncOpenAI(api_key=api_key)
        self.model = model
        self.max_tokens = max_tokens
        self.temperature = temperature
        
        # Системний промпт для генерації коментарів
        self.system_prompt = """Ти експерт з аналізу соціальних мереж та генерації релевантних коментарів. 
Твоє завдання - проаналізувати Twitter-пост та згенерувати різноманітні, цікаві та релевантні коментарі.

Правила для генерації коментарів:
1. Коментарі мають бути релевантними до змісту посту
2. Використовуй різні стилі: підтримуючий, критичний, запитуючий, гумористичний
3. Коментарі мають бути природними та не надто формальними
4. Уникай повторень та шаблонних фраз
5. Враховуй контекст зображень або відео, якщо вони є
6. Коментарі мають бути різної довжини (короткі та середні)
7. Використовуй емодзі де доречно, але не переборщуй

Формат відповіді:
{
    "comments": [
        "Коментар 1",
        "Коментар 2",
        "Коментар 3",
        "Коментар 4",
        "Коментар 5"
    ],
    "analysis": {
        "tone": "загальний тон посту",
        "topics": ["тема1", "тема2"],
        "sentiment": "позитивний/негативний/нейтральний",
        "engagement_potential": "високий/середній/низький"
    }
}"""
    
    async def generate_comments(self, request: CommentRequest) -> CommentResponse:
        """Генерація коментарів до Twitter-посту"""
        try:
            logger.info(f"Generating comments for post by {request.author}")
            
            # Формування промпту для користувача
            user_prompt = self._build_user_prompt(request)
            
            # Виклик GPT API
            response = await self.client.chat.completions.create(
                model=self.model,
                messages=[
                    {"role": "system", "content": self.system_prompt},
                    {"role": "user", "content": user_prompt}
                ],
                max_tokens=self.max_tokens,
                temperature=self.temperature,
                response_format={"type": "json_object"}
            )
            
            # Парсинг відповіді
            content = response.choices[0].message.content
            result = self._parse_gpt_response(content)
            
            logger.info(f"Generated {len(result['comments'])} comments successfully")
            
            return CommentResponse(
                comments=result['comments'],
                analysis=result['analysis'],
                generated_at=asyncio.get_event_loop().time()
            )
            
        except Exception as e:
            logger.error(f"Error generating comments: {e}")
            raise ValueError(f"Failed to generate comments: {e}")
    
    def _build_user_prompt(self, request: CommentRequest) -> str:
        """Формування промпту для користувача"""
        prompt_parts = [
            f"Автор посту: {request.author}",
            f"Текст посту: {request.post_text}",
        ]
        
        # Додавання інформації про медіа
        if request.images_description:
            prompt_parts.append(f"Зображення: {request.images_description}")
        
        if request.video_description:
            prompt_parts.append(f"Відео: {request.video_description}")
        
        # Додавання статистики
        if request.engagement_stats:
            stats = request.engagement_stats
            stats_text = []
            if stats.get('likes'):
                stats_text.append(f"лайків: {stats['likes']}")
            if stats.get('retweets'):
                stats_text.append(f"ретвітів: {stats['retweets']}")
            if stats.get('replies'):
                stats_text.append(f"коментарів: {stats['replies']}")
            
            if stats_text:
                prompt_parts.append(f"Статистика: {', '.join(stats_text)}")
        
        prompt_parts.append(f"Згенеруй {request.comment_count} різноманітних коментарів до цього посту.")
        
        return "\n".join(prompt_parts)
    
    def _parse_gpt_response(self, content: str) -> Dict[str, Any]:
        """Парсинг відповіді від GPT"""
        try:
            result = json.loads(content)
            
            # Валідація структури
            if 'comments' not in result or 'analysis' not in result:
                raise ValueError("Invalid response structure")
            
            # Перевірка, що коментарі є списком
            if not isinstance(result['comments'], list):
                raise ValueError("Comments must be a list")
            
            # Обмеження кількості коментарів
            result['comments'] = result['comments'][:5]
            
            # Валідація аналізу
            if not isinstance(result['analysis'], dict):
                result['analysis'] = {
                    "tone": "нейтральний",
                    "topics": [],
                    "sentiment": "нейтральний",
                    "engagement_potential": "середній"
                }
            
            return result
            
        except json.JSONDecodeError:
            logger.error(f"Failed to parse GPT response: {content}")
            # Fallback - спробуємо витягти коментарі з тексту
            return self._extract_comments_from_text(content)
        except Exception as e:
            logger.error(f"Error parsing GPT response: {e}")
            raise ValueError(f"Failed to parse GPT response: {e}")
    
    def _extract_comments_from_text(self, text: str) -> Dict[str, Any]:
        """Витяг коментарів з тексту (fallback метод)"""
        lines = text.split('\n')
        comments = []
        
        for line in lines:
            line = line.strip()
            if line and len(line) > 10 and not line.startswith('{') and not line.startswith('"'):
                # Видаляємо номери та маркери
                line = re.sub(r'^\d+\.\s*', '', line)
                line = re.sub(r'^[-*]\s*', '', line)
                comments.append(line)
        
        # Обмежуємо кількість коментарів
        comments = comments[:5]
        
        return {
            "comments": comments,
            "analysis": {
                "tone": "нейтральний",
                "topics": [],
                "sentiment": "нейтральний",
                "engagement_potential": "середній"
            }
        }
    
    async def analyze_post_sentiment(self, post_text: str) -> Dict[str, Any]:
        """Аналіз настрою посту"""
        try:
            prompt = f"""Проаналізуй настрій наступного Twitter-посту та поверни результат у JSON форматі:

Текст: {post_text}

Результат має містити:
- sentiment: позитивний/негативний/нейтральний
- confidence: число від 0 до 1
- topics: список основних тем
- tone: загальний тон (формальний/неформальний/гумористичний/серйозний)"""

            response = await self.client.chat.completions.create(
                model=self.model,
                messages=[
                    {"role": "user", "content": prompt}
                ],
                max_tokens=200,
                temperature=0.3,
                response_format={"type": "json_object"}
            )
            
            content = response.choices[0].message.content
            return json.loads(content)
            
        except Exception as e:
            logger.error(f"Error analyzing sentiment: {e}")
            return {
                "sentiment": "нейтральний",
                "confidence": 0.5,
                "topics": [],
                "tone": "нейтральний"
            }
    
    async def test_connection(self) -> bool:
        """Тест з'єднання з OpenAI API"""
        try:
            response = await self.client.models.list()
            return len(response.data) > 0
        except Exception as e:
            logger.error(f"OpenAI API connection test failed: {e}")
            return False
