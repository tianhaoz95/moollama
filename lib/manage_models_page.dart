import 'package:flutter/material.dart';
import 'package:moollama/database_helper.dart';
import 'package:moollama/models.dart'; // Import models.dart to use the Model class if needed
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'dart:io';
import 'package:cactus/cactus.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart'; // Added import
import 'package:toggle_switch/toggle_switch.dart';

class ManageModelsPage extends StatefulWidget {
  final Talker talker;

  const ManageModelsPage({super.key, required this.talker});

  @override
  State<ManageModelsPage> createState() => _ManageModelsPageState();
}

enum ModelInputType { url, file }

class _ManageModelsPageState extends State<ManageModelsPage> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> _models = [];
  final Map<String, double?> _downloadProgress = {};
  final Map<String, String> _downloadStatus = {};
  PlatformFile? _pickedFile;
  ModelInputType _selectedInputType = ModelInputType.url;

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
      final agent = CactusLM();
      await agent.downloadModel(
        model: model['name'],
        downloadProcessCallback: (progress, statusMessage, isError) {
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
      modelsWithStatus.add({...model, 'isDownloaded': isDownloaded});
    }
    setState(() {
      _models = modelsWithStatus;
    });
  }

  void _refreshModels() {
    _loadModels();
  }

  Future<PlatformFile?> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
      );

      if (result != null) {
        PlatformFile file = result.files.first;
        if (file.extension?.toLowerCase() != 'gguf') {
          if (!mounted) return null;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select a .gguf file.')),
          );
          return null;
        }
        return file;
      } else {
        // User canceled the picker
        if (!mounted) return null;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File selection cancelled.')),
        );
        return null;
      }
    } catch (e) {
      widget.talker.error('Error picking file: $e', e);
      if (!mounted) return null;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error picking file: $e')));
      return null;
    }
  }

  void _showAddModelDialog(BuildContext context) {
    final TextEditingController nicknameController = TextEditingController();
    final TextEditingController urlController = TextEditingController();
    final TextEditingController filenameController = TextEditingController();

    // Listener to update filename from URL
    urlController.addListener(() {
      try {
        final uri = Uri.parse(urlController.text);
        if (uri.pathSegments.isNotEmpty) {
          filenameController.text = uri.pathSegments.last;
        }
      } catch (e) {
        // Ignore parsing errors, filename will remain empty or as set by file picker
      }
    });

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          // Use StatefulBuilder to update dialog content
          builder: (context, setState) {
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
                  ToggleSwitch(
                    minWidth: 90.0,
                    cornerRadius: 20.0,
                    activeBgColors: [
                      [Colors.blue[800]!],
                      [Colors.blue[800]!],
                    ],
                    activeFgColor: Colors.white,
                    inactiveBgColor: Colors.grey,
                    inactiveFgColor: Colors.white,
                    initialLabelIndex: _selectedInputType == ModelInputType.url
                        ? 0
                        : 1,
                    totalSwitches: 2,
                    labels: const ['From URL', 'Upload File'],
                    radiusStyle: true,
                    onToggle: (index) {
                      setState(() {
                        _selectedInputType = index == 0
                            ? ModelInputType.url
                            : ModelInputType.file;
                        if (_selectedInputType == ModelInputType.url) {
                          _pickedFile =
                              null; // Clear picked file when switching to URL
                          filenameController.clear(); // Clear filename
                        } else {
                          urlController
                              .clear(); // Clear URL when switching to file
                          filenameController.clear(); // Clear filename
                        }
                      });
                    },
                  ),
                  if (_selectedInputType == ModelInputType.url) ...[
                    TextField(
                      controller: urlController,
                      decoration: const InputDecoration(labelText: 'Model URL'),
                    ),
                    const SizedBox(height: 16),
                  ] else ...[
                    // Display filename as text, not editable
                    Align(
                      alignment: Alignment.centerLeft,
                      child: ValueListenableBuilder<TextEditingValue>(
                        valueListenable: filenameController,
                        builder: (context, value, child) {
                          return Text(
                            value.text.isEmpty
                                ? 'Filename: (not selected)'
                                : 'Filename: ${value.text}',
                            style: const TextStyle(fontSize: 16),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          final result = await _pickFile();
                          if (result != null) {
                            setState(() {
                              // Update dialog state after file pick
                              _pickedFile = result; // Store the picked file
                              filenameController.text = result.name;
                            });
                          }
                        },
                        child: const Text('Select from Files'),
                      ),
                    ),
                  ],
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
                    String? url;
                    String? filename;

                    if (_selectedInputType == ModelInputType.url) {
                      url = urlController.text;
                      filename = filenameController.text.isNotEmpty
                          ? filenameController.text
                          : null;
                      if (nickname.isEmpty || url!.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Please enter both nickname and URL.',
                            ),
                          ),
                        );
                        return;
                      }
                    } else {
                      // ModelInputType.file
                      if (_pickedFile == null || _pickedFile!.path == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please select a file.'),
                          ),
                        );
                        return;
                      }
                      filename = _pickedFile!.name;
                      if (nickname.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Please enter a nickname.'),
                          ),
                        );
                        return;
                      }
                    }

                    if (_pickedFile != null && _pickedFile!.path != null) {
                      final appDocDir =
                          await getApplicationDocumentsDirectory();
                      final newFilePath = p.join(
                        appDocDir.path,
                        _pickedFile!.name,
                      );
                      final newFile = File(newFilePath);
                      await File(_pickedFile!.path!).copy(newFile.path);
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'File ${_pickedFile!.name} copied successfully!',
                          ),
                        ),
                      );
                    }

                    await _dbHelper.insertModel({
                      'name': nickname,
                      'url': url,
                      'filename': filename,
                    });
                    _refreshModels();
                    if (!context.mounted) return;
                    Navigator.of(context).pop(); // Dismiss the dialog
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Model added successfully!'),
                      ),
                    );
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showEditModelDialog(BuildContext context, Map<String, dynamic> model) {
    final TextEditingController nicknameController = TextEditingController(
      text: model['name'],
    );
    final TextEditingController urlController = TextEditingController(
      text: model['url'],
    );

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
                decoration: const InputDecoration(labelText: 'Model Nickname'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: urlController,
                decoration: const InputDecoration(labelText: 'Model URL'),
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
                    const SnackBar(
                      content: Text('Model updated successfully!'),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please enter both nickname and URL.'),
                    ),
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
      appBar: AppBar(title: const Text('Manage Local Models')),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddModelDialog(context);
        },
        child: const Icon(Icons.add),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: _models.length,
                itemBuilder: (context, index) {
                  final model = _models[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            model['name'],
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.link),
                                onPressed: () async {
                                  final url = Uri.parse(model['url']);
                                  if (await canLaunchUrl(url)) {
                                    await launchUrl(url);
                                  } else {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Could not launch ${model['url']}',
                                        ),
                                      ),
                                    );
                                  }
                                },
                              ),
                              const Spacer(),
                              if (model['isDownloaded'])
                                const Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Icon(
                                    Icons.check_circle,
                                    color: Colors.green,
                                    size: 24.0,
                                  ),
                                )
                              else if (_downloadProgress[model['name']] != null)
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      value: _downloadProgress[model['name']],
                                    ),
                                  ),
                                )
                              else if (_downloadStatus[model['name']] != null)
                                Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Text(_downloadStatus[model['name']]!),
                                ),
                              if (!model['isDownloaded'] &&
                                  _downloadProgress[model['name']] == null)
                                IconButton(
                                  icon: const Icon(Icons.download),
                                  onPressed: () => _downloadModel(model),
                                ),
                              IconButton(
                                icon: const Icon(Icons.ios_share),
                                onPressed: () async {
                                  final directory =
                                      await getApplicationDocumentsDirectory();
                                  String filename = model['filename'];
                                  if (filename == null &&
                                      model['url'] != null) {
                                    filename = p.basename(model['url']);
                                  }
                                  final filePath =
                                      '${directory.path}/$filename';
                                  final file = XFile(filePath);
                                  try {
                                    await Share.shareXFiles([
                                      file,
                                    ], text: 'Sharing model file');
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Error sharing file: $e'),
                                      ),
                                    );
                                  }
                                },
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
