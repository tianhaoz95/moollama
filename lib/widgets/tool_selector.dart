import 'package:flutter/material.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';

class ToolSelector extends StatefulWidget {
  final List<String> availableTools;
  final List<String> selectedTools;
  final Function(List<String>) onToolsChanged;

  const ToolSelector({
    super.key,
    required this.availableTools,
    required this.selectedTools,
    required this.onToolsChanged,
  });

  @override
  State<ToolSelector> createState() => _ToolSelectorState();
}

class _ToolSelectorState extends State<ToolSelector> {
  late List<String> _selectedTools;

  @override
  void initState() {
    super.initState();
    _selectedTools = widget.selectedTools;
  }

  @override
  void didUpdateWidget(covariant ToolSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedTools != oldWidget.selectedTools) {
      _selectedTools = widget.selectedTools;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Tools'),
        MultiSelectDialogField(
          items: widget.availableTools
              .map((tool) => MultiSelectItem<String>(tool, tool))
              .toList(),
          title: const Text("Select Tools"),
          selectedColor: Colors.blue,
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: const BorderRadius.all(Radius.circular(8)),
            border: Border.all(color: Colors.blue, width: 1.8),
          ),
          buttonIcon: const Icon(Icons.build, color: Colors.blue),
          buttonText: const Text(
            "Select Tools",
            style: TextStyle(color: Colors.blue, fontSize: 16),
          ),
          initialValue: _selectedTools,
          onConfirm: (values) {
            final newSelectedTools = values.cast<String>();
            setState(() {
              _selectedTools = newSelectedTools;
            });
            widget.onToolsChanged(newSelectedTools);
          },
          chipDisplay: MultiSelectChipDisplay(
            onTap: (item) {
              final newSelectedTools = List<String>.from(_selectedTools);
              newSelectedTools.remove(item);
              setState(() {
                _selectedTools = newSelectedTools;
              });
              widget.onToolsChanged(newSelectedTools);
            },
          ),
        ),
      ],
    );
  }
}
