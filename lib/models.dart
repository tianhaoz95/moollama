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
}