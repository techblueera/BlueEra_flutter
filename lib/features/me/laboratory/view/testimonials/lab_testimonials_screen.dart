import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/me/laboratory/controller/lab_testimonial_controller.dart';
import 'package:BlueEra/features/me/laboratory/model/lab_testimonial_model.dart';
import 'package:BlueEra/features/me/laboratory/view/testimonials/lab_testimonial_form_sheet.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Owner-side testimonials manager. Lists the lab's own testimonials with
/// edit / delete actions; a FAB opens the add-testimonial sheet.
/// See lib/docs/LABORATORY_INTEGRATION.md §2.
class LabTestimonialsScreen extends StatefulWidget {
  const LabTestimonialsScreen({super.key});

  @override
  State<LabTestimonialsScreen> createState() => _LabTestimonialsScreenState();
}

class _LabTestimonialsScreenState extends State<LabTestimonialsScreen> {
  static const Color _accent = AppColors.primaryColor;
  static const Color _accentDeep = AppColors.blue5CAF;
  static const Color _line = Color(0xFFE5E7EB);

  late final LabTestimonialController _ctrl =
      getOrPut(() => LabTestimonialController());

  @override
  void initState() {
    super.initState();
    _ctrl.fetchMyTestimonials();
  }

  Future<void> _openForm({LabTestimonial? existing}) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => LabTestimonialFormSheet(existing: existing),
    );
    if (result == true && mounted) {
      // Controller already refreshed the list on success — nothing more
      // to do; the Obx below repaints.
    }
  }

  Future<void> _confirmDelete(LabTestimonial t) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete testimonial?'),
        content: Text(
          '"${(t.message ?? '').trim().isEmpty ? '(empty)' : (t.message ?? '')}" — '
          'from ${t.authorName ?? ''}',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel')),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _ctrl.deleteTestimonial(t.id ?? '');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const CommonBackAppBar(title: 'Testimonials'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        backgroundColor: _accent,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'Add Testimonial',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Obx(() {
        if (_ctrl.isLoading.value && _ctrl.myTestimonials.isEmpty) {
          return const Center(
              child: CircularProgressIndicator(color: _accentDeep));
        }
        if (_ctrl.myTestimonials.isEmpty) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(SizeConfig.size24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.format_quote_rounded,
                      size: 40, color: AppColors.secondaryTextColor),
                  SizedBox(height: SizeConfig.size10),
                  CustomText(
                    'You have not added any testimonial yet.',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.secondaryTextColor,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: SizeConfig.size6),
                  CustomText(
                    'Tap the button below to add your first one.',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.secondaryTextColor,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: _ctrl.fetchMyTestimonials,
          child: ListView.separated(
            padding: EdgeInsets.fromLTRB(
                SizeConfig.size14, SizeConfig.size14, SizeConfig.size14, 100),
            itemCount: _ctrl.myTestimonials.length,
            separatorBuilder: (_, __) => SizedBox(height: SizeConfig.size10),
            itemBuilder: (_, i) => _card(_ctrl.myTestimonials[i]),
          ),
        );
      }),
    );
  }

  Widget _card(LabTestimonial t) {
    final photo = (t.photoUrl ?? '').trim();
    final initials = _initials(t.authorName ?? '');
    return Container(
      padding: EdgeInsets.all(SizeConfig.size14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _line),
        boxShadow: const [
          BoxShadow(
              color: Color(0x0F001120),
              blurRadius: 6,
              offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _accent.withValues(alpha: 0.10),
                  shape: BoxShape.circle,
                ),
                clipBehavior: Clip.antiAlias,
                child: photo.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: photo,
                        width: 42,
                        height: 42,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => _initialAvatar(initials),
                      )
                    : _initialAvatar(initials),
              ),
              SizedBox(width: SizeConfig.size10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      t.authorName ?? '',
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.mainTextColor,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if ((t.designation ?? '').trim().isNotEmpty)
                      CustomText(
                        t.designation ?? '',
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.secondaryTextColor,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert_rounded,
                    color: AppColors.secondaryTextColor),
                onSelected: (v) {
                  if (v == 'edit') _openForm(existing: t);
                  if (v == 'delete') _confirmDelete(t);
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ],
          ),
          SizedBox(height: SizeConfig.size10),
          CustomText(
            (t.message ?? '').trim().isEmpty ? '(empty)' : (t.message ?? ''),
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.mainTextColor,
            height: 1.4,
            maxLines: 6,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _initialAvatar(String initials) => CustomText(
        initials,
        fontSize: 15,
        fontWeight: FontWeight.w800,
        color: _accent,
      );

  String _initials(String name) {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }
}
