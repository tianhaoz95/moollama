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

  int lastIndex = 0;

  for (final match in thinkRegex.allMatches(content)) {
    // Add content inside <think>...</think> as a thinking session
    thinkingSessions.add(match.group(1)!.trim());
    lastIndex = match.end;
  }

  // Get the remaining content after the last </think> tag
  if (content.length > lastIndex) {
    String remainingContent = content.substring(lastIndex).trim();
    // Remove <|im_end|> if it exists at the end of the remaining content
    if (imEndRegex.hasMatch(remainingContent)) {
      remainingContent = remainingContent.replaceAll(imEndRegex, '').trim();
    }
    finalOutput = remainingContent;
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
