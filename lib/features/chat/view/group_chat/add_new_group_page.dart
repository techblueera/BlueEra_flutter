import 'dart:io';

import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/api/apiService/api_keys.dart';
import '../../../../core/api/apiService/api_response.dart';
import '../../../../core/constants/app_constant.dart';
import '../../../../core/constants/common_methods.dart';
import '../../../../core/constants/regular_expression.dart';
import '../../../../core/constants/app_colors.dart'; // ADDED
import '../../../common/auth/views/dialogs/select_profile_picture_dialog.dart';
import '../../auth/controller/chat_view_controller.dart';
import '../../auth/model/GetChatListModel.dart';
import '../widget/component_widgets.dart';

class AddNewGroupPage extends StatefulWidget {
  final List<String> selectedUserIds;

  const AddNewGroupPage({super.key, required this.selectedUserIds});

  @override
  State<AddNewGroupPage> createState() => _AddNewGroupPageState();
}

class _AddNewGroupPageState extends State<AddNewGroupPage> {
  final TextEditingController groupNameController = TextEditingController();
  final chatViewController = Get.find<ChatViewController>();
  final _formKey = GlobalKey<FormState>();
  bool publicGroup = false;
  File? pickedFile;
  bool isLoadingMembers = true;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _populateSelectedChatList();
    });
  }

  Future<void> _populateSelectedChatList() async {
    setState(() {
      isLoadingMembers = true;
    });

    chatViewController.selectedChatList.clear();
    chatViewController.selectedUserIds.clear();

    chatViewController.selectedUserIds.addAll(widget.selectedUserIds);

    final details = chatViewController.contactsListModel?.value.data;

    if (details == null &&
        chatViewController.viewContactsListResponse.value.status !=
            Status.COMPLETE) {
      await chatViewController.uploadContacts([]);
    }

    final updatedDetails = chatViewController.contactsListModel?.value.data;
    if (updatedDetails != null) {
      for (String userId in widget.selectedUserIds) {
        final existingContact = updatedDetails.existingNotConnected
            ?.where((contact) => contact.id == userId)
            .firstOrNull;
        if (existingContact != null) {
          final chatList = ChatList(
            sender: Sender(
              id: existingContact.id,
              name: existingContact.name,
              contactNo: existingContact.contactNo,
              profileImage: existingContact.profileImage,
            ),
          );
          chatViewController.selectedChatList.add(chatList);
        } else {
          final groupConnection = chatViewController.groupConnections
              .where((connection) =>
                  connection['id'] == userId || connection['_id'] == userId)
              .firstOrNull;

          if (groupConnection != null) {
            final chatList = ChatList(
              sender: Sender(
                id: groupConnection['id'] ?? groupConnection['_id'],
                name: groupConnection['name'],
                contactNo: groupConnection['contact_no'],
                profileImage: groupConnection['profile_image'],
              ),
            );
            chatViewController.selectedChatList.add(chatList);
          } else {
            final chatList = ChatList(
              sender: Sender(
                id: userId,
                name: "User $userId",
                contactNo: "",
                profileImage: null,
              ),
            );
            chatViewController.selectedChatList.add(chatList);
          }
        }
      }
    }

    if (mounted) {
      setState(() {
        isLoadingMembers = false;
      });
    }
  }

  Future<void> captureImageFromCamera() async {
    String? imagePath = await SelectProfilePictureDialog.showLogoDialog(
        context, "Choose Group Icon");
    if (imagePath != null) {
      setState(() {
        pickedFile = File(imagePath);
      });
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: CommonBackAppBar(
        title: "New Group",
      ),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16),
                child: Row(
                  children: [
                    InkWell(
                      onTap: () => captureImageFromCamera(),
                      child: CircleAvatar(
                        radius: 22,
                        backgroundColor: AppColors.grey9B,
                        backgroundImage:
                            pickedFile != null ? FileImage(pickedFile!) : null,
                        child: pickedFile == null
                            ? Icon(Icons.camera_alt,
                                color: AppColors.white
                                    ,
                                size: 30)
                            : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CommonTextField(
                        validator: (val) =>
                            val!.isEmpty ? "Enter Group Name" : null,
                        maxLine: 1,
                        textEditController: groupNameController,
                        inputLength: AppConstants.inputCharterLimit50,
                        keyBoardType: TextInputType.text,
                        regularExpression:
                            RegularExpressionUtils.alphabetSpacePattern,
                        hintText: "Group Name",
                        isValidate: false,
                      ),
                    ),
                  ],
                ),
              ),
              Divider(color: AppColors.grey9B),
              ListTile(
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
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Obx(() => CustomText(
                      "${AppStrings.members.tr}: ${chatViewController.selectedChatList.length}",
                      color: AppColors.black,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    )),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 800,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: isLoadingMembers
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(
                                  color: AppColors.primaryColor),
                              SizedBox(height: 16),
                              CustomText("Loading members...",
                                  color: AppColors.black),
                            ],
                          ),
                        )
                      : Obx(() => chatViewController.selectedChatList.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.people_outline,
                                      size: 64, color: AppColors.grey9B),
                                  SizedBox(height: 16),
                                  CustomText(
                                    "No members found",
                                    color: AppColors.grey9B,
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              itemCount:
                                  chatViewController.selectedChatList.length,
                              itemBuilder: (context, index) {
                                return ChatListTile(
                                  onSelect: () => setState(() {}),
                                  type: "create group",
                                  index: index,
                                  chatViewController: chatViewController,
                                  chat: chatViewController
                                      .selectedChatList[index],
                                  theme: theme,
                                  isForwardUI: true,
                                  context: context,
                                  isFromGroupSelect: true,
                                );
                              },
                            )),
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          if (_formKey.currentState!.validate()) {
            Map<String, dynamic> data = {};

            if (pickedFile != null) {
              String path = pickedFile!.path;
              File selectedFiles = File(path);

              List<String?> fileNames = [];
              List<String?> fileTypes = [];

              Map<String, String?> info = getFileInfo(selectedFiles);
              fileNames.add(info['fileName']);
              fileTypes.add(info['mimeType']);

              Map<String, dynamic> uploadParams = {
                ApiKeys.fileName: fileNames,
                ApiKeys.fileType: fileTypes,
              };

              data = {
                ApiKeys.group_name: groupNameController.text,
                ApiKeys.conversation_users: widget.selectedUserIds,
                ApiKeys.public_group: publicGroup,
              };

              bool value = await chatViewController.createGroupApi(
                data,
                isFromFile: true,
                fileParams: uploadParams,
                fileSended: selectedFiles,
              );

              if (value == true) {
                Navigator.pop(context);
                Navigator.pop(context);
              }
            } else {
              data = {
                ApiKeys.group_name: groupNameController.text,
                ApiKeys.conversation_users: widget.selectedUserIds,
                ApiKeys.public_group: publicGroup,
              };

              bool value = await chatViewController.createGroupApi(data);
              if (value == true) {
                Navigator.pop(context);
                Navigator.pop(context);
              }
            }
          }
        },
        backgroundColor: AppColors.primaryColor,
        child: const Icon(Icons.check, color: AppColors.white),
      ),
    );
  }
}
