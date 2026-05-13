import 'dart:io';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_enum.dart';
import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/chat/auth/controller/chat_view_controller.dart';
import 'package:BlueEra/features/chat/view/business_chat/business_chat_list.dart';
import 'package:BlueEra/features/common/feed/view/feed_screen.dart';
import 'package:BlueEra/features/common/home/widgets/drawer.dart';
import 'package:BlueEra/features/me/vehicle/controller/vehicle_controller.dart';
import 'package:BlueEra/features/me/vehicle/model/vehicle_models.dart';
import 'package:BlueEra/features/me/vehicle/view/widgets/vehicle_card.dart';
import 'package:BlueEra/features/me/vehicle/view/widgets/vehicle_contact_form_sheet.dart';
import 'package:BlueEra/features/me/vehicle/view/widgets/vehicle_form_sheet.dart';
import 'package:BlueEra/features/personal/auth/controller/view_personal_details_controller.dart';
import 'package:BlueEra/widgets/cached_avatar_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/refer_earn_pill.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

/// Vehicle "me" profile home (v2) — owner-side dashboard for the
/// `vehicle-service` microservice documented in
/// `lib/docs/FLUTTER_INTEGRATION_GUIDE.md`.
///
/// Shell mirrors `professionals_main.dart` / `lab_home_screen_v2.dart`
/// (gradient top bar, pill tab strip, scrollable body) with the five
/// tabs adapted to vehicle ownership: Inquiry, Overview, Vehicles,
/// Posts, Stats. Owner-only — public browsing happens through
/// [VehicleListingScreen] in the Discover flow.
class VehicleHomeScreenV2 extends StatefulWidget {
  const VehicleHomeScreenV2({super.key});

  @override
  State<VehicleHomeScreenV2> createState() => _VehicleHomeScreenV2State();
}

class _VehicleHomeScreenV2State extends State<VehicleHomeScreenV2> {
  final VehicleController _ctrl =
      getOrPut(() => VehicleController(), permanent: true);

  // Drives the inquiry list shown under the Inquiry tab — same
  // controller the Connect screen uses, so socket-driven updates land
  // on both. Mirrors `lab_home_screen_v2` / `professionals_main`.
  final ChatViewController _chatViewController =
      getOrPut(() => ChatViewController());

  bool _isGoLive = false;
  int _selectedTab = 1; // default to Overview, like professionals_main

  static const _tabs = [
    'Inquiry',
    'Overview',
    'Vehicles',
    'Posts',
    'Stats',
  ];

