import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../ai/provider_health_monitor.dart';
import '../models/ai_provider_model.dart';

final aiHealthProvider =
    StateNotifierProvider<AiHealthNotifier, Map<AiProviderName, AiProviderModel>>(
        (ref) {
  return AiHealthNotifier(ref);
});

class AiHealthNotifier
    extends StateNotifier<Map<AiProviderName, AiProviderModel>> {
  final Ref _ref;

  AiHealthNotifier(this._ref) : super({}) {
    _loadProviders();
  }

  void _loadProviders() {
    final monitor = _ref.read(providerHealthMonitorProvider);
    state = {
      for (final p in monitor.allProviders) p.name: p
    };
  }

  void refresh() {
    _loadProviders();
  }

  AiProviderName? get activeProvider {
    return _ref.read(providerHealthMonitorProvider).activeProvider;
  }

  Map<String, dynamic> get healthSummary {
    return _ref.read(providerHealthMonitorProvider).getHealthSummary();
  }
}
