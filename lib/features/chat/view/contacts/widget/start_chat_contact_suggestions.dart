import 'dart:convert';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_view_controller.dart';
import 'package:BlueEra/features/chat/auth/model/contactListModel.dart';
import 'package:BlueEra/features/chat/view/widget/component_widgets.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

/// Shown INSTEAD of the plain "no chats found" placeholder when the personal
/// chat list has nothing in it but the BlueEra broadcast thread.
///
/// A brand-new user has no conversation to tap, so the list would otherwise be
/// a dead end. This renders the phonebook contacts that are already on BlueEra
/// as chat-list rows with a "Chat" button, so the first conversation can be
/// started without hunting for the floating "+" → My Contacts screen.
///
/// It deliberately reuses the SAME data path as that screen
/// (`ChatViewController.uploadContacts` → `chat-service/connections/sync`,
/// cached in Hive / secure storage), so entering an empty chat list costs at
/// most one sync — and usually nothing at all, because the Connect tab has
/// already hydrated it.
class StartChatContactSuggestions extends StatefulWidget {
  const StartChatContactSuggestions({super.key});

  @override
  State<StartChatContactSuggestions> createState() =>
      _StartChatContactSuggestionsState();
}

class _StartChatContactSuggestionsState
    extends State<StartChatContactSuggestions> {
  final chatViewController = getOrPut(() => ChatViewController());

  /// Only the first load blocks with a spinner — once contacts are in memory
  /// every later rebuild renders straight from the controller.
  bool _isLoading = true;

  /// True when we have no cached contacts AND contacts permission hasn't been
  /// granted, so the only thing we can show is a "find contacts" CTA. We never
  /// pop the OS permission dialog on our own here: the chat list is not a
  /// place the user asked for contact access.
  bool _needsPermission = false;

  /// Set when the permission was permanently denied, so the CTA sends the user
  /// to app settings instead of re-requesting (which would silently no-op).
  bool _permissionPermanentlyDenied = false;

  /// Guards against two hydrations running at once (initState + CTA tap).
  bool _hydrating = false;

  @override
  void initState() {
    super.initState();
    // Already synced (the Connect tab hydrates on entry, and this widget is
    // rebuilt every time it scrolls back into view) — render straight away
    // instead of flashing a spinner over data we already hold.
    if (chatViewController.contactsListModel?.value.data != null) {
      _isLoading = false;
      return;
    }
    _hydrate();
  }

  /// Memory → Hive → secure storage → phonebook, stopping at the first hit.
  ///
  /// [requestPermission] is only true when the user tapped the CTA, i.e. asked
  /// for this explicitly.
  Future<void> _hydrate({bool requestPermission = false}) async {
    if (_hydrating) return;
    _hydrating = true;
    if (mounted) {
      setState(() {
        _isLoading = true;
        _needsPermission = false;
      });
    }
    try {
      // 1. Already in memory, or in the Hive cache the contacts screen writes.
      if (await chatViewController.hydrateContactsFromCache()) return;

      // 2. The secure-storage snapshot the "+" → My Contacts screen reads.
      final stored = await SharedPreferenceUtils.getSecureValue(
          SharedPreferenceUtils.saved_contacts);
      if (stored != null && stored.isNotEmpty) {
        final decoded = await compute<String, dynamic>(jsonDecode, stored);
        if (decoded is Map<String, dynamic>) {
          chatViewController.loadContactsFromLocalStorage(decoded);
          return;
        }
      }

      // 3. Nothing cached — read the phonebook and sync it, exactly like the
      //    contacts screen does.
      var status = await Permission.contacts.status;
      if (!status.isGranted && requestPermission) {
        status = await Permission.contacts.request();
      }
      if (!status.isGranted) {
        _needsPermission = true;
        _permissionPermanentlyDenied = status.isPermanentlyDenied;
        return;
      }

      final contacts = await FlutterContacts.getContacts(withProperties: true);
      final formatted = contacts
          .where((c) => c.phones.isNotEmpty)
          .map<Map<String, dynamic>>((c) => {
                ApiKeys.contact_no: c.phones.first.number,
                ApiKeys.name: c.displayName,
              })
          .toList();
      if (formatted.isEmpty) return;
      await chatViewController.uploadContacts(formatted);
    } catch (_) {
      // Never blow up the chat list over a suggestion strip — the plain empty
      // state below is a fine fallback.
    } finally {
      _hydrating = false;
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openChat(ExistingNotConnected contact) {
    final userId = contact.id ?? '';
    if (userId.isEmpty) return;
    chatViewController.checkChatConnectionAndOpenChat(
      userId: userId,
      isFromContactList: true,
      name: contact.name,
      conductNo: contact.contactNo,
      profile: contact.profileImage,
      route: AppConstants.route_contact,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: SizedBox(
              height: 26, width: 26, child: CircularProgressIndicator()),
        ),
      );
    }

    if (_needsPermission) return _permissionCta();

    return Obx(() {
      final contacts = chatViewController
              .contactsListModel?.value.data?.existingNotConnected ??
          <ExistingNotConnected>[];
      if (contacts.isEmpty) return noChatsFound();

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _header(contacts.length),
          ...contacts.map(_contactRow),
          const SizedBox(height: 12),
        ],
      );
    });
  }

  Widget _header(int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CustomText(
            "Start a conversation",
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
          const SizedBox(height: 4),
          CustomText(
            "$count of your contacts are on BlueEra",
            fontSize: 12.5,
            color: Colors.grey.shade600,
          ),
        ],
      ),
    );
  }

  Widget _contactRow(ExistingNotConnected contact) {
    final name = contact.name ?? '';
    final phone = contact.contactNo ?? '';
    final profileImage = contact.profileImage ?? '';
    // Business rows carry no designation worth showing, so they fall back to
    // the number just like the My Contacts screen.
    final subtitle = (contact.accountType == AppConstants.INDIVIDUAL &&
            (contact.designation?.isNotEmpty ?? false))
        ? contact.designation!
        : phone;

    return InkWell(
      onTap: () => _openChat(contact),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: AppColors.primaryColor.withValues(alpha: 0.12),
              backgroundImage: profileImage.isNotEmpty
                  ? CachedNetworkImageProvider(profileImage)
                  : null,
              child: profileImage.isEmpty
                  ? CustomText(
                      name.isNotEmpty ? name[0].toUpperCase() : "?",
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryColor,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomText(
                    name.isNotEmpty ? name : phone,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    CustomText(
                      subtitle,
                      fontSize: 12.5,
                      color: Colors.grey.shade600,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 10),
            _chatButton(contact),
          ],
        ),
      ),
    );
  }

  Widget _chatButton(ExistingNotConnected contact) {
    return InkWell(
      onTap: () => _openChat(contact),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.primaryColor,
          borderRadius: BorderRadius.circular(20),
        ),
        child: CustomText(
          "Chat",
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.white,
        ),
      ),
    );
  }

  /// No cached contacts and no permission — offer the sync instead of leaving
  /// a blank list.
  Widget _permissionCta() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.contacts_outlined, size: 54, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          CustomText(
            "No chats yet",
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          const SizedBox(height: 6),
          CustomText(
            "Allow contact access to see who from your phonebook is already on BlueEra.",
            fontSize: 12.5,
            textAlign: TextAlign.center,
            color: Colors.grey.shade600,
          ),
          const SizedBox(height: 14),
          InkWell(
            onTap: () async {
              if (_permissionPermanentlyDenied) {
                await openAppSettings();
                return;
              }
              await _hydrate(requestPermission: true);
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
              decoration: BoxDecoration(
                color: AppColors.primaryColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: CustomText(
                "Find contacts",
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: AppColors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
