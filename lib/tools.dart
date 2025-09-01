import 'package:cactus/cactus.dart';
import 'package:dio/dio.dart';
import 'package:sanitize_html/sanitize_html.dart';
import 'package:html2md/html2md.dart' as html2md;
import 'package:flutter_email_sender/flutter_email_sender.dart';

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
  description:
      'Fetches the content of a webpage from a given URL. Use this tool to get information from the internet.',
  parameters: {
    'url': Parameter(
      type: 'string',
      description: 'The URL of the webpage to fetch.',
      required: true,
    ),
  },
);

class SendEmailTool extends ToolExecutor {
  @override
  Future<dynamic> execute(Map<String, dynamic> args) async {
    final recipients = (args['recipients'] as List<dynamic>)
        .map((e) => e.toString())
        .toList();
    final subject = args['subject'] as String? ?? '';
    final body = args['body'] as String? ?? '';

    final Email email = Email(
      body: body,
      subject: subject,
      recipients: recipients,
      isHTML: false,
    );

    try {
      await FlutterEmailSender.send(email);
      return 'Email sent successfully!';
    } catch (e) {
      return 'Error sending email: $e';
    }
  }
}

final sendEmailAgentTool = AgentTool(
  name: 'send_email',
  executor: SendEmailTool(),
  description: 'Sends an email to the specified recipients.',
  parameters: {
    'recipients': Parameter(
      type: 'array',
      description: 'A list of email addresses to send the email to.',
      required: true,
    ),
    'subject': Parameter(
      type: 'string',
      description: 'The subject of the email.',
      required: false,
    ),
    'body': Parameter(
      type: 'string',
      description: 'The body of the email.',
      required: false,
    ),
  },
);
