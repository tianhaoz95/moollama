import 'package:flutter/material.dart';
import 'package:moollama/database_helper.dart';
import 'package:moollama/widgets/tool_selector.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AgentSettingsDrawerContent extends StatefulWidget {
  const AgentSettingsDrawerContent({
    super.key,
    required this.initialModelName,
    required this.initialCreativity,
    required this.initialContextWindowSize,
    required this.onApply,
    this.initialSystemPrompt,
    required this.initialIsTtsEnabled, // New parameter
  });

  final String initialModelName;
  final double initialCreativity;
  final int initialContextWindowSize;
  final Function(String, double, int, List<String>, String, bool)
  onApply; // Updated signature
  final String? initialSystemPrompt;
  final bool initialIsTtsEnabled; // New field

  @override
  State<AgentSettingsDrawerContent> createState() =>
      _AgentSettingsDrawerContentState();
}

class _AgentSettingsDrawerContentState
    extends State<AgentSettingsDrawerContent> {
  late String _selectedModelName;
  late double _creativityValue;
  late double _contextWindowSliderValue;
  final List<int> _contextWindowSizes = [1024, 4096, 8192, 16384, 32768];
  List<String> _availableModels = [];
  List<String> _availableTools = [];
  List<String> _selectedTools = [];
  final DatabaseHelper _dbHelper = DatabaseHelper();
  late final TextEditingController _systemPromptController;
  late bool _isTtsEnabled; // New class member

  @override
  void initState() {
    super.initState();
    _selectedModelName = widget.initialModelName;
    _creativityValue = widget.initialCreativity;
    _contextWindowSliderValue = _contextWindowSizes
        .indexOf(widget.initialContextWindowSize)
        .toDouble();
    _systemPromptController = TextEditingController(
      text: widget.initialSystemPrompt,
    ); // Initialize the controller
    _isTtsEnabled = widget.initialIsTtsEnabled; // Initialize _isTtsEnabled
    _loadAvailableModels();
    _loadAvailableTools(); // Load available tools dynamically
    _loadSelectedTools(); // Load selected tools
  }

  @override
  void dispose() {
    _systemPromptController.dispose(); // Dispose the controller
    super.dispose();
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

  Future<void> _loadAvailableTools() async {
    // In a real app, you'd dynamically discover tools.
    // For this example, we'll use the hardcoded list from the problem description.
    // In a real app, this would involve reading from a tool registry or similar.
    setState(() {
      _availableTools = ['fetch_webpage', 'send_email', 'fetch_current_time'];
    });
  }

  Future<void> _loadSelectedTools() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTools = prefs.getStringList('selectedTools');
    if (savedTools != null) {
      setState(() {
        _selectedTools = savedTools;
      });
    }
  }

  Future<void> _saveSelectedTools(List<String> tools) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('selectedTools', tools);
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
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: <Widget>[
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12.0,
                            ),
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
                                  .map<DropdownMenuItem<String>>((
                                    String value,
                                  ) {
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
                                max: (_contextWindowSizes.length - 1)
                                    .toDouble(),
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
                    const SizedBox(height: 24), // Add spacing
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: _systemPromptController,
                          decoration: InputDecoration(
                            hintText: 'Enter system prompt',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(
                                12.0,
                              ), // Increased radius
                            ),
                          ),
                          maxLines: 3,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    ToolSelector(
                      availableTools: _availableTools,
                      selectedTools: _selectedTools,
                      onToolsChanged: (tools) {
                        setState(() {
                          _selectedTools = tools;
                        });
                        _saveSelectedTools(tools);
                      },
                    ),
                    const SizedBox(height: 24), // Add spacing
                    SwitchListTile(
                      title: const Text('Enable TTS'),
                      value: _isTtsEnabled,
                      onChanged: (bool value) {
                        setState(() {
                          _isTtsEnabled = value;
                        });
                      },
                    ),
                  ],
                ),
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
                    _selectedTools,
                    _systemPromptController.text, // Pass system prompt
                    _isTtsEnabled, // Pass TTS setting
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
