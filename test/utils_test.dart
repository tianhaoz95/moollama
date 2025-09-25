import 'package:flutter_test/flutter_test.dart';
import 'package:moollama/utils.dart'; // Assuming your utils.dart is in lib/

void main() {
  group('splitContentByThinkTags', () {
    test('should correctly split content with multiple think tags', () {
      const content =
          '<think>This is the first thought.</think>Some text.<think>Second thought.</think>Final output.';
      final result = splitContentByThinkTags(content);
      expect(result.thinkingSessions, [
        'This is the first thought.',
        'Second thought.',
      ]);
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
}
