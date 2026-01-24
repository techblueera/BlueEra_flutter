import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../../core/api/apiService/api_response.dart';
import '../../../auth/controller/chat_view_controller.dart';
import '../../../auth/model/find_service_by_contact_model.dart';
import '../widget/common_subtab_widget.dart';

class ProfessionalsMain extends StatefulWidget {
  const ProfessionalsMain({super.key,});



  @override
  State<ProfessionalsMain> createState() => _ProfessionalsMainState();
}

class _ProfessionalsMainState extends State<ProfessionalsMain> {
  final chatViewController = Get.find<ChatViewController>();

  @override
  void initState() {
    // TODO: implement initState
    WidgetsBinding.instance.addPostFrameCallback((val){
      chatViewController.selectedIndex.value=0;
    });
    super.initState();
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Obx(() {
        return Column(crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: SizeConfig.size10,),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for(int i=0;i<professionalContactCategories.length;i++ )
                    CommonSubTabWidget(
                      selectedIndex: chatViewController.selectedIndex
                          .value,
                      index: i,
                      title: professionalContactCategories[i].name,
                      icon:professionalContactCategories[i].icon,
                      onTap: () async{
                        chatViewController.selectedIndex.value = i;
                        await chatViewController.findServiceByContacts(
                            professionalContactCategories[i].slugId, null);
                      },
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: SizeConfig.size10,),
            if(chatViewController.getServiceByContactResponse.value.status==Status.COMPLETE)
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

                        return  ListTile(
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
                                : phone
                               ,
                            fontSize: 12,
                            color: AppColors.grayText,
                          )
                              : null,

                        );
                      },
                    );
                  },
                ),
              ),
            )
            else if(chatViewController.getServiceByContactResponse.value.status==Status.ERROR)
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                    color: AppColors.white,
                  ),
                  child: Center(
                  child: CustomText(
                      textAlign: TextAlign.center,
                      "${chatViewController.getServiceByContactResponse.value.message}"),
                ),)
              )
            else
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                    color: AppColors.white,
                  ),
                  child: Center(
                  child: CircularProgressIndicator(),
                ),)
              )

          ],
        );
    });
  }
}
