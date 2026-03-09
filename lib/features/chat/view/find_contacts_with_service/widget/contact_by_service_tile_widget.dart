import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
import '../../../../../core/api/apiService/api_response.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/constants/shared_preference_utils.dart';
import '../../../../../widgets/custom_text_cm.dart';
import '../../../auth/controller/chat_view_controller.dart';
import '../../../auth/model/find_service_by_contact_model.dart';

class FindContactByServiceListWidget extends StatelessWidget {
  final ChatViewController chatViewController;
  final ThemeData theme;

  const FindContactByServiceListWidget({
    super.key,
    required this.chatViewController,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final status =
          chatViewController.getServiceByContactResponse.value.status;

      return Expanded(
        child: Container(
          decoration: const BoxDecoration(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
            color: AppColors.white,
          ),
          clipBehavior: Clip.antiAlias,
          child: _buildContent(status ?? Status.LOADING),
        ),
      );
    });
  }

  Widget _buildContent(Status status) {
    if (status == Status.COMPLETE) {
      final List<ProfessionalContact> professionals =
          chatViewController.findProfessionalContactList
              .where((c) => c.id != userId)
              .toList();

      if (professionals.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.person_search_rounded,
                  size: 56, color: Colors.grey.shade300),
              const SizedBox(height: 12),
              CustomText(
                'No services found',
                fontSize: 15,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w500,
              ),
              const SizedBox(height: 4),
              CustomText(
                'Try a different category',
                fontSize: 12,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        );
      }

      return ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: professionals.length,
        separatorBuilder: (_, __) => Divider(
          height: 1,
          indent: 72,
          endIndent: 16,
          color: Colors.grey.shade100,
        ),
        itemBuilder: (context, index) {
          final contact = professionals[index];
          final name = contact.name ?? "";
          final phone = contact.contactNo ?? "No number";
          final profileImage = contact.profileImage ?? "";
          final designation = contact.designation ?? "";

          return InkWell(
            onTap: () {
              if (contact.id != null) {
                chatViewController.checkChatConnectionAndOpenChat(
                  userId: contact.id!,
                );
              }
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  _buildAvatar(name, profileImage),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomText(
                          name.isNotEmpty ? name : phone,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        if (designation.isNotEmpty)
                          CustomText(
                            designation,
                            fontSize: 12,
                            color: AppColors.primaryColor,
                            fontWeight: FontWeight.w500,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          )
                        else if (name.isNotEmpty)
                          CustomText(
                            phone,
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 18,
                      color: AppColors.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    }

    if (status == Status.ERROR) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: CustomText(
                chatViewController.getServiceByContactResponse.value.message ?? '',
                textAlign: TextAlign.center,
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      );
    }

    // LOADING
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 36,
            height: 36,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: AppColors.primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          CustomText(
            'Finding contacts...',
            fontSize: 13,
            color: Colors.grey.shade400,
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(String name, String profileImage) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : "?";
    final colors = [
      AppColors.primaryColor,
      Colors.teal,
      Colors.orange,
      Colors.purple,
      Colors.indigo,
    ];
    final colorIndex = name.isNotEmpty ? name.codeUnitAt(0) % colors.length : 0;

    return CircleAvatar(
      radius: 22,
      backgroundColor: profileImage.isNotEmpty
          ? Colors.grey.shade200
          : colors[colorIndex].withValues(alpha: 0.15),
      backgroundImage: profileImage.isNotEmpty
          ? CachedNetworkImageProvider(profileImage)
          : null,
      child: profileImage.isEmpty
          ? CustomText(
              initial,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: colors[colorIndex],
            )
          : null,
    );
  }
}
