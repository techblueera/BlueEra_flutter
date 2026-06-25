import 'dart:io';
import 'package:BlueEra/features/chat/view/group_chat/widgets/edit_group_details.dart';
import 'package:BlueEra/features/chat/view/group_chat/widgets/group_members_list.dart';
import 'package:croppy/croppy.dart';
import 'package:intl/intl.dart';
import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/constants/common_methods.dart' as cmd;

import '../../../../core/api/apiService/api_response.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_icon_assets.dart';
import '../../../../widgets/common_back_app_bar.dart';
import '../../../../widgets/expandable_text.dart';
import '../../../../widgets/horizontal_tab_selector.dart';
import '../../../../widgets/local_assets.dart';
import 'package:BlueEra/core/services/photo_picker_service.dart';
import '../../auth/controller/chat_view_controller.dart';
import '../../auth/model/group_details_model.dart';
import '../widget/component_widgets.dart' show showDeleteChatDialog, showExitGroupDialog;
import '../../../../core/constants/snackbar_helper.dart';
import '../contacts/view/be_available_contacts_list.dart';
import '../../auth/model/messageMediaUrl.dart';
import 'widgets/manage_group_storage_screen.dart';
import 'widgets/group_all_media_page.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ViewGroupMembers extends StatefulWidget {
  const ViewGroupMembers(
      {required this.conversationId,
      required this.type,
      super.key});

  final String? conversationId;
  final String? type;

  @override
  State<ViewGroupMembers> createState() => _ViewGroupMembersState();
}

class _ViewGroupMembersState extends State<ViewGroupMembers> {
  final chatViewController = Get.find<ChatViewController>();
  int selectedIndex = 0;
  bool muteNotifications = false;

