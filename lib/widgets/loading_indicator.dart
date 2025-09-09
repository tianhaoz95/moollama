import 'package:flutter/material.dart';

class LoadingIndicator extends StatelessWidget {
  final double? initializationProgress;
  final double? downloadProgress;

  const LoadingIndicator({
    super.key,
    this.initializationProgress,
    this.downloadProgress,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          if (initializationProgress != null)
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32.0,
                  ),
                  child: LinearProgressIndicator(
                    value: initializationProgress,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${(initializationProgress! * 100).toInt()}% Initializing...',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            )
          else if (downloadProgress != null)
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32.0,
                  ),
                  child: LinearProgressIndicator(
                    value: downloadProgress,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${(downloadProgress! * 100).toInt()}% Downloading...',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
        ],
      ),
    );
  }
}
