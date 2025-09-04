import 'package:flutter/material.dart';
import 'package:moollama/database_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:restart_app/restart_app.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:feature_flags/feature_flags.dart';
import 'package:moollama/main.dart';

class SettingsPage extends StatelessWidget {
  final int? agentId;

  const SettingsPage({super.key, this.agentId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.bug_report_outlined),
                label: const Text('View Logs'),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => TalkerScreen(
                        talker: talker,
                        theme: TalkerScreenTheme(
                          cardColor: Theme.of(context).cardColor,
                          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                          textColor:
                              Theme.of(context).textTheme.bodyLarge?.color ?? Colors.white,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.flag),
                label: const Text('Manage Feature Flags'),
                onPressed: () {
                  DebugFeatures.show(
                    context,
                    availableFeatures: [
                      Feature('DECREMENT', name: 'Decrement'),
                      Feature('RESET', name: 'Reset'),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            _ShakeToFeedbackToggle(), // New toggle widget
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

class _ShakeToFeedbackToggle extends StatefulWidget {
  const _ShakeToFeedbackToggle({super.key});

  @override
  State<_ShakeToFeedbackToggle> createState() => _ShakeToFeedbackToggleState();
}

class _ShakeToFeedbackToggleState extends State<_ShakeToFeedbackToggle> {
  bool _isShakeToFeedbackEnabled = true; // Default to true

  @override
  void initState() {
    super.initState();
    _loadShakeToFeedbackPreference();
  }

  Future<void> _loadShakeToFeedbackPreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isShakeToFeedbackEnabled =
          prefs.getBool('isShakeToFeedbackEnabled') ?? true;
    });
  }

  Future<void> _saveShakeToFeedbackPreference(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isShakeToFeedbackEnabled', value);
  }

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      title: const Text('Enable Shake to Feedback'),
      value: _isShakeToFeedbackEnabled,
      onChanged: (bool value) {
        setState(() {
          _isShakeToFeedbackEnabled = value;
        });
        _saveShakeToFeedbackPreference(value);
      },
    );
  }
}