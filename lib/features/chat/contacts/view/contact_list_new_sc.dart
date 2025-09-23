import 'dart:convert';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_theme_controller.dart';
import 'package:BlueEra/features/chat/view/group_chat/add_new_group_page.dart';
import 'package:BlueEra/features/common/auth/views/screens/visiting_card_page.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/visiting_card_helper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/api/apiService/api_response.dart';
import '../../../../core/constants/shared_preference_utils.dart';
import '../../../../widgets/custom_btn.dart';
import '../../auth/controller/chat_view_controller.dart';
import '../../auth/model/contactListModel.dart';
import '../auth/controller/secound_chat_view_controller.dart';
import '../auth/model/snd_contact_sync_list_model.dart';

class ContactsPageNew extends StatefulWidget {
  final String? from;
  const ContactsPageNew({
    super.key,
    this.from,
  });

  @override
  State<ContactsPageNew> createState() => _ContactsPageNewState();
}

class _ContactsPageNewState extends State<ContactsPageNew> {
  final chatThemeController = Get.find<ChatThemeController>();
  List<Contact> _contacts = [];
  List<SecondContactSyncList?> _filteredExisting = [];
  List<SecondContactSyncList?> _filteredNonExisting = [];

  bool _isLoading = true;
  final chatViewController = Get.find<ChatViewController>();
  final secondChatViewController = Get.find<SecondChatViewController>();
  final TextEditingController _searchController = TextEditingController();
  final Set<String> _selectedUserIds = <String>{};
  @override
  void initState() {
    super.initState();
    if (widget.from == "Group") {
      setState(() {
        _isLoading = false;
      });
      chatViewController.loadGroupConnections();
    } else {
      _loadContactsFromStorage();
    }
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    String query = _searchController.text.toLowerCase();
    final details = chatViewController.contactsListModel?.value.data;

    if (details != null) {

    }
  }

  List<Map<String, String>> getFormattedContacts() {
    String normalizePhone(String number) {
      return number
          .replaceAll(" ", "")      // remove spaces
          .replaceFirst(RegExp(r'^\+?91'), ""); // remove +91 or 91 at start
    }
    return _contacts
        .where((contact) => contact.phones.isNotEmpty)
        .map((contact) => {
      ApiKeys.name: contact.displayName,
    ApiKeys.phoneNumber: normalizePhone(contact.phones.first.number),

    })
        .toList();
  }

  Future<void> _loadContactsFromStorage() async {
    String? storedData = await SharedPreferenceUtils.getSecureValue(
        SharedPreferenceUtils.saved_contacts);

    if (storedData != null) {
      List decoded = json.decode(storedData);
      setState(() {
        _contacts = decoded.map((c) => Contact.fromJson(c)).toList();
        // _filteredContacts = List.from(_contacts); // initialize filtered list
        _isLoading = false;
      });
    } else {
      await _refreshContacts();
    }
    List<Map<String, dynamic>> formattedContacts = await getFormattedContacts();
    Map<String,dynamic> body={
      ApiKeys.userId: "$userId",
      ApiKeys.contacts: formattedContacts
    };
    secondChatViewController.syncContacts(body);
  }

