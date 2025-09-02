import 'package:cactus/cactus.dart';
import 'package:secret_agent/tools.dart';

void addAgentTools(CactusAgent agent, List<String> selectedTools) {
  if (selectedTools.contains('fetch_webpage')) {
    agent.addTool(
      fetchWebpageTool.name,
      fetchWebpageTool.executor,
      fetchWebpageTool.description,
      fetchWebpageTool.parameters,
    );
  }
  if (selectedTools.contains('send_email')) {
    agent.addTool(
      sendEmailAgentTool.name,
      sendEmailAgentTool.executor,
      sendEmailAgentTool.description,
      sendEmailAgentTool.parameters,
    );
  }
  if (selectedTools.contains('fetch_current_time')) {
    agent.addTool(
      fetchCurrentTimeTool.name,
      fetchCurrentTimeTool.executor,
      fetchCurrentTimeTool.description,
      fetchCurrentTimeTool.parameters,
    );
  }
}