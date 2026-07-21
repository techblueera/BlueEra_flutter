import 'dart:async';

import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_view_controller.dart';
import 'package:BlueEra/features/contacts/controller/contact_sync_controller.dart';
import 'package:BlueEra/features/contacts/model/blue_era_contact.dart';
import 'package:BlueEra/widgets/cached_avatar_widget.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/empty_state_widget.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// "Contacts on BlueEra" — the people already in the user's phonebook who have
/// a BlueEra account, rendered under the name the USER saved them as.
///
/// Backed by `GET contact-service/api/contacts/on-blueera`. Pull-to-refresh
/// re-checks matches server-side (`POST /rebuild`) instead of re-uploading the
/// phonebook.
class BlueEraContactsScreen extends StatefulWidget {
  const BlueEraContactsScreen({super.key});

  @override
  State<BlueEraContactsScreen> createState() => _BlueEraContactsScreenState();
}

class _BlueEraContactsScreenState extends State<BlueEraContactsScreen> {
  final ContactSyncController controller =
      getOrPut(() => ContactSyncController());
  final ChatViewController chatViewController =
      getOrPut(() => ChatViewController());

  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    controller.loadBlueEraContacts(page: 1);
    _scrollController.addListener(_onScroll);
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - SizeConfig.size200) {
      controller.loadMoreBlueEraContacts();
    }
  }

  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      // Server-side name-prefix search — always restarts at page 1.
      controller.loadBlueEraContacts(
          page: 1, search: _searchController.text.trim());
    });
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig.init(context);
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: CommonBackAppBar(title: AppStrings.contactsOnBlueEra),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(
                horizontal: SizeConfig.size15, vertical: SizeConfig.size10),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: AppStrings.searchContacts.tr,
                prefixIcon: const Icon(Icons.search),
                isDense: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(SizeConfig.size10),
                ),
              ),
            ),
          ),
          Expanded(
            child: Obx(() {
              final status = controller.blueEraContactsResponse.value.status;
              final contacts = controller.blueEraContacts;

              if (status == Status.INITIAL || status == Status.LOADING) {
                return const Center(child: CircularProgressIndicator());
              }
              if (status == Status.ERROR && contacts.isEmpty) {
                return EmptyStateWidget(
                  message: controller.blueEraContactsResponse.value.message ??
                      AppStrings.somethingWentWrong,
                  actionText: AppStrings.retry.tr,
                  actionCallback: () =>
                      controller.loadBlueEraContacts(page: 1),
                );
              }
              if (contacts.isEmpty) {
                return RefreshIndicator(
                  onRefresh: controller.refreshBlueEraContacts,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      SizedBox(height: SizeConfig.size100),
                      EmptyStateWidget(
                          message: AppStrings.noContactsOnBlueEra),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: controller.refreshBlueEraContacts,
                child: ListView.separated(
                  controller: _scrollController,
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount:
                      contacts.length + (controller.isLoadingMore.value ? 1 : 0),
                  separatorBuilder: (_, __) => Divider(
                      height: 1, color: AppColors.greyE0),
                  itemBuilder: (context, index) {
                    if (index >= contacts.length) {
                      return Padding(
                        padding: EdgeInsets.all(SizeConfig.size15),
                        child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 2)),
                      );
                    }
                    return _contactTile(contacts[index]);
                  },
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _contactTile(BlueEraContact contact) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size15, vertical: SizeConfig.size5),
      leading: CachedAvatarWidget(
        imageUrl: null,
        size: SizeConfig.size45,
        borderRadius: SizeConfig.size30,
      ),
      // The user's OWN phonebook name — never the platform name.
      title: CustomText(
        contact.name.isNotEmpty ? contact.name : contact.phone,
        fontWeight: FontWeight.w600,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: CustomText(contact.phone,
          fontSize: SizeConfig.small, color: AppColors.grey83),
      trailing: TextButton(
        onPressed: () => _openChat(contact),
        child: CustomText(AppStrings.messageAction,
            color: AppColors.primaryColor, fontWeight: FontWeight.w600),
      ),
      onTap: () => _openProfile(contact),
    );
  }

  void _openProfile(BlueEraContact contact) {
    final id = contact.userId ?? '';
    if (id.isEmpty) return;
    redirectToProfileScreen(
      accountType: AppConstants.individual,
      profileId: id,
    );
  }

  void _openChat(BlueEraContact contact) {
    final id = contact.userId ?? '';
    if (id.isEmpty) return;
    chatViewController.checkChatConnectionAndOpenChat(
      userId: id,
      name: contact.name,
      conductNo: contact.phone,
    );
  }
}