  Future<void> _refreshContacts() async {

    setState(() => _isLoading = true);

    PermissionStatus status = await Permission.contacts.status;

    if (status.isGranted) {
      List<Contact> contacts =
      await FlutterContacts.getContacts(withProperties: true);
      List<Map<String, dynamic>> contactList =
      contacts.map((c) => c.toJson()).toList();

      await SharedPreferenceUtils.setSecureValue(
        SharedPreferenceUtils.saved_contacts,
        json.encode(contactList),
      );

      setState(() {
        _contacts = contacts;

        _isLoading = false;
      });
    } else {
      PermissionStatus newStatus = await Permission.contacts.request();
      if (newStatus.isGranted) {
        return _refreshContacts();
      } else if (newStatus.isPermanentlyDenied) {
        setState(() => _isLoading = false);
        _showPermissionDialog();
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Permission denied")),
        );
      }
    }
  }

  void _showPermissionDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Permission Required"),
        content:
        Text("Please allow contact access in app settings to continue."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await openAppSettings();
            },
            child: Text("Allow Permission"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isGroupMode = widget.from == "Group";

    return WillPopScope(
      onWillPop: () async {
        chatViewController.emitEvent("ChatList", {ApiKeys.type: "personal"});
        return true;
      },
      child: Scaffold(
        appBar: CommonBackAppBar(
          onBackTap: () {
            chatViewController
                .emitEvent("ChatList", {ApiKeys.type: "personal"});
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
            // Padding(
            //   padding: const EdgeInsets.all(12.0),
            //   child: TextField(
            //     controller: _searchController,
            //     decoration: InputDecoration(
            //       hintText: "Search contacts...",
            //       prefixIcon: Icon(Icons.search),
            //       filled: true,
            //       fillColor: theme.colorScheme.surface,
            //       contentPadding:
            //       EdgeInsets.symmetric(vertical: 0, horizontal: 16),
            //       border: OutlineInputBorder(
            //         borderRadius: BorderRadius.circular(30),
            //         borderSide: BorderSide.none,
            //       ),
            //     ),
            //   ),
            // ),
            Expanded(
              child: Obx(() {
                if (secondChatViewController.sndContactSyncListModel?.value !=null) {
                  final existingNotConnected = secondChatViewController.sndContactSyncListModel?.value.data
                      ?.where((e) => e.registered ?? false)
                      .toList()
                      ?? [];

                  final nonExistingContacts = secondChatViewController.sndContactSyncListModel?.value.data
                      ?.where((e) => !(e.registered ?? false))
                      .toList()
                      ?? [];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18.0),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 12),
                          CustomText(
                            "Contacts Available on BlueEra",
                            color: theme.colorScheme.inverseSurface,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                          const SizedBox(height: 4),
                          _isLoading
                              ? Center(child: SizedBox(
                              height: 26,
                              width: 26,
                              child: CircularProgressIndicator()))
                              : ((_searchController.text.isEmpty)?existingNotConnected.isEmpty:_filteredExisting.isEmpty)
                              ? Center(child: Text("No contacts found"))
                              : ListView.builder(
                            physics: NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                            itemCount: (_searchController.text.isEmpty)?existingNotConnected.length:_filteredExisting.length,
                            itemBuilder: (context, index) {
                              final contact =
                              existingNotConnected[index];
                              final name = contact.name;
                              final phone =
                              (contact?.phoneNumber?.isNotEmpty ??
                                  false)
                                  ? contact?.phoneNumber
                                  : 'No number';

                              return ListTile(
                                onTap: () {
                                  Map<String,dynamic> data={
                                    "participants": [
                                    "${existingNotConnected[
                                    index]
                                        .userInfo['id']}","$userId"
                                    ],
                                    "type": "individual",
                                    "name": "${existingNotConnected[
                                    index].name}",
                                    "admins": [
                                      "${existingNotConnected[
                                      index]
                                          .userInfo['id']}","$userId"
                                    ]
                                  };
                                  secondChatViewController.createNewConversation(data);
                                  // chatViewController.openAnyOneChatFunction(
                                  //     type: "personal",
                                  //     isInitialMessage: true,
                                  //     userId:existingNotConnected[
                                  //     index]
                                  //         .userInfo['id'],
                                  //     conversationId: existingNotConnected[
                                  //     index]
                                  //         .userInfo['id'],
                                  //     profileImage: '',
                                  //     contactName: existingNotConnected[
                                  //     index]
                                  //         .name,
                                  //     contactNo: phone,
                                  //     //  businessId: details.existingNotConnected[index].,
                                  //     isFromContactList: true);
                                },
                                contentPadding: EdgeInsets.all(0),
                                leading: CircleAvatar(
                                  radius: 20,
                                  child: Icon(Icons.person),
                                ),
                                title: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                      MainAxisAlignment
                                          .spaceBetween,
                                      children: [
                                        SizedBox(
                                          // width: 170,
                                          child: CustomText(
                                            maxLines: 1,
                                            overflow:
                                            TextOverflow.ellipsis,
                                            name ?? phone,
                                            fontWeight:
                                            FontWeight.w600,
                                            fontSize: 16,
                                            fontFamily:
                                            "Rounded Mplus 1c",
                                          ),
                                        ),

                                      ],
                                    ),
                                    CustomText(
                                      "${phone}",
                                      fontSize: 14,
                                      fontFamily:
                                      "Rounded Mplus 1c",
                                    )
                                  ],
                                ),
                              );
                            },
                          ),
                          CustomText(
                            "Invite to BlueEra",
                            color: theme.colorScheme.inverseSurface,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                          const SizedBox(height: 4),
                          _isLoading
                              ? Center(child: CircularProgressIndicator())
                              : ((_searchController.text.isEmpty)?(nonExistingContacts.isEmpty):_filteredNonExisting.isEmpty)
                              ? Center(child: Text("No contacts found"))
                              : ListView.builder(

                            physics:
                            const NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                            itemCount: (_searchController.text.isEmpty)?nonExistingContacts.length:_filteredNonExisting.length,
                            itemBuilder: (context, index) {
                              final contact = (_searchController.text.isEmpty)?nonExistingContacts[index]:
                              _filteredNonExisting[index];
                              final rawName = contact?.name ?? "";
                              final phone =
                              (contact?.phoneNumber?.isNotEmpty ??
                                  false)
                                  ? contact!.phoneNumber
                                  : 'No number';


                              final name =
                              rawName.characters.toString();


                              final firstLetter =
                              name.characters.isNotEmpty
                                  ? name.characters.first
                                  .toUpperCase()
                                  : "A";

                              return ListTile(
                                contentPadding: EdgeInsets.all(0),
                                leading: CircleAvatar(
                                  radius: 20,
                                  child: CustomText(
                                    firstLetter,
                                    fontFamily: "Rounded Mplus 1c",
                                    fontWeight: FontWeight.w400,
                                    fontSize: 20,
                                    color: theme.colorScheme.surface,
                                  ),
                                ),
                                title: Row(
                                  mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                        children: [
                                          CustomText(
                                            name,
                                            maxLines: 1,
                                            overflow:
                                            TextOverflow.ellipsis,
                                            fontWeight:
                                            FontWeight.w600,
                                            fontSize: 16,
                                            fontFamily:
                                            "Rounded Mplus 1c",
                                          ),
                                          const SizedBox(height: 2),
                                          CustomText(
                                            phone,
                                            fontSize: 14,
                                            fontFamily:
                                            "Rounded Mplus 1c",
                                          ),
                                        ],
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () =>
                                          VisitingCardHelper.buildAndShareVisitingCard(context),
                                      child: const Text(
                                        "Invite",
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,

                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                } else {
                  return Center(
                    child: SizedBox(
                      height: 26,
                      width: 26,
                      child: SizedBox(
                          height: 26,
                          width: 26,
                          child: CircularProgressIndicator()),
                    ),
                  );
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
              bgColor: theme.colorScheme.primary,
              width: double.infinity,
              height: 48,
              onTap: _selectedUserIds.isEmpty
                  ? null
                  : () {
                print("Selected:${_selectedUserIds}");
                //   Navigator.pop(context, _selectedUserIds.toList());
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => AddNewGroupPage(
                          selectedUserIds:
                          _selectedUserIds.toList(),
                        )));
              },
              title: _selectedUserIds.isEmpty
                  ? "Select members"
                  : "Add Members (${_selectedUserIds.length})",
            ),
          ),
        )
            : null,
      ),
    );
  }
}
