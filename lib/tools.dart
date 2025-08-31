import 'package:cactus/cactus.dart';

class AgentTool {
  final String name;
  final ToolExecutor executor;
  final String description;
  final Map<String, Parameter> parameters;

  AgentTool({
    required this.name,
    required this.executor,
    required this.description,
    required this.parameters,
  });
}

class WeatherTool extends ToolExecutor {
  @override
  Future<dynamic> execute(Map<String, dynamic> args) async {
    final location = args['location'] as String? ?? 'unknown';
    return 'The weather in $location is sunny, 72°F';
  }
}

final weatherAgentTool = AgentTool(
  name: 'get_weather',
  executor: WeatherTool(),
  description: 'Get current weather information for a location',
  parameters: {
    'location': Parameter(
      type: 'string',
      description: 'The location to get weather for',
      required: true,
    ),
  },
);
