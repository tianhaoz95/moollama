import 'package:flutter/material.dart';

class MessageInputBar extends StatelessWidget {
  final TextEditingController textController;
  final bool isGenerating;
  final VoidCallback onSendMessage;
  final VoidCallback onStopGeneration;
  final VoidCallback onShowAttachmentOptions;

  const MessageInputBar({
    super.key,
    required this.textController,
    required this.isGenerating,
    required this.onSendMessage,
    required this.onStopGeneration,
    required this.onShowAttachmentOptions,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 16.0,
        left: 12.0,
        right: 12.0,
        top: 8.0,
      ),
      child: TextField(
        controller: textController,
        minLines: 1,
        maxLines: 6,
        textInputAction: TextInputAction.send,
        keyboardType: TextInputType.multiline,
        decoration: InputDecoration(
          hintText: 'Ask Secret Agent',
          hintStyle: TextStyle(color: Theme.of(context).hintColor),
          filled: true,
          fillColor: Theme.of(context).inputDecorationTheme.fillColor ??
              Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 12,
            horizontal: 16,
          ),
          prefixIcon: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.attach_file),
                onPressed: onShowAttachmentOptions,
              ),
              const SizedBox(width: 8),
            ],
          ),
          suffixIcon: isGenerating
              ? IconButton(
                  icon: const Icon(Icons.stop),
                  onPressed: onStopGeneration,
                )
              : IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: onSendMessage,
                ),
        ),
        style: TextStyle(
          color: Theme.of(context).textTheme.bodyLarge?.color,
        ),
        onSubmitted: (_) => onSendMessage(),
      ),
    );
  }
}