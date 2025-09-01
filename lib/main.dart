import 'package:card_loading/card_loading.dart';
import 'package:flutter/material.dart';
import 'package:secret_agent/database_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:secret_agent/settings_page.dart';
import 'package:cactus/cactus.dart';
import 'package:secret_agent/utils.dart'; // Import the new utility file
import 'package:siri_wave/siri_wave.dart'; // Ensure this package is added in pubspec.yaml
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:talker_flutter/talker_flutter.dart';
import 'package:secret_agent/agent_helper.dart';

final talker = TalkerFlutter.init();

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.system);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseHelper().init();
  final prefs = await SharedPreferences.getInstance();
  final themeModeString = prefs.getString('themeMode');
  if (themeModeString == 'light') {
    themeNotifier.value = ThemeMode.light;
  } else if (themeModeString == 'dark') {
    themeNotifier.value = ThemeMode.dark;
  } else {
    themeNotifier.value = ThemeMode.system;
  }
  runApp(const MyApp());

  themeNotifier.addListener(() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'themeMode',
      themeNotifier.value.toString().split('.').last,
    );
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentMode, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData.light(),
          darkTheme: ThemeData.dark().copyWith(
            scaffoldBackgroundColor: const Color(0xFF232629),
          ),
          themeMode: currentMode,
          home: const SecretAgentHome(),
        );
      },
    );
  }
}

class SecretAgentHome extends StatefulWidget {
  const SecretAgentHome({super.key});

  @override
  State<SecretAgentHome> createState() => _SecretAgentHomeState();
}

class Agent {
  int? id;
  String name;
  String modelName; // New field

  Agent({
    this.id,
    required this.name,
    this.modelName = 'Qwen3 0.6B',
  }); // Default value

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'model_name': modelName,
    }; // Include new field
  }

  static Agent fromMap(Map<String, dynamic> map) {
    return Agent(
      id: map['id'],
      name: map['name'],
      modelName:
          map['model_name'] ?? 'Qwen3 0.6B', // Handle null for old entries
    );
  }
}

class Message {
  final String? rawText;
  final String? thinkingText;
  final List<String>? toolCalls;
  final String finalText;
  final bool isUser;
  final bool isLoading;

