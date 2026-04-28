import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/chat/auth/model/GetListOfMessageData.dart';
import 'package:BlueEra/features/common/delivery_partner/controller/delivery_partner_controller.dart';
import 'package:BlueEra/features/chat/view/widget/component_widgets.dart';
import 'package:BlueEra/features/common/delivery_partner/repo/delivery_partner_repo.dart';
import 'package:BlueEra/widgets/cached_avatar_widget.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class RiderAssociationMsgCard extends StatefulWidget {
  final Messages message;
  final String time;

  const RiderAssociationMsgCard({
    super.key,
    required this.message,
    required this.time,
  });

  @override
  State<RiderAssociationMsgCard> createState() =>
      _RiderAssociationMsgCardState();
}

class _RiderAssociationMsgCardState extends State<RiderAssociationMsgCard> {
  late String _localStatus;

  @override
  void initState() {
    super.initState();
    _localStatus =
        widget.message.metadata?.riderAssociation?.status ?? 'pending';
  }

  void _onStatusChanged(String newStatus) {
    if (mounted) {
      setState(() {
        _localStatus = newStatus;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final association = widget.message.metadata?.riderAssociation;
    if (association == null) {
      return const SizedBox.shrink();
    }

    final status = _localStatus;
    final requestedBy = association.requestedBy ?? '';
    final riderInfo = association.riderInfo;
    final businessInfo = association.businessInfo;
    final currentUserId = userId;

    final bool isCurrentUserBusiness =
        currentUserId == association.businessUserId;
    final bool isCurrentUserRider =
        currentUserId == association.riderUserId;

    final bool isRecipient;
    if (requestedBy == 'rider') {
      isRecipient = isCurrentUserBusiness;
    } else {
      isRecipient = isCurrentUserRider;
    }

    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: SizeConfig.size12,
        vertical: SizeConfig.size6,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _statusBorderColor(status), width: 1),
        boxShadow: [AppShadows.textFieldShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Header ───
          Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
            decoration: BoxDecoration(
              color: _statusBgColor(status),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(11)),
            ),
            child: Row(
              children: [
                Icon(Icons.handshake_outlined,
                    size: 18, color: _statusColor(status)),
                const SizedBox(width: 8),
                Expanded(
                  child: CustomText(
                    'Rider Association',
                    fontSize: SizeConfig.medium,
                    fontWeight: FontWeight.w700,
                    color: AppColors.mainTextColor,
                  ),
                ),
                _StatusBadge(status: status),
              ],
            ),
          ),

          // ═══════════════════════════════════════════════════════
          //  BUSINESS SIDE — compact card + "View Rider" button
          // ═══════════════════════════════════════════════════════
          if (isCurrentUserBusiness && riderInfo != null) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
              child: Row(
                children: [
                  CachedAvatarWidget(
                    imageUrl: riderInfo.profileImage ?? '',
                    size: 40,
                    borderColor: AppColors.greyE5,
                    borderRadius: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomText(
                          riderInfo.name ?? 'Unknown Rider',
                          fontSize: SizeConfig.medium,
                          fontWeight: FontWeight.w600,
                          color: AppColors.mainTextColor,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        // "Verified" static badge
                        Row(
                          children: [
                            Icon(Icons.verified,
                                size: 14, color: AppColors.primaryColor),
                            const SizedBox(width: 4),
                            CustomText(
                              'Verified',
                              fontSize: SizeConfig.extraSmall,
                              fontWeight: FontWeight.w500,
                              color: AppColors.primaryColor,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // "View Rider" button
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
              child: InkWell(
                onTap: () => _showRiderDetailsBottomSheet(
                  context,
                  riderInfo: riderInfo,
                  association: association,
                  status: status,
                  isRecipient: isRecipient,
                ),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withValues(alpha: 0.06),
                    border: Border.all(
                        color: AppColors.primaryColor, width: 1.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.person_search_rounded,
                          size: 16, color: AppColors.primaryColor),
                      const SizedBox(width: 6),
                      CustomText(
                        'View Rider',
                        fontSize: SizeConfig.medium,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryColor,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],

          // ═══════════════════════════════════════════════════════
          //  RIDER SIDE — show business info + contact
          // ═══════════════════════════════════════════════════════
          if (isCurrentUserRider && businessInfo != null) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
              child: _PersonRow(
                label: 'Business',
                name: businessInfo.businessName ?? 'Unknown',
                imageUrl: businessInfo.logo ?? '',
                subtitle: businessInfo.category ?? '',
              ),
            ),
            if (businessInfo.contactNo != null &&
                businessInfo.contactNo!.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
                child: Row(
                  children: [
                    const SizedBox(width: 46),
                    Icon(Icons.phone_outlined,
                        size: 13, color: AppColors.secondaryTextColor),
                    const SizedBox(width: 4),
                    CustomText(
                      businessInfo.contactNo!,
                      fontSize: SizeConfig.extraSmall,
                      color: AppColors.secondaryTextColor,
                      fontWeight: FontWeight.w400,
                    ),
                  ],
                ),
              ),
          ],

          // ─── Requested By ───
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
            child: Row(
              children: [
                Icon(Icons.arrow_forward_rounded,
                    size: 14, color: AppColors.secondaryTextColor),
                const SizedBox(width: 6),
                CustomText(
                  isRecipient
                      ? 'Request from ${requestedBy == 'rider' ? (riderInfo?.name ?? 'Rider') : (businessInfo?.businessName ?? 'Business')}'
                      : 'You sent this request',
                  fontSize: SizeConfig.extraSmall,
                  color: AppColors.secondaryTextColor,
                  fontWeight: FontWeight.w400,
                ),
              ],
            ),
          ),

          // ─── Rider side: Accept/Reject inline (when rider is recipient) ───
          // After 24h the request is locked — swap the button row for a
          // disabled "Order Closed" status so the rider can't act.
          if (status == 'pending' &&
              isRecipient &&
              isCurrentUserRider &&
              !isMessageOlderThan24Hours(widget.message.createdAt))
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
              child: Row(
                children: [
                  Expanded(
                    child: _ActionButton(
                      label: 'Reject',
                      color: AppColors.redBE,
                      icon: Icons.close_rounded,
                      onTap: () => _respondToRequest(
                        association.associationId ?? '',
                        'reject',
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ActionButton(
                      label: 'Accept',
                      color: AppColors.green1A,
                      icon: Icons.check_rounded,
                      filled: true,
                      onTap: () => _respondToRequest(
                        association.associationId ?? '',
                        'accept',
                      ),
                    ),
                  ),
                ],
              ),
            )
          else if (status == 'pending' &&
              isRecipient &&
              isCurrentUserRider &&
              isMessageOlderThan24Hours(widget.message.createdAt))
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock_clock,
                      color: AppColors.grayText, size: 18),
                  const SizedBox(width: 6),
                  CustomText(
                    'Order Closed',
                    fontSize: SizeConfig.size14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.grayText,
                  ),
                ],
              ),
            ),

          // ─── Time ───
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
            child: Align(
              alignment: Alignment.centerRight,
              child: CustomText(
                widget.time,
                fontSize: SizeConfig.extraSmall8,
                color: AppColors.secondaryTextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Bottom Sheet: Full Rider Details + Accept/Reject ─────────

  void _showRiderDetailsBottomSheet(
    BuildContext context, {
    required RiderAssociationRiderInfo riderInfo,
    required RiderAssociationMetadata association,
    required String status,
    required bool isRecipient,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RiderDetailsSheet(
        riderInfo: riderInfo,
        association: association,
        status: status,
        isRecipient: isRecipient,
        message: widget.message,
        onStatusChanged: _onStatusChanged,
      ),
    );
  }

  Future<void> _respondToRequest(String associationId, String action) async {
    if (associationId.isEmpty) return;
    final response = await DeliveryPartnerRepo().respondToAssociationRepo(
      associationId: associationId,
      action: action,
    );
    if (response.isSuccess) {
      final newStatus = action == 'accept' ? 'accepted' : 'rejected';
      widget.message.metadata?.riderAssociation?.status = newStatus;
      _onStatusChanged(newStatus);
      if (Get.isRegistered<DeliveryPartnerController>()) {
        Get.find<DeliveryPartnerController>().update();
      }
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return const Color(0xFFE6A800);
      case 'accepted':
        return AppColors.green1A;
      case 'rejected':
        return AppColors.redBE;
      case 'expired':
      case 'dissociated':
        return AppColors.secondaryTextColor;
      default:
        return AppColors.secondaryTextColor;
    }
  }

  Color _statusBgColor(String status) {
    switch (status) {
      case 'pending':
        return const Color(0xFFFFF8E1);
      case 'accepted':
        return const Color(0xFFE8F5E9);
      case 'rejected':
        return const Color(0xFFFFEBEE);
      case 'expired':
      case 'dissociated':
        return AppColors.fillColor;
      default:
        return AppColors.fillColor;
    }
  }

  Color _statusBorderColor(String status) {
    return _statusColor(status).withValues(alpha: 0.3);
  }
}

// ═══════════════════════════════════════════════════════════════════
//  RIDER DETAILS BOTTOM SHEET (shown to business side)
// ═══════════════════════════════════════════════════════════════════

class _RiderDetailsSheet extends StatelessWidget {
  final RiderAssociationRiderInfo riderInfo;
  final RiderAssociationMetadata association;
  final String status;
  final bool isRecipient;
  final Messages message;
  final void Function(String newStatus)? onStatusChanged;

  const _RiderDetailsSheet({
    required this.riderInfo,
    required this.association,
    required this.status,
    required this.isRecipient,
    required this.message,
    this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ─── Handle ───
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.greyCA,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),

              // ─── Rider Avatar + Name ───
              CachedAvatarWidget(
                imageUrl: riderInfo.profileImage ?? '',
                size: 72,
                borderColor: AppColors.greyE5,
                borderRadius: 36,
              ),
              const SizedBox(height: 12),
              CustomText(
                riderInfo.name ?? 'Unknown Rider',
                fontSize: SizeConfig.extraLarge,
                fontWeight: FontWeight.w700,
                color: AppColors.mainTextColor,
              ),
              const SizedBox(height: 4),

              // ─── Verified badge ───
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.verified,
                      size: 16, color: AppColors.primaryColor),
                  const SizedBox(width: 4),
                  CustomText(
                    'Verified',
                    fontSize: SizeConfig.medium,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primaryColor,
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // ─── Details Grid ───
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.fillColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    // Vehicle Type
                    _detailRow(
                      icon: Icons.two_wheeler_rounded,
                      label: 'Vehicle',
                      value: _vehicleLabel(riderInfo.vehicleType),
                    ),

                    const Divider(height: 20, color: AppColors.greyE5),

                    // Contact
                    if (riderInfo.contactNo != null &&
                        riderInfo.contactNo!.isNotEmpty)
                      _detailRow(
                        icon: Icons.phone_outlined,
                        label: 'Contact',
                        value: riderInfo.contactNo!,
                      ),

                    if (riderInfo.contactNo != null &&
                        riderInfo.contactNo!.isNotEmpty)
                      const Divider(height: 20, color: AppColors.greyE5),

                    // Ratings
                    _detailRow(
                      icon: Icons.star_rounded,
                      iconColor: const Color(0xFFE6A800),
                      label: 'Rating',
                      value:
                          '${riderInfo.ratingsAverage?.toStringAsFixed(1) ?? '0.0'} (${riderInfo.ratingsCount ?? 0} reviews)',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ─── Accept / Reject Buttons (only when pending & business is recipient) ───
              if (status == 'pending' && isRecipient) ...[
                Row(
                  children: [
                    Expanded(
                      child: _ActionButton(
                        label: 'Reject',
                        color: AppColors.redBE,
                        icon: Icons.close_rounded,
                        onTap: () async {
                          await _respond(context, 'reject');
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ActionButton(
                        label: 'Accept',
                        color: AppColors.green1A,
                        icon: Icons.check_rounded,
                        filled: true,
                        onTap: () async {
                          await _respond(context, 'accept');
                        },
                      ),
                    ),
                  ],
                ),
              ] else ...[
                // Show status info when not pending
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: _statusColor(status).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _statusColor(status).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(_statusIcon(status),
                          size: 18, color: _statusColor(status)),
                      const SizedBox(width: 8),
                      CustomText(
                        _statusLabel(status),
                        fontSize: SizeConfig.medium,
                        fontWeight: FontWeight.w600,
                        color: _statusColor(status),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _respond(BuildContext context, String action) async {
    final associationId = association.associationId ?? '';
    if (associationId.isEmpty) return;

    final response = await DeliveryPartnerRepo().respondToAssociationRepo(
      associationId: associationId,
      action: action,
    );
    if (response.isSuccess) {
      final newStatus = action == 'accept' ? 'accepted' : 'rejected';
      message.metadata?.riderAssociation?.status = newStatus;
      onStatusChanged?.call(newStatus);
      if (Get.isRegistered<DeliveryPartnerController>()) {
        Get.find<DeliveryPartnerController>().update();
      }
      if (context.mounted) Navigator.pop(context);
    }
  }

  Widget _detailRow({
    required IconData icon,
    required String label,
    required String value,
    Color? iconColor,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withValues(alpha: 0.06),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Icon(icon,
              size: 18, color: iconColor ?? AppColors.secondaryTextColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomText(
                label,
                fontSize: SizeConfig.extraSmall,
                color: AppColors.secondaryTextColor,
                fontWeight: FontWeight.w400,
              ),
              const SizedBox(height: 1),
              CustomText(
                value,
                fontSize: SizeConfig.medium,
                color: AppColors.mainTextColor,
                fontWeight: FontWeight.w600,
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _vehicleLabel(String? vehicleType) {
    switch (vehicleType) {
      case 'twoWheelerRider':
        return 'Two Wheeler';
      case 'fourWheeler':
        return 'Four Wheeler';
      case 'threeWheeler':
        return 'Three Wheeler';
      default:
        return vehicleType ?? 'N/A';
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return const Color(0xFFE6A800);
      case 'accepted':
        return AppColors.green1A;
      case 'rejected':
        return AppColors.redBE;
      default:
        return AppColors.secondaryTextColor;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'accepted':
        return Icons.check_circle_outline;
      case 'rejected':
        return Icons.cancel_outlined;
      case 'expired':
        return Icons.timer_off_outlined;
      case 'dissociated':
        return Icons.link_off_rounded;
      default:
        return Icons.info_outline;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'accepted':
        return 'Association Active';
      case 'rejected':
        return 'Request Rejected';
      case 'expired':
        return 'Request Expired';
      case 'dissociated':
        return 'Association Ended';
      default:
        return status;
    }
  }
}

// ═══════════════════════════════════════════════════════════════════
//  STATUS BADGE
// ═══════════════════════════════════════════════════════════════════

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = _color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 0.5),
      ),
      child: CustomText(
        _label,
        fontSize: SizeConfig.extraSmall8,
        fontWeight: FontWeight.w600,
        color: color,
      ),
    );
  }

  String get _label {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'accepted':
        return 'Accepted';
      case 'rejected':
        return 'Rejected';
      case 'expired':
        return 'Expired';
      case 'dissociated':
        return 'Dissociated';
      default:
        return status;
    }
  }

  Color get _color {
    switch (status) {
      case 'pending':
        return const Color(0xFFE6A800);
      case 'accepted':
        return AppColors.green1A;
      case 'rejected':
        return AppColors.redBE;
      default:
        return AppColors.secondaryTextColor;
    }
  }
}

// ═══════════════════════════════════════════════════════════════════
//  PERSON ROW (used for rider side — business info)
// ═══════════════════════════════════════════════════════════════════

class _PersonRow extends StatelessWidget {
  final String label;
  final String name;
  final String imageUrl;
  final String subtitle;

  const _PersonRow({
    required this.label,
    required this.name,
    required this.imageUrl,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CachedAvatarWidget(
          imageUrl: imageUrl,
          size: 36,
          borderColor: AppColors.greyE5,
          borderRadius: 18,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: CustomText(
                      name,
                      fontSize: SizeConfig.medium,
                      fontWeight: FontWeight.w600,
                      color: AppColors.mainTextColor,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: AppColors.fillColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: CustomText(
                      label,
                      fontSize: SizeConfig.extraSmall8,
                      color: AppColors.secondaryTextColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              if (subtitle.isNotEmpty) ...[
                const SizedBox(height: 2),
                CustomText(
                  subtitle,
                  fontSize: SizeConfig.extraSmall,
                  color: AppColors.secondaryTextColor,
                  fontWeight: FontWeight.w400,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════
//  ACTION BUTTON
// ═══════════════════════════════════════════════════════════════════

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  final bool filled;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.color,
    required this.icon,
    this.filled = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: filled ? color : AppColors.white,
          border: Border.all(color: color, width: 1.2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: filled ? AppColors.white : color),
            const SizedBox(width: 6),
            CustomText(
              label,
              fontSize: SizeConfig.medium,
              fontWeight: FontWeight.w600,
              color: filled ? AppColors.white : color,
            ),
          ],
        ),
      ),
    );
  }
}
