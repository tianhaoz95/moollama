import 'package:flutter/material.dart';

class BottomInputBar extends StatelessWidget {
  final TextEditingController textController;
  final bool isGenerating;
  final VoidCallback onSendMessage;
  final VoidCallback onStopGenerating;
  final Function(BuildContext) onShowAttachmentOptions;

  const BottomInputBar({
    super.key,
    required this.textController,
    required this.isGenerating,
    required this.onSendMessage,
    required this.onStopGenerating,
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
        maxLines: 6, // Allow up to 6 lines before scrolling
        textInputAction: TextInputAction.send,
        keyboardType:
            TextInputType.multiline, // Enable multiline keyboard
        decoration: InputDecoration(
          hintText: 'Ask Secret Agent',
          hintStyle: TextStyle(color: Theme.of(context).hintColor),
          filled: true,
          fillColor:
              Theme.of(context).inputDecorationTheme.fillColor ??
              Theme.of(
                context,
              ).colorScheme.surfaceVariant.withOpacity(0.5),
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
                onPressed: () {
                  onShowAttachmentOptions(context);
                },
              ),
              const SizedBox(width: 8),
            ],
          ),
          suffixIcon: isGenerating
              ? IconButton(
                  icon: const Icon(Icons.stop),
                  onPressed: onStopGenerating,
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