  Message({
    this.rawText,
    this.thinkingText,
    this.toolCalls,
    required this.finalText,
    required this.isUser,
    this.isLoading = false,
  });
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
  double? _initializationProgress;
  String _downloadStatus = 'Initializing...';
  final ScrollController _scrollController = ScrollController();
  bool _isListening = false;
  OverlayEntry? _listeningPopupEntry;
  final stt.SpeechToText _speechToText = stt.SpeechToText();
  String _lastWords = '';

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
      builder: (context) => Center(
        child: Card(
          color: Color.fromRGBO(0, 0, 0, 0.7),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30.0),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SiriWaveform.ios9(),
                const SizedBox(height: 10),
                Text(
                  _lastWords.isEmpty ? 'Listening...' : _lastWords,
                  style: TextStyle(color: Colors.white, fontSize: 24),
                ),
              ],
            ),
          ),
        ),
      ),
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
      talker.info('Speech recognition not available');
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

  @override
  void initState() {
    super.initState();
    _messagesFuture = Future.value([]); // Initialize with an empty future
    _loadAgents(); // Load agents, which will then load messages
    _speechToText.initialize(
      onStatus: (status) => talker.info('Speech recognition status: $status'),
      onError: (errorNotification) =>
          talker.info('Speech recognition error: $errorNotification'),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // Removed duplicate and unreferenced _initializeCactusModel method

  Future<void> _initializeCactusModel(String modelName) async {
    try {
      setState(() {
        _isLoading = true;
        _downloadProgress = null;
        _initializationProgress = null; // Reset initialization progress
        _downloadStatus = 'Downloading model...';
      });
      _agent = CactusAgent();
      final models = await _dbHelper.getModels();
      final model = models.firstWhere(
        (m) => m['name'] == modelName,
        orElse: () => <String, dynamic>{},
      );
      final modelUrl = model['url'];
      if (modelUrl == null) {
        talker.error('Model URL not found for $modelName');
        throw Exception('Model URL not found for $modelName');
      }
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
      // After download, start initialization
      setState(() {
        _downloadProgress = null; // Clear download progress
        _initializationProgress = 0.0; // Start initialization progress
        _downloadStatus = 'Initializing model...';
      });
      await _agent!.init(
        contextSize: _contextWindowSize,
        onProgress: (progress, statusMessage, isError) {
          setState(() {
            _initializationProgress = progress; // Update initialization progress
            _downloadStatus = statusMessage;
            if (isError) {
              _downloadStatus = 'Error: $statusMessage';
            }
          });
        },
      );
      addAgentTools(_agent!);
      setState(() {
        _isLoading = false;
        _downloadProgress = null; // Ensure download progress is null
        _initializationProgress = 1.0; // Set to 1.0 after successful init
        _downloadStatus = 'Model initialized';
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
        _initializationProgress = null; // Reset initialization progress on error
        _downloadStatus = 'Initialization failed';
      });
    }
  }

  Future<void> _loadAgents() async {
    final agentsFromDb = await _dbHelper.getAgents();
    if (agentsFromDb.isEmpty) {
      final defaultAgent = Agent(
        name: 'Default',
        modelName: _selectedModelName,
      );
      final id = await _dbHelper.insertAgent(defaultAgent.toMap());
      setState(() {
        _agents.add(
          Agent(id: id, name: 'Default', modelName: _selectedModelName),
        );
        _selectedAgent = _agents.first;
      });
    } else {
      setState(() {
        _agents = agentsFromDb.map((map) => Agent.fromMap(map)).toList();
        _selectedAgent = _agents.first;
      });
    }
    // After agents are loaded and a default/selected agent is set, load messages
    _messagesFuture = _loadMessages();
    if (_selectedAgent != null) {
      _initializeCactusModel(_selectedAgent!.modelName);
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
        true,
      ); // isUser: true
      setState(() {
        _messages.add(Message(finalText: userMessageText, isUser: true));
        _messages.add(Message(finalText: '', isUser: false, isLoading: true));
        _textController.clear();
      });
      _scrollToBottom();

      // Generate response using CactusLM
      if (_agent != null) {
        final messages = _messages.where((msg) => !msg.isLoading).map((msg) {
          return ChatMessage(
            role: msg.isUser ? 'user' : 'assistant',
            content: msg.finalText,
          );
        }).toList();
        final response = await _agent!.completionWithTools(
          messages,
          maxTokens: 2048,
          temperature: _creativity / 100.0,
        );
        talker.info(
          'Response result: ${response.result}, tool calls: ${response.toolCalls}',
        );
        final ThinkingModelResponse parsedResponse = splitContentByThinkTags(
          response.result ?? '',
        );

        final String? thinkingText = parsedResponse.thinkingSessions.isNotEmpty
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
            return AlertDialog(
              title: const Text('Delete Agent'),
              content: Text(
                'Are you sure you want to delete agent "${agentToDelete.name}"?',
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () {
                    Navigator.of(context).pop(false); // User cancelled
                  },
                ),
                TextButton(
                  child: const Text('Delete'),
                  onPressed: () {
                    Navigator.of(context).pop(true); // User confirmed
                  },
                ),
              ],
            );
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
        return AlertDialog(
          title: const Text('Rename Agent'),
          content: TextField(
            controller: renameController,
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
              child: const Text('Rename'),
              onPressed: () {
                Navigator.of(context).pop(renameController.text);
              },
            ),
          ],
        );
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

  void _debugAction() {
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
                    return _AgentItem(
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
                    icon: const Icon(Icons.bug_report_outlined),
                    onPressed: _debugAction,
                  ),
                  IconButton(
                    icon: const Icon(Icons.settings),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) =>
                              SettingsPage(agentId: _selectedAgent?.id),
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
      endDrawer: _AgentSettingsDrawerContent(
        initialModelName: _selectedModelName,
        initialCreativity: _creativity,
        initialContextWindowSize: _contextWindowSize,
        onApply: (modelName, creativity, contextWindowSize) {
          bool needsReinitialization =
              _selectedModelName != modelName ||
              _contextWindowSize != contextWindowSize;

          setState(() {
            _selectedModelName = modelName;
            _creativity = creativity;
            _contextWindowSize = contextWindowSize;
            if (_selectedAgent != null) {
              _selectedAgent!.modelName = modelName;
              _dbHelper.updateAgent(_selectedAgent!.toMap());
            }
          });

          if (needsReinitialization) {
            _initializeCactusModel(modelName);
          }
        },
      ),
      body: SafeArea(
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
                  const Spacer(),
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
                  ValueListenableBuilder<ThemeMode>(
                    valueListenable: themeNotifier,
                    builder: (context, currentMode, child) {
                      return DropdownButton<ThemeMode>(
                        underline: const SizedBox(),
                        icon: const SizedBox.shrink(),
                        value: currentMode,
                        onChanged: (ThemeMode? newValue) {
                          if (newValue != null) {
                            themeNotifier.value = newValue;
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
                child: _isLoading
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const CircularProgressIndicator(),
                            const SizedBox(height: 16),
                            if (_initializationProgress != null) // Check for initialization progress
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32.0,
                                ),
                                child: LinearProgressIndicator(
                                  value: _initializationProgress, // Use initialization progress
                                ),
                              )
                            else if (_downloadProgress != null) // Fallback to download progress
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32.0,
                                ),
                                child: LinearProgressIndicator(
                                  value: _downloadProgress,
                                ),
                              ),
                            const SizedBox(height: 8),
                            Text(_downloadStatus),
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
                              child: Text(
                                'Hello!',
                                style: TextStyle(
                                  color: Colors.blue[400],
                                  fontSize: 32,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            );
                          } else {
                            return ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.all(8.0),
                              itemCount: _messages.length,
                              itemBuilder: (context, index) {
                                return _buildMessageBubble(_messages[index]);
                              },
                            );
                          }
                        },
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
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[800]!
                        : Colors.grey[300]!,
                  ),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _textController,
                      minLines: 2,
                      maxLines: 2,
                      textInputAction: TextInputAction.send, // Add this line
                      decoration: InputDecoration(
                        hintText: 'Ask Secret Agent',
                        hintStyle: TextStyle(
                          color: Theme.of(context).hintColor,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 0,
                        ),
                      ),
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _BottomBarButton(
                          icon: Icons.camera_alt,
                          onPressed: null, // Disabled
                        ),
                        const SizedBox(width: 8),
                        _BottomBarButton(
                          icon: Icons.attach_file,
                          onPressed: null, // Disabled
                        ),
                        const SizedBox(width: 8),
                        _BottomBarButton(
                          icon: Icons.refresh,
                          onPressed: _resetChat,
                        ),
                        const SizedBox(width: 8),
                        _BottomBarButton(
                          icon: Icons.rocket_launch,
                          onPressed: _sendMessage,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
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
    final color = message.isUser ? Colors.blue : Colors.grey[300];
    final textColor = message.isUser ? Colors.white : Colors.black;

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
                      '🤔 Thinking...',
                      style: TextStyle(color: textColor),
                    ),
                    initiallyExpanded: false,
                    tilePadding: EdgeInsets.zero,
                    childrenPadding: EdgeInsets.zero,
                    expandedCrossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        message.thinkingText!,
                        style: TextStyle(color: textColor),
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
                          alignment:
                              WrapAlignment.start, // Align chips to the left
                          spacing: 8.0, // gap between adjacent chips
                          runSpacing: 4.0, // gap between lines
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
              Text(message.finalText, style: TextStyle(color: textColor)),
            ],
          ),
        ),
      ),
    );
  }
}

