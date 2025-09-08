
import 'package:flutter/material.dart';
import 'package:moollama/database_helper.dart';
import 'package:moollama/models.dart'; // Import models.dart to use the Model class if needed
import 'package:url_launcher/url_launcher.dart';

class ManageModelsPage extends StatefulWidget {
  const ManageModelsPage({super.key});

  @override
  State<ManageModelsPage> createState() => _ManageModelsPageState();
}

class _ManageModelsPageState extends State<ManageModelsPage> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> _models = [];

  @override
  void initState() {
    super.initState();
    _loadModels();
  }

  Future<void> _loadModels() async {
    final models = await _dbHelper.getModels();
    setState(() {
      _models = models;
    });
  }

  void _refreshModels() {
    _loadModels();
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
                  labelText: 'Model URL',
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // TODO: Implement file selection
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('File selection not yet implemented.')),
                    );
                  },
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
                final String nickname = nicknameController.text;
                final String url = urlController.text;
                if (nickname.isNotEmpty && url.isNotEmpty) {
                  await _dbHelper.insertModel({'name': nickname, 'url': url});
                  _refreshModels();
                  if (!context.mounted) return;
                  Navigator.of(context).pop(); // Dismiss the dialog
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Model added successfully!')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter both nickname and URL.')),
                  );
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  void _showEditModelDialog(BuildContext context, Map<String, dynamic> model) {
    final TextEditingController nicknameController =
        TextEditingController(text: model['name']);
    final TextEditingController urlController =
        TextEditingController(text: model['url']);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Edit Model'),
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
                  labelText: 'Model URL',
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
                final String nickname = nicknameController.text;
                final String url = urlController.text;
                if (nickname.isNotEmpty && url.isNotEmpty) {
                  await _dbHelper.updateModel({
                    'id': model['id'],
                    'name': nickname,
                    'url': url,
                  });
                  _refreshModels();
                  if (!context.mounted) return;
                  Navigator.of(context).pop(); // Dismiss the dialog
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Model updated successfully!')),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Please enter both nickname and URL.')),
                  );
                }
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }

  void _deleteModel(int id) async {
    await _dbHelper.deleteModel(id);
    _refreshModels();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Model deleted successfully!')),
    );
  }

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not launch $urlString')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Local Models'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add),
                label: const Text('Add New Model'),
                onPressed: () {
                  _showAddModelDialog(context);
                },
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _models.length,
                itemBuilder: (context, index) {
                  final model = _models[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    child: ListTile(
                      title: Text(model['name']),
                      subtitle: Row(
                        children: [
                          Expanded(child: Text(model['url'])),
                          IconButton(
                            icon: const Icon(Icons.link),
                            onPressed: () {
                              _launchUrl(model['url']);
                            },
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () {
                              _showEditModelDialog(context, model);
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () {
                              _deleteModel(model['id']);
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
