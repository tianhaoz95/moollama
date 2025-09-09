import 'package:flutter/material.dart';
import 'package:moollama/database_helper.dart';
import 'package:moollama/models.dart'; // Import models.dart to use the Model class if needed
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';
import 'package:cactus/cactus.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class ManageModelsPage extends StatefulWidget {
  final Talker talker;

  const ManageModelsPage({super.key, required this.talker});

  @override
  State<ManageModelsPage> createState() => _ManageModelsPageState();
}

class _ManageModelsPageState extends State<ManageModelsPage> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> _models = [];
  final Map<String, double?> _downloadProgress = {};
  final Map<String, String> _downloadStatus = {};

  @override
  void initState() {
    super.initState();
    _loadModels();
  }

  Future<String> _getModelFilePath(String modelName, String? filename) async {
    if (filename == null) {
      return p.join(
        (await getApplicationDocumentsDirectory()).path,
        '$modelName.gguf',
      );
    }
    return p.join((await getApplicationDocumentsDirectory()).path, filename);
  }

  Future<void> _downloadModel(Map<String, dynamic> model) async {
    final modelName = model['name'];
    final modelUrl = model['url'];
    String? filename = model['filename'];

    if (modelUrl == null) {
      widget.talker.error('Model URL not found for $modelName');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: Model URL not found for $modelName')),
      );
      return;
    }

    setState(() {
      _downloadProgress[modelName] = 0.0;
      _downloadStatus[modelName] = 'Starting download...';
    });

    try {
      final agent = CactusAgent();
      await agent.download(
        modelUrl: modelUrl,
        onProgress: (progress, statusMessage, isError) {
          setState(() {
            _downloadProgress[modelName] = progress;
            _downloadStatus[modelName] = statusMessage;
            if (isError) {
              _downloadStatus[modelName] = 'Error: $statusMessage';
            }
          });
        },
      );

      // After successful download, update filename in DB if it was null
      if (filename == null) {
        filename = modelUrl.split('/').last;
        await _dbHelper.updateModel({
          'id': model['id'],
          'name': modelName,
          'url': modelUrl,
          'filename': filename,
        });
      }

      setState(() {
        _downloadProgress[modelName] = 1.0;
        _downloadStatus[modelName] = 'Download complete!';
      });
      _refreshModels(); // Refresh the list to show downloaded status
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Model $modelName downloaded successfully!')),
      );
    } catch (e, s) {
      widget.talker.error('Error downloading model $modelName: $e', e, s);
      setState(() {
        _downloadProgress[modelName] = null;
        _downloadStatus[modelName] = 'Download failed: $e';
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error downloading model $modelName: $e')),
      );
    }
  }

  Future<void> _loadModels() async {
    final models = await _dbHelper.getModels();
    List<Map<String, dynamic>> modelsWithStatus = [];
    for (var model in models) {
      final modelName = model['name'];
      final filename = model['filename'];
      final modelFilePath = await _getModelFilePath(modelName, filename);
      final modelFile = File(modelFilePath);
      final bool isDownloaded = await modelFile.exists();
      if (isDownloaded) {
        _downloadProgress[modelName] = 1.0;
        _downloadStatus[modelName] = 'Downloaded';
      } else {
        _downloadProgress[modelName] = null;
        _downloadStatus[modelName] = '';
      }
      modelsWithStatus.add({
        ...model,
        'isDownloaded': isDownloaded,
      });
    }
    setState(() {
      _models = modelsWithStatus;
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
                          Expanded(
                            child: Text(
                              model['url'],
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.link),
                            onPressed: () async {
                              final url = Uri.parse(model['url']);
                              if (await canLaunchUrl(url)) {
                                await launchUrl(url);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Could not launch ${model['url']}')),
                                );
                              }
                            },
                          ),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (model['isDownloaded'])
                            const Icon(Icons.check_circle, color: Colors.green)
                          else if (_downloadProgress[model['name']] != null)
                            SizedBox(
                              width: 80,
                              child: LinearProgressIndicator(
                                value: _downloadProgress[model['name']],
                                backgroundColor: Colors.grey[300],
                                color: Colors.blue,
                              ),
                            ),
                          if (_downloadStatus[model['name']] != null &&
                              _downloadProgress[model['name']] == null)
                            Text(_downloadStatus[model['name']]!),
                          if (!model['isDownloaded'] &&
                              _downloadProgress[model['name']] == null)
                            IconButton(
                              icon: const Icon(Icons.download),
                              onPressed: () => _downloadModel(model),
                            ),
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