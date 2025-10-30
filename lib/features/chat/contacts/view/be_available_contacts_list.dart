import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_theme_controller.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';
import 'package:share_handler/share_handler.dart';
import '../../../../core/api/apiService/api_response.dart';
import '../../../../core/constants/common_methods.dart';
import '../../../../core/constants/shared_preference_utils.dart';
import '../../../../core/constants/snackbar_helper.dart';
import '../../../../widgets/custom_btn.dart';
import '../../auth/controller/chat_view_controller.dart';
import '../../auth/model/contactListModel.dart';
import '../../auth/model/view_group_members_model.dart';

class BeAvailableContactsList extends StatefulWidget {
  final String? sharedText;
  final String? conversationId;
  final List<SharedAttachment?>? sharedFiles;
  final bool? isFromAddMember;
  final  List<GroupMembersListModel>? members;
   BeAvailableContactsList({super.key, this.sharedText, this.sharedFiles, this.isFromAddMember, this.members, this.conversationId});


  @override
  State<BeAvailableContactsList> createState() => _BeAvailableContactsListState();
}

class _BeAvailableContactsListState extends State<BeAvailableContactsList> {
  final chatThemeController = Get.find<ChatThemeController>();
  final chatViewController = Get.find<ChatViewController>();
  final TextEditingController _searchController = TextEditingController();

  List<ExistingNotConnected?> _filteredExisting = [];
  final Set<ExistingNotConnected> _selectedUsers = <ExistingNotConnected>{};

  Timer? _debounce;


  @override
  void initState() {
    super.initState();
    widget.members;
    // if (widget.from == "group") {
    //   chatViewController.loadGroupConnections();
    // } else {
      _loadContactsFromStorage();
    // }
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }
  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      final query = _searchController.text.toLowerCase();
      final details = chatViewController.contactsListModel?.value.data;
      if (details != null) {
        List<ExistingNotConnected> baseList = details.existingNotConnected ?? [];

        // ✅ Exclude already added group members first
        baseList = _excludeGroupMembers(baseList);

        setState(() {
          _filteredExisting = baseList
              .where((c) =>
          (c.name?.toLowerCase().contains(query) ?? false) ||
              (c.contactNo?.toLowerCase().contains(query) ?? false))
              .toList();
        });
      }
    });
  }




  List<Map<String, dynamic>> getFormattedContacts(
      List<Map<String, dynamic>> rawContacts) {
    return rawContacts.map((c) {
      final phones = (c["phones"] as List).cast<String>();
      return {
        "name": c["displayName"] ?? "",
        "contactNo": phones.isNotEmpty ? phones.first : "",
      };
    }).toList();
  }

  Future<void> _loadContactsFromStorage() async {
    String? storedData = await SharedPreferenceUtils.getSecureValue(
        SharedPreferenceUtils.saved_contacts);
    if (storedData != null) {
      Map<String, dynamic> decoded =
      await compute(jsonDecode, storedData) as Map<String, dynamic>;
      chatViewController.loadContactsFromLocalStorage(decoded);
    } else {
      await _refreshContacts();
    }
  }
// This is the isolate function → runs in background
  List<Map<String, String>> formatContactsInIsolate(
      List<Map<String, dynamic>> rawContacts) {

    return rawContacts
        .where((c) => (c["phones"] as List).isNotEmpty)
        .map((c) => {
      ApiKeys.contact_no: (c["phones"] as List).first as String,
      ApiKeys.name: c["displayName"] as String,
    })
        .toList();
  }

  Future<void> _refreshContacts() async {
    PermissionStatus status = await Permission.contacts.status;
    if (status.isGranted) {
      List<Contact> contacts =
      await FlutterContacts.getContacts(withProperties: true);

      // Convert Contacts → plain JSON-safe map
      List<Map<String, dynamic>> rawContacts = contacts.map((c) {
        return {
          "displayName": c.displayName,
          "phones": c.phones.map((p) => p.number).toList(),
        };
      }).toList();

      // Compute in isolate
      List<Map<String, String>> formattedContacts = await formatContactsInIsolate(rawContacts);
      // await compute(formatContactsInIsolate, rawContacts);

      chatViewController.uploadContacts(formattedContacts);
    } else {
      PermissionStatus newStatus = await Permission.contacts.request();
      if (newStatus.isGranted) {
        return _refreshContacts();
      } else if (newStatus.isPermanentlyDenied) {
        _showPermissionDialog();
      } else {
        commonSnackBar(
            message: "Permission denied");

      }
    }
  }

