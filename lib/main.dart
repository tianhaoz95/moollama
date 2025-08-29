import 'package:flutter/material.dart';
import 'package:secret_agent/database_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:secret_agent/settings_page.dart';

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
    await prefs.setString('themeMode', themeNotifier.value.toString().split('.').last);
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
  String name;

  Agent(this.name);
}

class _SecretAgentHomeState extends State<SecretAgentHome> {
  final TextEditingController _textController = TextEditingController();
  final List<String> _messages = [];
  final DatabaseHelper _dbHelper = DatabaseHelper();
  late Future<List<String>> _messagesFuture;
  List<Agent> _agents = [
    Agent('Agent 1'),
    Agent('Agent 2'),
    Agent('Agent 3'),
  ];

  @override
  void initState() {
    super.initState();
    _messagesFuture = _loadMessages();
  }

  Future<List<String>> _loadMessages() async {
    final messages = await _dbHelper.getMessages();
    setState(() {
      _messages.addAll(messages);
    });
    return messages;
  }

  void _sendMessage() {
    if (_textController.text.isNotEmpty) {
      final message = _textController.text;
      _dbHelper.insertMessage(message);
      setState(() {
        _messages.add(message);
        _textController.clear();
      });
    }
  }

  void _resetChat() async {
    await _dbHelper.clearMessages();
    setState(() {
      _messages.clear();
    });
  }

  void _renameAgent(int index, String newName) {
    setState(() {
      _agents[index].name = newName;
    });
  }

  Future<void> _showRenameDialog(BuildContext context, int index) async {
    final TextEditingController renameController = TextEditingController(text: _agents[index].name);
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
      _renameAgent(index, newName);
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
                    child: Text(
                      'Agents',
                      style: TextStyle(fontSize: 24),
                    ),
                  ),
                  ..._agents.asMap().entries.map((entry) {
                    int idx = entry.key;
                    Agent agent = entry.value;
                    return _AgentItem(
                      title: agent.name,
                      onRename: () => _showRenameDialog(context, idx),
                    );
                  }).toList(),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 32.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(icon: const Icon(Icons.add), onPressed: () {}),
                  IconButton(
                    icon: const Icon(Icons.settings),
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const SettingsPage(),
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
                    'Secret Agent',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Spacer(),
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
              child: FutureBuilder<List<String>>(
                future: _messagesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
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
                        _BottomBarButton(icon: Icons.refresh, onPressed: _resetChat),
                        const SizedBox(width: 8),
                        _BottomBarButton(
                          icon: Icons.send,
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

  Widget _buildMessageBubble(String message) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4.0),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
        decoration: BoxDecoration(
          color: Colors.blue,
          borderRadius: BorderRadius.circular(20.0),
        ),
        child: Text(
          message,
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}

class _AgentItem extends StatelessWidget {
  final String title;
  final VoidCallback onRename;

  const _AgentItem({required this.title, required this.onRename});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.message),
      title: Text(title),
      trailing: IconButton(
        icon: const Icon(Icons.edit),
        onPressed: onRename,
      ),
    );
  }
}

class _BottomBarButton extends StatelessWidget {
  final IconData? icon;
  final VoidCallback? onPressed;
  const _BottomBarButton({this.icon, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondary,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Icon(
            icon,
            color: Theme.of(context).colorScheme.onSecondary,
            size: 20,
          ),
        ),
      ),
    );
  }
}