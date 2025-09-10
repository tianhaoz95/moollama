final Map<String, String> defaultModelUrls = {
  'Qwen3 0.6B':
      'https://huggingface.co/Cactus-Compute/Qwen3-600m-Instruct-GGUF/resolve/main/Qwen3-0.6B-Q8_0.gguf',
  'Qwen3 1.7B':
      'https://huggingface.co/Cactus-Compute/Qwen3-1.7B-Instruct-GGUF/resolve/main/Qwen3-1.7B-Q4_K_M.gguf',
  'Qwen3 4B':
      'https://huggingface.co/Cactus-Compute/Qwen3-4B-Instruct-GGUF/resolve/main/Qwen3-4B-Q4_K_M.gguf',
};

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
  final String? imagePath; // New field for image path

  Message({
    this.rawText,
    this.thinkingText,
    this.toolCalls,
    required this.finalText,
    required this.isUser,
    this.isLoading = false,
    this.imagePath, // Initialize new field
  });

  // Factory constructor to create a Message from a map (for database retrieval)
  factory Message.fromMap(Map<String, dynamic> map) {
    return Message(
      rawText: map['raw_text'],
      thinkingText: map['thinking_text'],
      toolCalls: map['tool_calls'] != null
          ? List<String>.from(map['tool_calls'].split(',')) // Assuming comma-separated string
          : null,
      finalText: map['text'],
      isUser: map['is_user'] == 1,
      imagePath: map['image_path'], // Retrieve image path
    );
  }

  // Convert Message to a map (for database insertion)
  Map<String, dynamic> toMap() {
    return {
      'raw_text': rawText,
      'thinking_text': thinkingText,
      'tool_calls': toolCalls?.join(','), // Store as comma-separated string
      'text': finalText,
      'is_user': isUser ? 1 : 0,
      'image_path': imagePath, // Store image path
    };
  }
}
