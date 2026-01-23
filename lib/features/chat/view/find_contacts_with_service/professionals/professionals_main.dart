import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../auth/controller/chat_view_controller.dart';
import '../../../auth/model/find_service_by_contact_model.dart';
import '../widget/common_subtab_widget.dart';

class ProfessionalsMain extends StatefulWidget {
  const ProfessionalsMain({super.key, required this.details});

  final ProfessionalContactsResponse details;

  @override
  State<ProfessionalsMain> createState() => _ProfessionalsMainState();
}

class _ProfessionalsMainState extends State<ProfessionalsMain> {
  final chatViewController = Get.find<ChatViewController>();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Obx(() {
      if(chatViewController.onFindContactLoading.value==false){
        return Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: SizeConfig.size10,),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Row(
                children: [
                  ...(widget.details.data?.entries.map((entry) {
                    final key = entry.key; // ARTIST, SELF_EMPLOYED
                    final value = entry.value; // List<ProfessionalContact>
                    if (chatViewController.selectedSubServiceToFind.value
                        .isEmpty) {
                      chatViewController.selectedSubServiceToFind.value = widget
                          .details.data?.keys.first.toString() ?? '';
                    }
                    return CommonSubTabWidget(
                      selectedKey: chatViewController.selectedSubServiceToFind
                          .value,
                      title: key.toString(),
                      onTap: () {
                        chatViewController.selectedSubServiceToFind.value =
                            key.toString();
                      },
                    );
                  }).toList() ?? []),

                ],
              ),
            ),
            SizedBox(height: SizeConfig.size10,),
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  color: AppColors.white,
                ),
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Builder(
                  builder: (_) {
                    final selectedKey =
                        chatViewController.selectedSubServiceToFind.value;

                    final List<ProfessionalContact> professionals =
                        widget.details.data?[selectedKey] ?? [];

                    if (professionals.isEmpty) {
                      return const Center(
                        child: Text('No Services found'),
                      );
                    }

                    return ListView.builder(
                      itemCount: professionals.length,
                      itemBuilder: (context, index) {
                        final item = professionals[index];
                        final contact = item.user;
                        final name = contact?.name ?? "";
                        final phone = contact?.contactNo ?? "No number";
                        final profileImage = contact?.profileImage ?? "";

                        return  ListTile(
                          onTap: () {
                            if (contact?.id != null) {
                              chatViewController.openAnyOneChatFunction(
                                type: contact?.accountType,
                                isInitialMessage: true,
                                userId: contact?.id,
                                conversationId: '',
                                // conversationId: contact?.conversationId ?? '',
                                profileImage: contact?.profileImage,
                                contactName: contact?.name,
                                contactNo: contact?.contactNo,
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
                          title: Text(
                            name.isNotEmpty ? name : phone,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: name.isNotEmpty
                              ? CustomText(
                            (contact?.accountType == "INDIVIDUAL")
                                ? (contact?.designation?.isNotEmpty ?? false)
                                ? contact!.designation!
                                : phone
                                : "",
                          )
                              : null,

                        );
                      },
                    );
                  },
                ),
              ),
            ),

          ],
        );
      }else{
        return Center(
          child: CircularProgressIndicator(),
        );
      }

    });
  }
}
