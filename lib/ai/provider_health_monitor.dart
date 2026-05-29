import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/ai_provider_model.dart';
import '../config/app_config.dart';

final providerHealthMonitorProvider =
    Provider<ProviderHealthMonitor>((ref) {
  return ProviderHealthMonitor();
});

class ProviderHealthMonitor {
  final Map<AiProviderName, AiProviderModel> _providers = {
    for (final name in AiProviderName.values)
      name: AiProviderModel(name: name),
  };

  AiProviderModel getProvider(AiProviderName name) {
    return _providers[name] ?? AiProviderModel(name: name);
  }

  List<AiProviderModel> get allProviders => _providers.values.toList();

  void recordSuccess(AiProviderName name, double latencyMs) {
    _providers[name]?.recordSuccess(latencyMs);
  }

  void recordFailure(AiProviderName name, String errorType) {
    final provider = _providers[name];
    if (provider == null) return;
    provider.recordFailure(errorType);

    if (provider.consecutiveFailures >= AppConfig.maxConsecutiveFailures) {
      provider.status = AiProviderStatus.failed;
    }
  }

  void checkAndRestoreProviders() {
    for (final provider in _providers.values) {
      if (provider.status == AiProviderStatus.failed && provider.canRecover) {
        provider.status = AiProviderStatus.recovering;
      }
    }
  }

  Map<String, dynamic> getHealthSummary() {
    return {
      for (final entry in _providers.entries)
        entry.key.name: {
          'status': entry.value.status.name,
          'success_rate': entry.value.successRate,
          'failure_rate': entry.value.failureRate,
          'avg_latency_ms': entry.value.averageLatencyMs,
          'consecutive_failures': entry.value.consecutiveFailures,
          'failover_count': entry.value.failoverCount,
          'total_requests': entry.value.totalRequests,
        }
    };
  }

  AiProviderName? get activeProvider {
    for (final name in [
      AiProviderName.gemini,
      AiProviderName.grok,
      AiProviderName.huggingface,
      AiProviderName.claude,
      AiProviderName.openai,
      AiProviderName.deepseek,
      AiProviderName.mistral,
    ]) {
      final p = _providers[name];
      if (p != null && p.isAvailable && p.status == AiProviderStatus.healthy) {
        return name;
      }
    }
    return null;
  }
}
