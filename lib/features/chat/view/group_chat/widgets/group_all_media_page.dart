import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../core/api/apiService/api_keys.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/shared_preference_utils.dart';
import '../../../../../core/constants/snackbar_helper.dart';
import '../../../../../widgets/common_back_app_bar.dart';
import '../../../../../widgets/custom_text_cm.dart';
import '../../../auth/controller/chat_theme_controller.dart';
import '../../../auth/controller/chat_view_controller.dart';
import '../../../auth/model/GetListOfMessageData.dart';
import '../../../auth/model/group_details_model.dart';
import '../../../auth/model/messageMediaUrl.dart';
import '../../contacts/view/be_available_contacts_list.dart';
import '../../widget/common_delete_message.dart';
import '../../widget/media_message_full_view.dart';

/// Full "All Media" browser for a group, opened from the group info gallery
/// preview / "Media, Links & Docs". Three tabs:
///   • Media — images + videos
///   • Docs  — files / pdf / audio
///   • Links — http(s) URLs extracted from text messages
///
/// Long-pressing any item surfaces Forward / Delete actions for the underlying
/// message.
class GroupAllMediaPage extends StatefulWidget {
  const GroupAllMediaPage({
    super.key,
    required this.conversationId,
    required this.mediaList,
    this.groupName,
  });

  final String? conversationId;
  final String? groupName;
  final List<GroupMediaModel> mediaList;

  @override
  State<GroupAllMediaPage> createState() => _GroupAllMediaPageState();
}

class _GroupAllMediaPageState extends State<GroupAllMediaPage> {
  final chatViewController = Get.find<ChatViewController>();
  final ChatThemeController chatThemeController =
      Get.isRegistered<ChatThemeController>()
          ? Get.find<ChatThemeController>()
          : Get.put(ChatThemeController());

  final List<_MediaEntry> _media = [];
  final List<_MediaEntry> _docs = [];
  final List<_MediaEntry> _links = [];

  @override
  void initState() {
    super.initState();
    _buildEntries();
  }

