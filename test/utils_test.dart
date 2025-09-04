import 'package:flutter_test/flutter_test.dart';
import 'package:moollama/utils.dart'; // Assuming your utils.dart is in lib/

void main() {
  group('splitContentByThinkTags', () {
    test('should correctly split content with multiple think tags', () {
      const content =
          '<think>This is the first thought.</think>Some text.<think>Second thought.</think>Final output.';
      final result = splitContentByThinkTags(content);
      expect(result.thinkingSessions, ['This is the first thought.', 'Second thought.']);
      expect(result.finalOutput, 'Some text.Final output.');
    });

    test('should handle content with no think tags', () {
      const content = 'Just some plain text.';
      final result = splitContentByThinkTags(content);
      expect(result.thinkingSessions, []);
      expect(result.finalOutput, 'Just some plain text.');
    });

    test('should handle content with only think tags', () {
      const content = '<think>Only thought.</think>';
      final result = splitContentByThinkTags(content);
      expect(result.thinkingSessions, ['Only thought.']);
      expect(result.finalOutput, '');
    });

    test('should handle empty content', () {
      const content = '';
      final result = splitContentByThinkTags(content);
      expect(result.thinkingSessions, []);
      expect(result.finalOutput, '');
    });

    test('should handle null content', () {
      final result = splitContentByThinkTags(null);
      expect(result.thinkingSessions, []);
      expect(result.finalOutput, '');
    });

    test('should handle content with <|im_end|> tag', () {
      const content = '<think>Thought.</think>Final output.<|im_end|>';
      final result = splitContentByThinkTags(content);
      expect(result.thinkingSessions, ['Thought.']);
      expect(result.finalOutput, 'Final output.');
    });

    test('should handle content with <|im_end|> tag and no final output', () {
      const content = '<think>Thought.</think><|im_end|>';
      final result = splitContentByThinkTags(content);
      expect(result.thinkingSessions, ['Thought.']);
      expect(result.finalOutput, '');
    });
  });

  group('getModelUrl', () {
    test('should return correct URL for Qwen3 0.6B', () {
      expect(getModelUrl('Qwen3 0.6B'),
          'https://huggingface.co/Cactus-Compute/Qwen3-600m-Instruct-GGUF/resolve/main/Qwen3-0.6B-Q8_0.gguf');
    });

    test('should return correct URL for Phi-3-mini-4k-instruct', () {
      expect(getModelUrl('Phi-3-mini-4k-instruct'),
          'https://huggingface.co/microsoft/Phi-3-mini-4k-instruct-gguf/resolve/main/Phi-3-mini-4k-instruct-q4.gguf');
    });

    test('should return correct URL for Llama-3-8B-Instruct', () {
      expect(getModelUrl('Llama-3-8B-Instruct'),
          'https://huggingface.co/unsloth/llama-3-8b-Instruct-gguf/resolve/main/llama-3-8b-Instruct-Q4_K_M.gguf');
    });

    test('should return default URL for unknown modelId', () {
      expect(getModelUrl('Unknown Model'),
          'https://huggingface.co/Cactus-Compute/Qwen3-600m-Instruct-GGUF/resolve/main/Qwen3-0.6B-Q8_0.gguf');
    });
  });
}