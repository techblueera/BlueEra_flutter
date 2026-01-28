import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
import '../../../../../core/api/apiService/api_response.dart';
import '../../../../../core/constants/app_colors.dart';
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
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: _buildContent(status ?? Status.LOADING),
        ),
      );
    });
  }

  Widget _buildContent(Status status) {
    if (status == Status.COMPLETE) {
      final List<ProfessionalContact> professionals =
          chatViewController.findProfessionalContactList;

      if (professionals.isEmpty) {
        return const Center(
          child: CustomText('No Services found'),
        );
      }

      return ListView.builder(
        itemCount: professionals.length,
        itemBuilder: (context, index) {
          final contact = professionals[index];
          final name = contact.name ?? "";
          final phone = contact.contactNo ?? "No number";
          final profileImage = contact.profileImage ?? "";

          return ListTile(
            onTap: () {
              if (contact.id != null) {
                chatViewController.openAnyOneChatFunction(
                  type: contact.accountType,
                  isInitialMessage: true,
                  userId: contact.id,
                  conversationId: contact.conversationId ?? '',
                  profileImage: contact.profileImage,
                  contactName: contact.name,
                  contactNo: contact.contactNo,
                  isFromContactList: true,
                );
              }
            },
            leading: CircleAvatar(
              radius: 20,
              backgroundImage: profileImage.isNotEmpty
                  ? CachedNetworkImageProvider(profileImage)
                  : null,
              child: profileImage.isEmpty
                  ? CustomText(
                name.isNotEmpty ? name[0].toUpperCase() : "?",
                fontSize: 20,
                color: theme.colorScheme.surface,
              )
                  : null,
            ),
            title: CustomText(
              name.isNotEmpty ? name : phone,
              fontWeight: FontWeight.w600,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: name.isNotEmpty
                ? CustomText(
              (contact.designation?.isNotEmpty ?? false)
                  ? contact.designation
                  : phone,
              fontSize: 12,
              color: AppColors.grayText,
            )
                : null,
          );
        },
      );
    }

    if (status == Status.ERROR) {
      return Center(
        child: CustomText(
          textAlign: TextAlign.center,
          chatViewController.getServiceByContactResponse.value.message ?? '',
        ),
      );
    }

    // LOADING
    return const Center(
      child: CircularProgressIndicator(),
    );
  }
}
