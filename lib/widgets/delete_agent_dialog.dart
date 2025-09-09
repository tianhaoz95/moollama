import 'package:flutter/material.dart';

class DeleteAgentDialog extends StatelessWidget {
  final String agentName;

  const DeleteAgentDialog({super.key, required this.agentName});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Delete Agent'),
      content: Text(
        'Are you sure you want to delete agent "$agentName"?',
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('Cancel'),
          onPressed: () {
            Navigator.of(context).pop(false); // User cancelled
          },
        ),
        TextButton(
          child: const Text('Delete'),
          onPressed: () {
            Navigator.of(context).pop(true); // User confirmed
          },
        ),
      ],
    );
  }
}
