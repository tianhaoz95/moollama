import 'dart:convert';

class ThinkingModelResponse {
  final List<String> thinkingSessions;
  final String finalOutput;

  ThinkingModelResponse({
    required this.thinkingSessions,
    required this.finalOutput,
  });
}

ThinkingModelResponse splitContentByThinkTags(String? content) {
  if (content == null) {
    return ThinkingModelResponse(thinkingSessions: [], finalOutput: '');
  }

  final List<String> thinkingSessions = [];
  String finalOutput = '';

  final RegExp thinkRegex = RegExp(r'<think>(.*?)</think>', dotAll: true);
  final RegExp imEndRegex = RegExp(r'<\|im_end\|>');

  int lastMatchEnd = 0; // Keep track of the end of the last matched <think> tag

  for (final match in thinkRegex.allMatches(content)) {
    // Add content between the previous match and the current <think> tag to finalOutput
    if (match.start > lastMatchEnd) {
      finalOutput += content.substring(lastMatchEnd, match.start);
    }

    // Add content inside <think>...</think> as a thinking session
    thinkingSessions.add(match.group(1)!.trim());
    lastMatchEnd = match.end;
  }

  // Add any remaining content after the last </think> tag to finalOutput
  if (content.length > lastMatchEnd) {
    finalOutput += content.substring(lastMatchEnd);
  }

  // Remove <|im_end|> if it exists at the end of the finalOutput
  if (imEndRegex.hasMatch(finalOutput)) {
    finalOutput = finalOutput.replaceAll(imEndRegex, '').trim();
  } else {
    finalOutput = finalOutput.trim(); // Trim even if no im_end tag
  }


  return ThinkingModelResponse(
    thinkingSessions: thinkingSessions,
    finalOutput: finalOutput,
  );
}

String getModelUrl(String modelId) {
  switch (modelId) {
    case 'Qwen3 0.6B':
      return 'https://huggingface.co/Cactus-Compute/Qwen3-600m-Instruct-GGUF/resolve/main/Qwen3-0.6B-Q8_0.gguf';
    case 'Phi-3-mini-4k-instruct':
      return 'https://huggingface.co/microsoft/Phi-3-mini-4k-instruct-gguf/resolve/main/Phi-3-mini-4k-instruct-q4.gguf';
    case 'Llama-3-8B-Instruct':
      return 'https://huggingface.co/unsloth/llama-3-8b-Instruct-gguf/resolve/main/llama-3-8b-Instruct-Q4_K_M.gguf';
    default:
      // Default to Qwen3 0.6B if the modelId is not found
      return 'https://huggingface.co/Cactus-Compute/Qwen3-600m-Instruct-GGUF/resolve/main/Qwen3-0.6B-Q8_0.gguf';
  }
}

String extractResponseFromJson(String text) {
  try {
    final decodedJson = jsonDecode(text);
    if (decodedJson is Map<String, dynamic>) {
      // Handle the original 'response' key
      if (decodedJson.containsKey('response')) {
        final responseValue = decodedJson['response'];
        if (responseValue is String) {
          return responseValue;
        }
      }
      // Handle the new 'tool_calls' structure
      if (decodedJson.containsKey('tool_calls')) {
        final toolCalls = decodedJson['tool_calls'];
        if (toolCalls is List) {
          for (final call in toolCalls) {
            if (call is Map<String, dynamic> && call['name'] == 'response') {
              if (call.containsKey('content')) {
                final content = call['content'];
                if (content is String) {
                  return content;
                }
              }
            }
          }
        }
      }
    }
  }
  catch (e) {
    // Not a valid JSON or doesn't contain the expected structure
    // Do nothing, return original text
  }
  return text;
}