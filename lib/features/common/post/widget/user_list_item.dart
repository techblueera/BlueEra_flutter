import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/reel/models/get_all_users.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class UserListItem extends StatelessWidget {
  final UsersData user;
  final VoidCallback onTap;

  const UserListItem({
    Key? key,
    required this.user,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.grey.shade200),
          ),
        ),
        child: Row(
          children: [
            // User avatar
            // Empty counts as absent: an API answering "" for a missing image
            // used to reach NetworkImage(""), which fails the load and leaves
            // an empty grey circle with no placeholder glyph.
            Builder(builder: (_) {
              final avatar = (user.profileImage ?? '').trim();
              return CircleAvatar(
                radius: 20,
                backgroundColor: Colors.grey.shade200,
                backgroundImage:
                    avatar.isNotEmpty ? NetworkImage(avatar) : null,
                child: avatar.isEmpty
                    ? Icon(Icons.person, color: Colors.grey.shade400)
                    : null,
              );
            }),
            const SizedBox(width: 12),
            // User name and details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    user.name??"N/A",
                    fontSize: SizeConfig.size16,
                    fontWeight: FontWeight.w500,
                  ),
                  if (user.username != null)
                    CustomText(
                      user.username??"N/A",
                      fontSize: SizeConfig.size14,
                      color: Colors.grey.shade600,
                    ),
                ],
              ),
            ),
            // Selection indicator
            Obx(() => user.isSelected.value
                ? const Icon(Icons.check_circle, color: Colors.blue)
                : const SizedBox.shrink()),
          ],
        ),
      ),
    );
  }
}