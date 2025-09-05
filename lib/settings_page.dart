import 'package:flutter/material.dart';
import 'package:moollama/database_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:restart_app/restart_app.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:file_picker/file_picker.dart';

class SettingsPage extends StatefulWidget {
  final int? agentId;
  final Talker talker;

  const SettingsPage({super.key, this.agentId, required this.talker});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  List<String> _availableModels = [];
  final DatabaseHelper _dbHelper = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    _loadAvailableModels();
  }

  Future<void> _loadAvailableModels() async {
    final models = await _dbHelper.getDistinctModelNames();
    setState(() {
      _availableModels = models;
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
                        talker: widget.talker, // Use widget.talker
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
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Add Model'),
                onPressed: () {
                  _showAddModelDialog(context);
                },
              ),
            ),
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Available Models'),
                Wrap(
                  spacing: 8.0,
                  runSpacing: 4.0,
                  children: _availableModels
                      .map(
                        (modelName) => Chip(
                          label: Text(modelName),
                          backgroundColor: Colors.grey[200],
                          labelStyle: const TextStyle(color: Colors.black),
                          deleteIcon: const Icon(Icons.cancel),
                          onDeleted: () => _deleteModel(modelName),
                        ),
                      )
                      .toList(),
                ),
              ],
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

  Future<void> _deleteModel(String modelName) async {
    final bool confirmDelete = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Deletion'),
          content: Text('Are you sure you want to delete the model "$modelName"?'),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    ) ?? false;

    if (confirmDelete) {
      // Get the model ID from the database using its name
      final models = await _dbHelper.getModels();
      final modelToDelete = models.firstWhere((m) => m['name'] == modelName);
      if (modelToDelete['id'] != null) {
        await _dbHelper.deleteModel(modelToDelete['id']);
        _loadAvailableModels(); // Refresh the list
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Model "$modelName" deleted.')),
        );
      }
    }
  }

  void _pickModelFile(TextEditingController urlController) async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['gguf'],
    );

    if (result != null && result.files.single.path != null) {
      urlController.text = result.files.single.path!;
    } else {
      // User canceled the picker or no file selected
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No file selected.')),
      );
    }
  }

  void _showAddModelDialog(BuildContext context) {
    final TextEditingController nicknameController = TextEditingController();
    final TextEditingController urlController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add New Model'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nicknameController,
                decoration: const InputDecoration(
                  labelText: 'Model Nickname',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: urlController,
                decoration: const InputDecoration(
                  labelText: 'Model URL or File Path',
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _pickModelFile(urlController),
                  child: const Text('Select from Files'),
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Dismiss the dialog
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final String nickname = nicknameController.text.trim();
                final String url = urlController.text.trim();

                if (nickname.isEmpty || url.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Nickname and URL/File Path cannot be empty.')),
                  );
                  return;
                }

                await _dbHelper.insertModel({'name': nickname, 'url': url});
                _loadAvailableModels(); // Refresh the list of available models
                if (!mounted) return;
                Navigator.of(context).pop(); // Dismiss the dialog
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Model "$nickname" added successfully.')),
                );
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }
}
