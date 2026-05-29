import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/ai_provider.dart';
import '../../models/ai_provider_model.dart';
import '../../cache/local_cache.dart';

class MonitoringDashboard extends ConsumerWidget {
  const MonitoringDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aiHealth = ref.watch(aiHealthProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Monitoring Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(aiHealthProvider.notifier).refresh(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ActiveProviderCard(
              activeProvider:
                  ref.read(aiHealthProvider.notifier).activeProvider,
            ),
            const SizedBox(height: 16),
            Text(
              'Provider Health Status',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            ...aiHealth.values.map(
              (provider) => _ProviderHealthCard(provider: provider),
            ),
            const SizedBox(height: 16),
            _CacheStatsCard(),
          ],
        ),
      ),
    );
  }
}

class _ActiveProviderCard extends StatelessWidget {
  final AiProviderName? activeProvider;
  const _ActiveProviderCard({this.activeProvider});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colorScheme.primary, colorScheme.secondary],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome, color: Colors.white, size: 32),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Active AI Provider',
                style: TextStyle(color: Colors.white70, fontSize: 12),
              ),
              Text(
                activeProvider?.name.toUpperCase() ?? 'None Available',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProviderHealthCard extends StatelessWidget {
  final AiProviderModel provider;
  const _ProviderHealthCard({required this.provider});

  Color get _statusColor {
    switch (provider.status) {
      case AiProviderStatus.healthy:
        return Colors.green;
      case AiProviderStatus.degraded:
        return Colors.orange;
      case AiProviderStatus.failed:
        return Colors.red;
      case AiProviderStatus.recovering:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: _statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  provider.displayName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    provider.status.name.toUpperCase(),
                    style: TextStyle(
                        color: _statusColor,
                        fontSize: 10,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _Stat(
                    'Success',
                    '${(provider.successRate * 100).toStringAsFixed(0)}%'),
                _Stat('Requests', '${provider.totalRequests}'),
                _Stat(
                    'Latency',
                    '${provider.averageLatencyMs.toStringAsFixed(0)}ms'),
                _Stat('Failovers', '${provider.failoverCount}'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  const _Stat(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 13)),
          Text(label,
              style: const TextStyle(color: Colors.grey, fontSize: 10)),
        ],
      ),
    );
  }
}

class _CacheStatsCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<int>(
      future: ref.read(localCacheProvider).size,
      builder: (context, snapshot) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Local AI Cache',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.storage, size: 16),
                    const SizedBox(width: 8),
                    Text(
                        'Cached Entries: ${snapshot.data ?? 0}'),
                  ],
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () async {
                    await ref.read(localCacheProvider).clear();
                  },
                  child: const Text('Clear Cache'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
