import 'package:flutter/material.dart';

class SystemPromptInput extends StatelessWidget {
  final TextEditingController controller;

  const SystemPromptInput({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'Enter system prompt',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0), // Increased radius
            ),
          ),
          maxLines: 3,
        ),
      ],
    );
  }
}
