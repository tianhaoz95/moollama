import 'package:cactus/cactus.dart';
import 'package:dio/dio.dart';
import 'package:sanitize_html/sanitize_html.dart';
import 'package:html2md/html2md.dart' as html2md;

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

class FetchWebpageTool extends ToolExecutor {
  @override
  Future<dynamic> execute(Map<String, dynamic> args) async {
    final url = args['url'] as String?;
    if (url == null) {
      return 'Error: URL is required.';
    }
    try {
      final dio = Dio();
      final response = await dio.get(url);
      final sanitizedHtml = sanitizeHtml(response.data.toString());
      final markdown = html2md.convert(sanitizedHtml);
      return markdown;
    } catch (e) {
      return 'Error fetching webpage: $e';
    }
  }
}

final fetchWebpageTool = AgentTool(
  name: 'fetch_webpage',
  executor: FetchWebpageTool(),
  description: 'Fetches the content of a webpage from a given URL. Use this tool to get information from the internet.',
  parameters: {
    'url': Parameter(
      type: 'string',
      description: 'The URL of the webpage to fetch.',
      required: true,
    ),
  },
);