class AppConfig {
  static const String appName = 'Global Culinary Hub';
  static const String appVersion = '1.0.0';

  // AI Provider Base URLs
  static const String geminiBaseUrl =
      'https://generativelanguage.googleapis.com/v1beta';
  static const String openaiBaseUrl = 'https://api.openai.com/v1';
  static const String claudeBaseUrl = 'https://api.anthropic.com/v1';
  static const String grokBaseUrl = 'https://api.x.ai/v1';
  static const String deepseekBaseUrl = 'https://api.deepseek.com/v1';
  static const String mistralBaseUrl = 'https://api.mistral.ai/v1';
  static const String huggingfaceBaseUrl =
      'https://api-inference.huggingface.co/models';

  // Timeouts
  static const int connectionTimeout = 30000;
  static const int receiveTimeout = 60000;

  // Cache
  static const int localCacheDurationHours = 24;
  static const int cloudCacheDurationHours = 72;
  static const int maxCacheEntries = 500;

  // Pagination
  static const int pageSize = 20;

  // Retry
  static const int maxRetries = 3;
  static const int retryDelayMs = 1000;

  // Health Monitor
  static const int maxConsecutiveFailures = 3;
  static const double minSuccessRate = 0.5;

  // Supported Languages
  static const List<String> supportedLanguages = [
    'en',
    'hi',
    'pa',
    'es',
    'fr',
    'de',
    'ar',
    'zh',
  ];
}