// Runs in isolate – must only use JSON-safe data



  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Permission Required"),
        content: const Text("Please allow contact access in app settings."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await openAppSettings();
            },
            child: const Text("Allow Permission"),
          ),
        ],
      ),
    );
  }
  List<ExistingNotConnected> _excludeGroupMembers(
      List<ExistingNotConnected> contacts) {
    if (widget.members == null || widget.members!.isEmpty) return contacts;

    final memberIds = widget.members!.map((m) => m.id).toSet();

    // remove those contacts whose id is already in group members
    return contacts.where((c) => !memberIds.contains(c.id)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isGroupMode = true;

    return WillPopScope(
      onWillPop: () async {

        return true;
      },
      child: Scaffold(
        appBar: CommonBackAppBar(
          onBackTap: () {
            // chatViewController
            //     .emitEvent("ChatList", {ApiKeys.type: "personal"});
            Navigator.pop(context);
          },
          title: "My Contacts",
          isLeading: true,
          isReloadContactButton: true,
          onRefreshContact: () {
            if (isGroupMode) {
              chatViewController.loadGroupConnections();
            } else {
              _refreshContacts();
            }
          },
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: "Search contacts...",
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: theme.colorScheme.surface,
                  contentPadding:
                  const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(30),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            Expanded(
              child: Obx(() {
                if (chatViewController.viewContactsListResponse.value.status ==
                    Status.COMPLETE) {
                  final details =
                      chatViewController.contactsListModel?.value.data;
                  List<ExistingNotConnected> existing =
                      details?.existingNotConnected ?? <ExistingNotConnected>[];

                  /// ✅ Apply exclusion here too
                  existing = _excludeGroupMembers(existing);

                  if (_filteredExisting.isEmpty &&
                      _searchController.text.isEmpty) {
                    _filteredExisting = List.from(existing);
                  }

                  return ListView(
                    children: [
                      _SectionTitle("Contacts Available on BlueEra", theme),
                      if ((_searchController.text.isEmpty ? existing.isEmpty : _filteredExisting.isEmpty))
                        const Center(child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text("No contacts found"),
                        ))
                      else
                        ...List.generate(
                          _searchController.text.isEmpty ? existing.length : _filteredExisting.length,
                              (index) {
                            final contact = _searchController.text.isEmpty
                                ? existing[index]
                                : _filteredExisting[index];
                            return _ExistingContactTile(
                              contact: contact,
                              isGroupMode: isGroupMode,
                              selectedUserIds: _selectedUsers,
                              onSelect: (id) {
                                if(widget.isFromAddMember==true){
                                  setState(() {
                                    if (_selectedUsers.contains(id)) {
                                      // If the same user is clicked again → unselect
                                      _selectedUsers.remove(id);
                                    } else {
                                      // If another user is clicked → clear old selection and select new one
                                      _selectedUsers
                                        ..add(id!);
                                    }
                                  });
                                }else{
                                  setState(() {
                                    if (_selectedUsers.contains(id)) {
                                      // If the same user is clicked again → unselect
                                      _selectedUsers.remove(id);
                                    } else {
                                      // If another user is clicked → clear old selection and select new one
                                      _selectedUsers
                                        ..clear()
                                        ..add(id!);
                                    }
                                  });
                                }


                              },
                              chatViewController: chatViewController,
                            );
                          },
                        ),
                    ],
                  );

                } else {
                  return const Center(
                      child: SizedBox(
                          height: 26,
                          width: 26,
                          child: CircularProgressIndicator()));
                }
              }),
            ),
          ],
        ),
        bottomNavigationBar: isGroupMode
            ? SafeArea(
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: CustomBtn(
              bgColor: _selectedUsers.isEmpty?theme.colorScheme.primary.withValues(alpha: 0.5):theme.colorScheme.primary,
              width: double.infinity,
              height: 48,
              onTap: _selectedUsers.isEmpty
                  ? null
                  : () async{
                if(widget.isFromAddMember==true){
                  List<String?> userId=_selectedUsers.map((e)=>e.id).toList();
                  Map<String,dynamic> data=
                    {
                      ApiKeys.conversation_id: "${widget.conversationId}",
                      ApiKeys.conversation_users: userId
                    }
                  ;
                  chatViewController.addGroupMember(params: data);
                }else{
                  if(widget.sharedFiles!=null){
                    List<File> selectedFiles = [];
                    List<SharedAttachment?>? sharedList = widget.sharedFiles;

                    if (sharedList != null && sharedList.isNotEmpty) {
                      selectedFiles = sharedList
                          .where((e) => e?.path != null && e!.path.isNotEmpty)
                          .map((e) => File(e!.path))
                          .toList();
                    }

                    List<String?> fileNames = [];
                    List<String?> fileTypes = [];
                    for (var file in selectedFiles) {
                      Map<String, String?> fileInfo = getFileInfo(file);
                      fileNames.add(fileInfo['fileName']);
                      fileTypes.add(fileInfo['mimeType']);
                    }

                    String firstFileExtension = selectedFiles.first.path
                        .split('.')
                        .last
                        .toLowerCase();
                    String messageType = ['mp4', 'mov', 'avi', 'mkv'].contains(
                        firstFileExtension)
                        ? 'video'
                        : 'image';

                    final uploadParams = {
                      ApiKeys.fileName: fileNames,
                      ApiKeys.fileType: fileTypes,
                    };

                    chatViewController.generateUploadUrlsApi(
                      params: uploadParams,
                      listFile: selectedFiles,
                      isInitialMessage: _selectedUsers.first.conversationId==null?true:false,
                      userId: _selectedUsers.first.id??'',
                      conversationId: _selectedUsers.first.conversationId??'',
                      messageType: messageType,
                    );
                  }else if(widget.sharedText!=null){
                    Map<String,dynamic> data = {
                      if(_selectedUsers.first.conversationId==null)
                        ApiKeys.other_user_id: _selectedUsers.first.id
                      else
                        ApiKeys.conversation_id: _selectedUsers.first.conversationId,
                      ApiKeys.message: "${widget.sharedText}",
                      ApiKeys.message_type: "text",
                    };
                    if(_selectedUsers.first.conversationId==null){
                      chatViewController.sendInitialMessage(data);
                    }else{
                      chatViewController.sendMessage(data);
                    }
                  }

                  chatViewController.openAnyOneChatFunction(
                    type: _selectedUsers.first.accountType,
                    isInitialMessage: true,
                    userId: _selectedUsers.first.id,
                    conversationId: _selectedUsers.first.conversationId ?? '',
                    profileImage: _selectedUsers.first.profileImage,
                    contactName: _selectedUsers.first.name,
                    contactNo: _selectedUsers.first.contactNo,
                    isFromContactList: true,
                  );
                }


              },
              title: _selectedUsers.isEmpty
                  ? "Select Contact"
                  :(widget.isFromAddMember==true)?"Add": "Share",
            ),
          ),
        )
            : null,
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  final ThemeData theme;
  const _SectionTitle(this.text, this.theme);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 8),
      child: CustomText(
        text,
        color: theme.colorScheme.inverseSurface,
        fontSize: 12,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}


