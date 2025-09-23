import 'package:cactus/cactus.dart';
import 'package:moollama/tools.dart';

List<CactusTool> getCactusTools(List<String> selectedTools, List<AgentTool> availableTools) {
  final List<CactusTool> cactusTools = [];
  for (final tool in availableTools) {
    if (selectedTools.contains(tool.tool.name)) {
      cactusTools.add(tool.tool);
    }
  }
  return cactusTools;
}