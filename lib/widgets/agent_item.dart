import 'package:flutter/material.dart';
import 'package:moollama/models.dart';

class AgentItem extends StatelessWidget {
  const AgentItem({
    super.key,
    required this.agent,
    this.onRename,
    this.onTap,
    this.onLongPress,
  });

  final Agent agent;
  final VoidCallback? onRename;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress; // New callback for long press

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(agent.name),
      onTap: onTap,
      onLongPress: onLongPress, // Assign the new callback
      trailing: IconButton(icon: const Icon(Icons.edit), onPressed: onRename),
    );
  }
}