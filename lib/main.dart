import 'package:flutter/material.dart';
import 'package:secret_agent/database_helper.dart';

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.system);

void main() async {
  await DatabaseHelper().init();
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
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

class _SecretAgentHomeState extends State<SecretAgentHome> {
  final TextEditingController _textController = TextEditingController();
  final List<String> _messages = [];
  final DatabaseHelper _dbHelper = DatabaseHelper();
  late Future<List<String>> _messagesFuture;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: const <Widget>[
                  DrawerHeader(
                    child: Text(
                      'Conversations',
                      style: TextStyle(fontSize: 24),
                    ),
                  ),
                  _ConversationItem(
                    title: 'Conversation 1',
                  ),
                  _ConversationItem(
                    title: 'Conversation 2',
                  ),
                  _ConversationItem(
                    title: 'Conversation 3',
                  ),
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
                    onPressed: () {},
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

class _ConversationItem extends StatelessWidget {
  final String title;

  const _ConversationItem({required this.title});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.message),
      title: Text(title),
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