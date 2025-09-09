
import 'package:card_loading/card_loading.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:moollama/models.dart';
import 'package:moollama/widgets/message_bubble.dart';

class ChatView extends StatelessWidget {
  final bool isLoading;
  final bool modelDownloaded;
  final Future<List<Message>> messagesFuture;
  final ScrollController scrollController;
  final double? downloadProgress;
  final double? initializationProgress;
  final Function(String) initializeCactusModel;
  final List<Message> messages;
  final Function(String?) showRawResponseDialog;

  const ChatView({
    super.key,
    required this.isLoading,
    required this.modelDownloaded,
    required this.messagesFuture,
    required this.scrollController,
    required this.downloadProgress,
    required this.initializationProgress,
    required this.initializeCactusModel,
    required this.messages,
    required this.showRawResponseDialog,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      // onLongPressStart: (_) => _showListeningPopup(context), // This will be handled in home_page
      // onLongPressEnd: (_) { // This will be handled in home_page
      //   final transcript = _lastWords;
      //   _hideListeningPopup();
      //   if (transcript.isNotEmpty) {
      //     _textController.text = transcript;
      //     _sendMessage();
      //   }
      // },
      child: Container(
        color: Colors.transparent,
        child: isLoading
            ? Center(
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
                            style: Theme.of(
                              context,
                            ).textTheme.bodyMedium,
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
                            style: Theme.of(
                              context,
                            ).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                  ],
                ),
              )
            : FutureBuilder<List<Message>>(
                future: messagesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  } else if (snapshot.hasError) {
                    return Center(
                      child: Text('Error: ${snapshot.error}'),
                    );
                  } else if (messages.isEmpty) {
                    return Center(
                      child: modelDownloaded
                          ? Text(
                              'Hello!',
                              style: TextStyle(
                                color: Colors.blue[400],
                                fontSize: 32,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'No model found. Please download one to start chatting.',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleLarge,
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 20),
                                ElevatedButton.icon(
                                  onPressed: () {
                                    // This needs to be passed from the parent
                                    // _initializeCactusModel(_selectedAgent!.modelName);
                                  },
                                  icon: const Icon(
                                    Icons.download,
                                  ),
                                  label: const Text(
                                    'Download Model',
                                  ),
                                ),
                              ],
                            ),
                    );
                  } else {
                    return ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.all(8.0),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        return _buildMessageBubble(
                          messages[index],
                          context,
                          showRawResponseDialog,
                        );
                      },
                    );
                  }
                },
              ),
      ),
    );
  }

  Widget _buildMessageBubble(
    Message message,
    BuildContext context,
    Function(String?) showRawResponseDialog,
  ) {
    return MessageBubble(
      message: message,
      onDoubleTapRawText: showRawResponseDialog,
    );
  }
}
