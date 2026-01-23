import 'dart:io';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import '../../../../core/constants/common_methods.dart' as cmd;

import '../../../../core/api/apiService/api_response.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_icon_assets.dart';
import '../../../../widgets/local_assets.dart';
import '../../../common/auth/views/dialogs/select_profile_picture_dialog.dart';
import '../../auth/controller/chat_view_controller.dart';
import '../../auth/model/view_group_members_model.dart';
import '../contacts/be_available_contacts_list.dart';

class ViewGroupMembers extends StatefulWidget {
  const ViewGroupMembers(
      {required this.conversationId,
      this.profileImage,
      required this.type,
      required this.publicGroup,
      this.name,
      super.key});

  final String? conversationId;
  final String? profileImage;
  final String? name;
  final String? type;
  final bool publicGroup;

  @override
  State<ViewGroupMembers> createState() => _ViewGroupMembersState();
}

class _ViewGroupMembersState extends State<ViewGroupMembers> {
  final chatViewController = Get.find<ChatViewController>();
  bool publicGroup = false;

  @override
  void initState() {
    Map<String, dynamic> data = {
      ApiKeys.conversation_id: widget.conversationId
    };
    publicGroup=widget.publicGroup;
    chatViewController.groupNameController.text=widget.name??"";
    chatViewController.getGroupMembersApi(data);
    super.initState();
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
          child: StatefulBuilder(
            builder: (context, setState) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [


                      Stack(
                        alignment: Alignment.center,
                        children: [
                          CircleAvatar(
                            radius: 45,
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            backgroundImage:
                            (chatViewController.editedGroupFile!=null)?
                            FileImage(chatViewController.editedGroupFile!) as ImageProvider:(widget.profileImage != null &&
                                widget.profileImage!.trim().isNotEmpty)
                                ? (widget.profileImage!.startsWith('http')
                                ? NetworkImage(widget.profileImage!)
                                : (File(widget.profileImage!).existsSync()
                                ? FileImage(File(widget.profileImage!)) as ImageProvider
                                : null))
                                : null,
                            child: (chatViewController.editedGroupFile == null &&
                                (widget.profileImage == null ||
                                    widget.profileImage!.isEmpty))
                                ? Text(
                              widget.name != null && widget.name!.isNotEmpty
                                  ? widget.name![0].toUpperCase()
                                  : '',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                                : null,
                          ),

                          /// ✏️ EDIT ICON
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: InkWell(
                              onTap: () async {
                                final newPath =
                                await SelectProfilePictureDialog.showLogoDialog(
                                    context, "Change Group Profile");

                                if (newPath != null && newPath.isNotEmpty) {
                                  chatViewController.editedGroupFile =
                                      File(newPath);
                                  setState(() {});
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppColors.primaryColor,
                                  border:
                                  Border.all(color: Colors.white, width: 2),
                                ),
                                child: Icon(
                                  Icons.edit,
                                  size: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),
                      // Divider(color: AppColors.grey9B),

                      ListTile(contentPadding: EdgeInsets.symmetric(horizontal: 6),
                        leading: Icon(
                          (!publicGroup) ? Icons.lock_outline : Icons.lock_open,
                          color: AppColors.black,
                          size: 22,
                        ),
                        title: CustomText(
                          (!publicGroup) ? "Private group" : "Public group",
                          color: AppColors.black,
                          fontSize: 16,
                        ),
                        trailing: CustomText(
                          (!publicGroup) ? "On" : "Off",
                          color: AppColors.black,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        onTap: () {
                          setState(() {
                            publicGroup = !publicGroup;
                          });
                        },
                      ),
                      const SizedBox(height: 12),

                      /// 🔹 GROUP NAME FIELD
                      CommonTextField(
                        title: "Group Name",
                        textEditController:chatViewController.groupNameController,
                        // controller: chatViewController.groupNameController,
                        hintText: "Group Name",
                      ),

                      const SizedBox(height: 12),

                      /// 🔹 GROUP DESCRIPTION FIELD
                      CommonTextField(
                        title: "Group Description",
                        textEditController:chatViewController.groupDescriptionController,
                        // controller: chatViewController.groupDescriptionController,
                        hintText: "Enter Group Description",
                        // maxLines: 3,
                      ),
                      const SizedBox(height: 20),
                      /// 🔹 SUBMIT BUTTON
                      SizedBox(
                        width: double.infinity,
                        child: CustomBtn(
                          isValidate: true,
                            onTap: ()async{
                              Map<String, dynamic> data = {};

                              if (chatViewController.editedGroupFile != null) {
                                String path = chatViewController.editedGroupFile!.path;
                                File selectedFiles = File(path);

                                List<String?> fileNames = [];
                                List<String?> fileTypes = [];

                                Map<String, String?> info = cmd.getFileInfo(selectedFiles);
                                fileNames.add(info['fileName']);
                                fileTypes.add(info['mimeType']);

                                Map<String, dynamic> uploadParams = {
                                  ApiKeys.fileName: fileNames,
                                  ApiKeys.fileType: fileTypes,
                                };

                                data = {
                                  ApiKeys.group_name: chatViewController.groupNameController.text,
                                  ApiKeys.description:chatViewController.groupDescriptionController.text,
                                  ApiKeys.public_group:true,
                                  ApiKeys.conversation_id:widget.conversationId,
                                };

                                bool value = await chatViewController.updateGroupInfo(
                                  data,
                                  isFromFile: true,
                                  fileParams: uploadParams,
                                  fileSended: selectedFiles,
                                );

                                if (value == true) {
                                  Navigator.pop(context);
                                  Navigator.pop(context);
                                  Navigator.pop(context);
                                }
                              }else{
                                 data={
                                  ApiKeys.group_name:chatViewController.groupNameController.text,
                                  ApiKeys.description:chatViewController.groupDescriptionController.text,
                                  ApiKeys.public_group:true,
                                  ApiKeys.conversation_id:widget.conversationId,
                                };
                                 bool value = await chatViewController.updateGroupInfo(data);
                                 if (value == true) {
                                   Navigator.pop(context);
                                   Navigator.pop(context);
                                   Navigator.pop(context);
                                 }
                              }

                        }, title: "Edit"),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(

      body: Obx(() {
        if (chatViewController.getGroupMembersResponse.value.status ==
            Status.COMPLETE) {
          List<GroupMembersListModel> members =
              chatViewController.getGroupMembersResponse.value.data;
            
          return SafeArea(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Container(
                        margin: EdgeInsets.only(bottom: 10,left: 10,right: 10),
                        decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                spreadRadius: 0.5,
                                blurRadius: 2,
                                offset: Offset(0, 1),
                              ),
                            ]),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(
                              height: 18,
                            ),
                            InkWell(
                              onTap: (){
                                Navigator.pop(context);
                              },
                              child: Padding(
                                padding: const EdgeInsets.only(right: 10.0),
                                child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        const SizedBox(width: 20,),
                                        Icon(Icons.arrow_back_ios,size: 22,),
                                        const SizedBox(width: 2,),
                                        CustomText(AppStrings.groupInfo,
                                          fontSize: SizeConfig.extraLarge-2,
                                        fontWeight: FontWeight.bold,
                                        )
                                      ],
                                    ),
                                    InkWell(
                                      onTap: (){
                                        chatViewController.editedGroupFile=null;
                                        showEditGroupDialog(context);
                                      },
                                      child: Container(
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(6),
                                          color: AppColors.primaryColor
                                        ),
                                        padding: EdgeInsets.symmetric(horizontal: 8,vertical: 4),
                                        child: Row(
                                          children: [
                                            LocalAssets(
                                              imagePath: AppIconAssets.editIcon,
                                              height: SizeConfig.size14,
                                              width: SizeConfig.size14,
                                              imgColor: Colors.white,
                                            ),
                                            SizedBox(width: 6,),
                                            CustomText("Edit",color: AppColors.white,),
                                          ],
                                        ),
                                      ),
                                    )
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(
                              height: 24,
                            ),
                            Center(
                              child: TweenAnimationBuilder<double>(
                                tween: Tween(begin: 30, end: 60), // radius from 30 → 60
                                duration: const Duration(milliseconds: 500),
                                curve: Curves.easeOutBack,
                                builder: (context, radius, child) {
                                  return TweenAnimationBuilder<Offset>(
                                    tween: Tween(begin: const Offset(-1.8, -1), end: Offset.zero),
                                    duration: const Duration(milliseconds: 500),
                                    curve: Curves.easeIn,
                                    builder: (context, offset, innerChild) {
                                      return Transform.translate(
                                        offset: Offset(offset.dx * 100, offset.dy * 100),
                                        child: Stack(
                                          children: [
                                            CircleAvatar(
                                              backgroundColor: theme.colorScheme.primary,
                                              radius: radius,
                                              backgroundImage:  (chatViewController.editedGroupFile!=null)?
                                              FileImage(chatViewController.editedGroupFile!) as ImageProvider:(widget.profileImage != null &&
                                                  widget.profileImage!.trim().isNotEmpty)
                                                  ? (widget.profileImage!.startsWith('http')
                                                  ? NetworkImage(widget.profileImage!)
                                                  : (File(widget.profileImage!).existsSync()
                                                  ? FileImage(File(widget.profileImage!)) as ImageProvider
                                                  : null))
                                                  : null,
                                              child:(widget.profileImage != null &&
                                                  widget.profileImage!.trim().isNotEmpty &&
                                                  (widget.profileImage!.startsWith('http') ||
                                                      File(widget.profileImage!).existsSync()))
                                                  ? null
                                                  : (widget.name != null && widget.name!.isNotEmpty)
                                                  ? Center(
                                                child: CustomText(
                                                  "${widget.name!.split('')[0]}",
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: radius * 0.83, // scale font with avatar
                                                ),
                                              )
                                                  : Center(
                                                child: Icon(
                                                  Icons.person,
                                                  color: theme.colorScheme.surface,
                                                  size: radius, // scale icon too
                                                ),
                                              ),
                                            ),
                                            // Positioned(
                                            //   bottom: 0,
                                            //   right: 0,
                                            //   child: InkWell(
                                            //     onTap: ()async{
                                            //       var newPath= await SelectProfilePictureDialog.showLogoDialog(
                                            //       context, "Change Group Profile");
                                            //       chatViewController.editedGroupFile=File(newPath);
                                            //       setState(() {
                                            //
                                            //       });
                                            //
                                            //     },
                                            //     child: Container(
                                            //       decoration: BoxDecoration(
                                            //         shape: BoxShape.circle,
                                            //         border: Border.all(color: AppColors.white, width: 2) ,
                                            //       ),
                                            //       child: Container(
                                            //
                                            //         padding: EdgeInsets.all(8),
                                            //         decoration: BoxDecoration(
                                            //           shape: BoxShape.circle,
                                            //           color: AppColors.primaryColor,
                                            //         ),
                                            //         child: LocalAssets(
                                            //           imagePath: AppIconAssets.editIcon,
                                            //           height: SizeConfig.size14,
                                            //           width: SizeConfig.size14,
                                            //           imgColor: Colors.white,
                                            //         ),
                                            //       ),
                                            //     ),
                                            //   ),
                                            // ),
                                          ],
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                            ),

                            SizedBox(
                              height: SizeConfig.size15,
                            ),
                            SizedBox(
                              child: CustomText(
                                widget.name != null
                                    ? GetStringUtils(widget.name!).capitalize
                                    : '',
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
                                  AppStrings.group,
                                  color: AppColors.grayText,
                                ),
                                CustomText(" • ", color: AppColors.grayText),
                                CustomText(
                                  "${members.length} ${AppStrings.members.tr}",
                                  color: AppColors.grayText,
                                )
                              ],
                            ),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                // _groupFeature(
                                //     icon: AppIconAssets.chat_call,
                                //     title: 'Audio'),
                                // _groupFeature(
                                //     icon: AppIconAssets.chat_video_call,
                                //     title: 'Video'),
                              ],
                            ),
                            const SizedBox(height: 10),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          spreadRadius: 0.5,
                          blurRadius: 2,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: CustomText(
                            "${members.length} ${AppStrings.members.tr}",
                            // style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade800,
                            // ),
                          ),
                        ),
                        ListView.builder(
                          padding: const EdgeInsets.only(bottom: 10),
                          itemCount: chatViewController.viewAllMembers.value
                              ? members.length + 1   // +1 for Add Members card
                              : (members.length > 6 ? 8 : members.length + 1),
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemBuilder: (context, index) {
                            // First item — Add Members card

                            if (index == 0) {
                              return InkWell(
                                onTap: () {
                                  Get.to(()=>BeAvailableContactsList(isFromAddMember: true,members: members,conversationId: widget.conversationId,));
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
                                        // style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        // ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }

                            // Show current user ("You") right after Add Members
                            if (index == 1) {
                              GroupMembersListModel? me = members.firstWhere(
                                    (m) => m.id == userId,
                              );

                              final String displayName =
                              (me.name?.trim().isNotEmpty == true) ? me.name!.trim() : "-";
                              final String initial =
                              displayName.isNotEmpty ? displayName[0] : '?';
                              return ListTile(
                                contentPadding:
                                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                                leading: CircleAvatar(
                                  backgroundColor: theme.colorScheme.primary,
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
                                          // style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w800,
                                            fontSize: 18,
                                          // ),
                                        ),
                                      ),
                                    ),
                                  )
                                      : Center(
                                    child: CustomText(
                                      initial,
                                      // style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 18,
                                      // ),
                                    ),
                                  ),
                                ),
                                title: const CustomText(
                                    AppStrings.you,
                                  // style: TextStyle(
                                      fontSize: 16, fontWeight: FontWeight.bold
                                  // ),
                                ),
                                trailing: (me.isAdmin ?? false)
                                    ? Container(
                                  padding:
                                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.grey.shade400),
                                  ),
                                  child: const CustomText(
                                      AppStrings.admin,
                                    // style: TextStyle(
                                        fontSize: 14
                                    // ),
                                  ),
                                )
                                    : null,
                              );
                                                        }

                            // Last item — View All button if more than 6 members
                            // Last item — View All button if list is collapsed
                            if (!chatViewController.viewAllMembers.value && members.length > 6 && index == 7) {
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


                            // Normal member tile (excluding "You")
                            final nonMeMembers =
                            members.where((m) => m.id != userId).toList(); // exclude current user
                            final member = nonMeMembers[index - 2]; // shift by 2 (Add + You)

                            final String displayName =
                            (member.name?.trim().isNotEmpty == true) ? member.name!.trim() : "-";
                            final String initial = displayName.isNotEmpty ? displayName[0] : '?';

                            return ListTile(
                              contentPadding:
                              const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              leading: CircleAvatar(
                                backgroundColor: theme.colorScheme.primary,
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
                                        // style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 18,
                                        // ),
                                      ),
                                    ),
                                  ),
                                )
                                    : Center(
                                  child: CustomText(
                                    initial,
                                    // style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 18,
                                    // ),
                                  ),
                                ),
                              ),
                              title: CustomText(
                                displayName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                // style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                // ),
                              ),
                              trailing: (member.isAdmin ?? false)
                                  ? Container(
                                padding:
                                const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: Colors.grey.shade400),
                                ),
                                child: const CustomText(
                                    AppStrings.admin,
                                  // style: TextStyle(
                                      fontSize: 14
                                  // ),
                                ),
                              )
                                  : null,
                            );
                          },
                        )

                      ],
                    ),
                  ),
                  SizedBox(
                    height: SizeConfig.size12,
                  )

                ],
              ),
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
          width: SizeConfig.size80,
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Colors.grey.shade200,
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
              // SizedBox(
              //   height: SizeConfig.size5,
              // ),
              // CustomText(title ?? '')
            ],
          ),
        )
      ],
    );
  }
}
