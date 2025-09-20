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

class ContactsPage extends StatefulWidget {
  final String? from;
  const ContactsPage({
    super.key,
    this.from,
  });

  @override
  State<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  final chatThemeController = Get.find<ChatThemeController>();
  List<Contact> _contacts = [];
  List<ExistingNotConnected?> _filteredExisting = [];
  List<NonExistingContacts?> _filteredNonExisting = [];

  bool _isLoading = true;
  final chatViewController = Get.find<ChatViewController>();
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
      setState(() {
        _filteredExisting = details.existingNotConnected
            ?.where((c) =>
        (c.name?.toLowerCase().contains(query) ?? false) ||
            (c.contactNo?.toLowerCase().contains(query) ?? false))
            .toList() ??
            [];

        _filteredNonExisting = details.nonExistingContacts
            ?.where((c) =>
        (c.name?.toLowerCase().contains(query) ?? false) ||
            (c.contactNo?.toLowerCase().contains(query) ?? false))
            .toList() ??
            [];
      });
    }
  }

  List<Map<String, String>> getFormattedContacts() {
    return _contacts
        .where((contact) => contact.phones.isNotEmpty)
        .map((contact) => {
      ApiKeys.contact_no: contact.phones.first.number,
      ApiKeys.name: contact.displayName,
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
    chatViewController.uploadContacts(formattedContacts);
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
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: "Search contacts...",
                  prefixIcon: Icon(Icons.search),
                  filled: true,
                  fillColor: theme.colorScheme.surface,
                  contentPadding:
                  EdgeInsets.symmetric(vertical: 0, horizontal: 16),
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
                  ContactListModel? contactsListModel =
                      chatViewController.contactsListModel?.value;
                  Data? details = contactsListModel?.data;
                  if (isGroupMode) {
                    // build list from groupConnections (flat list)
                    final groupList = chatViewController.groupConnections;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18.0),
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 12),
                            CustomText(
                              "Select Group Members",
                              color: theme.colorScheme.inverseSurface,
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                            ),
                            const SizedBox(height: 4),
                            (groupList.isEmpty)
                                ? Center(child: Text("No contacts found"))
                                : ListView.builder(
                              physics: NeverScrollableScrollPhysics(),
                              shrinkWrap: true,
                              itemCount: groupList.length,
                              itemBuilder: (context, index) {
                                final item = groupList[index];
                                final String? userId =
                                    item['platform_id'] ??
                                        item['user_id'];
                                final String name =
                                (item['name'] ?? '').toString();
                                final String phone =
                                (item['contact_no'] ??
                                    item['contact'] ??
                                    '')
                                    .toString();
                                final String profileImage =
                                (item['profile_image'] ?? '')
                                    .toString();

                                final bool isSelected = userId != null &&
                                    _selectedUserIds.contains(userId);
                                return ListTile(
                                  onTap: () {
                                    if (userId == null) return;
                                    setState(() {
                                      if (isSelected) {
                                        _selectedUserIds.remove(userId);
                                      } else {
                                        _selectedUserIds.add(userId);
                                      }
                                    });
                                  },
                                  contentPadding: EdgeInsets.all(0),
                                  leading: CircleAvatar(
                                    radius: 24,
                                    backgroundImage:
                                    (profileImage.isNotEmpty)
                                        ? NetworkImage(profileImage)
                                        : null,
                                    child: (profileImage.isNotEmpty)
                                        ? null
                                        : (name.isNotEmpty)
                                        ? CustomText(
                                      name[0].toUpperCase(),
                                      fontFamily:
                                      "Rounded Mplus 1c",
                                      fontWeight:
                                      FontWeight.w400,
                                      fontSize: 20,
                                      color: theme
                                          .colorScheme.surface,
                                    )
                                        : Icon(Icons.person,
                                        color: theme
                                            .colorScheme.surface),
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
                                            // width: 60,
                                            child: CustomText(
                                              overflow:
                                              TextOverflow.ellipsis,
                                              maxLines: 1,
                                              name.isNotEmpty
                                                  ? name
                                                  : phone,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 16,
                                              fontFamily:
                                              "Rounded Mplus 1c",
                                            ),
                                          ),
                                          Checkbox(
                                            value: isSelected,
                                            onChanged: (value) {
                                              if (userId == null) return;
                                              setState(() {
                                                if (value == true) {
                                                  _selectedUserIds
                                                      .add(userId);
                                                } else {
                                                  _selectedUserIds
                                                      .remove(userId);
                                                }
                                              });
                                            },
                                          ),
                                        ],
                                      ),
                                      CustomText(
                                        phone,
                                        fontSize: 14,
                                        fontFamily: "Rounded Mplus 1c",
                                      )
                                    ],
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  }
                  if (_filteredNonExisting.isEmpty) {
                    if (details != null) {
                      _filteredExisting =
                          List.from(details.existingNotConnected ?? []);
                      _filteredNonExisting =
                          List.from(details.nonExistingContacts ?? []);
                    }
                  }
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
                              ? Center(child: CircularProgressIndicator())
                              : (_filteredExisting.isEmpty)
                              ? Center(child: Text("No contacts found"))
                              : ListView.builder(
                            physics: NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                            itemCount: _filteredExisting.length,
                            itemBuilder: (context, index) {
                              final contact =
                              _filteredExisting[index];
                              final name = contact?.name;
                              final phone =
                              (contact?.contactNo?.isNotEmpty ??
                                  false)
                                  ? contact?.contactNo
                                  : 'No number';

                              return ListTile(
                                onTap: () {
                                  final String? userId =
                                      _filteredExisting[index]?.id;
                                  final bool isSelected =
                                      userId != null &&
                                          _selectedUserIds
                                              .contains(userId);
                                  if (isGroupMode) {
                                    if (userId != null) {
                                      setState(() {
                                        if (isSelected) {
                                          _selectedUserIds
                                              .remove(userId);
                                        } else {
                                          _selectedUserIds
                                              .add(userId);
                                        }
                                      });
                                    }
                                  } else {
                                    if (details
                                        ?.existingNotConnected?[
                                    index]
                                        .id !=
                                        null) {
                                      chatViewController.openAnyOneChatFunction(
                                          type: details
                                              ?.existingNotConnected?[
                                          index]
                                              .accountType,
                                          isInitialMessage: true,
                                          userId: details
                                              ?.existingNotConnected?[
                                          index]
                                              .id,
                                          conversationId: details
                                              ?.existingNotConnected?[
                                          index]
                                              .conversationId ??
                                              '',
                                          profileImage: details
                                              ?.existingNotConnected?[
                                          index]
                                              .profileImage,
                                          contactName: details
                                              ?.existingNotConnected?[
                                          index]
                                              .name,
                                          contactNo: details
                                              ?.existingNotConnected?[
                                          index]
                                              .contactNo,
                                          //  businessId: details.existingNotConnected[index].,
                                          isFromContactList: true);
                                    }
                                  }
                                },
                                contentPadding: EdgeInsets.all(0),
                                leading: CircleAvatar(
                                  radius: 20,
                                  backgroundImage:
                                  contact?.profileImage != null
                                      ? NetworkImage(
                                      contact?.profileImage)
                                      : null,
                                  child: (contact?.profileImage !=
                                      null)
                                      ? null
                                      : (name?.isNotEmpty ?? false)
                                      ? CustomText(
                                    name![0].toUpperCase(),
                                    fontFamily:
                                    "Rounded Mplus 1c",
                                    fontWeight:
                                    FontWeight.w400,
                                    fontSize: 20,
                                    color: theme.colorScheme
                                        .surface,
                                  )
                                      : Icon(Icons.person,
                                      color: theme.colorScheme
                                          .surface),
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
                                        if (isGroupMode)
                                          Builder(builder: (context) {
                                            final String? userId =
                                                _filteredExisting[
                                                index]
                                                    ?.id;
                                            final bool isSelected =
                                                userId != null &&
                                                    _selectedUserIds
                                                        .contains(
                                                        userId);
                                            return Checkbox(
                                              value: isSelected,
                                              onChanged: (value) {
                                                if (userId == null)
                                                  return;
                                                setState(() {
                                                  if (value == true) {
                                                    _selectedUserIds
                                                        .add(userId);
                                                  } else {
                                                    _selectedUserIds
                                                        .remove(
                                                        userId);
                                                  }
                                                });
                                              },
                                            );
                                          }),
                                      ],
                                    ),
                                    (name == null)
                                        ? SizedBox()
                                        : CustomText(
                                      (contact?.accountType=="INDIVIDUAL")?(contact?.designation=="")?phone:(contact?.designation??'$phone'):"",
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
                              : (_filteredNonExisting.isEmpty)
                              ? Center(child: Text("No contacts found"))
                              : ListView.builder(

                            physics:
                            const NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                            itemCount: _filteredNonExisting.length,
                            itemBuilder: (context, index) {
                              final contact =
                              _filteredNonExisting[index];
                              final rawName = contact?.name ?? "";
                              final phone =
                              (contact?.contactNo?.isNotEmpty ??
                                  false)
                                  ? contact!.contactNo
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
                  return SizedBox();
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
