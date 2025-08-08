import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { Twitter, Brain, Sparkles, ArrowRight } from 'lucide-react';
import toast from 'react-hot-toast';
import { analyzeTwitterPost } from '../services/api';

const Home = () => {
  const [url, setUrl] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [results, setResults] = useState(null);
  const navigate = useNavigate();

  const handleSubmit = async (e) => {
    e.preventDefault();
    
    if (!url.trim()) {
      toast.error('Please enter a Twitter URL');
      return;
    }

    if (!url.includes('twitter.com') && !url.includes('x.com')) {
      toast.error('Please enter a valid Twitter URL');
      return;
    }

    setIsLoading(true);
    toast.loading('Analyzing Twitter post...');

    try {
      const data = await analyzeTwitterPost(url);
      setResults(data);
      toast.dismiss();
      toast.success('Analysis completed!');
    } catch (error) {
      toast.dismiss();
      toast.error(error.message || 'Failed to analyze post');
    } finally {
      setIsLoading(false);
    }
  };

  const handleAdvancedAnalysis = () => {
    navigate('/analysis');
  };

  return (
    <div className="max-w-4xl mx-auto">
      {/* Hero Section */}
      <div className="text-center mb-12">
        <div className="flex justify-center mb-6">
          <div className="flex items-center space-x-3">
            <Twitter className="h-12 w-12 text-blue-500" />
            <Brain className="h-10 w-10 text-indigo-600" />
            <Sparkles className="h-8 w-8 text-yellow-500" />
          </div>
        </div>
        <h1 className="text-4xl font-bold text-gray-900 mb-4">
          Twitter Analyzer
        </h1>
        <p className="text-xl text-gray-600 mb-8 max-w-2xl mx-auto">
          Analyze any Twitter post and generate intelligent comments using AI. 
          Get insights, engagement predictions, and creative responses.
        </p>
      </div>

      {/* Main Form */}
      <div className="card max-w-2xl mx-auto mb-8">
        <form onSubmit={handleSubmit} className="space-y-6">
          <div>
            <label htmlFor="twitter-url" className="block text-sm font-medium text-gray-700 mb-2">
              Twitter Post URL
            </label>
            <div className="flex space-x-2">
              <input
                id="twitter-url"
                type="url"
                value={url}
                onChange={(e) => setUrl(e.target.value)}
                placeholder="https://twitter.com/username/status/123456789"
                className="input-field flex-1"
                disabled={isLoading}
              />
              <button
                type="submit"
                disabled={isLoading || !url.trim()}
                className="btn-primary disabled:opacity-50 disabled:cursor-not-allowed flex items-center space-x-2"
              >
                {isLoading ? (
                  <>
                    <div className="loading-spinner"></div>
                    <span>Analyzing...</span>
                  </>
                ) : (
                  <>
                    <Brain className="h-4 w-4" />
                    <span>Analyze</span>
                  </>
                )}
              </button>
            </div>
          </div>
        </form>

        {/* Advanced Analysis Button */}
        <div className="mt-6 pt-6 border-t border-gray-200">
          <button
            onClick={handleAdvancedAnalysis}
            className="btn-secondary w-full flex items-center justify-center space-x-2"
          >
            <Sparkles className="h-4 w-4" />
            <span>Advanced Analysis</span>
            <ArrowRight className="h-4 w-4" />
          </button>
        </div>
      </div>

      {/* Results */}
      {results && (
        <div className="space-y-6 fade-in">
          {/* Post Information */}
          <div className="card">
            <h2 className="text-xl font-semibold text-gray-900 mb-4">Post Analysis</h2>
            <div className="space-y-3">
              <div>
                <span className="text-sm font-medium text-gray-500">Author:</span>
                <span className="ml-2 text-gray-900">{results.post.author}</span>
              </div>
              <div>
                <span className="text-sm font-medium text-gray-500">Text:</span>
                <p className="mt-1 text-gray-900 bg-gray-50 p-3 rounded-md">
                  {results.post.text}
                </p>
              </div>
              {results.post.images && results.post.images.length > 0 && (
                <div>
                  <span className="text-sm font-medium text-gray-500">Images:</span>
                  <span className="ml-2 text-gray-900">{results.post.images.length} attached</span>
                </div>
              )}
              <div className="flex space-x-4 text-sm">
                <span className="text-gray-500">
                  ❤️ {results.post.engagement.likes || 0}
                </span>
                <span className="text-gray-500">
                  🔄 {results.post.engagement.retweets || 0}
                </span>
                <span className="text-gray-500">
                  💬 {results.post.engagement.replies || 0}
                </span>
              </div>
            </div>
          </div>

          {/* Generated Comments */}
          <div className="card">
            <h2 className="text-xl font-semibold text-gray-900 mb-4">Generated Comments</h2>
            <div className="space-y-3">
              {results.comments.map((comment, index) => (
                <div
                  key={index}
                  className="bg-blue-50 border border-blue-200 rounded-lg p-4 slide-up"
                  style={{ animationDelay: `${index * 0.1}s` }}
                >
                  <div className="flex items-start space-x-3">
                    <div className="flex-shrink-0">
                      <div className="w-8 h-8 bg-blue-500 rounded-full flex items-center justify-center">
                        <span className="text-white text-sm font-medium">
                          {index + 1}
                        </span>
                      </div>
                    </div>
                    <p className="text-gray-900 flex-1">{comment}</p>
                  </div>
                </div>
              ))}
            </div>
          </div>

          {/* Analysis Summary */}
          {results.analysis && (
            <div className="card">
              <h2 className="text-xl font-semibold text-gray-900 mb-4">Analysis Summary</h2>
              <div className="grid grid-cols-2 gap-4">
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
                <div>
                  <span className="text-sm font-medium text-gray-500">Processing Time:</span>
                  <span className="ml-2 text-gray-900">{results.processing_time}s</span>
                </div>
              </div>
            </div>
          )}
        </div>
      )}

      {/* Features */}
      <div className="mt-16 grid md:grid-cols-3 gap-6">
        <div className="text-center">
          <div className="w-12 h-12 bg-blue-100 rounded-lg flex items-center justify-center mx-auto mb-4">
            <Twitter className="h-6 w-6 text-blue-600" />
          </div>
          <h3 className="text-lg font-semibold text-gray-900 mb-2">Smart Parsing</h3>
          <p className="text-gray-600">
            Automatically extract text, images, and engagement data from any Twitter post
          </p>
        </div>
        
        <div className="text-center">
          <div className="w-12 h-12 bg-indigo-100 rounded-lg flex items-center justify-center mx-auto mb-4">
            <Brain className="h-6 w-6 text-indigo-600" />
          </div>
          <h3 className="text-lg font-semibold text-gray-900 mb-2">AI Analysis</h3>
          <p className="text-gray-600">
            Advanced sentiment analysis and content understanding using GPT-4
          </p>
        </div>
        
        <div className="text-center">
          <div className="w-12 h-12 bg-green-100 rounded-lg flex items-center justify-center mx-auto mb-4">
            <Sparkles className="h-6 w-6 text-green-600" />
          </div>
          <h3 className="text-lg font-semibold text-gray-900 mb-2">Smart Comments</h3>
          <p className="text-gray-600">
            Generate diverse, relevant comments that match the post's tone and content
          </p>
        </div>
      </div>
    </div>
  );
};

export default Home;
