import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/features/common/feed/models/posts_response.dart';
import 'package:BlueEra/features/common/post/controller/message_post_controller.dart';
import 'package:BlueEra/features/common/post/controller/photo_post_controller.dart';
import 'package:BlueEra/features/common/post/controller/tag_user_controller.dart';
import 'package:BlueEra/features/common/post/repo/post_repo.dart';
import 'package:BlueEra/features/personal/personal_profile/repo/user_repo.dart';
import 'package:dio/dio.dart' show RequestOptions, Response;
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart' hide Response;

/// Serves [pages] of users in order, one per request.
class _FakeUserRepo extends UserRepo {
  _FakeUserRepo(this.pages);

  final List<List<String>> pages;
  int _next = 0;

  @override
  Future<ResponseModel> getAllUsers(
      {required Map<String, dynamic> params}) async {
    final ids = _next < pages.length ? pages[_next++] : const <String>[];
    return ResponseModel(
      statusCode: 200,
      response: Response(
        requestOptions: RequestOptions(),
        statusCode: 200,
        data: {
          'status': true,
          'data': [
            for (final id in ids) {'_id': id, 'account_type': 'INDIVIDUAL'}
          ],
        },
      ),
    );
  }
}

TagUserController _tagUsers(List<List<String>> pages,
    {Iterable<String> tagged = const []}) {
  final controller = TagUserController(
      repo: _FakeUserRepo(pages), initialTaggedIds: tagged)
    // Page size small enough that the fake's pages count as full pages.
    ..limit = 2;
  return Get.put(controller);
}

Future<void> _settle() => Future<void>.delayed(Duration.zero);

void main() {
  setUp(Get.reset);
  tearDown(Get.reset);

  group('TagUserController', () {
    test('selects the edited post\'s tagged users as their page loads',
        () async {
      final c = _tagUsers([
        ['a', 'b'],
        ['c', 'd'],
      ], tagged: ['b', 'c']);
      await _settle();
      expect(c.selectedUsers.map((u) => u.id), ['b']);

      c.fetchUsers();
      await _settle();
      expect(c.selectedUsers.map((u) => u.id), ['b', 'c']);
      expect(c.selectedUsers.every((u) => u.isSelected.value), isTrue);
    });

    test('does not re-tag a user removed before the next page loads',
        () async {
      final c = _tagUsers([
        ['a', 'b'],
        ['c', 'd'],
      ], tagged: ['b']);
      await _settle();
      c.removeSelectedUser(c.selectedUsers.single);

      c.fetchUsers();
      await _settle();
      expect(c.selectedUsers, isEmpty);
    });
  });

  group('PhotoPostController', () {
    test('fills the form from the post being edited', () async {
      final tags = _tagUsers(const []);
      final c = Get.put(PhotoPostController(
        repo: PostRepo(),
        tagUsers: tags,
        editPost: Post(
          id: 'p1',
          subTitle: 'Sunset',
          natureOfPost: 'Travel',
          media: ['https://example.com/1.jpg'],
          visibilityDuration: 7,
        ),
      ));

      expect(c.isPhotoPostEdit, isTrue);
      expect(c.selectedPhotos, ['https://example.com/1.jpg']);
      expect(c.descriptionTextEdit.text, 'Sunset');
      expect(c.natureOfPostTextEdit.text, 'Travel');
      expect(c.selectedSymbol.value, SymbolDuration.days7);
    });

    test('takes the photo editor\'s result, and ignores a dismissed editor',
        () {
      final c = Get.put(PhotoPostController(
          repo: PostRepo(), tagUsers: _tagUsers(const [])));
      c.applyEditedPhotos(['/a.jpg', '/b.jpg']);
      expect(c.selectedPhotos, ['/a.jpg', '/b.jpg']);
      expect(c.selectedPhotoFiles.map((f) => f.path), ['/a.jpg', '/b.jpg']);

      c.applyEditedPhotos(null);
      expect(c.selectedPhotos, ['/a.jpg', '/b.jpg']);

      // The editor returns an empty list when the last photo is removed.
      c.applyEditedPhotos([]);
      expect(c.selectedPhotos, isEmpty);
    });

    test('refuses to post a new symbol without a photo', () async {
      final c = Get.put(PhotoPostController(
          repo: PostRepo(), tagUsers: _tagUsers(const [])));

      expect(c.isPhotoPostEdit, isFalse);
      expect(await c.submitPost(), isFalse);
    });
  });

  group('MessagePostController', () {
    test('fills the form from the post being edited', () {
      final c = Get.put(MessagePostController(
        repo: PostRepo(),
        tagUsers: _tagUsers(const []),
        editPost: Post(
          id: 'p1',
          message: 'Hello',
          subTitle: 'A long enough description for a lekha post',
          media: ['https://example.com/1.jpg'],
          referenceLink: 'https://example.com',
        ),
      ));

      expect(c.isMsgPostEdit, isTrue);
      expect(c.uploadImageList, ['https://example.com/1.jpg']);
      expect(c.descriptionMessage.value.text,
          'A long enough description for a lekha post');
      expect(c.isAddLink.value, isTrue);
      expect(c.referenceLinkController.value.text, 'https://example.com');
      expect(c.validateDescription(), isNull);
    });

    test('asks for at least 30 characters of description', () {
      final c = Get.put(MessagePostController(repo: PostRepo()));

      c.descriptionMessage.value.text = 'Too short';
      expect(c.validateDescription(), isNotNull);
    });

    test('keeps the post being reposted', () {
      final original = Post(id: 'orig');
      final c =
          Get.put(MessagePostController(repo: PostRepo(), repostOf: original));

      expect(c.repostOf, same(original));
      expect(c.isMsgPostEdit, isFalse);
    });
  });
}
