import 'package:cactus/cactus.dart';
import 'package:moollama/agent.dart';
import 'package:moollama/tools.dart';
import 'package:talker_flutter/talker_flutter.dart';

final talker = TalkerFlutter.init();

class CactusAgentAdapter implements Agent {
  CactusAgent? _cactusAgent;

  @override
  Future<void> initialize({
    required String modelPath,
    int? contextLength,
  }) async {
    _cactusAgent = CactusAgent();
    final gpuLayerCount = await getGpuLayerCount();
    talker.info('GPU Layer Count: \$gpuLayerCount');
    talker.info('Model file path: \$modelPath');
    await _cactusAgent!.init(
      modelFilename: modelPath,
      contextSize: contextLength ?? 8192, // Default to 8192 if not provided
      gpuLayers: gpuLayerCount,
      onProgress: (progress, statusMessage, isError) {
        // TODO: Pass progress updates to UI if needed
        talker.info('Cactus initialization progress: \$progress, status: \$statusMessage');
      },
    );
    if (tools != null && tools.isNotEmpty) {
      addAgentTools(_cactusAgent!, tools, allAgentTools);
    }
  }

  @override
  Stream<AgentResponse> generate(AgentRequest request) async* {
    if (_cactusAgent == null) {
      yield AgentResponse(
        status: AgentResponseStatus.error,
        errorMessage: 'Cactus agent not initialized.',
      );
      return;
    }

    final List<ChatMessage> messages = [];
    if (request.systemPrompt.isNotEmpty) {
      messages.add(ChatMessage(role: 'system', content: request.systemPrompt));
    }

    // Parse history into ChatMessage objects
    final historyLines = request.history.split('\n');
    for (final line in historyLines) {
      if (line.startsWith('User: ')) {
        messages.add(ChatMessage(role: 'user', content: line.substring(6)));
      } else if (line.startsWith('Assistant: ')) {
        messages.add(ChatMessage(role: 'assistant', content: line.substring(11)));
      }
    }

    messages.add(ChatMessage(role: 'user', content: request.prompt));

    try {
      final completionResult = await _cactusAgent!.completionWithTools(
        messages,
        maxTokens: 2048, // This should probably be configurable
        temperature: request.temperature,
      );

      if (completionResult != null) {
        yield AgentResponse(
          response: completionResult.result,
          status: AgentResponseStatus.success,
        );
      } else {
        yield AgentResponse(
          status: AgentResponseStatus.error,
          errorMessage: 'Empty completion result from Cactus.',
        );
      }
    } catch (e) {
      yield AgentResponse(
        status: AgentResponseStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  @override
  void unload() {
    _cactusAgent?.unload();
  }
}
