
import 'package:cactus/cactus.dart';
import 'package:dio/dio.dart';
import 'package:sanitize_html/sanitize_html.dart';
import 'package:html2md/html2md.dart' as html2md;
import 'package:flutter_email_sender/flutter_email_sender.dart';

class AgentTool {
  final CactusTool tool;
  final Future<dynamic> Function(Map<String, dynamic> args) executor;

  AgentTool({
    required this.tool,
    required this.executor,
  });
}

Future<dynamic> fetchWebpageExecutor(Map<String, dynamic> args) async {
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

final fetchWebpageTool = AgentTool(
  tool: CactusTool(
    name: 'fetch_webpage',
    description:
        'Fetches the content of a webpage from a given URL. Use this tool to get information from the internet.',
    parameters: ToolParametersSchema(
      properties: {
        'url': ToolParameter(
          type: 'string',
          description: 'The URL of the webpage to fetch.',
          required: true,
        ),
      },
    ),
  ),
  executor: fetchWebpageExecutor,
);

Future<dynamic> sendEmailExecutor(Map<String, dynamic> args) async {
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

final sendEmailAgentTool = AgentTool(
  tool: CactusTool(
    name: 'send_email',
    description: 'Sends an email to the specified recipients.',
    parameters: ToolParametersSchema(
      properties: {
        'recipients': ToolParameter(
          type: 'array',
          description: 'A list of email addresses to send the email to.',
          required: true,
        ),
        'subject': ToolParameter(
          type: 'string',
          description: 'The subject of the email.',
          required: false,
        ),
        'body': ToolParameter(
          type: 'string',
          description: 'The body of the email.',
          required: false,
        ),
      },
    ),
  ),
  executor: sendEmailExecutor,
);

Future<dynamic> fetchCurrentTimeExecutor(Map<String, dynamic> args) async {
  final now = DateTime.now();
  return "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
}

final fetchCurrentTimeTool = AgentTool(
  tool: CactusTool(
    name: 'fetch_current_time',
    description: 'Returns the current date and time in ISO 8601 format.',
    parameters: ToolParametersSchema(properties: {}),
  ),
  executor: fetchCurrentTimeExecutor,
);

final List<AgentTool> allAgentTools = [
  fetchWebpageTool,
  sendEmailAgentTool,
  fetchCurrentTimeTool,
];

