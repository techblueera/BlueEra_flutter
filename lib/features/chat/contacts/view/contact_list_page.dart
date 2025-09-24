import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_theme_controller.dart';
import 'package:BlueEra/features/chat/view/group_chat/add_new_group_page.dart';
import 'package:BlueEra/features/common/auth/views/screens/visiting_card_page.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/visiting_card_helper.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart'; // for compute

import '../../../../core/api/apiService/api_response.dart';
import '../../../../core/constants/shared_preference_utils.dart';
import '../../../../widgets/custom_btn.dart';
import '../../auth/controller/chat_view_controller.dart';
import '../../auth/model/contactListModel.dart';

class ContactsPage extends StatefulWidget {
  final String? from;
  const ContactsPage({super.key, this.from});

  @override
  State<ContactsPage> createState() => _ContactsPageState();
}

class _ContactsPageState extends State<ContactsPage> {
  final chatThemeController = Get.find<ChatThemeController>();
  final chatViewController = Get.find<ChatViewController>();
  final TextEditingController _searchController = TextEditingController();

  List<ExistingNotConnected?> _filteredExisting = [];
  List<NonExistingContacts?> _filteredNonExisting = [];
  final Set<String> _selectedUserIds = <String>{};

  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    if (widget.from == "Group") {
      chatViewController.loadGroupConnections();
    } else {
      _loadContactsFromStorage();
    }
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
    log("slkdmcklmslksdmclsdkc ${storedData}");
    if (storedData != null) {
      // decode in background
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
          "displayName": c.displayName ?? "",
          "phones": c.phones.map((p) => p.number ?? "").toList(),
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Permission denied")),
        );
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
                  final existing =
                      details?.existingNotConnected ?? <ExistingNotConnected>[];
                  final nonExisting =
                      details?.nonExistingContacts ?? <NonExistingContacts>[];

                  if (_filteredExisting.isEmpty &&
                      _filteredNonExisting.isEmpty &&
                      _searchController.text.isEmpty) {
                    _filteredExisting = List.from(existing);
                    _filteredNonExisting = List.from(nonExisting);
                  }

                  if (isGroupMode) {
                    final groupList = chatViewController.groupConnections;
                    return ListView.builder(physics: NeverScrollableScrollPhysics(),
                      itemCount: groupList.length,
                      itemBuilder: (context, index) {
                        final item = groupList[index];
                        return _GroupContactTile(
                          item: item,
                          isSelected: _selectedUserIds
                              .contains(item['platform_id'] ?? item['user_id']),
                          onSelect: (id) {
                            setState(() {
                              if (_selectedUserIds.contains(id)) {
                                _selectedUserIds.remove(id);
                              } else {
                                _selectedUserIds.add(id);
                              }
                            });
                          },
                        );
                      },
                    );
                  }

                  // Normal contacts (with two sections)
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
                            selectedUserIds: _selectedUserIds,
                            onSelect: (id) {
                              setState(() {
                                if (_selectedUserIds.contains(id)) {
                                  _selectedUserIds.remove(id);
                                } else {
                                  _selectedUserIds.add(id);
                                }
                              });
                            },
                            chatViewController: chatViewController,
                          );
                        },
                      ),

                    _SectionTitle("Invite to BlueEra", theme),
                    if ((_searchController.text.isEmpty ? nonExisting.isEmpty : _filteredNonExisting.isEmpty))
                      const Center(child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text("No contacts found"),
                      ))
                    else
                      ...List.generate(
                        _searchController.text.isEmpty ? nonExisting.length : _filteredNonExisting.length,
                            (index) {
                          final contact = _searchController.text.isEmpty
                              ? nonExisting[index]
                              : _filteredNonExisting[index];
                          return _NonExistingContactTile(contact: contact);
                        },
                      ),
                  ],
                  );
                  ;
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
              bgColor: theme.colorScheme.primary,
              width: double.infinity,
              height: 48,
              onTap: _selectedUserIds.isEmpty
                  ? null
                  : () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AddNewGroupPage(
                      selectedUserIds: _selectedUserIds.toList(),
                    ),
                  ),
                );
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

class _GroupContactTile extends StatelessWidget {
  final Map<String, dynamic> item;
  final bool isSelected;
  final void Function(String id) onSelect;

  const _GroupContactTile({
    required this.item,
    required this.isSelected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userId = item['platform_id'] ?? item['user_id'];
    final name = (item['name'] ?? '').toString();
    final phone =
    (item['contact_no'] ?? item['contact'] ?? '').toString();
    final profileImage = (item['profile_image'] ?? '').toString();

    return ListTile(
      onTap: () => onSelect(userId),
      leading: CircleAvatar(
        radius: 24,
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
      title: Text(name.isNotEmpty ? name : phone,
          style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(phone),
      trailing: Checkbox(
        value: isSelected,
        onChanged: (_) => onSelect(userId),
      ),
    );
  }
}

class _ExistingContactTile extends StatelessWidget {
  final ExistingNotConnected? contact;
  final bool isGroupMode;
  final Set<String> selectedUserIds;
  final void Function(String id) onSelect;
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

    final isSelected = selectedUserIds.contains(userId);

    return ListTile(
      onTap: () {
        if (isGroupMode) {
          if (userId.isNotEmpty) onSelect(userId);
        } else {
          if (contact?.id != null) {
            chatViewController.openAnyOneChatFunction(
              type: contact?.accountType,
              isInitialMessage: true,
              userId: contact?.id,
              conversationId: contact?.conversationId ?? '',
              profileImage: contact?.profileImage,
              contactName: contact?.name,
              contactNo: contact?.contactNo,
              isFromContactList: true,
            );
          }
        }
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
      title: Text(name.isNotEmpty ? name : phone,
          style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: name.isNotEmpty
          ? Text(
        (contact?.accountType == "INDIVIDUAL")
            ? (contact?.designation?.isNotEmpty ?? false)
            ? contact!.designation!
            : phone
            : "",
      )
          : null,
      trailing: isGroupMode
          ? Checkbox(
        value: isSelected,
        onChanged: (_) => onSelect(userId),
      )
          : null,
    );
  }
}

class _NonExistingContactTile extends StatelessWidget {
  final NonExistingContacts? contact;
  const _NonExistingContactTile({required this.contact});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = contact?.name ?? "";
    final phone = contact?.contactNo ?? "No number";
    final firstLetter = name.isNotEmpty ? name[0].toUpperCase() : "?";

    return ListTile(
      leading: CircleAvatar(
        radius: 20,
        child: CustomText(
          firstLetter,
          fontSize: 20,
          color: theme.colorScheme.surface,
        ),
      ),
      title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(phone),
      trailing: TextButton(
        onPressed: () =>
            VisitingCardHelper.buildAndShareVisitingCard(context),
        child: const Text("Invite",
            style: TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }
}
