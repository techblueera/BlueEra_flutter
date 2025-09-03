import 'dart:io';

import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
// import 'package:device_info_plus/device_info_plus.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class DownloaderServices {
  DownloaderServices._();

  static final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(minutes: 5),
    ),
  );

  static Future<int> _androidSdk() async {
    if (!Platform.isAndroid) return 0;
    final info = await DeviceInfoPlugin().androidInfo;
    return info.version.sdkInt;
  }

  static Future<void> _ensureStoragePermission() async {
    if (!Platform.isAndroid) return;
    final int sdk = await _androidSdk();
    if (sdk >= 33) return;

    final status = await Permission.storage.request();
    if (!status.isGranted) {
      throw DownloadException('Storage permission denied');
    }
  }

  static Future<File?> download({
    required String url,
    String? fileName,
    void Function(int received, int total)? onProgress,
  }) async {
    try {
      final Directory dir = await _getDownloadsDirectory();
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }

      final String name = fileName ?? p.basename(Uri.parse(url).path);
      final File target = await _uniqueFile(File(p.join(dir.path, name)));

      await _ensureStoragePermission();

      await _dio.download(
        url,
        target.path,
        onReceiveProgress: onProgress,
        options: Options(responseType: ResponseType.bytes, followRedirects: true),
      );

      return target;
    } on DioException catch (e) {
      logs('Download failed: ${e.message}');
      return null;
    } on DownloadException catch (e) {
      logs(e.toString());
      return null;
    } catch (e) {
      logs('Unexpected error: $e');
      return null;
    }
  }

  static Future<Directory> _getDownloadsDirectory() async {
    if (Platform.isAndroid) {
      return Directory('/storage/emulated/0/Download');
    }
    // For iOS Documents folder
    return await getApplicationDocumentsDirectory();
  }

  static Future<File> _uniqueFile(File original) async {
    if (!await original.exists()) return original;

    final String dir = original.parent.path;
    final String base = p.basenameWithoutExtension(original.path);
    final String ext = p.extension(original.path);
    int counter = 1;

    File candidate;
    do {
      candidate = File(p.join(dir, '$base ($counter)$ext'));
      counter++;
    } while (await candidate.exists());
    return candidate;
  }
}

class DownloadException implements Exception {
  final String message;
  DownloadException(this.message);
  @override
  String toString() => 'DownloadException: $message';
}
