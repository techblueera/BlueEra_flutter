import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/app_strings.dart';
import '../../../../../core/constants/shared_preference_utils.dart';
import '../../../../../widgets/custom_text_cm.dart';
import '../../../auth/controller/chat_view_controller.dart';
import '../../../auth/model/group_details_model.dart';
import '../../contacts/view/be_available_contacts_list.dart';

class GroupMembersList extends StatefulWidget {
  GroupMembersList({super.key, required this.members, required this.conversationId});
  final List<GroupMembersListModel> members;
  final String? conversationId;
  @override
  State<GroupMembersList> createState() => _GroupMembersListState();
}

class _GroupMembersListState extends State<GroupMembersList> {
  final chatViewController = Get.find<ChatViewController>();

  void _showMemberBottomSheet(BuildContext context, GroupMembersListModel member) {
    final amIAdmin = widget.members.firstWhere((m) => m.id == userId, orElse: () => GroupMembersListModel()).isAdmin ?? false;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Container(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                CircleAvatar(
                  radius: 40,
                  backgroundColor: AppColors.primaryColor,
                  backgroundImage: (member.profileImage != null && member.profileImage!.isNotEmpty)
                      ? CachedNetworkImageProvider(member.profileImage!)
                      : null,
                  child: (member.profileImage == null || member.profileImage!.isEmpty)
                      ? CustomText(
                          member.name?.isNotEmpty == true ? member.name![0].toUpperCase() : '?',
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        )
                      : null,
                ),
                const SizedBox(height: 16),
                CustomText(
                  member.name ?? 'Unknown Member',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
                if (member.contact != null && member.contact!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: CustomText(
                      member.contact!,
                      color: Colors.grey.shade600,
                      fontSize: 16,
                    ),
                  ),
                const SizedBox(height: 18),
                // const Divider(color: AppColors.primaryColor, thickness: 1),
                // const SizedBox(height: 12),
                _buildBottomSheetButton(
                  icon: Icons.message_outlined,
                  text: 'Message',
                  onTap: () {
                    Navigator.pop(context);
                    // TODO: Implement message action
                    print('Messaging ${member.name}');
                  },
                ),
                if (amIAdmin && member.id != userId) ...[
                  const SizedBox(height: 12),
                  _buildBottomSheetButton(
                    icon: member.isAdmin == true ? Icons.security_outlined : Icons.admin_panel_settings_outlined,
                    text: member.isAdmin == true ? 'Remove as Admin' : 'Make Admin',
                    onTap: () {
                      Navigator.pop(context);
                      print('Toggling admin status for ${member.name}');
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildBottomSheetButton(
                    icon: Icons.remove_circle_outline,
                    text: 'Remove from group',
                    iconColor: Colors.red.shade700,
                    textColor: Colors.red.shade700,
                    onTap: () {
                      Navigator.pop(context);
                      print('Removing ${member.name} from group');
                    },
                  ),
                ],
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomSheetButton({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
    Color? iconColor,
    Color? textColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: (iconColor ?? AppColors.primaryColor).withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: (iconColor ?? AppColors.primaryColor).withOpacity(0.1)),
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor ?? AppColors.primaryColor),
            const SizedBox(width: 16),
            CustomText(
              text,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: textColor ?? Colors.black87,
            ),
            const Spacer(),
            Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: CustomText(
            "${widget.members.length} ${AppStrings.members.tr}",
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
        ListView.builder(
          padding: const EdgeInsets.only(bottom: 10),
          itemCount: chatViewController.viewAllMembers.value ? widget.members.length + 1 : (widget.members.length > 6 ? 8 : widget.members.length + 1),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            if (index == 0) {
              return InkWell(
                onTap: () {
                  Get.to(() => BeAvailableContactsList(
                        isFromAddMember: true,
                        members: widget.members,
                        conversationId: widget.conversationId,
                      ));
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: AppColors.primaryColor,
                        radius: 22,
                        child: const Icon(Icons.person_add, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      const CustomText(
                        AppStrings.addedMembers,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ],
                  ),
                ),
              );
            }

            if (index == 1) {
              GroupMembersListModel? me = widget.members.firstWhere(
                (m) => m.id == userId,
              );

              final String displayName = (me.name?.trim().isNotEmpty == true) ? me.name!.trim() : "-";
              final String initial = displayName.isNotEmpty ? displayName[0] : '?';
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: CircleAvatar(
                  backgroundColor: AppColors.primaryColor,
                  radius: 22,
                  child: (me.profileImage != null)
                      ? ClipOval(
                          child: CachedNetworkImage(
                            imageUrl: me.profileImage!,
                            fit: BoxFit.cover,
                            width: 44,
                            height: 44,
                            placeholder: (context, url) => Container(
                              color: Colors.grey.shade300,
                              child: const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => Center(
                              child: CustomText(
                                initial,
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        )
                      : Center(
                          child: CustomText(
                            initial,
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                ),
                title: const CustomText(AppStrings.you, fontSize: 16, fontWeight: FontWeight.bold),
                trailing: (me.isAdmin ?? false)
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade400),
                        ),
                        child: const CustomText(AppStrings.admin, fontSize: 14),
                      )
                    : null,
              );
            }

            if (!chatViewController.viewAllMembers.value && widget.members.length > 6 && index == 7) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Center(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      setState(() {
                        chatViewController.viewAllMembers.value = true;
                      });
                    },
                    icon: const Icon(Icons.expand_more, size: 18),
                    label: const CustomText(
                      AppStrings.viewAll,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryColor,
                    ),
                  ),
                ),
              );
            }

            final nonMeMembers = widget.members.where((m) => m.id != userId).toList();
            final member = nonMeMembers[index - 2];

            final String displayName = (member.name?.trim().isNotEmpty == true) ? member.name!.trim() : "-";
            final String initial = displayName.isNotEmpty ? displayName[0] : '?';

            return GestureDetector(
              onLongPress: () => _showMemberBottomSheet(context, member),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: CircleAvatar(
                  backgroundColor: AppColors.primaryColor,
                  radius: 22,
                  child: (member.profileImage != null)
                      ? ClipOval(
                          child: CachedNetworkImage(
                            imageUrl: member.profileImage!,
                            fit: BoxFit.cover,
                            width: 44,
                            height: 44,
                            placeholder: (context, url) => Container(
                              color: Colors.grey.shade300,
                              child: const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => Center(
                              child: CustomText(
                                initial,
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        )
                      : Center(
                          child: CustomText(
                            initial,
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                ),
                title: CustomText(
                  displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                trailing: (member.isAdmin ?? false)
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade400),
                        ),
                        child: const CustomText(AppStrings.admin, fontSize: 14),
                      )
                    : null,
              ),
            );
          },
        )
      ],
    );
  }
}
