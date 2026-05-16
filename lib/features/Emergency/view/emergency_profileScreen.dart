import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:get/get.dart';

import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import '../controller/emergency_profile_controller.dart';
import '../model/emergency_profile_model.dart';

const kBlue = AppColors.kBlue;
const kBlueDark = AppColors.kBlueDark;
const kBlueLight = AppColors.kBlueLight;
const kGreen = AppColors.kGreen;
const kGreenText = AppColors.kGreenText;
const kGrey = AppColors.kGrey;
const kGreyLabel = AppColors.kGreyLabel;
const kBg = AppColors.kBg;
const kCard = AppColors.kCard;
const kRed = AppColors.kRed;

// ─────────────────────────────────────────────
// MAIN SCREEN
// ─────────────────────────────────────────────
class EmergencyProfileScreen1 extends StatelessWidget {
  EmergencyProfileScreen1({super.key});

  final _controller = Get.put(EmergencyProfileController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Obx(() {
          if (_controller.profileResponse.value.status == Status.LOADING) {
            return const Center(child: CircularProgressIndicator());
          } else if (_controller.profileResponse.value.status == Status.ERROR) {
            return Center(
                child: Text(_controller.profileResponse.value.message ??
                    'Error fetching profile'));
          }

          final data = _controller.emergencyProfileData.value;
          if (data == null) {
            return const Center(child: Text('No Profile Data Available'));
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _AppBar(),
                _ProfileHeader(basicInfo: data.basicInfo),
                const SizedBox(height: 20),
                if (data.basicInfo != null) ...[
                  _ContactDetailsCard(basicInfo: data.basicInfo),
                  const SizedBox(height: 12),
                  _VehicleInfoCard(basicInfo: data.basicInfo),
                  const SizedBox(height: 12),
                  _MedicalInfoCard(basicInfo: data.basicInfo),
                  const SizedBox(height: 12),
                ],
                _EmergencyContactsCard(contacts: data.emergencyContacts),
                const SizedBox(height: 12),
                const _GetAppBanner(),
                const SizedBox(height: 28),
              ],
            ),
          );
        }),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// APP BAR
