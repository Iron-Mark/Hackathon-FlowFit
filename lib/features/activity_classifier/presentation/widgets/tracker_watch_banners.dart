import 'package:flutter/material.dart';

/// Always-on banner showing the live watch heart rate connection state.
class TrackerWatchLiveBanner extends StatelessWidget {
  const TrackerWatchLiveBanner({
    super.key,
    required this.watchLiveConnected,
    required this.watchLiveBpm,
    required this.isStartingWatchListener,
    required this.watchListenerError,
  });

  final bool watchLiveConnected;
  final int? watchLiveBpm;
  final bool isStartingWatchListener;
  final String? watchListenerError;

  @override
  Widget build(BuildContext context) {
    final connected = watchLiveConnected && watchLiveBpm != null;
    final color = connected
        ? Colors.red
        : watchListenerError != null
        ? Colors.orange
        : Colors.grey;
    final label = isStartingWatchListener
        ? 'Starting listener...'
        : watchListenerError != null
        ? 'Listener inactive'
        : connected
        ? '$watchLiveBpm BPM'
        : 'Not connected';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.watch, color: color, size: 18),
          const SizedBox(width: 8),
          Text(
            'Galaxy Watch: ',
            style: TextStyle(color: color, fontWeight: FontWeight.w600),
          ),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: connected ? Colors.green : Colors.grey,
              shape: BoxShape.circle,
            ),
          ),
        ],
      ),
    );
  }
}

/// Error banner shown when the watch listener could not start, with a retry
/// action.
class TrackerWatchListenerError extends StatelessWidget {
  const TrackerWatchListenerError({
    super.key,
    required this.message,
    required this.isStartingWatchListener,
    required this.onRetry,
  });

  final String message;
  final bool isStartingWatchListener;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.watch_off, color: Colors.orange, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: isStartingWatchListener ? null : onRetry,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Retry watch listener'),
          ),
        ],
      ),
    );
  }
}

/// Error banner shown when the TensorFlow Lite activity model failed to load.
class TrackerModelLoadError extends StatelessWidget {
  const TrackerModelLoadError({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Activity model unavailable',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: const TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
