import 'package:flutter/material.dart';
import 'package:siri_wave/siri_wave.dart';

class ListeningPopup extends StatelessWidget {
  final String lastWords;

  const ListeningPopup({
    super.key,
    required this.lastWords,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        color: Theme.of(context).dialogBackgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30.0),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SiriWaveform.ios9(),
              const SizedBox(height: 10),
              Text(
                lastWords.isEmpty ? 'Listening...' : lastWords,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 24,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
