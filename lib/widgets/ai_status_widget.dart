import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/ai_provider.dart';
import '../models/ai_provider_model.dart';

class AiStatusWidget extends ConsumerWidget {
  const AiStatusWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aiHealth = ref.watch(aiHealthProvider);
    final activeProvider =
        ref.read(aiHealthProvider.notifier).activeProvider;

    if (activeProvider == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 14, color: Colors.red),
            SizedBox(width: 4),
            Text('AI Unavailable',
                style: TextStyle(fontSize: 11, color: Colors.red)),
          ],
        ),
      );
    }

    final provider = aiHealth[activeProvider];
    final color = provider?.status == AiProviderStatus.healthy
        ? Colors.green
        : Colors.orange;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration:
                BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(
            activeProvider.name.toUpperCase(),
            style:
                TextStyle(fontSize: 11, color: color),
          ),
        ],
      ),
    );
  }
}
