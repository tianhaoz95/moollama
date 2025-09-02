import 'package:flutter/material.dart';
import 'package:secret_agent/database_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:restart_app/restart_app.dart';

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
            ListTile(
              title: const Text('Select Tools'),
              subtitle: const Text('Tap to select tools for this agent'),
              onTap: () {
                _showToolSelectionDialog(context);
              },
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

  void _showToolSelectionDialog(BuildContext context) {
    final List<String> availableTools = [
      "webpage-fetcher",
      "alarm-setter",
      "weather-fetcher",
    ];
    // This list will hold the current selection state for the UI only
    // No actual logic for saving/loading selection is implemented as per requirements
    final List<bool> _selectedTools = List.generate(availableTools.length, (index) => false);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Select Tools'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: availableTools.asMap().entries.map((entry) {
                int idx = entry.key;
                String tool = entry.value;
                return CheckboxListTile(
                  title: Text(tool),
                  value: _selectedTools[idx], // Placeholder value
                  onChanged: (bool? value) {
                    // No logic to update state as per requirements (UI only)
                    // In a real implementation, this would update _selectedTools and then setState
                  },
                );
              }).toList(),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Dismiss the dialog
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                // No logic to save selection as per requirements (UI only)
                Navigator.of(context).pop(); // Dismiss the dialog
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }
}

