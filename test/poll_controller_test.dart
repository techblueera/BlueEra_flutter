import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/features/common/feed/models/posts_response.dart';
import 'package:BlueEra/features/common/post/controller/poll_controller.dart';
import 'package:BlueEra/features/common/post/repo/post_repo.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';

void main() {
  setUp(Get.reset);
  tearDown(Get.reset);

  PollController create({Post? editPost}) =>
      Get.put(PollController(repo: PostRepo(), editPost: editPost));

  group('PollController for a new poll', () {
    test('starts with two empty options that can grow to four', () {
      final c = create();

      expect(c.isEdit, isFalse);
      expect(c.optionControllers.length, 2);
      expect(c.canRemoveOption, isFalse);

      c.addOption();
      c.addOption();
      c.addOption();
      expect(c.optionControllers.length, 4);
      expect(c.canAddOption, isFalse);
      expect(c.canRemoveOption, isTrue);
    });

    test('asks for a question, then for two options', () {
      final c = create();

      expect(c.validateQuestion(), AppStrings.fillQuestion);

      c.questionController.text = 'Tea or coffee?';
      c.optionControllers[0].text = 'Tea';
      expect(c.validateQuestion(), AppStrings.fillTwoOptions);

      c.optionControllers[1].text = ' Coffee ';
      expect(c.validateQuestion(), isNull);
      expect(c.options, ['Tea', 'Coffee']);
    });

    test('clears the picked answer each time the options are re-validated',
        () {
      final c = create();
      c.questionController.text = 'Tea or coffee?';
      c.optionControllers[0].text = 'Tea';
      c.optionControllers[1].text = 'Coffee';
      c.validateQuestion();

      c.correctAnswerIndex.value = 1;
      expect(c.needsCorrectAnswer, isFalse);

      c.validateQuestion();
      expect(c.needsCorrectAnswer, isTrue);
    });
  });

  group('PollController editing a poll', () {
    test('fills the form from the post and locks the options', () {
      final c = create(
        editPost: Post(
          id: 'p1',
          subTitle: 'Vote!',
          poll: Poll(question: 'Tea or coffee?', options: [
            PollOption(text: 'Tea', isCorrect: true, votes: null),
            PollOption(text: 'Coffee', isCorrect: false, votes: null),
            PollOption(text: 'Water', isCorrect: false, votes: null),
          ]),
        ),
      );

      expect(c.isEdit, isTrue);
      expect(c.questionController.text, 'Tea or coffee?');
      expect(c.descriptionController.text, 'Vote!');
      expect(c.optionControllers.map((o) => o.text), ['Tea', 'Coffee', 'Water']);
      expect(c.canAddOption, isFalse);
      expect(c.canRemoveOption, isFalse);
      expect(c.needsCorrectAnswer, isFalse);
    });
  });
}
