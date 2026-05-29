enum AiProviderName {
  gemini,
  grok,
  huggingface,
  claude,
  openai,
  deepseek,
  mistral,
}

enum AiExecutionMode {
  highQuality,
  lowCost,
  fastest,
  custom,
}

enum AiProviderStatus {
  healthy,
  degraded,
  failed,
  recovering,
}

class AiProviderModel {
  final AiProviderName name;
  AiProviderStatus status;
  double successRate;
  double failureRate;
  double averageLatencyMs;
  int consecutiveFailures;
  DateTime? lastSuccessTime;
  DateTime? lastFailureTime;
  double estimatedCreditsRemaining;
  int failoverCount;
  int totalRequests;
  int successfulRequests;

  AiProviderModel({
    required this.name,
    this.status = AiProviderStatus.healthy,
    this.successRate = 1.0,
    this.failureRate = 0.0,
    this.averageLatencyMs = 0.0,
    this.consecutiveFailures = 0,
    this.lastSuccessTime,
    this.lastFailureTime,
    this.estimatedCreditsRemaining = 100.0,
    this.failoverCount = 0,
    this.totalRequests = 0,
    this.successfulRequests = 0,
  });

  String get displayName {
    switch (name) {
      case AiProviderName.gemini:
        return 'Gemini';
      case AiProviderName.grok:
        return 'Grok';
      case AiProviderName.huggingface:
        return 'Hugging Face';
      case AiProviderName.claude:
        return 'Claude';
      case AiProviderName.openai:
        return 'OpenAI';
      case AiProviderName.deepseek:
        return 'DeepSeek';
      case AiProviderName.mistral:
        return 'Mistral';
    }
  }

  void recordSuccess(double latencyMs) {
    totalRequests++;
    successfulRequests++;
    consecutiveFailures = 0;
    lastSuccessTime = DateTime.now();
    averageLatencyMs =
        (averageLatencyMs * (totalRequests - 1) + latencyMs) / totalRequests;
    successRate = successfulRequests / totalRequests;
    failureRate = 1.0 - successRate;
    if (status == AiProviderStatus.failed ||
        status == AiProviderStatus.degraded) {
      status = AiProviderStatus.recovering;
    } else {
      status = AiProviderStatus.healthy;
    }
  }

  void recordFailure(String errorType) {
    totalRequests++;
    consecutiveFailures++;
    lastFailureTime = DateTime.now();
    failoverCount++;
    successRate = successfulRequests / totalRequests;
    failureRate = 1.0 - successRate;
    if (consecutiveFailures >= 3) {
      status = AiProviderStatus.failed;
    } else {
      status = AiProviderStatus.degraded;
    }
  }

  bool get isAvailable =>
      status != AiProviderStatus.failed || canRecover;

  bool get canRecover {
    if (lastFailureTime == null) return true;
    final timeSinceFailure =
        DateTime.now().difference(lastFailureTime!).inMinutes;
    return timeSinceFailure >= 5;
  }
}
