import 'dart:developer';
import 'dart:io';

import 'package:BlueEra/widgets/commom_textfield.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:dio/dio.dart' as dio;
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/api/apiService/api_keys.dart';
import '../../../../core/api/apiService/api_response.dart';
import '../../../../core/constants/app_constant.dart';
import '../../../../core/constants/regular_expression.dart';
import '../../../common/auth/views/dialogs/select_profile_picture_dialog.dart';

import '../../auth/controller/chat_view_controller.dart';
import '../../auth/controller/group_chat_view_controller.dart';
import '../../auth/model/GetChatListModel.dart';
import '../widget/component_widgets.dart';

class AddNewGroupPage extends StatefulWidget {
  final List<String> selectedUserIds;
  const AddNewGroupPage({super.key, required this.selectedUserIds});

  @override
  State<AddNewGroupPage> createState() => _AddNewGroupPageState();
}

class _AddNewGroupPageState extends State<AddNewGroupPage> {
  final TextEditingController groupNameController=TextEditingController();
  final groupChatViewController = Get.find<GroupChatViewController>();
  final chatViewController = Get.find<ChatViewController>();
  final _formKey = GlobalKey<FormState>();
  bool publicGroup=false;
  File? pickedFile;
  bool isLoadingMembers = true;
  @override
  void initState() {
    super.initState();
  
    chatViewController.loadGroupConnections().then((_) {
      _populateSelectedChatList();
    });
    
 
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _populateSelectedChatList();
    });
  }

  Future<void> _populateSelectedChatList() async {
    setState(() {
      isLoadingMembers = true;
    });
    
    // Clear existing selected chat list and user IDs
    chatViewController.selectedChatList.clear();
    chatViewController.selectedUserIds.clear();
    
    // Add the selected user IDs to the controller
    chatViewController.selectedUserIds.addAll(widget.selectedUserIds);
    
    // Get the contacts data from the controller
    final details = chatViewController.contactsListModel?.value.data;
    
    // If contacts data is not available, try to load it
    if (details == null && chatViewController.viewContactsListResponse.value.status != Status.COMPLETE) {
      // Try to load contacts data
      await chatViewController.uploadContacts([]);
    }
    
    // Get the updated contacts data
    final updatedDetails = chatViewController.contactsListModel?.value.data;
    
    if (updatedDetails != null) {
      // Find existing contacts that match the selected user IDs
      for (String userId in widget.selectedUserIds) {
        // First try to find in existingNotConnected
        final existingContact = updatedDetails.existingNotConnected?.where(
          (contact) => contact.id == userId,
        ).firstOrNull;
        
        if (existingContact != null) {
          // Create a ChatList object from the contact data
          final chatList = ChatList(
            sender: Sender(
              id: existingContact.id,
              name: existingContact.name,
              contactNo: existingContact.contactNo,
              profileImage: existingContact.profileImage,
            ),
            // Add other required fields as needed
          );
          chatViewController.selectedChatList.add(chatList);
        } else {
          // If not found in existingNotConnected, try to find in groupConnections
          final groupConnection = chatViewController.groupConnections.where(
            (connection) => connection['id'] == userId || connection['_id'] == userId,
          ).firstOrNull;
          
          if (groupConnection != null) {
            // Create a ChatList object from the group connection data
            final chatList = ChatList(
              sender: Sender(
                id: groupConnection['id'] ?? groupConnection['_id'],
                name: groupConnection['name'],
                contactNo: groupConnection['contact_no'],
                profileImage: groupConnection['profile_image'],
              ),
              // Add other required fields as needed
            );
            chatViewController.selectedChatList.add(chatList);
          } else {
            // Fallback: Create a basic ChatList object with just the ID
            final chatList = ChatList(
              sender: Sender(
                id: userId,
                name: "User $userId", // Fallback name
                contactNo: "", // Empty contact number
                profileImage: null,
              ),
              // Add other required fields as needed
            );
            chatViewController.selectedChatList.add(chatList);
          }
        }
      }
    }
    
   
    print("Selected User IDs: ${widget.selectedUserIds}");
    print("Selected Chat List Length: ${chatViewController.selectedChatList.length}");
    print("Contacts Data Available: ${updatedDetails != null}");
    if (updatedDetails != null) {
      print("Existing Not Connected Count: ${updatedDetails.existingNotConnected?.length ?? 0}");
      print("Group Connections Count: ${chatViewController.groupConnections.length}");
    }
    
    // Set loading to false and trigger UI rebuild
    if (mounted) {
      setState(() {
        isLoadingMembers = false;
      });
    }
  }

  Future<void> captureImageFromCamera() async {
    // final picker = ImagePicker();
    // final pickedFi = await picker.pickImage(source: ImageSource.gallery);
    //
    // if (pickedFi != null) {
    //   setState(() {
    //     pickedFile=File(pickedFi.path);
    //   });
    // }
   String? imagePath = await SelectProfilePictureDialog.showLogoDialog(
        context,
        "Choose Group Icon");
   if(imagePath!=null){
     setState(() {
       pickedFile=File(imagePath);
     });
   }

    return null;
  }


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: CommonBackAppBar(title: "New Group",),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Group Image + Name Field
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0,vertical: 16),
                child: Row(
                  children: [
                    InkWell(
                      onTap: (){
                        captureImageFromCamera();
                      },
                      child: CircleAvatar(
                        radius: 22,
                        backgroundColor: Colors.grey[400],
                        backgroundImage: pickedFile != null ? FileImage(pickedFile!) : null,
                        child: pickedFile == null
                            ? const Icon(Icons.camera_alt, color: Colors.white70, size: 30)
                            : null, // Hide icon if image is picked
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child:  CommonTextField(validator: (val){
                        if(val!.isEmpty){
                          return "Enter Group Name";
                        }else{
                          return null;
                        }
                      },
                        maxLine: 1,
                        textEditController: groupNameController,
                        inputLength: AppConstants.inputCharterLimit50,
                        keyBoardType: TextInputType.text,
                        regularExpression:
                        RegularExpressionUtils.alphabetSpacePattern,
                        hintText:"Group Name",
                        isValidate: false,
                      ),
                    ),
                    // Icon(Icons.emoji_emotions_outlined, color: Colors.black),
                  ],
                ),
              ),
               Divider(color: Colors.grey[400]),
              ListTile(
                leading:  Icon((!publicGroup)?Icons.lock_outline:Icons.lock_open, color: Colors.black,size: 22,),
                title:  CustomText(
                  (!publicGroup)?"Private group":"Public group",
                color: Colors.black,
                  fontSize: 16,
                ),
                trailing:  CustomText(
                  (!publicGroup)?"On":"Off",
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                onTap: () {
                  setState(() {
                    publicGroup=!publicGroup;
                  });
                },
              ),


              const SizedBox(height: 10),
               Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Obx(() => CustomText(
                  "Members: ${chatViewController.selectedChatList.length}",
                  color: Colors.black,
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
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text("Loading members..."),
                          ],
                        ),
                      )
                    : Obx(() => chatViewController.selectedChatList.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.people_outline, size: 64, color: Colors.grey),
                              SizedBox(height: 16),
                              Text("No members found", style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        )
                      : ListView.builder(
                        padding: EdgeInsets.symmetric(vertical: 6),
                        itemCount: chatViewController.selectedChatList.length,

                        itemBuilder: (context, index) {
                          return ChatListTile(
                              onSelect: (){
                            setState(() {

                            });
                          },type: "create group",index: index, chatViewController: chatViewController, chat: chatViewController.selectedChatList[index], theme: theme, isForwardUI: true, context: context, isFromGroupSelect: true);
                        },
                      )),
                ),
              ),
            ],
          ),
        ),
      ),

      // Floating check button
      floatingActionButton: FloatingActionButton(
        onPressed: () async{
        if(_formKey.currentState!.validate()){
          Map<String, dynamic> data = {};
          if(pickedFile!=null){
            String? imagePath = File(pickedFile!.path).path;
            String fileName = imagePath
                .split('/')
                .last;
            String fileExtension = fileName
                .split('.')
                .last
                .toLowerCase();


            dio.MultipartFile? imageByPart = await dio.MultipartFile
                .fromFile(
              imagePath,
              filename: fileName,
            );

           data = {
                ApiKeys.group_name :groupNameController.text,
                ApiKeys.conversation_users: widget.selectedUserIds,
                ApiKeys.public_group: publicGroup,
                ApiKeys.files: imageByPart,
            };

          }else{
            data = {
              ApiKeys.group_name :groupNameController.text,
              ApiKeys.conversation_users: widget.selectedUserIds,
              ApiKeys.public_group: publicGroup,
            };
          }
          log("sdkjklsdjcnksdc ${data}");
          bool value=await chatViewController.createGroupApi(data);
          
          if(value==true){
            Navigator.pop(context);
            Navigator.pop(context);
          }

        }
        },
        backgroundColor: Colors.green,
        child: const Icon(Icons.check, color: Colors.white),
      ),
    );
  }
}
