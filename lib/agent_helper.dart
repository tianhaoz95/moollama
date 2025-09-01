import 'package:cactus/cactus.dart';
import 'package:secret_agent/tools.dart';

void addAgentTools(CactusAgent agent) {
  agent.addTool(
    weatherAgentTool.name,
    weatherAgentTool.executor,
    weatherAgentTool.description,
    weatherAgentTool.parameters,
  );
  agent.addTool(
    fetchWebpageTool.name,
    fetchWebpageTool.executor,
    fetchWebpageTool.description,
    fetchWebpageTool.parameters,
  );
  agent.addTool(
    sendEmailAgentTool.name,
    sendEmailAgentTool.executor,
    sendEmailAgentTool.description,
    sendEmailAgentTool.parameters,
  );
}
