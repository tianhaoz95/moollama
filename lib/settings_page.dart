import 'package:flutter/material.dart';
import 'package:secret_agent/database_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:restart_app/restart_app.dart';

class SettingsPage extends StatefulWidget {
  final int? agentId;

  const SettingsPage({super.key, this.agentId});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  double _contextWindowSize = 2048; // Default value
  TextEditingController _systemPromptController = TextEditingController();

  @override
  void dispose() {
    _systemPromptController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Context Window Size Slider
            Row(
              children: [
                const Text('Context Window Size:'),
                Expanded(
                  child: Slider(
                    value: _contextWindowSize,
                    min: 512,
                    max: 4096,
                    divisions: 7, // (4096 - 512) / 512 = 7
                    label: _contextWindowSize.round().toString(),
                    onChanged: (double value) {
                      setState(() {
                        _contextWindowSize = value;
                      });
                    },
                  ),
                ),
                Text(_contextWindowSize.round().toString()),
              ],
            ),
            const SizedBox(height: 16),
            // System Prompt Text Field
            TextField(
              controller: _systemPromptController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'System Prompt',
                hintText: 'Enter system prompt here',
              ),
              maxLines: 5,
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  _confirmAndDeletePreferences(context);
                },
                child: const Text('Delete All Preferences'),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  _confirmAndDeleteData(context);
                },
                child: const Text('Delete All Data'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmAndDeletePreferences(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: const Text('Are you sure you want to delete all preferences? This action cannot be undone.'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Dismiss the dialog
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.clear();
                Restart.restartApp();
                if (!context.mounted) return;
                Navigator.of(context).pop(); // Dismiss the dialog
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All preferences deleted.')),
                );
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  void _confirmAndDeleteData(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: const Text('Are you sure you want to delete all data? This action cannot be undone.'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Dismiss the dialog
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final dbHelper = DatabaseHelper();
                await dbHelper.clearAllData(); // Call clearAllData()
                Restart.restartApp();
                if (!context.mounted) return;
                Navigator.of(context).pop(); // Dismiss the dialog
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All data deleted.')),
                );
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}

