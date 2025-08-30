class ThinkingModelResponse {
  final List<String> thinkingSessions;
  final String finalOutput;

  ThinkingModelResponse({
    required this.thinkingSessions,
    required this.finalOutput,
  });
}

ThinkingModelResponse splitContentByThinkTags(String content) {
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
