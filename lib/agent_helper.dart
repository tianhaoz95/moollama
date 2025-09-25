import 'package:cactus/cactus.dart';
import 'package:moollama/tools.dart';

void addAgentTools(
  CactusAgent agent,
  List<String> selectedTools,
  List<AgentTool> availableTools,
) {
  for (final tool in availableTools) {
    if (selectedTools.contains(tool.name)) {
      agent.addTool(
        tool.name,
        tool.executor,
        tool.description,
        tool.parameters,
      );
    }
  }
}
