import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:get/get.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/snackbar_helper.dart';
import '../../../../../widgets/common_back_app_bar.dart';
import '../../../../../widgets/custom_text_cm.dart';
import '../../../auth/model/messageMediaUrl.dart';

/// "Manage Storage" for a group: lists every shared media item with the space
/// it currently occupies on this device (the on-disk cache for network media,
/// or the file itself for locally-stored media) and lets the user free space by
/// deleting individual items — or everything at once. Deleted network media is
/// simply re-downloaded the next time it's opened.
class ManageGroupStorageScreen extends StatefulWidget {
  const ManageGroupStorageScreen({
    super.key,
    required this.mediaList,
    this.groupName,
  });

  final List<MessageMediaUrl> mediaList;
  final String? groupName;

  @override
  State<ManageGroupStorageScreen> createState() =>
      _ManageGroupStorageScreenState();
}

class _ManageGroupStorageScreenState extends State<ManageGroupStorageScreen> {
  final _items = <_MediaStorageItem>[];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _measure();
  }

  /// Resolve the on-device footprint of every media item, then sort largest
  /// first so the heavy items the user most likely wants to clear are on top.
  Future<void> _measure() async {
    final futures = widget.mediaList
        .where((m) => (m.url ?? '').isNotEmpty)
        .map(_resolveItem);
    final resolved = await Future.wait(futures);
    resolved.sort((a, b) => b.deviceBytes.compareTo(a.deviceBytes));
    if (!mounted) return;
    setState(() {
      _items
        ..clear()
        ..addAll(resolved);
      _loading = false;
    });
  }

  Future<_MediaStorageItem> _resolveItem(MessageMediaUrl media) async {
    final url = media.url!;
    final isNetwork = url.startsWith('http');
    int bytes = 0;
    bool onDevice = false;
    try {
      if (isNetwork) {
        final info = await DefaultCacheManager().getFileFromCache(url);
        if (info != null && await info.file.exists()) {
          bytes = await info.file.length();
          onDevice = true;
        }
      } else {
        final file = File(url);
        if (await file.exists()) {
          bytes = await file.length();
          onDevice = true;
        }
      }
    } catch (_) {
      // Treat any cache/IO error as "not on device".
    }
    return _MediaStorageItem(
      media: media,
      isNetwork: isNetwork,
      deviceBytes: bytes,
      onDevice: onDevice,
    );
  }

  Future<void> _delete(_MediaStorageItem item) async {
    final url = item.media.url ?? '';
    if (url.isEmpty || !item.onDevice) return;
    try {
      if (item.isNetwork) {
        await DefaultCacheManager().removeFile(url);
      } else {
        final file = File(url);
        if (await file.exists()) await file.delete();
      }
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      item
        ..onDevice = false
        ..deviceBytes = 0;
    });
    commonSnackBar(message: 'Removed from device');
  }

  Future<void> _deleteAll() async {
    final onDevice = _items.where((e) => e.onDevice).toList();
    if (onDevice.isEmpty) return;
    for (final item in onDevice) {
      final url = item.media.url ?? '';
      try {
        if (item.isNetwork) {
          await DefaultCacheManager().removeFile(url);
        } else {
          final file = File(url);
          if (await file.exists()) await file.delete();
        }
      } catch (_) {}
    }
    if (!mounted) return;
    setState(() {
      for (final item in onDevice) {
        item
          ..onDevice = false
          ..deviceBytes = 0;
      }
    });
    commonSnackBar(message: 'Freed up space on this device');
  }

  int get _totalBytes =>
      _items.fold(0, (sum, e) => sum + (e.onDevice ? e.deviceBytes : 0));
  int get _onDeviceCount => _items.where((e) => e.onDevice).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: CommonBackAppBar(title: 'Manage Storage'),
      body: _loading
          ? const Center(
              child: SizedBox(
                height: 28,
                width: 28,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
            )
          : Column(
              children: [
                _summaryCard(),
                Expanded(
                  child: _items.isEmpty
                      ? Center(
                          child: CustomText(
                            'No media shared in this group',
                            color: AppColors.grayText,
                          ),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(10, 4, 10, 20),
                          itemCount: _items.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, index) =>
                              _mediaTile(_items[index]),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _summaryCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(10, 12, 10, 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            AppColors.primaryColor,
            AppColors.primaryColor.withValues(alpha: 0.7),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.sd_storage_outlined, color: Colors.white, size: 22),
              const SizedBox(width: 8),
              CustomText(
                'Used on this device',
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ],
          ),
          const SizedBox(height: 10),
          CustomText(
            _formatBytes(_totalBytes),
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w800,
          ),
          const SizedBox(height: 4),
          CustomText(
            '$_onDeviceCount of ${_items.length} items downloaded',
            color: Colors.white.withValues(alpha: 0.85),
            fontSize: 12,
          ),
          if (_onDeviceCount > 0) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  side: BorderSide.none,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: _confirmDeleteAll,
                icon: Icon(Icons.delete_sweep_outlined,
                    size: 18, color: AppColors.red),
                label: CustomText(
                  'Free up ${_formatBytes(_totalBytes)}',
                  color: AppColors.red,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _mediaTile(_MediaStorageItem item) {
    final media = item.media;
    final type = media.type ?? '';
    final isImage = type.startsWith('image');
    final isVideo = type.startsWith('video');
    final name = (media.name?.isNotEmpty == true)
        ? media.name!
        : isImage
            ? 'Photo'
            : isVideo
                ? 'Video'
                : 'File';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          // Thumbnail / type icon
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 48,
              height: 48,
              child: (isImage && item.isNetwork)
                  ? CachedNetworkImage(
                      imageUrl: media.url!,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => _typeIconBox(media.type),
                    )
                  : _typeIconBox(media.type),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  name,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      item.onDevice
                          ? Icons.phone_iphone
                          : Icons.cloud_outlined,
                      size: 13,
                      color: item.onDevice
                          ? AppColors.primaryColor
                          : AppColors.grayText,
                    ),
                    const SizedBox(width: 4),
                    CustomText(
                      item.onDevice
                          ? _formatBytes(item.deviceBytes)
                          : 'Not on device',
                      fontSize: 12,
                      color: item.onDevice
                          ? AppColors.primaryColor
                          : AppColors.grayText,
                      fontWeight: FontWeight.w500,
                    ),
                    if (!item.onDevice && (media.size ?? 0) > 0) ...[
                      const SizedBox(width: 6),
                      CustomText(
                        '· ${_formatBytes(media.size!)}',
                        fontSize: 11,
                        color: AppColors.grayText,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (item.onDevice)
            IconButton(
              icon: Icon(Icons.delete_outline, color: AppColors.red),
              onPressed: () => _delete(item),
            )
          else
            const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _typeIconBox(String? type) {
    IconData icon;
    if ((type ?? '').startsWith('video')) {
      icon = Icons.videocam_outlined;
    } else if ((type ?? '').startsWith('audio')) {
      icon = Icons.audiotrack_outlined;
    } else if ((type ?? '').startsWith('image')) {
      icon = Icons.image_outlined;
    } else if ((type ?? '').contains('pdf')) {
      icon = Icons.picture_as_pdf_outlined;
    } else {
      icon = Icons.insert_drive_file_outlined;
    }
    return Container(
      color: AppColors.fillColor,
      child: Icon(icon, color: AppColors.grayText),
    );
  }

  void _confirmDeleteAll() {
    Get.dialog(
      Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 24),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText('Free up space',
                  fontSize: 18, fontWeight: FontWeight.bold),
              const SizedBox(height: 12),
              CustomText(
                'Delete all downloaded media for this group from your device? '
                'Items will re-download when you open them again.',
                fontSize: 14,
              ),
              const SizedBox(height: 22),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Get.back(),
                      child: CustomText('Cancel',
                          color: AppColors.primaryColor),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.red,
                      ),
                      onPressed: () {
                        Get.back();
                        _deleteAll();
                      },
                      child: const CustomText('Delete', color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatBytes(num bytes) {
    if (bytes <= 0) return '0 B';
    const units = ['B', 'KB', 'MB', 'GB'];
    double size = bytes.toDouble();
    int i = 0;
    while (size >= 1024 && i < units.length - 1) {
      size /= 1024;
      i++;
    }
    final decimals = (i > 0 && size < 100) ? 1 : 0;
    return '${size.toStringAsFixed(decimals)} ${units[i]}';
  }
}

class _MediaStorageItem {
  _MediaStorageItem({
    required this.media,
    required this.isNetwork,
    required this.deviceBytes,
    required this.onDevice,
  });

  final MessageMediaUrl media;
  final bool isNetwork;
  int deviceBytes;
  bool onDevice;
}
