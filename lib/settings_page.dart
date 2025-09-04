import 'package:flutter/material.dart';
import 'package:moollama/database_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:restart_app/restart_app.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:feature_flags/feature_flags.dart';

class SettingsPage extends StatefulWidget {
  final int? agentId;
  final Talker talker;

  const SettingsPage({super.key, this.agentId, required this.talker});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _shakeToFeedbackEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadShakeToFeedbackSetting();
  }

  Future<void> _loadShakeToFeedbackSetting() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _shakeToFeedbackEnabled = prefs.getBool('shakeToFeedbackEnabled') ?? false;
    });
  }

  Future<void> _setShakeToFeedbackSetting(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('shakeToFeedbackEnabled', value);
    setState(() {
      _shakeToFeedbackEnabled = value;
    });
  }

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
                        talker: widget.talker, // Use talker from constructor
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
              ), // Corrected: Removed extra '\n' here
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Shake to Feedback'),
              value: _shakeToFeedbackEnabled,
              onChanged: _setShakeToFeedbackSetting,
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