// ─────────────────────────────────────────────
class _AppBar extends StatelessWidget {
  const _AppBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF1E3A8A),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(
              child: Text(
                'BE',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Blue Era',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                  color: Color(0xFF111827),
                ),
              ),
              Text(
                'Emergency Services',
                style: TextStyle(fontSize: 13, color: kGrey),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// PROFILE HEADER
// ─────────────────────────────────────────────
class _ProfileHeader extends StatelessWidget {
  final BasicInfo? basicInfo;
  const _ProfileHeader({this.basicInfo});

  @override
  Widget build(BuildContext context) {
    final name = basicInfo?.fullName ?? 'Unknown';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';

    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 34,
                backgroundColor: kBlue,
                child: Text(
                  initial,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(height: 3),
                  const Text(
                    'Emergency Profile',
                    style: TextStyle(fontSize: 14, color: kGrey),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Blood group chip
          if (basicInfo?.bloodGroup != null &&
              basicInfo!.bloodGroup!.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1F2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFFFCDD2)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.favorite, color: kRed, size: 15),
                  const SizedBox(width: 6),
                  Text(
                    basicInfo?.bloodGroup ?? '',
                    style: const TextStyle(
                      color: kRed,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// REUSABLE SECTION CARD WRAPPER
// ─────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;

  const _SectionCard({
    required this.icon,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
            child: Row(
              children: [
                Icon(icon, color: kBlue, size: 22),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF111827),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF3F4F6)),
          child,
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// INFO ROW
// ─────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              color: kGreyLabel,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 15, color: Color(0xFF111827)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// CONTACT DETAILS CARD
// ─────────────────────────────────────────────
class _ContactDetailsCard extends StatelessWidget {
  final BasicInfo? basicInfo;
  const _ContactDetailsCard({this.basicInfo});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      icon: Icons.phone_outlined,
      title: 'Contact Details',
      child: Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _InfoRow(
                label: 'Mobile Number',
                value: basicInfo?.mobileNumber ?? 'N/A'),
            _InfoRow(
                label: 'Alternate Number',
                value: basicInfo?.alternateNumber ?? 'N/A'),
            _InfoRow(label: 'Email', value: basicInfo?.emailId ?? 'N/A'),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// VEHICLE INFORMATION CARD
// ─────────────────────────────────────────────
class _VehicleInfoCard extends StatelessWidget {
  final BasicInfo? basicInfo;
  const _VehicleInfoCard({this.basicInfo});

  @override
  Widget build(BuildContext context) {
    if (basicInfo?.vehicleNumber == null || basicInfo!.vehicleNumber!.isEmpty) {
      return const SizedBox.shrink(); // Hide the card if no vehicle info
    }

    return _SectionCard(
      icon: Icons.directions_car_outlined,
      title: 'Vehicle Information',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Text(
            basicInfo?.vehicleNumber ?? '',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
              color: Color(0xFF111827),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// MEDICAL INFORMATION CARD
// ─────────────────────────────────────────────
class _MedicalInfoCard extends StatelessWidget {
  final BasicInfo? basicInfo;
  const _MedicalInfoCard({this.basicInfo});

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      icon: Icons.favorite_border,
      title: 'Medical Information',
      child: Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _InfoRow(
                label: 'Blood Group',
                value: basicInfo?.bloodGroup ?? 'Unknown'),
            _InfoRow(
                label: 'Known Allergies',
                value: basicInfo?.knownAllergies ?? 'None'),
            _InfoRow(
                label: 'Known Diseases',
                value: basicInfo?.knownDisease ?? 'None'),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// EMERGENCY CONTACTS CARD
// ─────────────────────────────────────────────
class _EmergencyContactsCard extends StatelessWidget {
  final List<EmergencyContacts>? contacts;
  const _EmergencyContactsCard({this.contacts});

  Future<void> _callNumber(String number) async {
    final uri = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (contacts == null || contacts!.isEmpty) {
      return const SizedBox.shrink(); // hide if empty
    }

    return _SectionCard(
      icon: Icons.group_outlined,
      title: 'Emergency Contacts',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(0, 14, 0, 18),
        child: ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: contacts!.length,
          itemBuilder: (context, index) {
            final contact = contacts![index];
            final name = contact.name ?? 'Unknown';
            final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: kGreen,
                    child: Text(
                      initial,
                      style: const TextStyle(
                        color: kGreenText,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: Color(0xFF111827),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          contact.relationship ?? '',
                          style: const TextStyle(fontSize: 13, color: kGrey),
                        ),
                      ],
                    ),
                  ),
                  // Call icon → opens dial pad
                  if (contact.mobileNumber != null &&
                      contact.mobileNumber!.isNotEmpty)
                    GestureDetector(
                      onTap: () => _callNumber(contact.mobileNumber!),
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: kBlueLight,
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFBFDBFE)),
                        ),
                        child: const Icon(
                          Icons.phone_outlined,
                          color: kBlue,
                          size: 20,
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
// GET APP BANNER
// ─────────────────────────────────────────────
class _GetAppBanner extends StatelessWidget {
  const _GetAppBanner();

  Future<void> _openPlayStore() async {
    // Replace with your actual package name
    final uri = Uri.parse(
      'https://play.google.com/store/apps/details?id=ai.blueera.app',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _openAppStore() async {
    // Replace with your actual App Store link
    final uri = Uri.parse('https://apps.apple.com/app/blueera/id0000000000');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _installNow() async {
    // Opens Play Store on Android, App Store on iOS.
    // url_launcher resolves platform automatically via universal links.
    // Adjust the URI to your app's universal/smart-app-banner link.
    final uri = Uri.parse('https://emergency.beapp.in/download');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: kBlue,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          const Text(
            'Get the Blue Era App',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Manage your emergency profile, contacts & alerts on the go',
            style: TextStyle(color: Colors.white70, fontSize: 14, height: 1.4),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),

          // Google Play
          _StoreButton(
            onTap: _openPlayStore,
            icon: Icons.play_arrow_rounded,
            label: 'Google Play',
          ),
          const SizedBox(height: 12),

          // App Store
          _StoreButton(
            onTap: _openAppStore,
            icon: Icons.apple,
            label: 'App Store',
          ),
          const SizedBox(height: 12),

          // Install Now
          GestureDetector(
            onTap: _installNow,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: kBlueDark,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Install Now — Takes you to the right store',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
// WHITE STORE BUTTON
// ─────────────────────────────────────────────
class _StoreButton extends StatelessWidget {
  final VoidCallback onTap;
  final IconData icon;
  final String label;

  const _StoreButton({
    required this.onTap,
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.black87, size: 20),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
