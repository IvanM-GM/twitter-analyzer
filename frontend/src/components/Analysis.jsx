import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { ArrowLeft, Settings, BarChart3, TrendingUp, Activity } from 'lucide-react';
import toast from 'react-hot-toast';
import { analyzeTwitterPost, checkHealth, getMetrics } from '../services/api';

const Analysis = () => {
  const [url, setUrl] = useState('');
  const [commentCount, setCommentCount] = useState(5);
  const [isLoading, setIsLoading] = useState(false);
  const [results, setResults] = useState(null);
  const [healthStatus, setHealthStatus] = useState(null);
  const [metrics, setMetrics] = useState(null);
  const navigate = useNavigate();

  useEffect(() => {
    checkSystemHealth();
  }, []);

  const checkSystemHealth = async () => {
    try {
      const health = await checkHealth();
      setHealthStatus(health);
      
      const metricsData = await getMetrics();
      setMetrics(metricsData);
    } catch (error) {
      console.error('Health check failed:', error);
    }
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    
    if (!url.trim()) {
      toast.error('Please enter a Twitter URL');
      return;
    }

    setIsLoading(true);
    toast.loading('Performing advanced analysis...');

    try {
      const data = await analyzeTwitterPost(url, commentCount);
      setResults(data);
      toast.dismiss();
      toast.success('Advanced analysis completed!');
    } catch (error) {
      toast.dismiss();
      toast.error(error.message || 'Failed to analyze post');
    } finally {
      setIsLoading(false);
    }
  };

  const getHealthColor = (status) => {
    switch (status) {
      case 'healthy':
        return 'text-green-600';
      case 'unhealthy':
        return 'text-red-600';
      default:
        return 'text-yellow-600';
    }
  };

  return (
    <div className="max-w-6xl mx-auto">
      {/* Header */}
      <div className="flex items-center justify-between mb-8">
        <button
          onClick={() => navigate('/')}
          className="flex items-center space-x-2 text-gray-600 hover:text-gray-900 transition-colors"
        >
          <ArrowLeft className="h-5 w-5" />
          <span>Back to Home</span>
        </button>
        
        <div className="flex items-center space-x-4">
          {healthStatus && (
            <div className="flex items-center space-x-2">
              <div className={`w-2 h-2 rounded-full ${
                healthStatus.status === 'healthy' ? 'bg-green-500' : 'bg-red-500'
              }`}></div>
              <span className={`text-sm font-medium ${getHealthColor(healthStatus.status)}`}>
                {healthStatus.status}
              </span>
            </div>
          )}
        </div>
      </div>

      <div className="grid lg:grid-cols-3 gap-8">
        {/* Main Analysis Form */}
        <div className="lg:col-span-2">
          <div className="card">
            <div className="flex items-center space-x-2 mb-6">
              <Settings className="h-6 w-6 text-blue-600" />
              <h2 className="text-2xl font-bold text-gray-900">Advanced Analysis</h2>
            </div>
            
            <form onSubmit={handleSubmit} className="space-y-6">
              <div>
                <label htmlFor="twitter-url" className="block text-sm font-medium text-gray-700 mb-2">
                  Twitter Post URL
                </label>
                <input
                  id="twitter-url"
                  type="url"
                  value={url}
                  onChange={(e) => setUrl(e.target.value)}
                  placeholder="https://twitter.com/username/status/123456789"
                  className="input-field"
                  disabled={isLoading}
                />
              </div>

              <div>
                <label htmlFor="comment-count" className="block text-sm font-medium text-gray-700 mb-2">
                  Number of Comments to Generate
                </label>
                <select
                  id="comment-count"
                  value={commentCount}
                  onChange={(e) => setCommentCount(parseInt(e.target.value))}
                  className="input-field"
                  disabled={isLoading}
                >
                  <option value={3}>3 comments</option>
                  <option value={5}>5 comments</option>
                  <option value={7}>7 comments</option>
                  <option value={10}>10 comments</option>
                </select>
              </div>

              <button
                type="submit"
                disabled={isLoading || !url.trim()}
                className="btn-primary w-full disabled:opacity-50 disabled:cursor-not-allowed flex items-center justify-center space-x-2"
              >
                {isLoading ? (
                  <>
                    <div className="loading-spinner"></div>
                    <span>Analyzing...</span>
                  </>
                ) : (
                  <>
                    <BarChart3 className="h-4 w-4" />
                    <span>Start Advanced Analysis</span>
                  </>
                )}
              </button>
            </form>
          </div>

          {/* Results */}
          {results && (
            <div className="mt-8 space-y-6 fade-in">
              {/* Post Analysis */}
              <div className="card">
                <h3 className="text-xl font-semibold text-gray-900 mb-4">Post Analysis</h3>
                <div className="space-y-4">
                  <div className="grid md:grid-cols-2 gap-4">
                    <div>
                      <span className="text-sm font-medium text-gray-500">Author:</span>
                      <p className="text-gray-900 font-medium">{results.post.author}</p>
                    </div>
                    <div>
                      <span className="text-sm font-medium text-gray-500">Processing Time:</span>
                      <p className="text-gray-900">{results.processing_time}s</p>
                    </div>
                  </div>
                  
                  <div>
                    <span className="text-sm font-medium text-gray-500">Content:</span>
                    <div className="mt-2 p-4 bg-gray-50 rounded-lg">
                      <p className="text-gray-900">{results.post.text}</p>
                    </div>
                  </div>

                  <div className="grid grid-cols-3 gap-4 text-center">
                    <div className="bg-blue-50 p-3 rounded-lg">
                      <div className="text-2xl font-bold text-blue-600">
                        {results.post.engagement.likes || 0}
                      </div>
                      <div className="text-sm text-gray-600">Likes</div>
                    </div>
                    <div className="bg-green-50 p-3 rounded-lg">
                      <div className="text-2xl font-bold text-green-600">
                        {results.post.engagement.retweets || 0}
                      </div>
                      <div className="text-sm text-gray-600">Retweets</div>
                    </div>
                    <div className="bg-purple-50 p-3 rounded-lg">
                      <div className="text-2xl font-bold text-purple-600">
                        {results.post.engagement.replies || 0}
                      </div>
                      <div className="text-sm text-gray-600">Replies</div>
                    </div>
                  </div>
                </div>
              </div>

              {/* Generated Comments */}
              <div className="card">
                <h3 className="text-xl font-semibold text-gray-900 mb-4">Generated Comments</h3>
                <div className="space-y-4">
                  {results.comments.map((comment, index) => (
                    <div
                      key={index}
                      className="bg-gradient-to-r from-blue-50 to-indigo-50 border border-blue-200 rounded-lg p-4 slide-up"
                      style={{ animationDelay: `${index * 0.1}s` }}
                    >
                      <div className="flex items-start space-x-3">
                        <div className="flex-shrink-0">
                          <div className="w-8 h-8 bg-gradient-to-r from-blue-500 to-indigo-600 rounded-full flex items-center justify-center">
                            <span className="text-white text-sm font-medium">
                              {index + 1}
                            </span>
                          </div>
                        </div>
                        <div className="flex-1">
                          <p className="text-gray-900">{comment}</p>
                          <div className="mt-2 flex space-x-2">
                            <span className="text-xs bg-blue-100 text-blue-800 px-2 py-1 rounded">
                              AI Generated
                            </span>
                            <span className="text-xs bg-gray-100 text-gray-600 px-2 py-1 rounded">
                              Comment {index + 1}
                            </span>
                          </div>
                        </div>
                      </div>
                    </div>
                  ))}
                </div>
              </div>

              {/* Analysis Summary */}
              {results.analysis && (
                <div className="card">
                  <h3 className="text-xl font-semibold text-gray-900 mb-4">Analysis Summary</h3>
                  <div className="grid md:grid-cols-2 gap-6">
                    <div className="space-y-4">
                      <div>
                        <span className="text-sm font-medium text-gray-500">Tone:</span>
                        <span className="ml-2 text-gray-900 capitalize">{results.analysis.tone}</span>
                      </div>
                      <div>
                        <span className="text-sm font-medium text-gray-500">Sentiment:</span>
                        <span className="ml-2 text-gray-900 capitalize">{results.analysis.sentiment}</span>
                      </div>
                      <div>
                        <span className="text-sm font-medium text-gray-500">Engagement Potential:</span>
                        <span className="ml-2 text-gray-900 capitalize">{results.analysis.engagement_potential}</span>
                      </div>
                    </div>
                    
                    {results.analysis.topics && results.analysis.topics.length > 0 && (
                      <div>
                        <span className="text-sm font-medium text-gray-500">Topics:</span>
                        <div className="mt-2 flex flex-wrap gap-2">
                          {results.analysis.topics.map((topic, index) => (
                            <span
                              key={index}
                              className="bg-indigo-100 text-indigo-800 text-xs px-2 py-1 rounded"
                            >
                              {topic}
                            </span>
                          ))}
                        </div>
                      </div>
                    )}
                  </div>
                </div>
              )}
            </div>
          )}
        </div>

        {/* Sidebar */}
        <div className="space-y-6">
          {/* System Status */}
          <div className="card">
            <div className="flex items-center space-x-2 mb-4">
              <Activity className="h-5 w-5 text-green-600" />
              <h3 className="text-lg font-semibold text-gray-900">System Status</h3>
            </div>
            
            {healthStatus && (
              <div className="space-y-3">
                <div className="flex justify-between items-center">
                  <span className="text-sm text-gray-600">API Status:</span>
                  <span className={`text-sm font-medium ${getHealthColor(healthStatus.status)}`}>
                    {healthStatus.status}
                  </span>
                </div>
                
                {healthStatus.services && (
                  <div className="space-y-2">
                    <div className="text-sm text-gray-600">Services:</div>
                    {Object.entries(healthStatus.services).map(([service, status]) => (
                      <div key={service} className="flex justify-between items-center">
                        <span className="text-xs text-gray-500 capitalize">{service}:</span>
                        <span className={`text-xs font-medium ${
                          status === 'available' || status === 'connected' 
                            ? 'text-green-600' 
                            : 'text-red-600'
                        }`}>
                          {status}
                        </span>
                      </div>
                    ))}
                  </div>
                )}
              </div>
            )}
          </div>

          {/* Metrics */}
          {metrics && (
            <div className="card">
              <div className="flex items-center space-x-2 mb-4">
                <TrendingUp className="h-5 w-5 text-blue-600" />
                <h3 className="text-lg font-semibold text-gray-900">Metrics</h3>
              </div>
              
              <div className="space-y-3">
                <div className="flex justify-between items-center">
                  <span className="text-sm text-gray-600">Total Requests:</span>
                  <span className="text-sm font-medium text-gray-900">{metrics.requests_total || 0}</span>
                </div>
                <div className="flex justify-between items-center">
                  <span className="text-sm text-gray-600">Requests/min:</span>
                  <span className="text-sm font-medium text-gray-900">{metrics.requests_per_minute || 0}</span>
                </div>
                <div className="flex justify-between items-center">
                  <span className="text-sm text-gray-600">Avg Response:</span>
                  <span className="text-sm font-medium text-gray-900">{metrics.average_response_time || 0}ms</span>
                </div>
                <div className="flex justify-between items-center">
                  <span className="text-sm text-gray-600">Error Rate:</span>
                  <span className="text-sm font-medium text-gray-900">{metrics.error_rate || 0}%</span>
                </div>
              </div>
            </div>
          )}

          {/* Tips */}
          <div className="card">
            <h3 className="text-lg font-semibold text-gray-900 mb-4">Analysis Tips</h3>
            <div className="space-y-3 text-sm text-gray-600">
              <div className="flex items-start space-x-2">
                <div className="w-2 h-2 bg-blue-500 rounded-full mt-2 flex-shrink-0"></div>
                <p>Use public Twitter posts for best results</p>
              </div>
              <div className="flex items-start space-x-2">
                <div className="w-2 h-2 bg-blue-500 rounded-full mt-2 flex-shrink-0"></div>
                <p>Posts with images or videos get richer analysis</p>
              </div>
              <div className="flex items-start space-x-2">
                <div className="w-2 h-2 bg-blue-500 rounded-full mt-2 flex-shrink-0"></div>
                <p>Higher engagement posts generate better comments</p>
              </div>
              <div className="flex items-start space-x-2">
                <div className="w-2 h-2 bg-blue-500 rounded-full mt-2 flex-shrink-0"></div>
                <p>Processing time depends on post complexity</p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};

export default Analysis;
