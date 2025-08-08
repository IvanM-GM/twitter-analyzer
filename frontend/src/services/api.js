import axios from 'axios';

// Базовий URL для API
const API_BASE_URL = process.env.REACT_APP_API_URL || 'http://localhost:8000/api/v1';

// Створення axios інстансу
const api = axios.create({
  baseURL: API_BASE_URL,
  timeout: 30000, // 30 секунд
  headers: {
    'Content-Type': 'application/json',
  },
});

// Інтерцептор для обробки помилок
api.interceptors.response.use(
  (response) => response,
  (error) => {
    console.error('API Error:', error);
    
    if (error.response) {
      // Сервер повернув помилку
      const message = error.response.data?.detail || error.response.data?.error || 'Server error';
      throw new Error(message);
    } else if (error.request) {
      // Помилка мережі
      throw new Error('Network error. Please check your connection.');
    } else {
      // Інша помилка
      throw new Error(error.message || 'Unknown error occurred');
    }
  }
);

// API функції
export const analyzeTwitterPost = async (twitterUrl, commentCount = 5) => {
  try {
    const response = await api.post('/analyze', {
      twitter_url: twitterUrl,
      comment_count: commentCount,
    });
    
    return response.data;
  } catch (error) {
    throw error;
  }
};

export const validateTwitterUrl = async (url) => {
  try {
    const response = await api.post('/validate-url', {
      twitter_url: url,
    });
    
    return response.data;
  } catch (error) {
    throw error;
  }
};

export const getPostInfo = async (postId) => {
  try {
    const response = await api.get(`/post/${postId}`);
    return response.data;
  } catch (error) {
    throw error;
  }
};

export const checkHealth = async () => {
  try {
    const response = await api.get('/health');
    return response.data;
  } catch (error) {
    throw error;
  }
};

export const getMetrics = async () => {
  try {
    const response = await api.get('/metrics');
    return response.data;
  } catch (error) {
    throw error;
  }
};

// Утиліти для валідації
export const validateTwitterUrlFormat = (url) => {
  if (!url) return false;
  
  const twitterPatterns = [
    /^https?:\/\/(www\.)?twitter\.com\/[^\/]+\/status\/\d+/,
    /^https?:\/\/(www\.)?x\.com\/[^\/]+\/status\/\d+/,
  ];
  
  return twitterPatterns.some(pattern => pattern.test(url));
};

// Експорт axios інстансу для прямого використання
export default api;
