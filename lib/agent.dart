import 'package:flutter/foundation.dart';

enum AgentResponseStatus {
  success,
  error,
  toolCode,
  toolOutput,
}

class AgentResponse {
  final String? response;
  final AgentResponseStatus status;
  final String? errorMessage;

  AgentResponse({this.response, required this.status, this.errorMessage});
}

class Message {
  final String finalText;
  final String? rawText;
  final String? thinkingText;
  final List<String>? toolCalls;
  final bool isUser;
  final bool isLoading;

  Message({
    required this.finalText,
    this.rawText,
    this.thinkingText,
    this.toolCalls,
    required this.isUser,
    this.isLoading = false,
  });
}

class AgentRequest {
  final String prompt;
  final String systemPrompt;
  final List<Message> history;
  final bool useTools;
  final double temperature;
  final List<String> tools;

  AgentRequest({
    required this.prompt,
    required this.systemPrompt,
    required this.history,
    this.useTools = false,
    this.temperature = 0.7,
    this.tools = const [],
  });
}

abstract class Agent {
  Future<void> initialize({
    required String modelPath,
    int? contextLength,
    double? temperature,
    List<String>? tools,
  });

  Stream<AgentResponse> generate(AgentRequest request);

  void unload();
}
