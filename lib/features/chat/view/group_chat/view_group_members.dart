import 'dart:io';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';

import '../../../../core/api/apiService/api_response.dart';
import '../../../../core/constants/app_colors.dart';
import '../../auth/controller/chat_view_controller.dart';
import '../../auth/model/view_group_members_model.dart';

class ViewGroupMembers extends StatefulWidget {
  const ViewGroupMembers(
      {required this.conversationId,
      this.profileImage,
      required this.type,
      this.name,
      super.key});

  final String? conversationId;
  final String? profileImage;
  final String? name;
  final String? type;

  @override
  State<ViewGroupMembers> createState() => _ViewGroupMembersState();
}

class _ViewGroupMembersState extends State<ViewGroupMembers> {
  final chatViewController = Get.find<ChatViewController>();
  @override
  void initState() {
    // TODO: implement initState
    Map<String, dynamic> data = {
      ApiKeys.conversation_id: widget.conversationId
    };
    chatViewController.getGroupMembersApi(data);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: CommonBackAppBar(
        title: "Group Members",
      ),
      body: Obx(() {
        if (chatViewController.getGroupMembersResponse.value.status ==
            Status.COMPLETE) {
          List<GroupMembersListModel> members =
              chatViewController.getGroupMembersResponse.value.data;
            
          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              
                Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              spreadRadius: 0.5,
                              blurRadius: 2,
                              offset: Offset(0, 1),
                            ),
                          ]),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Center(
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                  vertical: SizeConfig.size13),
                              child: CircleAvatar(
                                backgroundColor: theme.colorScheme.primary,
                                radius: 60,
                                backgroundImage: (widget.profileImage != null &&
                                        widget.profileImage!.trim().isNotEmpty)
                                    ? (widget.profileImage!.startsWith('http')
                                        ? NetworkImage(widget.profileImage!)
                                        : (File(widget.profileImage!).existsSync()
                                            ? FileImage(File(widget.profileImage!))
                                                as ImageProvider
                                            : null))
                                    : null,
                                child: (widget.profileImage != null &&
                                        widget.profileImage!.trim().isNotEmpty &&
                                        (widget.profileImage!.startsWith('http') ||
                                            File(widget.profileImage!).existsSync()))
                                    ? null
                                    : (widget.name != null &&
                                            widget.name!.isNotEmpty)
                                        ? Center(
                                            child: CustomText(
                                            "${widget.name!.split('')[0]}",
                                            color: Colors.white,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 50,
                                          ))
                                        : Center(
                                            child: Icon(
                                              Icons.person,
                                              color: theme.colorScheme.surface,
                                            ),
                                          ),
                              ),
                            ),
                          ),
                          SizedBox(
                            height: SizeConfig.size15,
                          ),
                          SizedBox(
                            //width: 160,
                            child: CustomText(
                              '${widget.name?.capitalize}',
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(
                            height: SizeConfig.size5,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              CustomText(
                                'Group',
                                color: AppColors.grayText,
                              ),
                              CustomText(" • ", color: AppColors.grayText),
                              CustomText(
                                "${members.length} Members",
                                color: AppColors.grayText,
                              )
                            ],
                          ),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _groupFeature(
                                  icon: AppIconAssets.chat_call,
                                  title: 'Audio'),
                              _groupFeature(
                                  icon: AppIconAssets.chat_video_call,
                                  title: 'Video'),
                              _groupFeature(
                                  icon: AppIconAssets.add, title: 'Add'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
                ListView.builder(
  padding: EdgeInsets.symmetric(vertical: 6),
  itemCount: members.length + 1, // 👈 extra item for "Add Members"00
  shrinkWrap: true,
  physics: NeverScrollableScrollPhysics(), // optional (if inside scroll)
  itemBuilder: (context, index) {
    if (index == 0) {
    
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.grey.shade300,
              radius: 22,
              child: Icon(Icons.person_add, color: Colors.black87),
            ),
            SizedBox(width: 12),
            CustomText(
              "Add Members",
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.grayText,
            ),
          ],
        ),
      );
    }

   
    final member = members[index - 1];

    final String displayName = (member.name?.trim().isNotEmpty == true)
        ? member.name!.trim()
        : (member.username?.trim().isNotEmpty == true
            ? member.username!.trim()
            : "-");
    final String initial = displayName.isNotEmpty
        ? displayName[0]
        : '?';
   

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.primary,
        radius: 22,
        child: Center(
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
      subtitle: ((member.designation ?? '').trim().isNotEmpty)
          ? CustomText(
              (member.designation ?? '').trim(),
              fontSize: 14,
              color: AppColors.grey9A,
              overflow: TextOverflow.ellipsis,
            )
          : null,
      trailing:
      //  isAdmin
      //     ?
           Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade400),
              ),
              child: const CustomText(
                'Admin',
            
              ),
            )
        //  : null,
    );
  },
)

              ],
            ),
          );
        } else {
          return Center(
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

  Row _groupFeature({String? icon, String? title}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Container(
          padding: EdgeInsets.all(10),
          margin: EdgeInsets.all(10),
          height: SizeConfig.size80,
          width: SizeConfig.size80,
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Colors.grey.shade300,
              border: Border.all(color: Colors.grey.shade400)),
          child: Column(
            children: [
              if (icon != null && icon.isNotEmpty)
                SvgPicture.asset(
                  height: title == "Add" ? SizeConfig.size25 : null,
                  icon,
                  color: Colors.black54,
                )
              else
                Icon(
                  Icons.image_not_supported,
                  color: Colors.black54,
                ),
              SizedBox(
                height: SizeConfig.size5,
              ),
              CustomText(title ?? '')
            ],
          ),
        )
      ],
    );
  }
}
