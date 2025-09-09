
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:moollama/models.dart';
import 'package:card_loading/card_loading.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final Function(String?) onDoubleTapRawText;

  const MessageBubble({
    super.key,
    required this.message,
    required this.onDoubleTapRawText,
  });

  @override
  Widget build(BuildContext context) {
    if (message.isLoading) {
      return Align(
        alignment: Alignment.centerLeft,
        child: CardLoading(
          height: 50,
          width: 150,
          borderRadius: BorderRadius.all(Radius.circular(20)),
          margin: EdgeInsets.symmetric(vertical: 4.0),
        ),
      );
    }

    final alignment = message.isUser
        ? Alignment.centerRight
        : Alignment.centerLeft;
    final color = message.isUser
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.surfaceVariant;
    final textColor = message.isUser
        ? Theme.of(context).colorScheme.onPrimary
        : Theme.of(context).colorScheme.onSurfaceVariant;

    return GestureDetector(
      onDoubleTap: () {
        if (!message.isUser) {
          onDoubleTapRawText(message.rawText);
        }
      },
      child: Align(
        alignment: alignment,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4.0),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(20.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (message.thinkingText != null &&
                  message.thinkingText!.isNotEmpty)
                Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    title: Text(
                      '🤔 Thinking...',
                      style: TextStyle(color: textColor),
                    ),
                    initiallyExpanded: false,
                    tilePadding: EdgeInsets.zero,
                    childrenPadding: EdgeInsets.zero,
                    expandedCrossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      MarkdownBody(
                        data: message.thinkingText!,
                        styleSheet: MarkdownStyleSheet.fromTheme(
                          Theme.of(context),
                        ).copyWith(p: TextStyle(color: textColor)),
                      ),
                    ],
                  ),
                ),
              if (message.toolCalls != null && message.toolCalls!.isNotEmpty)
                Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    title: Text(
                      '🛠️ Tool Calls',
                      style: TextStyle(color: textColor),
                    ),
                    initiallyExpanded: false,
                    tilePadding: EdgeInsets.zero,
                    childrenPadding: EdgeInsets.zero,
                    expandedCrossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Align(
                        alignment: Alignment.topLeft,
                        child: Wrap(
                          alignment: WrapAlignment.start,
                          spacing: 8.0,
                          runSpacing: 4.0,
                          children: message.toolCalls!
                              .map(
                                (toolCall) => Chip(
                                  label: Text(toolCall),
                                  backgroundColor: Colors.blueGrey[100],
                                  labelStyle: TextStyle(color: Colors.black),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              MarkdownBody(
                data: message.finalText,
                styleSheet: MarkdownStyleSheet.fromTheme(
                  Theme.of(context),
                ).copyWith(p: TextStyle(color: textColor)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
