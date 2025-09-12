import 'package:card_loading/card_loading.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:moollama/database_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:moollama/settings_page.dart';
import 'package:cactus/cactus.dart';
import 'package:moollama/utils.dart';
import 'package:siri_wave/siri_wave.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:talker_flutter/talker_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:moollama/agent_helper.dart';
import 'package:moollama/tools.dart';

import 'package:shake/shake.dart';
import 'package:feedback/feedback.dart';

import 'package:path/path.dart' as p;
import 'dart:io';
import 'package:moollama/models.dart';

import 'package:moollama/widgets/agent_item.dart';
import 'package:moollama/widgets/agent_settings_drawer_content.dart';
import 'package:moollama/widgets/delete_agent_dialog.dart';
import 'package:moollama/widgets/rename_agent_dialog.dart';
import 'package:blur/blur.dart';
import 'package:moollama/widgets/listening_popup.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:background_downloader/background_downloader.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:async';

const bool FLAG_USE_BACKGROUND_DOWNLOADER = true;

final talker = TalkerFlutter.init();

class SecretAgentHome extends StatefulWidget {
  final ValueNotifier<ThemeMode> themeNotifier;
  final Talker talker;

  const SecretAgentHome({
    super.key,
    required this.themeNotifier,
    required this.talker,
  });

  @override
  State<SecretAgentHome> createState() => _SecretAgentHomeState();
}

class _SecretAgentHomeState extends State<SecretAgentHome> {
  final TextEditingController _textController = TextEditingController();
  final List<Message> _messages = [];
  final DatabaseHelper _dbHelper = DatabaseHelper();
  late Future<List<Message>> _messagesFuture;
  List<Agent> _agents = [];
  Agent? _selectedAgent;
  String _selectedModelName = 'Qwen3 0.6B'; // New field for selected model name
  double _creativity = 70.0;
  int _contextWindowSize = 8192;
  bool _isLoading = true;
  CactusAgent? _agent;
  double? _downloadProgress;
  bool _isGenerating = false; // New: To track if AI is generating
  bool _modelDownloaded = false;
  bool _cancellationToken = false; // New: To signal cancellation
  double? _initializationProgress;
  String _downloadStatus = 'Initializing...';

  final ScrollController _scrollController = ScrollController();
  bool _isListening = false;
  OverlayEntry? _listeningPopupEntry;
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  String _lastWords = '';
  String _systemPrompt = ''; // New field for system prompt
  late ShakeDetector _shakeDetector;
  late FlutterTts _flutterTts;
  bool _isTtsEnabled = false;
  StreamSubscription<dynamic>? _downloadSubscription;