  @override
  void initState() {
    super.initState();
    _ctrl.fetchMyVehicles();
    _ctrl.fetchMyContacts(showProgress: false);
    _ctrl.fetchMyGallery(showProgress: false);
    // Hydrate the business chat list for the Inquiry tab.
    _chatViewController.emitEvent(
      ChatEmitEvents.ChatList,
      {ApiKeys.type: AppConstants.business_Chat_Type},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEAF2FB),

      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            _buildPatternBackground(),
            Column(
              children: [
                _buildTopBar(),

                Expanded(
                  child: RefreshIndicator(
                    // Pull-to-refresh hydrates fleet + gallery + contacts
                    // in parallel — gallery and contacts both render
                    // inside the Overview tab so every section the user
                    // can see must refresh on every pull.
                    onRefresh: () async {
                      await Future.wait([
                        _ctrl.fetchMyVehicles(showProgress: false),
                        _ctrl.fetchMyGallery(showProgress: false),
                        _ctrl.fetchMyContacts(showProgress: false),
                      ]);
                    },
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.only(
                        bottom: kBottomNavigationBarHeight + 30,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: SizeConfig.size10),
                          _buildTabsCard(),
                          SizedBox(height: SizeConfig.size12),
                          _buildTabContent(),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      floatingActionButton: _selectedTab == 2
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.primaryColor,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const CustomText(
                'Add vehicle',
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
              onPressed: (){
                Get.to(VehicleContactFormSheet());

              },
              // onPressed: _onAddVehicle,
            )
          : null,
    );
  }

  // ─── Tab body ───────────────────────────────────────────────────
  Widget _buildTabContent() {
    switch (_selectedTab) {
      case 0:
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.65,
          child: const BusinessChatsList(),
        );
      case 1:
        return _OverviewTab(
          controller: _ctrl,
          onAdd: _onAddVehicle,
          onAddGalleryPhoto: _onAddGalleryPhoto,
          onDeleteGalleryItem: _confirmDeleteGalleryItem,
          onAddContact: _onAddContact,
          onEditContact: _onEditContact,
          onDeleteContact: _confirmDeleteContact,
        );
      case 2:
        return _VehiclesTab(
          controller: _ctrl,
          onEdit: _onEditVehicle,
          onDelete: _confirmDelete,
        );
      case 3:
        // Embed feed filtered to the user's posts — same hook
        // professionals_main uses.
        return SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: FeedScreen(postFilterType: PostType.myPosts),
        );
      case 4:
        return _StatsTab(controller: _ctrl);
      default:
        return const SizedBox.shrink();
    }
  }

  // ─── Background pattern ─────────────────────────────────────────
  Widget _buildPatternBackground() {
    return Positioned.fill(
      child: Image.asset(
        AppImageAssets.chatDefaultBg,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            Container(color: const Color(0xFFEAF2FB)),
      ),
    );
  }

  // ─── Top bar (gradient, mirrors lab_home_screen_v2) ─────────────
  Widget _buildTopBar() {
    final topInset = MediaQuery.of(context).padding.top;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        SizeConfig.size12,
        topInset + SizeConfig.size8,
        SizeConfig.size12,
        SizeConfig.size10,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1E88FF), Color(0xFF0040A0)],
        ),
      ),
      child: Row(
        children: [
          _circleIconButton(icon: Icons.menu, onTap: _openDrawer),
          SizedBox(width: SizeConfig.size8),
          const ReferEarnPill(),
          const Spacer(),
          SizedBox(width: SizeConfig.size2),
          _circleIconButton(
            icon: Icons.notifications_none,
            onTap: _openNotifications,
          ),
          SizedBox(width: SizeConfig.size8),
          _goLivePill(),
        ],
      ),
    );
  }

  void _openDrawer() {
    showDialog(
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.3),
      useSafeArea: false,
      context: context,
      builder: (_) => Align(
        alignment: Alignment.centerLeft,
        child: SizedBox(
          height: double.infinity,
          child: Drawer(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: ProfileMenuDrawer(),
          ),
        ),
      ),
    );
  }

  void _openNotifications() {
    Navigator.pushNamed(context, RouteHelper.getNotificationScreenRoute());
  }

  Widget _circleIconButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        height: SizeConfig.size36,
        width: SizeConfig.size36,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 20, color: AppColors.mainTextColor),
      ),
    );
  }

  Widget _goLivePill() {
    return GestureDetector(
      onTap: () => setState(() => _isGoLive = !_isGoLive),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size10,
          vertical: SizeConfig.size6,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CustomText(
              'Go live',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.mainTextColor,
            ),
            SizedBox(width: SizeConfig.size6),
            Container(
              width: 30,
              height: 18,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: _isGoLive
                    ? AppColors.primaryColor
                    : Colors.grey.shade400,
                borderRadius: BorderRadius.circular(20),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 180),
                alignment: _isGoLive
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Container(
                  height: 14,
                  width: 14,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Tabs row (pill chips, mirrors lab_home_screen_v2) ──────────
  Widget _buildTabsCard() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(_tabs.length, (i) {
            final selected = i == _selectedTab;
            return Padding(
              padding: EdgeInsets.symmetric(horizontal: SizeConfig.size4),
              child: GestureDetector(
                onTap: () => setState(() => _selectedTab = i),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: SizeConfig.size16,
                    vertical: SizeConfig.size6,
                  ),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.primaryColor : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected
                          ? AppColors.primaryColor
                          : Colors.grey.shade300,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: CustomText(
                    _tabs[i],
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : AppColors.mainTextColor,
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  // ─── Add / edit / delete handlers ───────────────────────────────
  // The vehicle form was previously a `showModalBottomSheet` — it's
  // now a full-screen page (`VehicleFormSheet` renders as a Scaffold)
  // so long forms scroll comfortably and the keyboard never collapses
  // the form on small devices.
  Future<void> _onAddVehicle() async {
    final result = await Navigator.of(context).push<VehicleFormResult>(
      MaterialPageRoute(
        builder: (_) => const VehicleFormSheet(),
        fullscreenDialog: true,
      ),
    );
    if (result == null) return;
    await _ctrl.createVehicle(
      draft: result.draft,
      coverImageFile: result.coverFile,
      imageFiles: result.imageFiles,
    );
  }

  Future<void> _onEditVehicle(Vehicle v) async {
    final result = await Navigator.of(context).push<VehicleFormResult>(
      MaterialPageRoute(
        builder: (_) => VehicleFormSheet(initial: v),
        fullscreenDialog: true,
      ),
    );
    if (result == null || v.id == null) return;
    final patch = result.draft.toCreateJson();
    await _ctrl.updateVehicle(id: v.id!, patch: patch);
    if (result.coverFile != null) {
      final coverUrl = await _ctrl.uploadFile(result.coverFile!);
      if (coverUrl != null) {
        await _ctrl.updateVehicle(id: v.id!, patch: {'cover_image': coverUrl});
      }
    }
    if (result.imageFiles.isNotEmpty) {
      await _ctrl.addVehicleImagesFromFiles(
        id: v.id!,
        files: result.imageFiles,
      );
    }
  }

  // ─── Gallery actions ────────────────────────────────────────────
  /// Pick a single image from the gallery and upload it to the
  /// vehicle service via the controller's existing 2-step flow
  /// (S3 presigned PUT → POST gallery item). Reused image_picker
  /// instance is fine — `pickImage` is stateless on the plugin side.
  Future<void> _onAddGalleryPhoto() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (picked == null) return;
      await _ctrl.addGalleryFromFile(File(picked.path));
    } catch (_) {
      // The controller already surfaces a snackbar on failure; we just
      // need to swallow PlatformExceptions (permission denial etc.) so
      // they don't crash the screen.
    }
  }

  Future<void> _confirmDeleteGalleryItem(VehicleGalleryItem g) async {
    if (g.id == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove photo'),
        content: const Text(
          'This photo will be removed from your public gallery.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _ctrl.deleteGalleryItem(g.id!);
    }
  }

  // ─── Contact-us actions ─────────────────────────────────────────
  /// Open the contact form with no initial value, then POST to the
  /// vehicle service via the controller. The controller refreshes
  /// `myContacts` on success so the list updates without us having to
  /// touch local state.
  Future<void> _onAddContact() async {
    final draft = await Navigator.of(context).push<VehicleContact>(
      MaterialPageRoute(
        // builder: (_) => const HomeD(),
        builder: (_) => const VehicleContactFormSheet(),
        fullscreenDialog: false,
      ),
    );
    if (draft == null) return;
    await _ctrl.addContact(draft);
  }

  /// Edit existing contact. We submit a partial PATCH (`toCreateJson`
  /// drops null fields) so the server retains anything the form
  /// doesn't expose (e.g. lat/lon picked from a future map widget).
  Future<void> _onEditContact(VehicleContact c) async {
    final patched = await Navigator.of(context).push<VehicleContact>(
      MaterialPageRoute(
        builder: (_) => VehicleContactFormSheet(initial: c),
        fullscreenDialog: true,
      ),
    );
    if (patched == null || c.id == null) return;
    await _ctrl.updateContact(id: c.id!, patch: patched.toCreateJson());
  }

  Future<void> _confirmDeleteContact(VehicleContact c) async {
    if (c.id == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove contact'),
        content: Text(
          'Remove ${c.locationName.isNotEmpty ? c.locationName : "this contact"}? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remove', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _ctrl.deleteContact(c.id!);
    }
  }

  Future<void> _confirmDelete(Vehicle v) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete vehicle'),
        content: Text(
          'Remove ${v.name}? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (ok == true && v.id != null) {
      await _ctrl.deleteVehicle(v.id!);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────
// Tab bodies
// ─────────────────────────────────────────────────────────────────────

class _OverviewTab extends StatelessWidget {
  final VehicleController controller;
  final VoidCallback onAdd;
  // Gallery hooks live on the parent State (it owns the BuildContext
  // for `showDialog` + the ImagePicker invocation) and are forwarded
  // here so the embedded gallery section can fire them directly.
  final Future<void> Function() onAddGalleryPhoto;
  final Future<void> Function(VehicleGalleryItem) onDeleteGalleryItem;
  // Contact-us hooks — same reasoning as gallery: routed back to the
  // parent state so navigation + dialogs use the screen's BuildContext.
  final Future<void> Function() onAddContact;
  final Future<void> Function(VehicleContact) onEditContact;
  final Future<void> Function(VehicleContact) onDeleteContact;

  const _OverviewTab({
    required this.controller,
    required this.onAdd,
    required this.onAddGalleryPhoto,
    required this.onDeleteGalleryItem,
    required this.onAddContact,
    required this.onEditContact,
    required this.onDeleteContact,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Full-width identity card — name + joining date pulled from
          // the shared personal-profile controller (same source the
          // professionals dashboard uses). Constrained to maxWidth via
          // the parent padding so it expands edge-to-edge on every
          // device size, with a Row laid out in a LayoutBuilder so the
          // pill never overflows on narrow screens.
          const _IdentityHeaderCard(),
          SizedBox(height: SizeConfig.size12),
          _StatsRow(controller: controller),
          SizedBox(height: SizeConfig.size16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CustomText(
                'My fleet',
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.mainTextColor,
              ),
              TextButton.icon(
                onPressed: onAdd,
                icon: Icon(Icons.add, size: 18, color: AppColors.primaryColor),
                label: CustomText(
                  'Add',
                  color: AppColors.primaryColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          SizedBox(height: SizeConfig.size8),
          Obx(() {
            final state = controller.myVehiclesState.value.status;
            if (state == Status.LOADING && controller.myVehicles.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 30),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (controller.myVehicles.isEmpty) {
              return _EmptyState(
                title: 'No vehicles yet',
                subtitle:
                    'Add a vehicle to start showing it on your public profile.',
                cta: 'Add a vehicle',
                onTap: onAdd,
              );
            }
            return SizedBox(
              height: 200,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: controller.myVehicles.length,
                separatorBuilder: (_, __) =>
                    SizedBox(width: SizeConfig.size12),
                itemBuilder: (_, i) => SizedBox(
                  width: 280,
                  child: VehicleCard(
                    vehicle: controller.myVehicles[i],
                    compact: true,
                  ),
                ),
              ),
            );
          }),
          SizedBox(height: SizeConfig.size16),
          // Gallery section — embedded inside Overview (no separate
          // tab) using the same 1 / 2 / 3 / 4+ collage layout the
          // hospital overview uses (`HospitalHomeGalleryWidget`):
          //   • 1 photo  → full-width single tile
          //   • 2 photos → side-by-side
          //   • 3 photos → 1 large left, 2 stacked right
          //   • 4+ photos → 2×2 grid with `+N` overlay on the last cell
          _OverviewGallerySection(
            controller: controller,
            onAdd: onAddGalleryPhoto,
            onDelete: onDeleteGalleryItem,
          ),
          SizedBox(height: SizeConfig.size16),
          // Contact-us section — modelled after `HospitalContactUsView`
          // (same title row + edit affordance, per-contact expansion
          // tile with website / phone / email / address). Sourced from
          // `controller.myContacts`, mutated via the parent state's
          // add / edit / delete handlers wired to the controller's
          // existing contact CRUD methods.
          _OverviewContactUsSection(
            controller: controller,
            onAdd: onAddContact,
            onEdit: onEditContact,
            onDelete: onDeleteContact,
          ),
        ],
      ),
    );
  }
}

/// Vehicle-side echo of `HospitalHomeGalleryWidget`. Renders the
/// gallery photos with the same 1/2/3/4+ collage rules so the owner's
/// dashboard reads consistently across services. Tap any tile to open
/// a full-screen pinch-zoom viewer; tap the small × on a tile to
/// remove it (with a confirm dialog handled by the parent state).
class _OverviewGallerySection extends StatelessWidget {
  final VehicleController controller;
  final Future<void> Function() onAdd;
  final Future<void> Function(VehicleGalleryItem) onDelete;

  const _OverviewGallerySection({
    required this.controller,
    required this.onAdd,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CustomText(
              'Gallery',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.mainTextColor,
            ),
            // Edit affordance on the right side of the header — same
            // `add_circle_outline` / `edit_outlined` swap the hospital
            // gallery uses, so the icon hints at "fresh upload" when
            // empty and "manage" when there's already content.
            Obx(() {
              final empty = controller.myGallery.isEmpty;
              return IconButton(
                onPressed: onAdd,
                tooltip: empty ? 'Add photo' : 'Add more',
                icon: Icon(
                  empty ? Icons.add_circle_outline : Icons.add_a_photo_rounded,
                  size: 22,
                  color: AppColors.primaryColor,
                ),
              );
            }),
          ],
        ),
        SizedBox(height: SizeConfig.size8),
        Obx(() {
          // Show a spinner while the very first upload is in flight
          // — `isUploadingMedia` flips inside `addGalleryFromFile`.
          if (controller.isUploadingMedia.value &&
              controller.myGallery.isEmpty) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 30),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          if (controller.myGallery.isEmpty) {
            return _EmptyState(
              title: 'No photos yet',
              subtitle:
                  'Add photos of your vehicles, livery and workspace to make your public profile stand out.',
              cta: 'Add a photo',
              onTap: onAdd,
            );
          }
          return _GalleryCollage(
            items: controller.myGallery,
            onDelete: onDelete,
          );
        }),
      ],
    );
  }
}

/// Vehicle-side echo of `HospitalContactUsView`. Shows the contact
/// list as a card with a section header (edit/add icon on the right)
/// followed by an `ExpansionTile` per contact carrying website /
/// phone / email / address / hours rows. Rows that look like links
/// (`url`, `mailto:`, `tel:`) are tap-launchable via `url_launcher`.
class _OverviewContactUsSection extends StatelessWidget {
  final VehicleController controller;
  final Future<void> Function() onAdd;
  final Future<void> Function(VehicleContact) onEdit;
  final Future<void> Function(VehicleContact) onDelete;

  const _OverviewContactUsSection({
    required this.controller,
    required this.onAdd,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            CustomText(
              'Contact us',
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.mainTextColor,
            ),
            // Mirrors `HospitalContactUsView`'s icon affordance —
            // `add_circle_outline` when empty, `edit_outlined` when
            // there's at least one contact already saved.
            Obx(() {
              final empty = controller.myContacts.isEmpty;
              return IconButton(
                onPressed: onAdd,
                tooltip: empty ? 'Add contact' : 'Add another',
                icon: Icon(
                  empty
                      ? Icons.add_circle_outline
                      : Icons.add_location_alt_outlined,
                  size: 22,
                  color: AppColors.primaryColor,
                ),
              );
            }),
          ],
        ),
        SizedBox(height: SizeConfig.size8),
        Obx(() {
          if (controller.myContacts.isEmpty) {
            return _EmptyState(
              title: 'No contact info yet',
              subtitle:
                  'Add your branch address, phone and email so customers can reach you.',
              cta: 'Add a contact',
              onTap: onAdd,
            );
          }
          // Sort: primary contact first, then preserve server order —
          // matches the public discover view's expectation.
          final contacts = controller.myContacts.toList()
            ..sort((a, b) {
              final aP = a.isPrimary ?? false;
              final bP = b.isPrimary ?? false;
              if (aP == bP) return 0;
              return aP ? -1 : 1;
            });
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: contacts
                .map((c) => _ContactCard(
                      contact: c,
                      onEdit: () => onEdit(c),
                      onDelete: () => onDelete(c),
                    ))
                .toList(),
          );
        }),
      ],
    );
  }
}

