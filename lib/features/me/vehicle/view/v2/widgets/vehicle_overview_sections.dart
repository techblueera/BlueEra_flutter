import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/vehicle/controller/vehicle_controller.dart';
import 'package:BlueEra/features/me/vehicle/model/vehicle_models.dart';
import 'package:BlueEra/features/personal/auth/controller/view_personal_details_controller.dart';
import 'package:BlueEra/widgets/cached_avatar_widget.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

/// Shared, reusable building blocks for the redesigned vehicle "me"
/// dashboard (v2). Extracted out of the old monolithic
/// `vehicle_home_screen_v2.dart` so each tab file can compose them —
/// mirroring how the hospital v2 tabs share `widgets/`.

// ─────────────────────────────────────────────────────────────────────
// Identity header card
// ─────────────────────────────────────────────────────────────────────

/// Full-width identity header used at the top of the Overview tab.
/// Pulls name / avatar / joining date from the shared
/// [ViewPersonalDetailsController].
class VehicleIdentityCard extends StatelessWidget {
  const VehicleIdentityCard({super.key});

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
              final stackPill = constraints.maxWidth < 320;
              final identity = _NameBlock(
                name: name.isEmpty
                    ? AppStrings.welcomeLabel.tr
                    : _capitalizeFirst(name),
                subtitle: designation.isNotEmpty
                    ? designation
                    : AppStrings.vehicleServiceProvider.tr,
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

  String _capitalizeFirst(String text) =>
      text.isEmpty ? text : text[0].toUpperCase() + text.substring(1);

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
            '${AppStrings.memberPrefix.tr} · $since',
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

// ─────────────────────────────────────────────────────────────────────
// Stats
// ─────────────────────────────────────────────────────────────────────

class VehicleStatsRow extends StatelessWidget {
  final VehicleController controller;
  final bool expanded;

  const VehicleStatsRow({
    super.key,
    required this.controller,
    this.expanded = false,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() => Wrap(
          spacing: SizeConfig.size10,
          runSpacing: SizeConfig.size10,
          children: [
            _StatTile(
              label: AppStrings.vehiclesTab.tr,
              value: controller.myVehicles.length.toString(),
              icon: Icons.directions_car_filled_rounded,
              color: const Color(0xFF1E88FF),
            ),
            _StatTile(
              label: AppStrings.active.tr,
              value: controller.myVehicles
                  .where((v) => v.isActive ?? true)
                  .length
                  .toString(),
              icon: Icons.bolt_rounded,
              color: const Color(0xFF22C55E),
            ),
            _StatTile(
              label: AppStrings.verified.tr,
              value: controller.myVehicles
                  .where((v) => v.isVerified ?? false)
                  .length
                  .toString(),
              icon: Icons.verified_rounded,
              color: const Color(0xFF8B5CF6),
            ),
            _StatTile(
              label: AppStrings.contactsLabel.tr,
              value: controller.myContacts.length.toString(),
              icon: Icons.contact_phone_rounded,
              color: const Color(0xFFF59E0B),
            ),
            if (expanded)
              _StatTile(
                label: AppStrings.gallery.tr,
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

// ─────────────────────────────────────────────────────────────────────
// Empty state
// ─────────────────────────────────────────────────────────────────────

class VehicleEmptyState extends StatelessWidget {
  final String title;
  final String subtitle;
  final String cta;
  final VoidCallback onTap;

  const VehicleEmptyState({
    super.key,
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

// ─────────────────────────────────────────────────────────────────────
// Gallery collage + viewer
// ─────────────────────────────────────────────────────────────────────

class VehicleGalleryCollage extends StatelessWidget {
  final List<VehicleGalleryItem> items;
  final Future<void> Function(VehicleGalleryItem) onDelete;

  const VehicleGalleryCollage({
    super.key,
    required this.items,
    required this.onDelete,
  });

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

    if (display.length == 1) {
      return SizedBox(height: height, width: double.infinity, child: tile(0));
    }
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
      builder: (_) => _GalleryPhotoViewer(items: all, initialIndex: initialIndex),
    );
  }
}

class _GalleryPhotoViewer extends StatefulWidget {
  final List<VehicleGalleryItem> items;
  final int initialIndex;

  const _GalleryPhotoViewer({required this.items, required this.initialIndex});

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

// ─────────────────────────────────────────────────────────────────────
// Contact card
// ─────────────────────────────────────────────────────────────────────

class VehicleContactCard extends StatelessWidget {
  final VehicleContact contact;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const VehicleContactCard({
    super.key,
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
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: isPrimary,
          shape: const RoundedRectangleBorder(side: BorderSide.none),
          tilePadding: EdgeInsets.symmetric(horizontal: SizeConfig.size12),
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
                      : AppStrings.branchLabel.tr,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: AppColors.mainTextColor,
                ),
              ),
              if (isPrimary)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: CustomText(
                    AppStrings.primaryLabel.tr,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryColor,
                  ),
                ),
              IconButton(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 18),
                tooltip: AppStrings.edit.tr,
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
              _ContactRow(icon: Icons.access_time_outlined, text: hours),
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
              color:
                  isLink ? AppColors.primaryColor : AppColors.secondaryTextColor,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: CustomText(
                text,
                color: isLink ? AppColors.primaryColor : AppColors.mainTextColor,
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

// ─────────────────────────────────────────────────────────────────────
// QR card (mirrors the hospital/food QR block)
// ─────────────────────────────────────────────────────────────────────

class VehicleQrCard extends StatelessWidget {
  const VehicleQrCard({super.key});

  @override
  Widget build(BuildContext context) {
    final viewCtrl =
        getOrPut(() => ViewPersonalDetailsController(), permanent: true);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(SizeConfig.size16),
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
        final website = viewCtrl.website.value.trim();
        final data = website.isNotEmpty
            ? website
            : 'BlueEra:${name.isEmpty ? AppStrings.vehicle.tr : name}';
        return Column(
          children: [
            CustomText(
              name.isEmpty
                  ? AppStrings.businessProfileTitle.tr
                  : (name[0].toUpperCase() + name.substring(1)),
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.mainTextColor,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: SizeConfig.size4),
            CustomText(
              AppStrings.scanToConnect.tr,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.secondaryTextColor,
            ),
            SizedBox(height: SizeConfig.size12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE8ECF2)),
              ),
              child: QrImageView(
                data: data,
                version: QrVersions.auto,
                size: 170,
                backgroundColor: Colors.white,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: Color(0xFF0A1A33),
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: Color(0xFF0A1A33),
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}
