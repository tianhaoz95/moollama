import 'package:flutter/material.dart';
import 'package:moollama/models.dart';
import 'package:moollama/widgets/agent_item.dart';
import 'package:moollama/settings_page.dart';
import 'package:talker_flutter/talker_flutter.dart';

class AgentDrawer extends StatelessWidget {
  final List<Agent> agents;
  final Function(Agent) onRenameAgent;
  final Function(Agent) onSelectAgent;
  final Function(Agent) onDeleteAgent;
  final Function(BuildContext) onAddAgent;
  final Agent? selectedAgent;
  final Talker talker;

  const AgentDrawer({
    super.key,
    required this.agents,
    required this.onRenameAgent,
    required this.onSelectAgent,
    required this.onDeleteAgent,
    required this.onAddAgent,
    required this.selectedAgent,
    required this.talker,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: <Widget>[
                const DrawerHeader(
                  child: Text('Agents', style: TextStyle(fontSize: 24)),
                ),
                ...agents.asMap().entries.map((entry) {
                  Agent agent = entry.value;
                  return AgentItem(
                    agent: agent,
                    onRename: () => onRenameAgent(agent),
                    onTap: () => onSelectAgent(agent),
                    onLongPress: () => onDeleteAgent(agent),
                  );
                }),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 32.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    onAddAgent(context);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => SettingsPage(
                          agentId: selectedAgent?.id,
                          talker: talker,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