  @override
  void initState() {
    Map<String, dynamic> data = {
      ApiKeys.conversation_id: widget.conversationId
    };
    chatViewController.getGroupDetailsApi(data);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {


    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: CommonBackAppBar(),
      body: Obx(() {
        if (chatViewController.groupDetailsResponse.value.status ==
            Status.COMPLETE) {
          GroupDetailsModel details=chatViewController.groupDetailsModel.value;
          List<GroupMediaModel> mediaList=details.media??[];
          List<GroupMembersListModel> members =details.members??[];
          String groupName=details.groupName??'';
          String groupProfileImage=details.groupProfileImage??'';
          String groupCoverImage=details.groupCoverImage??'';

          final adminName = details.members
                  ?.firstWhereOrNull((e) => e.isAdmin == true)
                  ?.name ??
              '-';

          // Flattened media (images/videos/docs) for the storage manager.
          final List<MessageMediaUrl> allMediaUrls = [
            for (final m in mediaList)
              if (m.url != null) ...m.url!,
          ];

          return SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _headerCard(
                    details: details,
                    groupName: groupName,
                    groupProfileImage: groupProfileImage,
                    groupCoverImage: groupCoverImage,
                    members: members,
                    adminName: adminName,
                  ),
                  const SizedBox(height: 12),
                  _sectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                          child: HorizontalTabSelector(
                            unSelectedBackgroundColor: AppColors.white,
                            horizontalPadding: 8,
                            tabs: [
                              AppStrings.membersTab.tr,
                              AppStrings.galleryTab.tr,
                              AppStrings.documentsTab.tr
                            ],
                            selectedIndex: selectedIndex,
                            onTabSelected: (index, dd) {
                              selectedIndex = index;
                              if (index == 1) {
                                chatViewController.getPinMessageListDataApi({
                                  ApiKeys.conversation_id: widget.conversationId
                                });
                              }
                              setState(() {});
                            },
                            labelBuilder: (value) => value,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildTabContent(selectedIndex, groupProfileImage,
                            groupName, members, mediaList),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _sectionLabel("Settings"),
                  _buildActionsSection(groupName, allMediaUrls, mediaList),
                ],
              ),
            ),
          );
        } else {
          return const Center(
            child: SizedBox(
              height: 30,
              width: 30,
              child: CircularProgressIndicator(),
            ),
          );
        }
      }),
    );
  }

  /// Reusable white rounded card with a soft shadow, used for every section.
  Widget _sectionCard({required Widget child, EdgeInsets? padding}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _sectionLabel(String text) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 0, 16, 8),
      child: CustomText(
        text.toUpperCase(),
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppColors.grayText,
      ),
    );
  }

  /// Bottom action card: mute, media, clear chat, report and exit group.
  Widget _buildActionsSection(String groupName,
      List<MessageMediaUrl> allMedia, List<GroupMediaModel> mediaModels) {
    return _sectionCard(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        children: [
          _actionTile(
            icon: muteNotifications
                ? Icons.notifications_off_outlined
                : Icons.notifications_active_outlined,
            label: muteNotifications
                ? "Unmute Notifications"
                : "Mute Notifications",
            onTap: () {
              setState(() => muteNotifications = !muteNotifications);
              commonSnackBar(
                  message: muteNotifications
                      ? "Group notifications muted"
                      : "Group notifications unmuted");
            },
            trailing: Container(
              width: 42,
              height: 24,
              padding: const EdgeInsets.all(2),
              alignment:
                  muteNotifications ? Alignment.centerRight : Alignment.centerLeft,
              decoration: BoxDecoration(
                color: muteNotifications
                    ? AppColors.primaryColor
                    : AppColors.whiteE5,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          _divider(),
          _actionTile(
            icon: Icons.perm_media_outlined,
            label: "Media, Links & Docs",
            onTap: () => _openAllMedia(groupName, mediaModels),
          ),
          _divider(),
          _actionTile(
            icon: Icons.sd_storage_outlined,
            label: "Manage Storage",
            onTap: () => Get.to(() => ManageGroupStorageScreen(
                  mediaList: allMedia,
                  groupName: groupName,
                )),
          ),
          _divider(),
          _actionTile(
            icon: Icons.delete_sweep_outlined,
            label: "Clear Chat",
            onTap: () => showDeleteChatDialog(widget.conversationId ?? ''),
          ),
          _divider(),
          _actionTile(
            icon: Icons.flag_outlined,
            label: "Report Group",
            iconColor: AppColors.red,
            labelColor: AppColors.red,
            onTap: () => commonSnackBar(
                message: "Report submitted for \"$groupName\""),
          ),
          _divider(),
          _actionTile(
            icon: Icons.logout,
            label: "Exit Group",
            iconColor: AppColors.red,
            labelColor: AppColors.red,
            onTap: () => showExitGroupDialog(widget.conversationId ?? ''),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Divider(height: 1, thickness: 0.6, color: AppColors.whiteE5),
      );

  Widget _actionTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? iconColor,
    Color? labelColor,
    Widget? trailing,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (iconColor ?? AppColors.primaryColor)
                    .withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon,
                  size: 20, color: iconColor ?? AppColors.primaryColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: CustomText(
                label,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: labelColor ?? AppColors.black,
              ),
            ),
            trailing ??
                Icon(Icons.arrow_forward_ios,
                    size: 14, color: AppColors.greyLite),
          ],
        ),
      ),
    );
  }

  void _openAllMedia(String groupName, List<GroupMediaModel> mediaList) {
    Get.to(() => GroupAllMediaPage(
          conversationId: widget.conversationId,
          groupName: groupName,
          mediaList: mediaList,
        ));
  }

  /// Gallery tab: a single row of thumbnails (images/videos) with the last tile
  /// showing "+N" when there's more, plus a "View all media" row. Tapping any of
  /// it opens the full [GroupAllMediaPage].
  Widget _galleryPreview(String groupName, List<GroupMediaModel> mediaList) {
    final List<MessageMediaUrl> visualMedia = [
      for (final m in mediaList)
        if (m.url != null)
          for (final u in m.url!)
            if ((u.url ?? '').isNotEmpty &&
                ((u.type ?? '').toLowerCase().startsWith('image') ||
                    (u.type ?? '').toLowerCase().startsWith('video')))
              u,
    ];

    if (visualMedia.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: CustomText(AppStrings.noMediaFoundLabel.tr,
              color: AppColors.grayText),
        ),
      );
    }

    const int rowCount = 3;
    final int previewCount =
        visualMedia.length < rowCount ? visualMedia.length : rowCount;
    final int remaining = visualMedia.length - previewCount;

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
      child: Column(
        children: [
          Row(
            children: List.generate(previewCount, (i) {
              final media = visualMedia[i];
              final isVideo =
                  (media.type ?? '').toLowerCase().startsWith('video');
              // The last preview tile doubles as a "+N more" overlay.
              final showMoreOverlay = i == previewCount - 1 && remaining > 0;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: i == previewCount - 1 ? 0 : 4),
                  child: GestureDetector(
                    onTap: () => _openAllMedia(groupName, mediaList),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            CachedNetworkImage(
                              imageUrl: media.url ?? '',
                              fit: BoxFit.cover,
                              errorWidget: (_, __, ___) => Container(
                                color: AppColors.fillColor,
                                child: Icon(
                                  isVideo
                                      ? Icons.videocam_outlined
                                      : Icons.broken_image_outlined,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                            if (isVideo && !showMoreOverlay)
                              const Center(
                                child: Icon(Icons.play_circle_fill,
                                    color: Colors.white, size: 30),
                              ),
                            if (showMoreOverlay)
                              Container(
                                color: Colors.black.withValues(alpha: 0.5),
                                alignment: Alignment.center,
                                child: CustomText(
                                  '+$remaining',
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: () => _openAllMedia(groupName, mediaList),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CustomText(
                    "View all media (${visualMedia.length})",
                    color: AppColors.primaryColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.arrow_forward_ios,
                      size: 12, color: AppColors.primaryColor),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent(int index,String profileImage,String groupName, List<GroupMembersListModel> members, List<GroupMediaModel> mediaList, ) {
    switch (index) {
      case 0:
        return GroupMembersList(conversationId: widget.conversationId,members: members,);
      case 1: // Gallery — one-row preview + "View all"
        return _galleryPreview(groupName, mediaList);
      default:
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: CustomText(AppStrings.noRecordFoundUpdate.tr),
          ),
        );
    }
  }

  void showEditGroupDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: EditGroupDetailsDialog(conversationId: widget.conversationId,),
        );
      },
    );
  }

  String formatDate(DateTime? date) {
    if (date == null) return '';
    return DateFormat('dd/MM/yyyy').format(date.toLocal());
  }
  // ── Header ────────────────────────────────────────────────────────────────

  /// Hero card: cover + overlapping avatar, group name, meta pills,
  /// description and a quick-action row.
  Widget _headerCard({
    required GroupDetailsModel details,
    required String groupName,
    required String groupProfileImage,
    required String groupCoverImage,
    required List<GroupMembersListModel> members,
    required String adminName,
  }) {
    final bool isPublic = details.publicGroup == true;
    return _sectionCard(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover + avatar zone
            Stack(
              clipBehavior: Clip.none,
              children: [
                _coverImage(groupCoverImage),
                Positioned(
                  top: 10,
                  right: 10,
                  child: _circleEditButton(onTap: _pickCover),
                ),
                Positioned(
                  left: 16,
                  bottom: -34,
                  child: _avatar(groupProfileImage, groupName),
                ),
              ],
            ),
            const SizedBox(height: 42),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name + edit
                  Row(
                    children: [
                      Expanded(
                        child: CustomText(
                          groupName.isEmpty ? AppStrings.groupInfo.tr : groupName,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: () {
                          chatViewController.editedGroupFile = null;
                          chatViewController.isPublicGroup.value =
                              details.publicGroup ?? false;
                          chatViewController.groupNameController.text =
                              details.groupName ?? '';
                          chatViewController.groupDescriptionController.text =
                              details.description ?? '';
                          showEditGroupDialog(context);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: AppColors.primaryColor.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: LocalAssets(
                            imagePath: AppIconAssets.pencilEditIcon,
                            imgColor: AppColors.primaryColor,
                            height: 15,
                            width: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Meta pills
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _metaPill(
                        icon: Icons.group_outlined,
                        text: "${members.length} ${AppStrings.members.tr}",
                        highlighted: true,
                      ),
                      _metaPill(
                        icon: isPublic ? Icons.public : Icons.lock_outline,
                        text: isPublic
                            ? AppStrings.publicGroupLabel.tr
                            : AppStrings.privateGroupLabel.tr,
                      ),
                      _metaPill(
                        icon: Icons.calendar_today_outlined,
                        text: formatDate(details.createdAt),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.shield_outlined,
                          size: 14, color: AppColors.grayText),
                      const SizedBox(width: 4),
                      CustomText(
                        "Admin: ",
                        fontSize: 12,
                        color: AppColors.grayText,
                      ),
                      Flexible(
                        child: CustomText(
                          adminName,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ExpandableText(
                    text: (details.description != null &&
                            details.description != '')
                        ? details.description!
                        : AppStrings.noGroupDescriptionAdded.tr,
                    trimLines: 4,
                    style: TextStyle(
                      fontSize: SizeConfig.small,
                      fontWeight: FontWeight.w400,
                      color: AppColors.secondaryTextColor,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _quickActionsRow(members),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _coverImage(String groupCoverImage) {
    return Stack(
      children: [
        SizedBox(
          height: 140,
          width: double.infinity,
          child: (groupCoverImage.trim().isNotEmpty)
              ? Image.network(
                  groupCoverImage,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      _coverFallback(),
                )
              : _coverFallback(),
        ),
        // Bottom scrim so the overlapping avatar stays readable.
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.28),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _coverFallback() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryColor,
            AppColors.primaryColor.withValues(alpha: 0.65),
          ],
        ),
      ),
      child: const Center(
        child: Icon(Icons.groups_2_outlined, size: 46, color: Colors.white70),
      ),
    );
  }

  Widget _circleEditButton({required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.45),
          shape: BoxShape.circle,
        ),
        child: LocalAssets(
          imagePath: AppIconAssets.pencilEditIcon,
          imgColor: AppColors.white,
          height: 15,
          width: 15,
        ),
      ),
    );
  }

  Widget _avatar(String groupProfileImage, String groupName) {
    final bool hasNetwork =
        groupProfileImage.trim().isNotEmpty && groupProfileImage.startsWith('http');
    final bool hasLocal = groupProfileImage.trim().isNotEmpty &&
        !groupProfileImage.startsWith('http') &&
        File(groupProfileImage).existsSync();

    ImageProvider? provider;
    if (chatViewController.editedGroupFile != null) {
      provider = FileImage(chatViewController.editedGroupFile!);
    } else if (hasNetwork) {
      provider = NetworkImage(groupProfileImage);
    } else if (hasLocal) {
      provider = FileImage(File(groupProfileImage));
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.white, width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 8,
              ),
            ],
          ),
          child: CircleAvatar(
            radius: 38,
            backgroundColor: AppColors.primaryColor,
            backgroundImage: provider,
            child: provider != null
                ? null
                : (groupName.isNotEmpty)
                    ? CustomText(
                        groupName[0].toUpperCase(),
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 32,
                      )
                    : const Icon(Icons.person, color: Colors.white, size: 28),
          ),
        ),
        Positioned(
          bottom: -2,
          right: -2,
          child: InkWell(
            onTap: _pickProfile,
            child: Container(
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryColor,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: const Icon(Icons.edit, size: 13, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Widget _metaPill(
      {required IconData icon, required String text, bool highlighted = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: highlighted
            ? AppColors.primaryColor.withValues(alpha: 0.08)
            : AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: highlighted ? AppColors.primaryColor : AppColors.whiteE5,
          width: highlighted ? 1 : 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon,
              size: 13,
              color: highlighted ? AppColors.primaryColor : AppColors.grayText),
          const SizedBox(width: 5),
          CustomText(
            text,
            fontSize: 12,
            fontWeight: highlighted ? FontWeight.w600 : FontWeight.w400,
            color: highlighted ? AppColors.primaryColor : AppColors.black,
          ),
        ],
      ),
    );
  }

  Widget _quickActionsRow(List<GroupMembersListModel> members) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _quickAction(
          icon: Icons.person_add_alt_1_outlined,
          label: AppStrings.addTab.tr,
          onTap: () => Get.to(() => BeAvailableContactsList(
                isFromAddMember: true,
                members: members,
                conversationId: widget.conversationId,
              )),
        ),
        _quickAction(
          icon: Icons.perm_media_outlined,
          label: AppStrings.galleryTab.tr,
          onTap: () {
            setState(() => selectedIndex = 1);
            chatViewController.getPinMessageListDataApi({
              ApiKeys.conversation_id: widget.conversationId,
            });
          },
        ),
        _quickAction(
          icon: muteNotifications
              ? Icons.notifications_off_outlined
              : Icons.notifications_active_outlined,
          label: muteNotifications ? "Unmute" : "Mute",
          active: muteNotifications,
          onTap: () {
            setState(() => muteNotifications = !muteNotifications);
            commonSnackBar(
                message: muteNotifications
                    ? "Group notifications muted"
                    : "Group notifications unmuted");
          },
        ),
        _quickAction(
          icon: Icons.share_outlined,
          label: "Share",
          onTap: () => commonSnackBar(message: "Coming soon..."),
        ),
      ],
    );
  }

  Widget _quickAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool active = false,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 46,
            width: 46,
            decoration: BoxDecoration(
              color: active
                  ? AppColors.primaryColor
                  : AppColors.primaryColor.withValues(alpha: 0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(icon,
                size: 22,
                color: active ? AppColors.white : AppColors.primaryColor),
          ),
          const SizedBox(height: 6),
          CustomText(
            label,
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppColors.secondaryTextColor,
          ),
        ],
      ),
    );
  }

  // ── Image pickers (cover / profile) ─────────────────────────────────────────

  Future<void> _pickCover() async {
    final newPath = await PhotoPickerService.pickSinglePhoto(
      cropAspectRatio: CropAspectRatio(width: 300, height: 150),
      context,
      "Change Group Cover Image",
    );
    if (newPath == null || newPath.isEmpty) return;

    chatViewController.editedGroupCoverFile = File(newPath);
    final selectedFiles = File(chatViewController.editedGroupCoverFile!.path);
    final info = cmd.getFileInfo(selectedFiles);

    await chatViewController.updateGroupInfo(
      {ApiKeys.conversation_id: widget.conversationId},
      isFromCoverImage: true,
      fileParams: {
        ApiKeys.fileName: [info['fileName']],
        ApiKeys.fileType: [info['mimeType']],
      },
      fileSended: selectedFiles,
    );
    if (mounted) setState(() {});
  }

  Future<void> _pickProfile() async {
    final newPath = await PhotoPickerService.pickSinglePhoto(
      context,
      "Change Group Profile",
    );
    if (newPath == null || newPath.isEmpty) return;

    chatViewController.editedGroupFile = File(newPath);
    final selectedFiles = File(chatViewController.editedGroupFile!.path);
    final info = cmd.getFileInfo(selectedFiles);

    await chatViewController.updateGroupInfo(
      {ApiKeys.conversation_id: widget.conversationId},
      isFromFile: true,
      fileParams: {
        ApiKeys.fileName: [info['fileName']],
        ApiKeys.fileType: [info['mimeType']],
      },
      fileSended: selectedFiles,
    );
    if (mounted) setState(() {});
  }

}
