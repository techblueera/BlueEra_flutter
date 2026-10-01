import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/api_exceptions.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// A file of [bytes] without allocating them.
MultipartFile _file(int bytes) => MultipartFile.fromStream(
    () => const Stream<List<int>>.empty(), bytes,
    filename: 'f.bin');

void main() {
  const mb = 1024 * 1024;

  test('a normal upload passes', () {
    final form = FormData()..files.add(MapEntry('file', _file(20 * mb)));
    expect(() => ApiBaseHelper.checkUploadSize(form), returnsNormally);
  });

  test('a body over the limit is refused before it is sent', () {
    final form = FormData()..files.add(MapEntry('file', _file(96 * mb)));
    expect(
      () => ApiBaseHelper.checkUploadSize(form),
      throwsA(isA<BadRequestException>()
          .having((e) => e.message, 'message', contains('95 MB'))),
    );
  });

  test('several files are counted together', () {
    final form = FormData()
      ..files.add(MapEntry('a', _file(50 * mb)))
      ..files.add(MapEntry('b', _file(50 * mb)));
    expect(() => ApiBaseHelper.checkUploadSize(form),
        throwsA(isA<BadRequestException>()));
  });
}
