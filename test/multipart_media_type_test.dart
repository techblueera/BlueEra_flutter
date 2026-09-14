import 'dart:io';

import 'package:BlueEra/core/services/multipart_image_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pins the media type attached to uploaded images.
///
/// The regression this guards: the type was built as
/// `'image/${fileName.split('.').last}'`, which emits **`image/jpg`** for the
/// `.jpg` files this app's own picker writes. `image/jpg` is not a registered
/// IANA media type, and server-side upload validators that whitelist types
/// reject it — the document-verification upload being the case that surfaced
/// it. PNG happened to work, so the failure looked format-dependent rather
/// than systematic.
void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('multipart_media_type');
  });

  tearDown(() async {
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  /// A real on-disk file — `MultipartFile.fromFile` stats the path.
  Future<File> fileNamed(String name) async {
    final file = File('${tempDir.path}/$name');
    await file.writeAsBytes(List<int>.filled(8, 0));
    return file;
  }

  Future<String> mediaTypeOf(String name) async {
    final parts = await multiPartMultipleImages(arrImages: [await fileNamed(name)]);
    return parts.single.contentType.toString();
  }

  group('media type by extension', () {
    test('.jpg maps to image/jpeg, NOT image/jpg', () async {
      expect(await mediaTypeOf('compressed_1739880000000.jpg'), 'image/jpeg');
    });

    test('.jpeg maps to image/jpeg', () async {
      expect(await mediaTypeOf('scan.jpeg'), 'image/jpeg');
    });

    test('.png maps to image/png', () async {
      expect(await mediaTypeOf('cropped_image_01.png'), 'image/png');
    });

    test('an uppercase extension is normalised', () async {
      // `PHOTO.JPG` used to yield the bogus `image/JPG`.
      expect(await mediaTypeOf('PHOTO.JPG'), 'image/jpeg');
    });

    test('a file with no extension falls back to a real image type', () async {
      // Used to yield `image/<whole filename>`.
      final type = await mediaTypeOf('aadhaar_front');
      expect(type, 'image/jpeg');
      expect(type, isNot(contains('aadhaar_front')));
    });

    test('other image formats are mapped, not guessed', () async {
      expect(await mediaTypeOf('a.webp'), 'image/webp');
      expect(await mediaTypeOf('b.heic'), 'image/heic');
    });

    test('every produced type is a registered image/* or application/* type',
        () async {
      const allowed = {
        'image/jpeg',
        'image/png',
        'image/webp',
        'image/heic',
        'image/heif',
        'image/gif',
        'image/bmp',
        'application/pdf',
      };
      for (final name in const [
        'a.jpg', 'b.JPEG', 'c.png', 'd.webp', 'e.heic',
        'f.heif', 'g.gif', 'h.bmp', 'i.pdf', 'j', 'k.unknownext',
      ]) {
        expect(allowed, contains(await mediaTypeOf(name)),
            reason: 'unregistered media type produced for "$name"');
      }
    });
  });

  group('filename', () {
    test('is the basename, not the full path', () async {
      final parts =
          await multiPartMultipleImages(arrImages: [await fileNamed('front.jpg')]);
      expect(parts.single.filename, 'front.jpg');
    });

    test('both sides of a document are returned in order', () async {
      final parts = await multiPartMultipleImages(arrImages: [
        await fileNamed('front.jpg'),
        await fileNamed('back.png'),
      ]);
      expect(parts, hasLength(2));
      expect(parts[0].filename, 'front.jpg');
      expect(parts[1].filename, 'back.png');
      expect(parts[0].contentType.toString(), 'image/jpeg');
      expect(parts[1].contentType.toString(), 'image/png');
    });

    test('a null or empty list yields no parts', () async {
      expect(await multiPartMultipleImages(arrImages: null), isEmpty);
      expect(await multiPartMultipleImages(arrImages: []), isEmpty);
    });
  });
}