class _ContactCard extends StatelessWidget {
  final VehicleContact contact;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ContactCard({
    required this.contact,
    required this.onEdit,
    required this.onDelete,
  });

  String? _addressLine() {
    final parts = <String>[
      if ((contact.address ?? '').trim().isNotEmpty) contact.address!.trim(),
      if ((contact.city ?? '').trim().isNotEmpty) contact.city!.trim(),
      if ((contact.state ?? '').trim().isNotEmpty) contact.state!.trim(),
      if (contact.pincode != null) contact.pincode!.toString(),
      if ((contact.country ?? '').trim().isNotEmpty) contact.country!.trim(),
    ];
    if (parts.isEmpty) return null;
    return parts.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final isPrimary = contact.isPrimary ?? false;
    final address = _addressLine();
    final phone = contact.phoneNumber?.number;
    final altPhone = contact.alternatePhoneNumber?.number;
    final email = contact.email;
    final website = contact.website;
    final hours = contact.openingHours;
    final mapLink = contact.mapLink;

    return Container(
      margin: EdgeInsets.only(bottom: SizeConfig.size10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEDEFF4)),
      ),
      child: Theme(
        // ExpansionTile shows a divider above/below by default — kill
        // it so the card edge stays clean.
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: isPrimary,
          shape: const RoundedRectangleBorder(side: BorderSide.none),
          tilePadding:
              EdgeInsets.symmetric(horizontal: SizeConfig.size12),
          childrenPadding: EdgeInsets.fromLTRB(
            SizeConfig.size12,
            0,
            SizeConfig.size12,
            SizeConfig.size12,
          ),
          title: Row(
            children: [
              Expanded(
                child: CustomText(
                  contact.locationName.isNotEmpty
                      ? contact.locationName
                      : 'Branch',
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: AppColors.mainTextColor,
                ),
              ),
              if (isPrimary)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: CustomText(
                    'Primary',
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryColor,
                  ),
                ),
              IconButton(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 18),
                tooltip: 'Edit',
              ),
              InkWell(
                onTap: onDelete,
                customBorder: const CircleBorder(),
                child: const Padding(
                  padding: EdgeInsets.all(8),
                  child: Icon(
                    Icons.delete_outline,
                    size: 18,
                    color: Colors.redAccent,
                  ),
                ),
              ),
            ],
          ),
          children: [
            if (address != null)
              _ContactRow(
                icon: Icons.place_outlined,
                text: address,
                onTap: mapLink != null && mapLink.isNotEmpty
                    ? () => _launchUrl(mapLink)
                    : null,
              ),
            if (website != null && website.isNotEmpty)
              _ContactRow(
                icon: Icons.language_outlined,
                text: website,
                isLink: true,
                onTap: () => _launchUrl(website),
              ),
            if (phone != null && phone.isNotEmpty)
              _ContactRow(
                icon: Icons.phone_outlined,
                text: _formattedPhone(contact.phoneNumber),
                isLink: true,
                onTap: () => _launchPhone(phone),
              ),
            if (altPhone != null && altPhone.isNotEmpty)
              _ContactRow(
                icon: Icons.phone_in_talk_outlined,
                text: _formattedPhone(contact.alternatePhoneNumber),
                isLink: true,
                onTap: () => _launchPhone(altPhone),
              ),
            if (email != null && email.isNotEmpty)
              _ContactRow(
                icon: Icons.email_outlined,
                text: email,
                isLink: true,
                onTap: () => _launchEmail(email),
              ),
            if (hours != null && hours.isNotEmpty)
              _ContactRow(
                icon: Icons.access_time_outlined,
                text: hours,
              ),
          ],
        ),
      ),
    );
  }

  String _formattedPhone(VehiclePhoneNumber? p) {
    if (p == null) return '';
    final pre = p.pre;
    final num = p.number ?? '';
    if (pre == null || num.isEmpty) return num;
    return '+$pre $num';
  }

  Future<void> _launchUrl(String url) async {
    var finalUrl = url.trim();
    if (!finalUrl.startsWith('http://') && !finalUrl.startsWith('https://')) {
      finalUrl = 'https://$finalUrl';
    }
    try {
      await launchUrl(Uri.parse(finalUrl), mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  Future<void> _launchEmail(String email) async {
    try {
      await launchUrl(Uri(scheme: 'mailto', path: email.trim()));
    } catch (_) {}
  }

  Future<void> _launchPhone(String phone) async {
    final clean = phone.replaceAll(RegExp(r'\s+'), '');
    try {
      await launchUrl(Uri(scheme: 'tel', path: clean));
    } catch (_) {}
  }
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String text;
  final bool isLink;
  final VoidCallback? onTap;

  const _ContactRow({
    required this.icon,
    required this.text,
    this.isLink = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              size: 18,
              color: isLink
                  ? AppColors.primaryColor
                  : AppColors.secondaryTextColor,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: CustomText(
                text,
                color: isLink
                    ? AppColors.primaryColor
                    : AppColors.mainTextColor,
                fontSize: 13,
                fontWeight: FontWeight.w500,
                decoration:
                    isLink ? TextDecoration.underline : TextDecoration.none,
                decorationColor: isLink ? AppColors.primaryColor : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pure-layout widget — given a list of gallery items, renders the
/// 1/2/3/4+ collage. Kept stateless / Rx-free so its rebuilds are
/// cheap and the surrounding Obx is the only reactive boundary.
class _GalleryCollage extends StatelessWidget {
  final List<VehicleGalleryItem> items;
  final Future<void> Function(VehicleGalleryItem) onDelete;

  const _GalleryCollage({required this.items, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final display = items.length > 4 ? items.sublist(0, 4) : items;
    final extra = items.length > 4 ? items.length - 4 : 0;

    Widget tile(int index, {bool showOverlay = false}) {
      final item = display[index];
      final url = (item.thumbnailUrl?.isNotEmpty ?? false)
          ? item.thumbnailUrl!
          : item.mediaUrl;
      return GestureDetector(
        onTap: () => _openViewer(context, items, index),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Stack(
            fit: StackFit.expand,
            children: [
              url.isNotEmpty
                  ? Image.network(
                      url,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey[300],
                        child: const Icon(Icons.broken_image),
                      ),
                    )
                  : Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.broken_image),
                    ),
              // +N overlay on the 4th tile when there are more than 4
              // photos — tap-through still opens the viewer at the
              // same index (which lets the user swipe through all).
              if (showOverlay && extra > 0)
                IgnorePointer(
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.5),
                    alignment: Alignment.center,
                    child: Text(
                      '+$extra',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              // Per-tile delete affordance — only shown when there's
              // no `+N` overlay on this same tile (otherwise the X
              // would compete with the overlay number for the corner).
              if (!(showOverlay && extra > 0) && item.id != null)
                Positioned(
                  top: 4,
                  right: 4,
                  child: InkWell(
                    onTap: () => onDelete(item),
                    customBorder: const CircleBorder(),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }

    const double height = 220;
    const double gap = 4;

    // 1 photo — full-width single tile
    if (display.length == 1) {
      return SizedBox(
        height: height,
        width: double.infinity,
        child: tile(0),
      );
    }

    // 2 photos — side by side
    if (display.length == 2) {
      return SizedBox(
        height: height,
        child: Row(
          children: [
            Expanded(child: tile(0)),
            const SizedBox(width: gap),
            Expanded(child: tile(1)),
          ],
        ),
      );
    }

    // 3 photos — 1 large left, 2 stacked right
    if (display.length == 3) {
      return SizedBox(
        height: height,
        child: Row(
          children: [
            Expanded(child: tile(0)),
            const SizedBox(width: gap),
            Expanded(
              child: Column(
                children: [
                  Expanded(child: tile(1)),
                  const SizedBox(height: gap),
                  Expanded(child: tile(2)),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // 4+ photos — 2×2 grid with +N overlay on the last cell
    return SizedBox(
      height: height,
      child: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                Expanded(child: tile(0)),
                const SizedBox(width: gap),
                Expanded(child: tile(1)),
              ],
            ),
          ),
          const SizedBox(height: gap),
          Expanded(
            child: Row(
              children: [
                Expanded(child: tile(2)),
                const SizedBox(width: gap),
                Expanded(child: tile(3, showOverlay: extra > 0)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openViewer(
    BuildContext context,
    List<VehicleGalleryItem> all,
    int initialIndex,
  ) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => _GalleryPhotoViewer(
        items: all,
        initialIndex: initialIndex,
      ),
    );
  }
}

/// Lightweight pinch-zoom + swipe full-screen viewer. Backed by
/// `PageView` so the user can flick through the entire gallery
/// (not just the four collage tiles).
class _GalleryPhotoViewer extends StatefulWidget {
  final List<VehicleGalleryItem> items;
  final int initialIndex;
  const _GalleryPhotoViewer({
    required this.items,
    required this.initialIndex,
  });

  @override
  State<_GalleryPhotoViewer> createState() => _GalleryPhotoViewerState();
}

class _GalleryPhotoViewerState extends State<_GalleryPhotoViewer> {
  late final PageController _page =
      PageController(initialPage: widget.initialIndex);

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(12),
      child: Stack(
        children: [
          PageView.builder(
            controller: _page,
            itemCount: widget.items.length,
            itemBuilder: (_, i) => InteractiveViewer(
              child: Center(
                child: Image.network(
                  widget.items[i].mediaUrl,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.broken_image_rounded,
                    color: Colors.white,
                    size: 48,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

/// Full-width identity header used at the top of the Vehicle Overview
/// tab. Pulls name / avatar / joining date from the shared
/// `ViewPersonalDetailsController` — the same source the professionals
/// dashboard uses — so the card stays in sync with profile edits made
/// elsewhere in the app. Lays out as `[avatar | name+role | member
/// pill]` and falls back to wrapping the pill below the row when the
/// device is narrow enough that the pill would overflow.
class _IdentityHeaderCard extends StatelessWidget {
  const _IdentityHeaderCard();

  @override
  Widget build(BuildContext context) {
    final viewCtrl =
        getOrPut(() => ViewPersonalDetailsController(), permanent: true);
    return SizedBox(
      width: double.infinity,
      child: Container(
        padding: EdgeInsets.all(SizeConfig.size12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFEDEFF4)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14001120),
              blurRadius: 14,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Obx(() {
          final user = viewCtrl.personalProfileDetails.value.user;
          final name = (user?.name ?? '').trim();
          final designation = (user?.designation ?? '').trim();
          final avatar = user?.profileImage ?? '';
          final since = _formatJoinedDate(user?.createdAt ?? '');
          return LayoutBuilder(
            builder: (context, constraints) {
              // Reserve room for avatar (44 + 12 gap) + member pill
              // (~135) before deciding to stack the pill on the next
              // line. Keeps the layout legible on phones as small as
              // 320 dp wide.
              final stackPill = constraints.maxWidth < 320;
              final identity = _NameBlock(
                name: name.isEmpty ? 'Welcome' : _capitalizeFirst(name),
                subtitle: designation.isNotEmpty
                    ? designation
                    : 'Vehicle service provider',
              );
              final memberPill = since.isEmpty
                  ? const SizedBox.shrink()
                  : _MemberSincePill(since: since);
              if (stackPill) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _Avatar(url: avatar, fallbackInitial: name),
                        SizedBox(width: SizeConfig.size12),
                        Expanded(child: identity),
                      ],
                    ),
                    if (since.isNotEmpty) ...[
                      SizedBox(height: SizeConfig.size8),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: memberPill,
                      ),
                    ],
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _Avatar(url: avatar, fallbackInitial: name),
                  SizedBox(width: SizeConfig.size12),
                  Expanded(child: identity),
                  if (since.isNotEmpty) ...[
                    SizedBox(width: SizeConfig.size8),
                    memberPill,
                  ],
                ],
              );
            },
          );
        }),
      ),
    );
  }

  String _capitalizeFirst(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }

  String _formatJoinedDate(String dateStr) {
    if (dateStr.isEmpty) return '';
    try {
      return DateFormat('MMMM yyyy').format(DateTime.parse(dateStr));
    } catch (_) {
      return '';
    }
  }
}

class _Avatar extends StatelessWidget {
  final String url;
  final String fallbackInitial;
  const _Avatar({required this.url, required this.fallbackInitial});

  @override
  Widget build(BuildContext context) {
    if (url.isNotEmpty) {
      return CachedAvatarWidget(
        imageUrl: url,
        size: 44,
        borderRadius: 22,
        showProfileOnFullScreen: false,
      );
    }
    final initial = fallbackInitial.isNotEmpty
        ? fallbackInitial.trim()[0].toUpperCase()
        : '?';
    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withValues(alpha: 0.10),
        shape: BoxShape.circle,
      ),
      child: Text(
        initial,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: AppColors.primaryColor,
        ),
      ),
    );
  }
}

class _NameBlock extends StatelessWidget {
  final String name;
  final String subtitle;

  const _NameBlock({required this.name, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        CustomText(
          name,
          fontSize: 15,
          fontWeight: FontWeight.w800,
          color: AppColors.mainTextColor,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        SizedBox(height: SizeConfig.size4),
        CustomText(
          subtitle,
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.secondaryTextColor,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class _MemberSincePill extends StatelessWidget {
  final String since;
  const _MemberSincePill({required this.since});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: SizeConfig.size10,
        vertical: SizeConfig.size4,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7E6),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE4D2A6), width: 0.6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.workspace_premium_rounded,
            size: 12,
            color: Color(0xFFB7781F),
          ),
          const SizedBox(width: 4),
          Text(
            'Member · $since',
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Color(0xFF6B3A00),
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

class _VehiclesTab extends StatelessWidget {
  final VehicleController controller;
  final void Function(Vehicle) onEdit;
  final void Function(Vehicle) onDelete;

  const _VehiclesTab({
    required this.controller,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
      child: Obx(() {
        final state = controller.myVehiclesState.value.status;
        if (state == Status.LOADING && controller.myVehicles.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 60),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (controller.myVehicles.isEmpty) {
          return _EmptyState(
            title: 'No vehicles in your fleet',
            subtitle:
                'Tap "Add vehicle" below to publish your first listing.',
            cta: 'Add a vehicle',
            onTap: () {
              // Bubble up via the FAB by triggering its tap target —
              // simpler to call edit with a fresh draft instead.
            },
          );
        }
        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemCount: controller.myVehicles.length,
          separatorBuilder: (_, __) => SizedBox(height: SizeConfig.size12),
          itemBuilder: (_, i) {
            final v = controller.myVehicles[i];
            return VehicleCard(
              vehicle: v,
              showOwnerActions: true,
              onEdit: () => onEdit(v),
              onDelete: () => onDelete(v),
            );
          },
        );
      }),
    );
  }
}

class _StatsTab extends StatelessWidget {
  final VehicleController controller;

  const _StatsTab({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
      child: _StatsRow(controller: controller, expanded: true),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final VehicleController controller;
  final bool expanded;

  const _StatsRow({required this.controller, this.expanded = false});

  @override
  Widget build(BuildContext context) {
    return Obx(() => Wrap(
          spacing: SizeConfig.size10,
          runSpacing: SizeConfig.size10,
          children: [
            _StatTile(
              label: 'Vehicles',
              value: controller.myVehicles.length.toString(),
              icon: Icons.directions_car_filled_rounded,
              color: const Color(0xFF1E88FF),
            ),
            _StatTile(
              label: 'Active',
              value: controller.myVehicles
                  .where((v) => v.isActive ?? true)
                  .length
                  .toString(),
              icon: Icons.bolt_rounded,
              color: const Color(0xFF22C55E),
            ),
            _StatTile(
              label: 'Verified',
              value: controller.myVehicles
                  .where((v) => v.isVerified ?? false)
                  .length
                  .toString(),
              icon: Icons.verified_rounded,
              color: const Color(0xFF8B5CF6),
            ),
            _StatTile(
              label: 'Contacts',
              value: controller.myContacts.length.toString(),
              icon: Icons.contact_phone_rounded,
              color: const Color(0xFFF59E0B),
            ),
            if (expanded)
              _StatTile(
                label: 'Gallery',
                value: controller.myGallery.length.toString(),
                icon: Icons.photo_library_rounded,
                color: const Color(0xFFEF4444),
              ),
          ],
        ));
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEDEFF4)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14001120),
            blurRadius: 14,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          SizedBox(width: SizeConfig.size8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomText(
                value,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.mainTextColor,
              ),
              CustomText(
                label,
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.secondaryTextColor,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final String cta;
  final VoidCallback onTap;

  const _EmptyState({
    required this.title,
    required this.subtitle,
    required this.cta,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(vertical: SizeConfig.size16),
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEDEFF4)),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primaryColor.withValues(alpha: 0.10),
              border: Border.all(
                color: AppColors.primaryColor.withValues(alpha: 0.20),
              ),
            ),
            child: Icon(
              Icons.directions_car_rounded,
              size: 26,
              color: AppColors.primaryColor,
            ),
          ),
          SizedBox(height: SizeConfig.size12),
          CustomText(
            title,
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.mainTextColor,
          ),
          SizedBox(height: SizeConfig.size6),
          CustomText(
            subtitle,
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.secondaryTextColor,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: SizeConfig.size16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onTap,
              icon: const Icon(Icons.add, size: 18, color: Colors.white),
              label: Text(cta,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  )),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

