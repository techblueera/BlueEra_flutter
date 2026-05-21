import 'dart:io';
import 'package:BlueEra/features/chat/view/group_chat/widgets/edit_group_details.dart';
import 'package:BlueEra/features/chat/view/group_chat/widgets/group_medias_list.dart';
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

          return SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: AppColors.white,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _groupBanner(groupProfileImage,groupCoverImage,groupName),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                SizedBox(
                                  height: 8,
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Row(
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(6),
                                            border: Border.all(
                                                color: AppColors.primaryColor)),
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 4),
                                        child: Center(
                                          child: CustomText(
                                            "${members.length}  ${AppStrings.members.tr}",
                                            color: AppColors.primaryColor,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 10,
                                      ),
                                      LocalAssets(
                                        imagePath: AppIconAssets.shareIcon,
                                        imgColor: AppColors.black,
                                      ),
                                      SizedBox(
                                        width: 10,
                                      ),
                                    ],
                                  ),
                                )
                              ],
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CustomText(
                                       groupName,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                      ),
                                      SizedBox(
                                        width: 8,
                                      ),
                                      InkWell(
                                          onTap: (){
                                            chatViewController.editedGroupFile=null;
                                            chatViewController.isPublicGroup.value=details.publicGroup??false;
                                            chatViewController.groupNameController.text=details.groupName??'';
                                            chatViewController.groupDescriptionController.text=details.description??'';
                                            showEditGroupDialog(context);
                                          },
                                          child: LocalAssets(imagePath: AppIconAssets.pencilEditIcon,imgColor: AppColors.black,height: 16,width: 16,))
                                    ],
                                  ),
                                  SizedBox(
                                    height: SizeConfig.size8,
                                  ),
                                  Row(
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            border: Border.all(
                                                color: AppColors.whiteE5)),
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 2),
                                        child: Center(
                                          child: CustomText(
                                            "${formatDate(details.createdAt)}",
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 6,
                                      ),
                                      Container(
                                        decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            border: Border.all(
                                                color: AppColors.whiteE5)),
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 2),
                                        child: Center(
                                          child: CustomText(
                                            "${details
                                                .members?.firstWhereOrNull(
                                                    (e)=>e.isAdmin==true)?.name}",
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        width: 6,
                                      ),
                                      Container(
                                        decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(20),
                                            border: Border.all(
                                                color: AppColors.whiteE5)),
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 2),
                                        child: Center(
                                          child: CustomText(
                                            "${details.publicGroup==true?AppStrings.publicGroupLabel.tr:AppStrings.privateGroupLabel.tr}",
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(
                                    height: SizeConfig.size10,
                                  ),
                                  ExpandableText(
                                    text: " ${(details.description!=null&&details.description!='')?
                                    details.description:AppStrings.noGroupDescriptionAdded.tr}",
                                    trimLines: 4,
                                    style: TextStyle(
                                      fontSize: SizeConfig.small,
                                      fontWeight: FontWeight.w400,
                                      color: AppColors.secondaryTextColor,
                                      height: 1.5,
                                    ),
                                  ),
                                  SizedBox(
                                    height: SizeConfig.size12,
                                  ),
                                ],
                              ),
                            )
                          ],
                        )),
                    SizedBox(
                      height: 16,
                    ),

                    HorizontalTabSelector(
                        tabs: [
                          AppStrings.membersTab.tr,
                          AppStrings.galleryTab.tr,
                          AppStrings.addTab.tr,
                          AppStrings.documentsTab.tr
                        ],
                        selectedIndex: selectedIndex,
                        onTabSelected: (index, dd) {
                          selectedIndex = index;
                          if(index==1){
                            chatViewController.getPinMessageListDataApi({
                              ApiKeys.conversation_id:widget.conversationId
                            });
                          }
                          setState(() {});
                        },
                        labelBuilder: (value) => value),
                    SizedBox(
                      height: 16,
                    ),

                    Container(
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: AppColors.white),
                      width: double.infinity,
                      child: _buildTabContent(selectedIndex,groupProfileImage,groupName, members, mediaList),
                    ),
                  ],
                ),
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

  Widget _buildTabContent(int index,String profileImage,String groupName, List<GroupMembersListModel> members, List<GroupMediaModel> mediaList, ) {
    switch (index) {
      case 0:
        return GroupMembersList(conversationId: widget.conversationId,members: members,);
      case 1: // Gallery
        return GroupMediasList(mediaList: mediaList,);
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
  Widget _groupBanner(String? groupProfileImage,String? groupCoverImage,String? groupName) {
    return Stack(
      // clipBehavior: Clip.none,
      children: [
        /// Banner Image
        Container(
         decoration:BoxDecoration(
           borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
         ),

          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(10),
            ),
            child: Image.network(
              groupCoverImage ?? '',
              height: 150,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 150,
                  width: double.infinity,
                  color: AppColors.greyLite,
                  child: const Center(
                    child: Icon(
                      Icons.image_not_supported_outlined,
                      size: 40,
                      color: Colors.grey,
                    ),
                  ),
                );
              },
            ),
          ),
        ),

        /// ✏️ BANNER EDIT ICON (Top Corner)
        Positioned(
          top: 10,
          right: 10,
          child: InkWell(
            onTap: () async{
              final newPath = await PhotoPickerService
                  .pickSinglePhoto(cropAspectRatio: CropAspectRatio(width: 300, height: 150),
                  context, "Change Group Cover Image");

              if (newPath != null && newPath.isNotEmpty) {
                chatViewController.editedGroupCoverFile = File(newPath);
                String path =
                    chatViewController.editedGroupCoverFile!.path;
                File selectedFiles = File(path);

                List<String?> fileNames = [];
                List<String?> fileTypes = [];

                Map<String, String?> info =
                cmd.getFileInfo(selectedFiles);
                fileNames.add(info['fileName']);
                fileTypes.add(info['mimeType']);

                Map<String, dynamic> uploadParams = {
                  ApiKeys.fileName: fileNames,
                  ApiKeys.fileType: fileTypes,
                };

                Map<String, dynamic> data = {
                  ApiKeys.conversation_id: widget.conversationId,
                };
                await chatViewController.updateGroupInfo(
                  data,
                  isFromCoverImage: true,
                  fileParams: uploadParams,
                  fileSended: selectedFiles,
                );
                setState(() {

                });

              }
            },
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primaryColor,
                shape: BoxShape.circle,
              ),
              child: LocalAssets(
                imagePath: AppIconAssets.pencilEditIcon,
                imgColor: AppColors.white,
                height: 16,
                width: 16,
              ),
            ),
          ),
        ),

        SizedBox(
          height: 170,
        ),
        /// Avatar
        Positioned(
          bottom: 0,
          left: 16,
          // bottom: -32,
          child: CircleAvatar(
            radius: 36,
            backgroundColor: AppColors.primaryColor,
            child: CircleAvatar(
              // backgroundColor: theme.colorScheme.primary,
              radius: 34,
              backgroundImage: (chatViewController.editedGroupFile != null)
                  ? FileImage(chatViewController.editedGroupFile!)
                      as ImageProvider
                  : (groupProfileImage != null &&
                          groupProfileImage.trim().isNotEmpty)
                      ? (groupProfileImage.startsWith('http')
                          ? NetworkImage(groupProfileImage)
                          : (File(groupProfileImage).existsSync()
                              ? FileImage(File(groupProfileImage))
                                  as ImageProvider
                              : null))
                      : null,
              child: (groupProfileImage != null &&
                      groupProfileImage.trim().isNotEmpty &&
                      (groupProfileImage.startsWith('http') ||
                          File(groupProfileImage).existsSync()))
                  ? null
                  : (groupName != null && (groupName.isNotEmpty))
                      ? Center(
                          child: CustomText(
                            "${groupName.split('')[0]}",
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 32, // scale font with avatar
                          ),
                        )
                      : Center(
                          child: Icon(
                            Icons.person,
                            color: AppColors.white,
                            size: 24, // scale icon too
                          ),
                        ),
            ),
          ),
        ),
        Positioned(
          bottom: 4,
          left: 60,
          child: InkWell(
            onTap: () async {
              final newPath = await PhotoPickerService
                  .pickSinglePhoto(
                  context, "Change Group Profile");

              if (newPath != null && newPath.isNotEmpty) {
                chatViewController.editedGroupFile = File(newPath);
                String path =
                    chatViewController.editedGroupFile!.path;
                File selectedFiles = File(path);

                List<String?> fileNames = [];
                List<String?> fileTypes = [];

                Map<String, String?> info =
                cmd.getFileInfo(selectedFiles);
                fileNames.add(info['fileName']);
                fileTypes.add(info['mimeType']);

                Map<String, dynamic> uploadParams = {
                  ApiKeys.fileName: fileNames,
                  ApiKeys.fileType: fileTypes,
                };

               Map<String,dynamic> data = {
                  ApiKeys.conversation_id: widget.conversationId,
                };
                await chatViewController.updateGroupInfo(
                  data,
                  isFromFile: true,
                  fileParams: uploadParams,
                  fileSended: selectedFiles,
                );
                setState(() {

                });

              }
            },
            child: Container(
              padding: const EdgeInsets.all(4),
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
    );
  }

}