class _ExistingContactTile extends StatelessWidget {
  final ExistingNotConnected? contact;
  final bool isGroupMode;
  final Set<ExistingNotConnected> selectedUserIds;
  final void Function(ExistingNotConnected? id) onSelect;
  final ChatViewController chatViewController;

  const   _ExistingContactTile({
    required this.contact,
    required this.isGroupMode,
    required this.selectedUserIds,
    required this.onSelect,
    required this.chatViewController,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = contact?.name ?? "";
    final phone = contact?.contactNo ?? "No number";
    final profileImage = contact?.profileImage ?? "";
    final userId = contact?.id ?? "";

    final isSelected = selectedUserIds.contains(contact);

    return ListTile(
      onTap: () {
          if (userId.isNotEmpty) onSelect(contact);
      },
      leading: CircleAvatar(
        radius: 20,
        backgroundImage:
        profileImage.isNotEmpty ? CachedNetworkImageProvider(profileImage) : null,
        child: profileImage.isEmpty
            ? CustomText(
          name.isNotEmpty ? name[0].toUpperCase() : "?",
          fontSize: 20,
          color: theme.colorScheme.surface,
        )
            : null,
      ),
      title: Text( name.isNotEmpty ? name : phone,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,),
      subtitle: name.isNotEmpty
          ? CustomText(
        (contact?.accountType == "INDIVIDUAL")
            ? (contact?.designation?.isNotEmpty ?? false)
            ? contact!.designation!
            : phone
            : "",
      )
          : null,
      trailing: isGroupMode
          ? Checkbox(
        activeColor: Colors.blue, // fill color when selected
        checkColor: Colors.white,
        value: isSelected,
        onChanged: (_) => onSelect(contact),
      )
          : null,
    );
  }
}