  void _handleAgentLongPress(Agent agent) async {
    if (_agents.length == 1) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Cannot Delete Last Agent'),
            content: const Text('You cannot delete the last remaining agent.'),
            actions: <Widget>[
              TextButton(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    } else {
      _deleteAgent(agent); // Call the existing delete logic
    }
  }

  void _showListeningPopup(BuildContext context) async {
    _listeningPopupEntry = OverlayEntry(
      builder: (context) => ListeningPopup(lastWords: _lastWords),
    );
    Overlay.of(context).insert(_listeningPopupEntry!);
    setState(() {
      _isListening = true;
      _lastWords = '';
    });

    if (_speechToText.isAvailable) {
      await _speechToText.listen(
        onResult: (result) {
          setState(() {
            _lastWords = result.recognizedWords;
          });
          _listeningPopupEntry?.markNeedsBuild();
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 5),
        listenOptions: stt.SpeechListenOptions(partialResults: true),
      );
    } else {
      widget.talker.info('Speech recognition not available');
    }
  }

  void _hideListeningPopup() {
    _speechToText.stop();
    _listeningPopupEntry?.remove();
    _listeningPopupEntry = null;
    setState(() {
      _isListening = false;
      _lastWords = '';
    });
  }

  Future<void> _loadTtsSetting() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isTtsEnabled = prefs.getBool('isTtsEnabled') ?? false;
    });
  }

  Future<void> _setTtsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isTtsEnabled', enabled);
    setState(() {
      _isTtsEnabled = enabled;
    });
  }

  @override
  void initState() {
    super.initState();
    _messagesFuture = Future.value([]); // Initialize with an empty future
    _loadAgents(); // Load agents, which will then load messages
    _speechToText.initialize(
      onStatus: (status) =>
          widget.talker.info('Speech recognition status: $status'),
      onError: (errorNotification) =>
          widget.talker.info('Speech recognition error: $errorNotification'),
    );

    _flutterTts = FlutterTts();
    _loadTtsSetting(); // Load TTS setting from SharedPreferences

    _shakeDetector = ShakeDetector.autoStart(
      onPhoneShake: () async {
        // Show feedback UI
        BetterFeedback.of(context).show((feedback) async {
          final file = await saveFeedback(feedback, widget.talker);

          // In a real app, you would send this feedback to a backend service.
          try {
            final result = await Share.shareXFiles([
              XFile(file.path),
            ], text: feedback.text);
            if (result.status == ShareResultStatus.unavailable) {
              widget.talker.warning('Sharing is unavailable on this device.');
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Sharing is not available on this device.'),
                ),
              );
            }
          } catch (e, s) {
            widget.talker.error('Error sharing feedback', e, s);
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Could not share feedback.')),
            );
          }
        });
      },
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _shakeDetector.stopListening(); // Changed from stop() to stopListening()
    _downloadSubscription?.cancel(); // Cancel the download subscription
    super.dispose();
  }

  Future<void> _initializeCactusModel(String modelName) async {
    try {
      setState(() {
        _isLoading = true;
        _downloadProgress = null;
        _initializationProgress = null; // Reset initialization progress
        _downloadStatus = 'Checking model availability...'; // Updated status
      });
      _agent = CactusAgent();

      final modelFilePath = await _dbHelper.getModelFilePath(modelName);
      final modelFile = File(modelFilePath);

      bool modelExistsLocally = await modelFile.exists();

      if (!modelExistsLocally) {
        widget.talker.info(
          'Model $modelName not found locally. Initiating download.',
        );
        setState(() {
          _downloadStatus = 'Downloading model...';
        });
        final model = await _dbHelper.getModelByName(modelName);
        final modelUrl = model['url'];
        if (modelUrl == null) {
          widget.talker.error('Model URL not found for $modelName');
          throw Exception('Model URL not found for $modelName');
        }
        widget.talker.info('Model URL for $modelName: $modelUrl');
        if (FLAG_USE_BACKGROUND_DOWNLOADER) {
          final documentsDirectory = await getApplicationDocumentsDirectory();
          final filePath = p.join(
            documentsDirectory.path,
            p.basename(modelUrl),
          );
          final tempFilePath = p.join(
            documentsDirectory.path,
            'temp_${p.basename(modelUrl)}',
          );
          setState(() {
            _downloadProgress = 0.0; // Initialize progress to 0.0
            _downloadStatus = 'Downloading model...';
          });
          widget.talker.info(
            'Attempting to download using background_downloader...',
          );
          try {
            FileDownloader().configureNotification(
              running: TaskNotification('Downloading', 'file: {filename}'),
              complete: TaskNotification(
                'Download finished',
                'file: {filename}',
              ),
              progressBar: true,
            );
            widget.talker.info(
              'Attempting to download model file to ${documentsDirectory.path}',
            );
            final DownloadTask downloadTask = DownloadTask(
              url: modelUrl,
              filename: p.basename(tempFilePath),
              allowPause: false,
              updates: Updates.statusAndProgress,
              retries: 5,
              requiresWiFi: false,
            );
            widget.talker.info(
              'Download task initiated with ID: ${downloadTask.taskId}',
            );
            final result = await FileDownloader().download(
              downloadTask,
              onProgress: (progress) {
                setState(() {
                  _downloadProgress = progress;
                  _downloadStatus = 'Downloading: ${(progress * 100).toInt()}%';
                });
              },
              onStatus: (status) => widget.talker.info('Status: $status'),
            );
            widget.talker.info('Finished downloading task initiated: $result');
            switch (result.status) {
              case TaskStatus.complete:
                {
                  try {
                    final dir = Directory(documentsDirectory.path);
                    final files = await dir.list().toList();
                    widget.talker.info(
                      'Found ${files.length} files in ${dir.path}...',
                    );
                    for (final file in files) {
                      if (p.extension(file.path) == '.gguf') {
                        widget.talker.info('Found gguf file: ${file.path}');
                      } else {
                        widget.talker.info(
                          'Found non-model file: ${file.path}',
                        );
                      }
                    }
                    final tempFile = File(tempFilePath);
                    final modelFile = await tempFile.rename(filePath);
                    widget.talker.info('File renamed to: ${modelFile.path}');
                  } catch (e) {
                    widget.talker.info('Error renaming file: $e');
                  }
                  setState(() {
                    _downloadProgress = 1.0; // Indicate 100% downloaded
                    _downloadStatus = 'Model found locally.';
                    _modelDownloaded = true;
                  });
                }

              case TaskStatus.canceled:
                {
                  try {
                    final tempFile = File(tempFilePath);
                    await tempFile.delete();
                    widget.talker.info('File successfully deleted.');
                  } catch (e) {
                    widget.talker.info('Error deleting file: $e');
                  }
                  widget.talker.info('Download was canceled');
                }

              case TaskStatus.paused:
                {
                  try {
                    final tempFile = File(tempFilePath);
                    await tempFile.delete();
                    widget.talker.info('File successfully deleted.');
                  } catch (e) {
                    widget.talker.info('Error deleting file: $e');
                  }
                  widget.talker.info('Download was paused');
                }

              default:
                {
                  try {
                    final tempFile = File(tempFilePath);
                    await tempFile.delete();
                    widget.talker.info('File successfully deleted.');
                  } catch (e) {
                    widget.talker.info('Error deleting file: $e');
                  }
                  widget.talker.info('Download not successful');
                }
            }
          } catch (e) {
            widget.talker.info('Error downloading file: $e');
          }
        } else {
          widget.talker.info('Attempting to download using _agent.download...');
          await _agent!.download(
            modelUrl: modelUrl,
            onProgress: (progress, statusMessage, isError) {
              setState(() {
                _downloadProgress = progress;
                _downloadStatus = statusMessage;
                if (isError) {
                  _downloadStatus = 'Error: $statusMessage';
                }
              });
            },
          );
        }
      } else {
        widget.talker.info(
          'Model $modelName already exists locally at $modelFilePath. Skipping download.',
        );
        setState(() {
          _downloadProgress = 1.0; // Indicate 100% downloaded
          _downloadStatus = 'Model found locally.';
          _modelDownloaded = true;
        });
      }

      // After download (or if already exists), start initialization
      setState(() {
        _downloadProgress = null; // Clear download progress
        _initializationProgress = 0.0; // Start initialization progress
        _downloadStatus = 'Initializing model...';
      });
      final gpuLayerCount = await getGpuLayerCount();
      widget.talker.info('GPU Layer Count: $gpuLayerCount');
      widget.talker.info('Model file path: ${p.basename(modelFilePath)}');
      await _agent!.init(
        modelFilename: p.basename(modelFilePath),
        contextSize: _contextWindowSize,
        gpuLayers: gpuLayerCount, // Offload all possible layers to GPU
        onProgress: (progress, statusMessage, isError) {
          setState(() {
            _initializationProgress =
                progress; // Update initialization progress
            _downloadStatus = statusMessage;
            if (isError) {
              _downloadStatus = 'Error: $statusMessage';
            }
          });
        },
      );
      final prefs = await SharedPreferences.getInstance();
      final selectedTools = prefs.getStringList('selectedTools') ?? [];
      addAgentTools(_agent!, selectedTools, allAgentTools);
      setState(() {
        _isLoading = false;
        _downloadProgress = null; // Ensure download progress is null
        _initializationProgress = 1.0; // Set to 1.0 after successful init
        _downloadStatus = 'Model initialized';
        _modelDownloaded = true;
      });
    } catch (e) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Error'),
            content: Text('Error initializing Cactus model: $e'),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
      setState(() {
        _isLoading = false;
        _downloadProgress = null;
        _initializationProgress =
            null; // Reset initialization progress on error
        _downloadStatus = 'Initialization failed';
      });
    }
  }

  Future<void> _loadAgents() async {
    final prefs = await SharedPreferences.getInstance();
    final hasLaunchedBefore = prefs.getBool('has_launched_before') ?? false;

    final modelsInDb = await _dbHelper.getModels();
    bool anyDefaultModelFileExists = false;
    final defaultModelNames = ['Qwen3 0.6B', 'Qwen3 1.7B', 'Qwen3 4B'];

    for (String modelName in defaultModelNames) {
      final modelFilePath = await _dbHelper.getModelFilePath(modelName);
      if (await File(modelFilePath).exists()) {
        anyDefaultModelFileExists = true;
        break;
      }
    }

    await _performAgentLoadingAndInitialization();
  }

  Future<void> _performAgentLoadingAndInitialization() async {
    final modelsInDb = await _dbHelper.getModels();
    if (modelsInDb.isEmpty) {
      // Insert default models if none exist
      await _dbHelper.insertModel({
        'name': 'Qwen3 0.6B',
        'url':
            'https://huggingface.co/Cactus-Compute/Qwen3-600m-Instruct-GGUF/resolve/main/Qwen3-0.6B-Q8_0.gguf',
      });
      await _dbHelper.insertModel({
        'name': 'Qwen3 1.7B',
        'url':
            'https://huggingface.co/Cactus-Compute/Qwen3-1.7B-Instruct-GGUF/resolve/main/Qwen3-1.7B-Q4_K_M.gguf',
      });
      await _dbHelper.insertModel({
        'name': 'Qwen3 4B',
        'url':
            'https://huggingface.co/Cactus-Compute/Qwen3-4B-Instruct-GGUF/resolve/main/Qwen3-4B-Q4_K_M.gguf',
      });
    }

    final agentsFromDb = await _dbHelper.getAgents();
    if (agentsFromDb.isEmpty) {
      final defaultAgent = Agent(name: 'Moo', modelName: _selectedModelName);
      final id = await _dbHelper.insertAgent(defaultAgent.toMap());
      setState(() {
        _agents.add(Agent(id: id, name: 'Moo', modelName: _selectedModelName));
        _selectedAgent = _agents.first;
      });
    } else {
      setState(() {
        _agents = agentsFromDb.map((map) => Agent.fromMap(map)).toList();
        _selectedAgent = _agents.first;
      });
    }
    if (_selectedAgent != null) {
      final prefs = await SharedPreferences.getInstance();
      _systemPrompt =
          prefs.getString('systemPrompt_${_selectedAgent!.id}') ?? '';

      final modelFilePath = await _dbHelper.getModelFilePath(
        _selectedAgent!.modelName,
      );
      final modelFile = File(modelFilePath);
      bool modelExistsLocally = await modelFile.exists();

      setState(() {
        _modelDownloaded = modelExistsLocally;
      });

      if (!modelExistsLocally) {
        // If model does not exist, set _isLoading to false and let the UI display the download button.
        setState(() {
          _isLoading = false;
          _modelDownloaded = false; // Ensure this is false so the button shows
        });
      } else {
        // If model exists, set _modelDownloaded to true and _isLoading to false
        // so the UI can show that the model is downloaded and ready.
        setState(() {
          _modelDownloaded = true;
          _isLoading = false;
        });
      }
      // After agents are loaded and a default/selected agent is set, load messages
      // Since the UI is dictated by _messagesFuture, set it last to reflect changes in download state.
      _messagesFuture = _loadMessages();
    }
  }

  Future<List<Message>> _loadMessages() async {
    if (_selectedAgent == null || _selectedAgent!.id == null) {
      return [];
    }
    final List<Map<String, dynamic>> maps = await _dbHelper.getMessages(
      _selectedAgent!.id!,
    );
    setState(() {
      _messages.clear();
      _messages.addAll(
        maps.map((map) {
          final bool isUser = map['is_user'] == 1;
          if (isUser) {
            return Message(finalText: map['text'], isUser: true);
          } else {
            final ThinkingModelResponse parsedResponse =
                splitContentByThinkTags(map['text']);
            final String? thinkingText =
                parsedResponse.thinkingSessions.isNotEmpty
                ? parsedResponse.thinkingSessions.join('\n')
                : null;
            final List<String> toolCalls = [];
            final String finalText = extractResponseFromJson(
              parsedResponse.finalOutput,
            );
            return Message(
              rawText: map['text'],
              thinkingText: thinkingText,
              toolCalls: toolCalls,
              finalText: finalText,
              isUser: false,
            );
          }
        }),
      );
    });
    return _messages; // Return List<Message>
  }

  void _sendMessage() async {
    if (_textController.text.isNotEmpty &&
        _selectedAgent != null &&
        _selectedAgent!.id != null) {
      final userMessageText = _textController.text;
      _dbHelper.insertMessage(
        _selectedAgent!.id!,
        userMessageText,
        true, // isUser: true
      );
      setState(() {
        _messages.add(Message(finalText: userMessageText, isUser: true));
        _messages.add(Message(finalText: '', isUser: false, isLoading: true));
        _textController.clear();
        _isGenerating = true; // Set generating state
        _cancellationToken = false; // Reset cancellation token
      });
      _scrollToBottom();

      // Generate response using CactusLM
      if (_agent != null) {
        try {
          final List<ChatMessage> messages = [];
          if (_systemPrompt.isNotEmpty) {
            messages.add(ChatMessage(role: 'system', content: _systemPrompt));
          }
          messages.addAll(
            _messages.where((msg) => !msg.isLoading).map((msg) {
              return ChatMessage(
                role: msg.isUser ? 'user' : 'assistant',
                content: msg.finalText,
              );
            }).toList(),
          );
          final response = await _agent!.completionWithTools(
            messages,
            maxTokens: 2048,
            temperature: _creativity / 100.0,
          );

          if (_cancellationToken) {
            // If cancelled, update the last message to indicate cancellation
            setState(() {
              _messages.removeLast();
              _messages.add(
                Message(
                  finalText: 'Generation stopped.',
                  isUser: false,
                  isLoading: false,
                ),
              );
            });
            _scrollToBottom();
            return; // Exit early if cancelled
          }

          widget.talker.info(
            'Response result: ${response.result}, tool calls: ${response.toolCalls}',
          );
          final ThinkingModelResponse parsedResponse = splitContentByThinkTags(
            response.result ?? '',
          );

          final String? thinkingText =
              parsedResponse.thinkingSessions.isNotEmpty
              ? parsedResponse.thinkingSessions.join('\n')
              : null;

          final List<String> toolCalls = response.toolCalls ?? [];

          final String finalText = extractResponseFromJson(
            parsedResponse.finalOutput,
          );

          // Store the combined message in the database
          _dbHelper.insertMessage(
            _selectedAgent!.id!,
            response.result ?? '',
            false, // isUser: false
          );

          setState(() {
            _messages.removeLast();
            _messages.add(
              Message(
                rawText: response.result ?? '',
                thinkingText: thinkingText,
                toolCalls: toolCalls,
                finalText: finalText,
                isUser: false,
              ),
            );
          });
          _scrollToBottom();

          if (_isTtsEnabled && finalText.isNotEmpty) {
            _flutterTts.speak(finalText);
          }
        } finally {
          setState(() {
            _isGenerating = false; // Reset generating state
          });
        }
      }
    }
  }

  void _resetChat() async {
    if (_selectedAgent != null && _selectedAgent!.id != null) {
      await _dbHelper.clearMessages(_selectedAgent!.id!);
      setState(() {
        _messages.clear();
      });
      // Dispose and re-initialize the agent
      _agent?.unload();
      if (_selectedAgent != null) {
        _initializeCactusModel(_selectedAgent!.modelName);
      }
    }
  }

  void _renameAgent(int index, String newName) async {
    final agentToRename = _agents[index];
    agentToRename.name = newName;
    await _dbHelper.updateAgent(agentToRename.toMap());
    setState(() {
      _agents[index] = agentToRename;
    });
  }

  void _deleteAgent(Agent agentToDelete) async {
    if (agentToDelete.id == null) return;

    if (_agents.length == 1) {
      // If it's the last agent, show a message and disable deletion
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Cannot Delete Last Agent'),
            content: const Text('You cannot delete the last remaining agent.'),
            actions: <Widget>[
              TextButton(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
      return; // Exit the function
    }

    // Show confirmation dialog
    final bool confirmDelete =
        await showDialog(
          context: context,
          builder: (BuildContext context) {
            return DeleteAgentDialog(agentName: agentToDelete.name);
          },
        ) ??
        false; // Default to false if dialog is dismissed

    if (confirmDelete) {
      await _dbHelper.deleteAgent(agentToDelete.id!);
      setState(() {
        _agents.removeWhere((agent) => agent.id == agentToDelete.id);
        // If the deleted agent was the selected one, select the first available agent
        if (_selectedAgent?.id == agentToDelete.id) {
          _selectedAgent = _agents.isNotEmpty ? _agents.first : null;
          _messages.clear(); // Clear messages for the deleted agent
          if (_selectedAgent != null) {
            _messagesFuture =
                _loadMessages(); // Load messages for the new selected agent
            _initializeCactusModel(
              _selectedAgent!.modelName,
            ); // Initialize model for new selected agent
          }
        }
      });
    }
  }

  Future<void> _showRenameDialog(BuildContext context, Agent agent) async {
    final TextEditingController renameController = TextEditingController(
      text: agent.name,
    );
    final newName = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return RenameAgentDialog(initialAgentName: agent.name);
      },
    );

    if (newName != null && newName.isNotEmpty) {
      // Find the index of the agent in the _agents list
      final index = _agents.indexOf(agent);
      if (index != -1) {
        _renameAgent(index, newName);
      }
    }
  }

  void _showAddAgentDialog(BuildContext context) async {
    final TextEditingController addAgentController = TextEditingController();
    final newAgentName = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add New Agent'),
          content: TextField(
            controller: addAgentController,
            decoration: const InputDecoration(hintText: "Enter new agent name"),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Add'),
              onPressed: () {
                Navigator.of(context).pop(addAgentController.text);
              },
            ),
          ],
        );
      },
    );

    if (newAgentName != null && newAgentName.isNotEmpty) {
      _addAgent(newAgentName, _selectedModelName);
    }
  }

  void _addAgent(String name, String modelName) async {
    final newAgent = Agent(name: name, modelName: modelName);
    final id = await _dbHelper.insertAgent(newAgent.toMap());
    setState(() {
      _agents.add(Agent(id: id, name: name, modelName: modelName));
    });
  }

  void _selectAgent(Agent agent) {
    setState(() {
      _selectedAgent = agent;
      _messagesFuture = _loadMessages(); // Reload messages for the new agent
    });
    _initializeCactusModel(
      _selectedAgent!.modelName,
    ); // Initialize model for the new agent
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  void _showCactusModelInfo(BuildContext context) {
    Scaffold.of(context).openEndDrawer();
  }

  void _showRawResponseDialog(String? rawText) {
    if (rawText == null) return;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Raw Response'),
          content: SingleChildScrollView(child: Text(rawText)),
          actions: <Widget>[
            TextButton(
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  void _showAttachmentOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.of(context).pop();
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: source);

    if (image != null) {
      widget.talker.info('Picked image path: ${image.path}');
      // For now, just log the path. In a real scenario, you'd process this image,
      // e.g., display it in the chat, send it to the agent, etc.
      // You might want to add a new Message type for images.
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Image selected: ${image.path.split('/').last}'),
        ),
      );
    } else {
      widget.talker.info('No image selected.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: <Widget>[
                  const DrawerHeader(
                    child: Text('Agents', style: TextStyle(fontSize: 24)),
                  ),
                  ..._agents.asMap().entries.map((entry) {
                    Agent agent = entry.value;
                    return AgentItem(
                      agent: agent,
                      onRename: () => _showRenameDialog(context, agent),
                      onTap: () => _selectAgent(agent),
                      onLongPress: () => _handleAgentLongPress(
                        agent,
                      ), // Always call the handler
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
                      _showAddAgentDialog(context);
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => SettingsPage(
                            agentId: _selectedAgent?.id,
                            talker: widget.talker,
                          ), // Pass talker
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      endDrawer: AgentSettingsDrawerContent(
        initialModelName: _selectedModelName,
        initialCreativity: _creativity,
        initialContextWindowSize: _contextWindowSize,
        initialSystemPrompt: _systemPrompt, // Pass system prompt
        initialIsTtsEnabled: _isTtsEnabled, // Pass TTS setting
        onApply:
            (
              modelName,
              creativity,
              contextWindowSize,
              selectedTools,
              systemPrompt,
              isTtsEnabled,
            ) async {
              bool needsReinitialization =
                  _selectedModelName != modelName ||
                  _contextWindowSize != contextWindowSize;

              setState(() {
                _selectedModelName = modelName;
                _creativity = creativity;
                _contextWindowSize = contextWindowSize;
                _systemPrompt = systemPrompt; // Update _systemPrompt
                _isTtsEnabled = isTtsEnabled; // Update _isTtsEnabled
                if (_selectedAgent != null) {
                  _selectedAgent!.modelName = modelName;
                  _dbHelper.updateAgent(_selectedAgent!.toMap());
                }
              });

              // Save system prompt to SharedPreferences
              if (_selectedAgent != null) {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setString(
                  'systemPrompt_${_selectedAgent!.id}',
                  systemPrompt,
                );
              }
              // Save TTS setting to SharedPreferences
              await _setTtsEnabled(isTtsEnabled);

              final modelFilePath = await _dbHelper.getModelFilePath(modelName);
              final modelFile = File(modelFilePath);
              bool modelExistsLocally = await modelFile.exists();

              if (needsReinitialization) {
                if (_selectedAgent != null && _selectedAgent!.id != null) {
                  await _dbHelper.clearMessages(_selectedAgent!.id!);
                }
                setState(() {
                  _messages.clear();
                });
                if (modelExistsLocally) {
                  _initializeCactusModel(modelName);
                } else {
                  setState(() {
                    _modelDownloaded = false;
                    _isLoading = false;
                  });
                }
              }
              // Re-initialize agent with new settings
              if (_agent != null) {
                _agent!.unload(); // Unload current agent
                if (modelExistsLocally) {
                  _initializeCactusModel(
                    modelName,
                  ); // Re-initialize with new settings
                } else {
                  setState(() {
                    _modelDownloaded = false;
                    _isLoading = false;
                  });
                }
              }
            },
      ),
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                // Top bar
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Row(
                    children: [
                      // Hamburger menu
                      Builder(
                        builder: (context) {
                          return IconButton(
                            icon: const Icon(Icons.menu),
                            onPressed: () {
                              Scaffold.of(context).openDrawer();
                            },
                          );
                        },
                      ),
                      const SizedBox(width: 16),
                      // App name
                      Text(
                        _selectedAgent?.name ?? 'Secret Agent',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: _resetChat,
                      ),
                      Spacer(), // Added this Spacer
                      Builder(
                        builder: (BuildContext innerContext) {
                          return IconButton(
                            icon: const Icon(Icons.smart_toy_outlined),
                            onPressed: () {
                              _showCactusModelInfo(innerContext);
                            },
                          );
                        },
                      ),
                      Spacer(), // Added this Spacer
                      ValueListenableBuilder<ThemeMode>(
                        valueListenable: widget.themeNotifier,
                        builder: (context, currentMode, child) {
                          return DropdownButton<ThemeMode>(
                            underline: const SizedBox(),
                            icon: const SizedBox.shrink(),
                            value: currentMode,
                            onChanged: (ThemeMode? newValue) {
                              if (newValue != null) {
                                widget.themeNotifier.value = newValue;
                              }
                            },
                            items: const [
                              DropdownMenuItem(
                                value: ThemeMode.light,
                                child: Icon(Icons.light_mode),
                              ),
                              DropdownMenuItem(
                                value: ThemeMode.dark,
                                child: Icon(Icons.dark_mode),
                              ),
                              DropdownMenuItem(
                                value: ThemeMode.system,
                                child: Icon(Icons.brightness_auto),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onLongPressStart: (_) => _showListeningPopup(context),
                    onLongPressEnd: (_) {
                      final transcript = _lastWords;
                      _hideListeningPopup();
                      if (transcript.isNotEmpty) {
                        _textController.text = transcript;
                        _sendMessage();
                      }
                    },
                    child: Container(
                      // Wrap with Container to fill available space
                      color: Colors
                          .transparent, // Make it transparent so content below is visible
                      child: _isLoading
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const CircularProgressIndicator(),
                                  const SizedBox(height: 16),
                                  if (_initializationProgress != null)
                                    Column(
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 32.0,
                                          ),
                                          child: LinearProgressIndicator(
                                            value: _initializationProgress,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          _downloadStatus,
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodyMedium,
                                        ),
                                      ],
                                    )
                                  else if (_downloadProgress != null)
                                    Column(
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 32.0,
                                          ),
                                          child: LinearProgressIndicator(
                                            value: _downloadProgress,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          _downloadStatus,
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodyMedium,
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            )
                          : FutureBuilder<List<Message>>(
                              future: _messagesFuture,
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return const Center(
                                    child: CircularProgressIndicator(),
                                  );
                                } else if (snapshot.hasError) {
                                  return Center(
                                    child: Text('Error: ${snapshot.error}'),
                                  );
                                } else if (_messages.isEmpty) {
                                  return Center(
                                    child: _modelDownloaded
                                        ? Text(
                                            'Hello!',
                                            style: TextStyle(
                                              color: Colors.blue[400],
                                              fontSize: 32,
                                              fontWeight: FontWeight.w500,
                                            ),
                                            textAlign: TextAlign.center,
                                          )
                                        : Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                'No model found. Please download one to start chatting.',
                                                style: Theme.of(
                                                  context,
                                                ).textTheme.titleLarge,
                                                textAlign: TextAlign.center,
                                              ),
                                              const SizedBox(height: 20),
                                              ElevatedButton.icon(
                                                onPressed: () {
                                                  if (_selectedAgent != null) {
                                                    _initializeCactusModel(
                                                      _selectedAgent!.modelName,
                                                    );
                                                  }
                                                },
                                                icon: const Icon(
                                                  Icons.download,
                                                ),
                                                label: const Text(
                                                  'Download Model',
                                                ),
                                              ),
                                            ],
                                          ),
                                  );
                                } else {
                                  return ListView.builder(
                                    controller: _scrollController,
                                    padding: const EdgeInsets.all(8.0),
                                    itemCount: _messages.length,
                                    itemBuilder: (context, index) {
                                      return _buildMessageBubble(
                                        _messages[index],
                                      );
                                    },
                                  );
                                }
                              },
                            ),
                    ),
                  ),
                ),
                // Bottom bar
                Padding(
                  padding: const EdgeInsets.only(
                    bottom: 16.0,
                    left: 12.0,
                    right: 12.0,
                    top: 8.0,
                  ),
                  child: TextField(
                    controller: _textController,
                    minLines: 1,
                    maxLines: 6, // Allow up to 6 lines before scrolling
                    textInputAction: TextInputAction.send,
                    keyboardType:
                        TextInputType.multiline, // Enable multiline keyboard
                    decoration: InputDecoration(
                      hintText: 'Ask Secret Agent',
                      hintStyle: TextStyle(color: Theme.of(context).hintColor),
                      filled: true,
                      fillColor:
                          Theme.of(context).inputDecorationTheme.fillColor ??
                          Theme.of(
                            context,
                          ).colorScheme.surfaceVariant.withOpacity(0.5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                      prefixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!kReleaseMode)
                            IconButton(
                              icon: const Icon(Icons.attach_file),
                              onPressed: () {
                                _showAttachmentOptions(context);
                              },
                            ),
                          const SizedBox(width: 8),
                        ],
                      ),
                      suffixIcon: _isGenerating
                          ? IconButton(
                              icon: const Icon(Icons.stop),
                              onPressed: () {
                                setState(() {
                                  _cancellationToken = true;
                                });
                              },
                            )
                          : IconButton(
                              icon: const Icon(Icons.send),
                              onPressed: _sendMessage,
                            ),
                    ),
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
              ],
            ),
          ),
          if (_isListening)
            Positioned.fill(
              child: Blur(
                blur: 10.0,
                blurColor: Theme.of(
                  context,
                ).dialogBackgroundColor.withOpacity(0.7),
                child: Container(), // Add an empty Container as a child
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Message message) {
    if (message.isLoading) {
      return Align(
        alignment: Alignment.centerLeft,
        child: const CardLoading(
          height: 50,
          width: 150,
          borderRadius: BorderRadius.all(Radius.circular(20)),
          margin: EdgeInsets.symmetric(vertical: 4.0),
        ),
      );
    }

    final alignment = message.isUser
        ? Alignment.centerRight
        : Alignment.centerLeft;
    final color = message.isUser
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.surfaceVariant;
    final textColor = message.isUser
        ? Theme.of(context).colorScheme.onPrimary
        : Theme.of(context).colorScheme.onSurfaceVariant;

    return GestureDetector(
      onDoubleTap: () {
        if (!message.isUser) {
          _showRawResponseDialog(message.rawText);
        }
      },
      child: Align(
        alignment: alignment,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4.0),
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(20.0),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (message.thinkingText != null &&
                  message.thinkingText!.isNotEmpty)
                Theme(
                  data: Theme.of(
                    context,
                  ).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    title: Text(
                      '🤔 Thinking...', // Corrected: Removed extra backslash before 🤔
                      style: TextStyle(color: textColor),
                    ),
                    initiallyExpanded: false,
                    tilePadding: EdgeInsets.zero,
                    childrenPadding: EdgeInsets.zero,
                    expandedCrossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      MarkdownBody(
                        data: message.thinkingText!,
                        styleSheet: MarkdownStyleSheet.fromTheme(
                          Theme.of(context),
                        ).copyWith(p: TextStyle(color: textColor)),
                      ),
                    ],
                  ),
                ),
              if (message.toolCalls != null && message.toolCalls!.isNotEmpty)
                Theme(
                  data: Theme.of(
                    context,
                  ).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    title: Text(
                      '🛠️ Tool Calls',
                      style: TextStyle(color: textColor),
                    ),
                    initiallyExpanded: false,
                    tilePadding: EdgeInsets.zero,
                    childrenPadding: EdgeInsets.zero,
                    expandedCrossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Align(
                        alignment: Alignment.topLeft,
                        child: Wrap(
                          alignment: WrapAlignment.start,
                          spacing: 8.0,
                          runSpacing: 4.0,
                          children: message.toolCalls!
                              .map(
                                (toolCall) => Chip(
                                  label: Text(toolCall),
                                  backgroundColor: Colors.blueGrey[100],
                                  labelStyle: TextStyle(color: Colors.black),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              MarkdownBody(
                data: message.finalText,
                styleSheet: MarkdownStyleSheet.fromTheme(
                  Theme.of(context),
                ).copyWith(p: TextStyle(color: textColor)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