class _BottomBarButton extends StatelessWidget {
  const _BottomBarButton({required this.icon, this.onPressed});

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(icon: Icon(icon), onPressed: onPressed);
  }
}

class _AgentItem extends StatelessWidget {
  const _AgentItem({
    required this.agent,
    this.onRename,
    this.onTap,
    this.onLongPress,
  });

  final Agent agent;
  final VoidCallback? onRename;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress; // New callback for long press

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(agent.name),
      onTap: onTap,
      onLongPress: onLongPress, // Assign the new callback
      trailing: IconButton(icon: const Icon(Icons.edit), onPressed: onRename),
    );
  }
}

class _AgentSettingsDrawerContent extends StatefulWidget {
  const _AgentSettingsDrawerContent({
    super.key,
    required this.initialModelName,
    required this.initialCreativity,
    required this.initialContextWindowSize,
    required this.onApply,
  });

  final String initialModelName;
  final double initialCreativity;
  final int initialContextWindowSize;
  final Function(String, double, int) onApply;

  @override
  State<_AgentSettingsDrawerContent> createState() =>
      _AgentSettingsDrawerContentState();
}

class _AgentSettingsDrawerContentState
    extends State<_AgentSettingsDrawerContent> {
  late String _selectedModelName;
  late double _creativityValue;
  late double _contextWindowSliderValue;
  final List<int> _contextWindowSizes = [1024, 4096, 8192, 16384, 32768];
  List<String> _availableModels = [];
  final DatabaseHelper _dbHelper = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    _selectedModelName = widget.initialModelName;
    _creativityValue = widget.initialCreativity;
    _contextWindowSliderValue = _contextWindowSizes
        .indexOf(widget.initialContextWindowSize)
        .toDouble();
    _loadAvailableModels();
  }

  Future<void> _loadAvailableModels() async {
    final models = await _dbHelper.getDistinctModelNames();
    setState(() {
      _availableModels = models;
      if (!_availableModels.contains(_selectedModelName) &&
          _availableModels.isNotEmpty) {
        _selectedModelName = _availableModels.first;
      } else if (_availableModels.isEmpty) {
        _selectedModelName = 'Qwen3 0.6B';
        _availableModels.add('Qwen3 0.6B');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          Container(
            height: 160.0,
            padding: const EdgeInsetsDirectional.only(
              start: 16.0,
              top: 16.0,
              end: 16.0,
              bottom: 8.0,
            ),
            alignment: AlignmentDirectional.bottomStart,
            child: Text('Agent Settings', style: TextStyle(fontSize: 24)),
          ),
          const Divider(height: 1, thickness: 1, indent: 0, endIndent: 0),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: <Widget>[
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: DropdownButton<String>(
                            value: _selectedModelName,
                            onChanged: (String? newValue) {
                              setState(() {
                                _selectedModelName = newValue!;
                              });
                            },
                            items: _availableModels
                                .map<DropdownMenuItem<String>>((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(value),
                                  );
                                })
                                .toList(),
                            underline: const SizedBox(),
                            isExpanded: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Creativity'),
                      Row(
                        children: [
                          Expanded(
                            child: Slider(
                              value: _creativityValue,
                              min: 0,
                              max: 100,
                              divisions: 100,
                              label: _creativityValue.round().toString(),
                              onChanged: (double value) {
                                setState(() {
                                  _creativityValue = value;
                                });
                              },
                            ),
                          ),
                          Text(_creativityValue.round().toString()),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Context Window'),
                      Row(
                        children: [
                          Expanded(
                            child: Slider(
                              value: _contextWindowSliderValue,
                              min: 0,
                              max: (_contextWindowSizes.length - 1).toDouble(),
                              divisions: _contextWindowSizes.length - 1,
                              label:
                                  '${(_contextWindowSizes[_contextWindowSliderValue.round()] / 1024).round()}k',
                              onChanged: (double value) {
                                setState(() {
                                  _contextWindowSliderValue = value;
                                });
                              },
                            ),
                          ),
                          Text(
                            '${(_contextWindowSizes[_contextWindowSliderValue.round()] / 1024).round()}k',
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity, // Make the button fill the width
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  widget.onApply(
                    _selectedModelName,
                    _creativityValue,
                    _contextWindowSizes[_contextWindowSliderValue.round()],
                  );
                  Navigator.of(context).pop(); // Close the drawer
                },
                icon: const Icon(Icons.check), // Add the icon here
                label: const Text('Apply'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
