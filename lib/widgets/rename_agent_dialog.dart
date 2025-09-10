import 'package:flutter/material.dart';
import 'package:moollama/widgets/custom_alert_dialog.dart';

class RenameAgentDialog extends StatefulWidget {
  final String initialAgentName;

  const RenameAgentDialog({super.key, required this.initialAgentName});

  @override
  State<RenameAgentDialog> createState() => _RenameAgentDialogState();
}

class _RenameAgentDialogState extends State<RenameAgentDialog> {
  late final TextEditingController _renameController;

  @override
  void initState() {
    super.initState();
    _renameController = TextEditingController(text: widget.initialAgentName);
  }

  @override
  void dispose() {
    _renameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomAlertDialog(
      title: const Text('Rename Agent'),
      content: TextField(
        controller: _renameController,
        decoration: const InputDecoration(hintText: "Enter new agent name"),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('Cancel'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        TextButton(
          child: const Text('Rename'),
          onPressed: () {
            Navigator.of(context).pop(_renameController.text);
          },
        ),
      ],
    );
  }
}
