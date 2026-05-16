import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Terms & Conditions for BlueEra transport / parcel services. Designed as a
/// read-only legal document with a hero banner and sectioned cards. Picked up
/// the structure from typical Indian on-demand transport apps (cab + parcel
/// platforms) and adapted the wording for BlueEra.
class TermsAndConditionsScreen extends StatelessWidget {
  const TermsAndConditionsScreen({super.key});

  static const _appName = 'BlueEra';
  static const _lastUpdated = '05 May 2026';

  static const List<_TermSection> _sections = [
    _TermSection(
      icon: Icons.handshake_outlined,
      title: '1. Acceptance of Terms',
      body:
          'By creating an account or using $_appName services, you agree to be bound by these Terms & Conditions, our Privacy Policy, and any community guidelines published in-app. If you do not agree, please discontinue use of the platform.\n\nThese terms form a legally enforceable contract between you and $_appName under the Indian Contract Act, 1872 and the Information Technology Act, 2000.',
    ),
    _TermSection(
      icon: Icons.local_taxi_outlined,
      title: '2. Our Services',
      body:
          '$_appName is a technology platform that connects users with independent driver-partners and delivery-partners across India for the following services:\n\n• City rides (bike, auto, taxi, e-rickshaw)\n• Outstation cabs (4-seater, 7-seater)\n• Hourly rentals\n• Doorstep parcel pickup and drop\n\n$_appName does not own a fleet, employ drivers, or provide transportation directly. We act solely as an intermediary between users and partners under the Information Technology (Intermediary Guidelines) Rules.',
    ),
    _TermSection(
      icon: Icons.person_outline,
      title: '3. User Account & Eligibility',
      body:
          'You must be at least 18 years of age and capable of entering into a binding contract under Indian law. You agree to provide accurate, current and complete information during registration and to keep it updated.\n\nYou are responsible for safeguarding your login credentials and for any activity from your account. Notify $_appName immediately of any unauthorized use.',
    ),
    _TermSection(
      icon: Icons.directions_car_outlined,
      title: '4. Booking, Cancellation & No-Show',
      body:
          'A booking is confirmed only when a driver / delivery-partner accepts the request. Estimated fares shown before booking are indicative; the final fare may vary based on actual distance, waiting time, route, tolls and prevailing surge multipliers.\n\nCancellation fees may apply if you cancel after a partner has been assigned, after the free-cancellation window, or fail to board within the no-show grace period.',
    ),
    _TermSection(
      icon: Icons.payments_outlined,
      title: '5. Fares & Payments',
      body:
          'Fares are inclusive of applicable GST and platform fees, and may include tolls, parking, night charges, and waiting charges where applicable. Payment can be made through UPI, debit/credit cards, net banking, supported wallets or cash, subject to availability for that ride type.\n\nRefunds (if eligible) are processed back to the original payment instrument within 5–7 working days.',
    ),
    _TermSection(
      icon: Icons.location_on_outlined,
      title: '6. Pickup & Drop Responsibilities',
      body:
          'You are responsible for providing an accurate pickup and drop address and the contact details of the sender / receiver where applicable. Please be present at the pickup location at the scheduled time.\n\nFor parcel deliveries, the sender must verify identification of the delivery-partner and ensure the package is properly sealed before handover.',
    ),
    _TermSection(
      icon: Icons.block_outlined,
      title: '7. Prohibited Items (Parcel)',
      body:
          'For everyone\'s safety, the following items must not be sent through $_appName parcel services:\n\n• Cash, jewellery, gold and other valuables\n• Illegal narcotics, firearms, ammunition, explosives\n• Live animals, perishables that require cold-chain handling\n• Hazardous chemicals, flammable liquids, compressed gases\n• Counterfeit goods or any item prohibited by Indian law\n\n$_appName reserves the right to refuse, return or report any consignment found to contain prohibited items.',
    ),
    _TermSection(
      icon: Icons.shield_outlined,
      title: '8. Safety & Trusted Contacts',
      body:
          'Your safety is our priority. $_appName provides Live Ride Tracking, in-app SOS, masked-number calling and the ability to add up to 3 trusted contacts who can receive trip updates.\n\nIn case of an emergency, immediately use the in-app SOS button or contact local authorities on 112.',
    ),
    _TermSection(
      icon: Icons.report_gmailerrorred_outlined,
      title: '9. User Conduct',
      body:
          'You agree not to:\n\n• Misuse the platform, attempt unauthorized access or interfere with its operation\n• Harass, threaten or discriminate against driver / delivery-partners\n• Damage partner vehicles, leave behind hazardous items, or refuse to disembark at the drop location\n• Use the service to commit any unlawful act\n\nViolations may result in account suspension, refusal of service and reporting to law-enforcement authorities.',
    ),
    _TermSection(
      icon: Icons.gavel_outlined,
      title: '10. Limitation of Liability',
      body:
          '$_appName acts as a technology intermediary and does not guarantee uninterrupted service. To the maximum extent permitted by law, $_appName, its directors and employees shall not be liable for any indirect, incidental, special or consequential damages arising from use of the platform.\n\nOur total liability for any claim shall not exceed the value of the specific ride / parcel order to which the claim relates.',
    ),
    _TermSection(
      icon: Icons.privacy_tip_outlined,
      title: '11. Privacy & Data',
      body:
          'Your personal data — including contacts, location and payment information — is processed in accordance with our Privacy Policy and the Digital Personal Data Protection Act, 2023.\n\nLocation tracking is enabled only during an active ride and is shared with your trusted contacts only when you choose to share trip status.',
    ),
    _TermSection(
      icon: Icons.balance_outlined,
      title: '12. Governing Law & Jurisdiction',
      body:
          'These Terms are governed by the laws of India. Any dispute arising out of or in connection with these Terms shall be subject to the exclusive jurisdiction of the competent courts located in India.\n\nDisputes shall first be attempted to be resolved through good-faith discussion within 30 days of notice.',
    ),
    _TermSection(
      icon: Icons.support_agent_outlined,
      title: '13. Contact Us',
      body:
          'For questions, complaints or grievances regarding these Terms, please reach our Grievance Officer through the in-app Help & Support section, or write to us at support@beapp.in.\n\nWe respond to grievances within the timelines prescribed under the IT Rules.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8FF),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            const SliverToBoxAdapter(child: _Hero()),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
              sliver: SliverList.separated(
                itemCount: _sections.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (_, i) => _SectionCard(section: _sections[i]),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: Column(
                  children: [
                    const _FooterBadge(),
                    const SizedBox(height: 14),
                    CustomText(
                      '© 2026 $_appName Technologies Pvt. Ltd.\nAll rights reserved.',
                      fontSize: 11,
                      color: AppColors.grayText,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Hero ───────────────────────────────────────────────────────────────────

class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: _HeroClipper(),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0086FF),
              Color(0xFF0064CC),
            ],
          ),
        ),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 38),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                InkWell(
                  onTap: () => Get.back(),
                  borderRadius: BorderRadius.circular(24),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_back,
                        color: AppColors.white, size: 20),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const CustomText(
                    'Updated ${TermsAndConditionsScreen._lastUpdated}',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.description_outlined,
                  size: 28, color: AppColors.white),
            ),
            const SizedBox(height: 14),
            const CustomText(
              'Terms & Conditions',
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AppColors.white,
            ),
            const SizedBox(height: 6),
            CustomText(
              '${TermsAndConditionsScreen._appName} User Agreement — please read these terms carefully before using our services.',
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.9),
            ),
            const SizedBox(height: 16),
            Row(
              children: const [
                _MetaChip(
                    icon: Icons.location_on_outlined, label: 'India'),
                SizedBox(width: 8),
                _MetaChip(
                    icon: Icons.menu_book_outlined,
                    label: '13 sections'),
                SizedBox(width: 8),
                _MetaChip(
                    icon: Icons.schedule_outlined,
                    label: '~6 min read'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final p = Path();
    p.lineTo(0, size.height - 26);
    p.quadraticBezierTo(size.width / 2, size.height + 24,
        size.width, size.height - 26);
    p.lineTo(size.width, 0);
    p.close();
    return p;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _MetaChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.white),
          const SizedBox(width: 4),
          CustomText(
            label,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.white,
          ),
        ],
      ),
    );
  }
}

// ─── Section card ───────────────────────────────────────────────────────────

class _TermSection {
  final IconData icon;
  final String title;
  final String body;

  const _TermSection({
    required this.icon,
    required this.title,
    required this.body,
  });
}

class _SectionCard extends StatelessWidget {
  final _TermSection section;

  const _SectionCard({required this.section});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(section.icon,
                    color: AppColors.primaryColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: CustomText(
                  section.title,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(height: 1, color: AppColors.whiteE5),
          const SizedBox(height: 10),
          CustomText(
            section.body,
            fontSize: 13,
            color: AppColors.grayText,
            height: 1.55,
          ),
        ],
      ),
    );
  }
}

// ─── Footer badge ───────────────────────────────────────────────────────────

class _FooterBadge extends StatelessWidget {
  const _FooterBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primaryColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.primaryColor.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: const [
          Icon(Icons.verified_outlined,
              size: 18, color: AppColors.primaryColor),
          SizedBox(width: 10),
          Expanded(
            child: CustomText(
              'By continuing to use BlueEra, you confirm that you have read and accepted these Terms & Conditions.',
              fontSize: 12,
              color: AppColors.primaryColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