  void _buildEntries() {
    _media.clear();
    _docs.clear();
    _links.clear();

    for (final m in widget.mediaList) {
      final mine = m.senderId != null && m.senderId == userId;
      for (final u in (m.url ?? [])) {
        if ((u.url ?? '').isEmpty) continue;
        final type = (u.type ?? '').toLowerCase();
        final entry = _MediaEntry(
          messageId: m.id,
          media: u,
          createdAt: m.createdAt,
          myMessage: mine,
        );
        if (type.startsWith('image') || type.startsWith('video')) {
          _media.add(entry);
        } else {
          _docs.add(entry);
        }
      }
    }

    // Links live inside text messages, not the media list — pull them from the
    // conversation's loaded messages.
    final urlReg = RegExp(r'(https?:\/\/[^\s]+)', caseSensitive: false);
    for (final msg in (chatViewController.getListOfMessageData ?? <Messages>[])) {
      final text = msg.message ?? '';
      if (text.isEmpty) continue;
      for (final match in urlReg.allMatches(text)) {
        final link = match.group(0);
        if (link == null) continue;
        _links.add(_MediaEntry(
          messageId: msg.id,
          link: link,
          createdAt: (msg.createdAt != null && msg.createdAt!.isNotEmpty)
              ? DateTime.tryParse(msg.createdAt!)
              : null,
          myMessage: msg.myMessage ?? false,
        ));
      }
    }

    // Newest first across all tabs.
    int byDateDesc(_MediaEntry a, _MediaEntry b) =>
        (b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0))
            .compareTo(a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0));
    _media.sort(byDateDesc);
    _docs.sort(byDateDesc);
    _links.sort(byDateDesc);
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: CommonBackAppBar(title: 'All Media'),
        body: Column(
          children: [
            Container(
              color: AppColors.white,
              child: TabBar(
                labelColor: AppColors.primaryColor,
                unselectedLabelColor: AppColors.grayText,
                indicatorColor: AppColors.primaryColor,
                indicatorWeight: 2.5,
                labelStyle: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w700),
                tabs: [
                  Tab(text: 'Media (${_media.length})'),
                  Tab(text: 'Docs (${_docs.length})'),
                  Tab(text: 'Links (${_links.length})'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _mediaGrid(),
                  _docsList(),
                  _linksList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Media tab ───────────────────────────────────────────────────────────
  Widget _mediaGrid() {
    if (_media.isEmpty) return _emptyState('No photos or videos');
    return GridView.builder(
      padding: const EdgeInsets.all(2),
      itemCount: _media.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2,
        mainAxisSpacing: 2,
      ),
      itemBuilder: (context, index) {
        final entry = _media[index];
        final isVideo = (entry.media?.type ?? '').toLowerCase().startsWith('video');
        return GestureDetector(
          onTap: () => _openMediaViewer(index),
          onLongPress: () => _showActions(entry),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(
                imageUrl: entry.media?.url ?? '',
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Container(
                  color: AppColors.fillColor,
                  child: Icon(
                    isVideo ? Icons.videocam_outlined : Icons.broken_image_outlined,
                    color: Colors.grey,
                  ),
                ),
              ),
              if (isVideo)
                const Center(
                  child: Icon(Icons.play_circle_fill,
                      color: Colors.white, size: 34),
                ),
            ],
          ),
        );
      },
    );
  }

  void _openMediaViewer(int index) {
    final urls = _media.map((e) => e.media!).toList();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FullImagePreviewPage(images: urls, initialIndex: index),
      ),
    );
  }

  // ── Docs tab ────────────────────────────────────────────────────────────
  Widget _docsList() {
    if (_docs.isEmpty) return _emptyState('No documents');
    return ListView.separated(
      padding: const EdgeInsets.all(10),
      itemCount: _docs.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final entry = _docs[index];
        final media = entry.media!;
        return GestureDetector(
          onTap: () => _launch(media.url ?? ''),
          onLongPress: () => _showActions(entry),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(_iconForType(media.type),
                      color: AppColors.primaryColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        (media.name?.isNotEmpty == true) ? media.name! : 'Document',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      CustomText(
                        '${(media.type ?? 'file').toUpperCase()}'
                        '${(media.size ?? 0) > 0 ? ' · ${_formatBytes(media.size!)}' : ''}',
                        fontSize: 12,
                        color: AppColors.grayText,
                      ),
                    ],
                  ),
                ),
                Icon(Icons.download_outlined,
                    color: AppColors.grayText, size: 20),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Links tab ───────────────────────────────────────────────────────────
  Widget _linksList() {
    if (_links.isEmpty) return _emptyState('No links shared');
    return ListView.separated(
      padding: const EdgeInsets.all(10),
      itemCount: _links.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final entry = _links[index];
        final link = entry.link ?? '';
        return GestureDetector(
          onTap: () => _launch(link),
          onLongPress: () => _showActions(entry),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.link, color: AppColors.primaryColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomText(
                    link,
                    fontSize: 13,
                    color: AppColors.primaryColor,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Shared actions ────────────────────────────────────────────────────────
  void _showActions(_MediaEntry entry) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            _actionRow(
              icon: Icons.forward,
              label: 'Forward',
              onTap: () {
                Get.back();
                _forward(entry);
              },
            ),
            _actionRow(
              icon: Icons.delete_outline,
              label: 'Delete',
              color: AppColors.red,
              onTap: () {
                Get.back();
                _confirmDelete(entry);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _actionRow({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: color ?? AppColors.mainTextColor),
      title: CustomText(
        label,
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: color ?? AppColors.mainTextColor,
      ),
    );
  }

  void _forward(_MediaEntry entry) {
    final id = entry.messageId;
    if (id == null || id.isEmpty) {
      commonSnackBar(message: 'Unable to forward this item');
      return;
    }
    // BeAvailableContactsList reads selectedMessageIds for the forward payload.
    chatThemeController.resetSelection();
    chatThemeController.selectedMessageIds.add(id);
    Get.to(() => BeAvailableContactsList(isFromForwardMessage: true));
  }

  void _confirmDelete(_MediaEntry entry) {
    showDialog(
      context: context,
      builder: (_) => CommonDeleteDialog(
        showDeleteForEveryone: entry.myMessage,
        showDeleteFromDevice: entry.media != null,
        onDeleteForMe: () {
          Navigator.pop(context);
          _doDelete(entry, false);
        },
        onDeleteForEveryone: () {
          Navigator.pop(context);
          _doDelete(entry, true);
        },
      ),
    );
  }

  Future<void> _doDelete(_MediaEntry entry, bool forEveryone) async {
    final id = entry.messageId;
    if (id == null || id.isEmpty) return;

    await chatViewController.deleteChatMessage({
      ApiKeys.conversation_id: widget.conversationId,
      ApiKeys.delete_from_every_one: forEveryone,
      ApiKeys.message_id_list: [id],
    }, '');

    if (!mounted) return;
    setState(() {
      _media.removeWhere((e) => e.messageId == id);
      _docs.removeWhere((e) => e.messageId == id);
      _links.removeWhere((e) => e.messageId == id);
    });
    // Keep the group info media list fresh.
    chatViewController.getGroupDetailsApi({
      ApiKeys.conversation_id: widget.conversationId,
    });
    commonSnackBar(message: 'Deleted');
  }

  Future<void> _launch(String url) async {
    if (url.isEmpty) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      commonSnackBar(message: 'Could not open link');
    }
  }

  Widget _emptyState(String text) => Center(
        child: CustomText(text, color: AppColors.grayText),
      );

  IconData _iconForType(String? type) {
    final t = (type ?? '').toLowerCase();
    if (t.startsWith('audio')) return Icons.audiotrack_outlined;
    if (t.contains('pdf')) return Icons.picture_as_pdf_outlined;
    return Icons.insert_drive_file_outlined;
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

class _MediaEntry {
  _MediaEntry({
    this.messageId,
    this.media,
    this.link,
    this.createdAt,
    this.myMessage = false,
  });

  final String? messageId;
  final MessageMediaUrl? media;
  final String? link;
  final DateTime? createdAt;
  final bool myMessage;
}
