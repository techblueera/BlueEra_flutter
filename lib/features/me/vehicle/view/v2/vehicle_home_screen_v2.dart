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
import 'package:BlueEra/features/me/vehicle/view/widgets/vehicle_form_sheet.dart';
import 'package:BlueEra/features/personal/auth/controller/view_personal_details_controller.dart';
import 'package:BlueEra/widgets/cached_avatar_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

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
                    onRefresh: () => _ctrl.fetchMyVehicles(showProgress: false),
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
              onPressed: _onAddVehicle,
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
        return _OverviewTab(controller: _ctrl, onAdd: _onAddVehicle);
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
          const Spacer(),
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
  Future<void> _onAddVehicle() async {
    final result = await showModalBottomSheet<VehicleFormResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: VehicleFormSheet(),
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
    final result = await showModalBottomSheet<VehicleFormResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: VehicleFormSheet(initial: v),
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

  const _OverviewTab({required this.controller, required this.onAdd});

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

