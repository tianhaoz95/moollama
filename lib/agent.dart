import 'package:flutter/foundation.dart';

enum LLMResponseStatus {
  success,
  error,
  modelNotFound,
  permissionDenied,
  unknown,
}

class LLMResponse {
  final String? response;
  final LLMResponseStatus status;
  final String? errorMessage;

  LLMResponse({this.response, required this.status, this.errorMessage});
}

abstract class Agent {
  Future<void> initialize({
    required String modelPath,
    int? contextLength,
    double? temperature,
    List<String>? tools,
  });

  Stream<LLMResponse> generate({
    required String prompt,
    required String systemPrompt,
    required String history,
    bool useTools,
  });
}
