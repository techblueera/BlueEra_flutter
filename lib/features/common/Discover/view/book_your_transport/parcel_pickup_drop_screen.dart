import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/common/Discover/controller/discover_controller.dart';
import 'package:BlueEra/features/common/Discover/view/book_your_transport/book_transport_main.dart';
import 'package:BlueEra/features/common/Discover/view/book_your_transport/search_transport_address.dart';
import 'package:BlueEra/features/common/Discover/view/book_your_transport/terms_and_conditions_screen.dart';
import 'package:BlueEra/features/common/Discover/view/book_your_transport/trusted_contacts_screen.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Pickup & drop entry screen. Sender / receiver contact rows on the address
/// cards only appear when [vehicleType] is `GOODS` (parcel booking) — for
/// in-city / outstation / hourly rentals the rider doesn't need a separate
/// contact, so those rows are hidden.
class ParcelPickupDropScreen extends StatefulWidget {
  final String? vehicleType;

  const ParcelPickupDropScreen({super.key, this.vehicleType});

  @override
  State<ParcelPickupDropScreen> createState() => _ParcelPickupDropScreenState();
}

class _ParcelPickupDropScreenState extends State<ParcelPickupDropScreen> {
  final discoverController = getOrPut(() => DiscoverController());

  final TextEditingController _pickupNameCtrl = TextEditingController();
  final TextEditingController _pickupPhoneCtrl = TextEditingController();
  final TextEditingController _dropNameCtrl = TextEditingController();
  final TextEditingController _dropPhoneCtrl = TextEditingController();
  List<TrustedContact> _trustedContacts = [];

  bool get _isParcel => widget.vehicleType == 'GOODS';

  @override
  void initState() {
    super.initState();
    discoverController.selectedHorizontalTab.value = _isParcel ? 3 : 0;
  }

  @override
  void dispose() {
    _pickupNameCtrl.dispose();
    _pickupPhoneCtrl.dispose();
    _dropNameCtrl.dispose();
    _dropPhoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _openTrustedContacts() async {
    final result = await Get.to<List<TrustedContact>>(() =>
        TrustedContactsScreen(initial: _trustedContacts));
    if (result != null) {
      setState(() => _trustedContacts = result);
    }
  }

  void _editAddress() {
    Get.to(() => SearchTransportAddress(
          onPlaceSelected: () {},
        ));
  }

  Future<void> _editContact({
    required String title,
    required TextEditingController nameCtrl,
    required TextEditingController phoneCtrl,
  }) async {
    final nameTemp = TextEditingController(text: nameCtrl.text);
    final phoneTemp = TextEditingController(text: phoneCtrl.text);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(title, fontSize: 16, fontWeight: FontWeight.w600),
              const SizedBox(height: 14),
              TextField(
                controller: nameTemp,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  hintText: 'Receiver name',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: phoneTemp,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                decoration: const InputDecoration(
                  hintText: '10-digit mobile number',
                  prefixText: '+91 ',
                  border: OutlineInputBorder(),
                  isDense: true,
                  counterText: '',
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    final phone = phoneTemp.text.trim();
                    if (nameTemp.text.trim().isEmpty) {
                      commonSnackBar(message: 'Please enter a name');
                      return;
                    }
                    if (phone.length != 10 ||
                        int.tryParse(phone) == null) {
                      commonSnackBar(
                          message: 'Enter a valid 10-digit number');
                      return;
                    }
                    setState(() {
                      nameCtrl.text = nameTemp.text.trim();
                      phoneCtrl.text = phone;
                    });
                    Get.back();
                  },
                  child: const Text(
                    'Save',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _swap() {
    final fromAddr = discoverController.selectedFromAddress?.value ?? '';
    final toAddr = discoverController.selectedToAddress?.value ?? '';
    final fromLat = discoverController.selectedFromLat?.value ?? 0.0;
    final fromLng = discoverController.selectedFromLong?.value ?? 0.0;
    final toLat = discoverController.selectedToLat?.value ?? 0.0;
    final toLng = discoverController.selectedToLong?.value ?? 0.0;

    discoverController.selectedFromAddress?.value = toAddr;
    discoverController.selectedToAddress?.value = fromAddr;
    discoverController.selectedFromLat?.value = toLat;
    discoverController.selectedFromLong?.value = toLng;
    discoverController.selectedToLat?.value = fromLat;
    discoverController.selectedToLong?.value = fromLng;

    final tmpName = _pickupNameCtrl.text;
    final tmpPhone = _pickupPhoneCtrl.text;
    setState(() {
      _pickupNameCtrl.text = _dropNameCtrl.text;
      _pickupPhoneCtrl.text = _dropPhoneCtrl.text;
      _dropNameCtrl.text = tmpName;
      _dropPhoneCtrl.text = tmpPhone;
    });
  }

  bool get _canContinue {
    final hasFrom = (discoverController.selectedFromLat?.value ?? 0) != 0.0 &&
        (discoverController.selectedFromLong?.value ?? 0) != 0.0;
    final hasTo = (discoverController.selectedToLat?.value ?? 0) != 0.0 &&
        (discoverController.selectedToLong?.value ?? 0) != 0.0;
    if (!hasFrom || !hasTo) return false;
    if (_isParcel) {
      if (_pickupNameCtrl.text.isEmpty ||
          _pickupPhoneCtrl.text.isEmpty ||
          _dropNameCtrl.text.isEmpty ||
          _dropPhoneCtrl.text.isEmpty) {
        return false;
      }
    }
    return _trustedContacts.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBlue,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.zero,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ParcelHeroBanner(onBack: () => Get.back()),
                    Padding(
                      padding:
                          const EdgeInsets.fromLTRB(14, 14, 14, 0),
                      child: Obx(() {
                        return _AddressBlock(
                          showContacts: _isParcel,
                          pickupAddress:
                              discoverController.selectedFromAddress?.value ??
                                  '',
                          dropAddress:
                              discoverController.selectedToAddress?.value ??
                                  '',
                          pickupName: _pickupNameCtrl.text,
                          pickupPhone: _pickupPhoneCtrl.text,
                          dropName: _dropNameCtrl.text,
                          dropPhone: _dropPhoneCtrl.text,
                          onEditPickupAddress: _editAddress,
                          onEditDropAddress: _editAddress,
                          onEditPickupContact: () => _editContact(
                            title: 'Pickup contact',
                            nameCtrl: _pickupNameCtrl,
                            phoneCtrl: _pickupPhoneCtrl,
                          ),
                          onEditDropContact: () => _editContact(
                            title: 'Drop contact',
                            nameCtrl: _dropNameCtrl,
                            phoneCtrl: _dropPhoneCtrl,
                          ),
                          onSwap: _swap,
                        );
                      }),
                    ),
                    const SizedBox(height: 14),
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 14),
                      child: _TrustedContactsButton(
                        contacts: _trustedContacts,
                        onTap: _openTrustedContacts,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: () => Get.to(
                                () => const TermsAndConditionsScreen()),
                            child: RichText(
                              text: TextSpan(
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.grayText,
                                ),
                                children: const [
                                  TextSpan(
                                      text: 'By continuing, you agree to our '),
                                  TextSpan(
                                    text: 'T&Cs',
                                    style: TextStyle(
                                      color: AppColors.primaryColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: SizeConfig.size20),
                  ],
                ),
              ),
            ),
            _ContinueBar(
              enabled: _canContinue,
              onTap: () {
                if (!_canContinue) {
                  commonSnackBar(
                      message:
                          'Add pickup, drop and contacts to continue');
                  return;
                }
                Get.to(() => const BookTransportMain());
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Hero banner ────────────────────────────────────────────────────────────

class _ParcelHeroBanner extends StatelessWidget {
  final VoidCallback onBack;

  const _ParcelHeroBanner({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: _BannerClipper(),
      child: Container(
        height: 270,
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFE4F2FF),
              Color(0xFFD9EBFF),
            ],
          ),
        ),
        child: Stack(
          children: [
            Positioned(
              top: 8,
              left: 8,
              child: IconButton(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back,
                    color: AppColors.black, size: 22),
              ),
            ),
            const Positioned(
              top: 18,
              left: 0,
              right: 0,
              child: Center(
                child: CustomText(
                  'Doorstep pickup and delivery',
                  fontSize: 14,
                  color: AppColors.grayText,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Positioned(
              left: -10,
              bottom: 22,
              child: _BikeIllustration(),
            ),
            const Positioned(
              right: -10,
              bottom: 22,
              child: _AutoIllustration(),
            ),
            const Positioned(
              left: 0,
              right: 0,
              bottom: 92,
              child: Center(child: _CarIllustration()),
            ),
            const Positioned(
              left: 0,
              right: 0,
              bottom: 18,
              child: Center(child: _ParcelItems()),
            ),
          ],
        ),
      ),
    );
  }
}

class _BannerClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 22);
    path.quadraticBezierTo(
      size.width / 2,
      size.height + 22,
      size.width,
      size.height - 22,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _BikeIllustration extends StatelessWidget {
  const _BikeIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 90,
      width: 130,
      child: LocalAssets(
        imagePath: AppIconAssets.transport_bike,
        height: 90,
        width: 130,
      ),
    );
  }
}

class _AutoIllustration extends StatelessWidget {
  const _AutoIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      width: 130,
      child: LocalAssets(
        imagePath: AppIconAssets.transport_auto,
        height: 100,
        width: 130,
      ),
    );
  }
}

class _CarIllustration extends StatelessWidget {
  const _CarIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      width: 110,
      child: LocalAssets(
        imagePath: AppIconAssets.transport_taxi,
        height: 60,
        width: 110,
      ),
    );
  }
}

class _ParcelItems extends StatelessWidget {
  const _ParcelItems();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: const [
        Icon(Icons.shopping_bag,
            size: 56, color: Color(0xFFC58A4B)),
        SizedBox(width: 6),
        Icon(Icons.luggage, size: 50, color: Color(0xFF9AA3AB)),
        SizedBox(width: 6),
        Icon(Icons.local_florist,
            size: 30, color: Color(0xFF4CAF50)),
        Icon(Icons.inventory_2,
            size: 50, color: Color(0xFFB07A48)),
      ],
    );
  }
}

// ─── Address card stack with swap pill ──────────────────────────────────────

class _AddressBlock extends StatelessWidget {
  final bool showContacts;
  final String pickupAddress;
  final String dropAddress;
  final String pickupName;
  final String pickupPhone;
  final String dropName;
  final String dropPhone;
  final VoidCallback onEditPickupAddress;
  final VoidCallback onEditDropAddress;
  final VoidCallback onEditPickupContact;
  final VoidCallback onEditDropContact;
  final VoidCallback onSwap;

  const _AddressBlock({
    required this.showContacts,
    required this.pickupAddress,
    required this.dropAddress,
    required this.pickupName,
    required this.pickupPhone,
    required this.dropName,
    required this.dropPhone,
    required this.onEditPickupAddress,
    required this.onEditDropAddress,
    required this.onEditPickupContact,
    required this.onEditDropContact,
    required this.onSwap,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Column(
          children: [
            _AddressCard(
              isPickup: true,
              showContact: showContacts,
              title: 'Pickup from current location',
              address: pickupAddress.isEmpty
                  ? 'Tap to select pickup address'
                  : pickupAddress,
              contactName: pickupName,
              contactPhone: pickupPhone,
              onEditAddress: onEditPickupAddress,
              onEditContact: onEditPickupContact,
            ),
            const SizedBox(height: 18),
            _AddressCard(
              isPickup: false,
              showContact: showContacts,
              title: 'Drop to',
              address: dropAddress.isEmpty
                  ? 'Tap to select drop address'
                  : dropAddress,
              contactName: dropName,
              contactPhone: dropPhone,
              onEditAddress: onEditDropAddress,
              onEditContact: onEditDropContact,
            ),
          ],
        ),
        Positioned.fill(
          child: Align(
            alignment: Alignment.center,
            child: Padding(
              padding: const EdgeInsets.only(right: 18),
              child: _SwapPill(onTap: onSwap),
            ),
          ),
        ),
      ],
    );
  }
}

class _AddressCard extends StatelessWidget {
  final bool isPickup;
  final bool showContact;
  final String title;
  final String address;
  final String contactName;
  final String contactPhone;
  final VoidCallback onEditAddress;
  final VoidCallback onEditContact;

  const _AddressCard({
    required this.isPickup,
    required this.showContact,
    required this.title,
    required this.address,
    required this.contactName,
    required this.contactPhone,
    required this.onEditAddress,
    required this.onEditContact,
  });

  @override
  Widget build(BuildContext context) {
    final hasContact = contactName.isNotEmpty && contactPhone.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onEditAddress,
            borderRadius: BorderRadius.circular(8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _LocationDot(isPickup: isPickup),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomText(
                        title,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.black,
                      ),
                      const SizedBox(height: 4),
                      CustomText(
                        address,
                        fontSize: 13,
                        color: AppColors.grayText,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.edit_outlined,
                    size: 16, color: AppColors.grayText),
              ],
            ),
          ),
          if (showContact) ...[
            const SizedBox(height: 10),
            _DashedDivider(color: AppColors.whiteE5),
            const SizedBox(height: 10),
            InkWell(
              onTap: onEditContact,
              borderRadius: BorderRadius.circular(8),
              child: Row(
                children: [
                  Expanded(
                    child: hasContact
                        ? CustomText(
                            '$contactName ($contactPhone)',
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.black,
                          )
                        : CustomText(
                            isPickup
                                ? '+ Add sender contact'
                                : '+ Add receiver contact',
                            fontSize: 13,
                            color: AppColors.primaryColor,
                            fontWeight: FontWeight.w600,
                          ),
                  ),
                  if (hasContact)
                    const Icon(Icons.edit_outlined,
                        size: 14, color: AppColors.grayText),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LocationDot extends StatelessWidget {
  final bool isPickup;

  const _LocationDot({required this.isPickup});

  @override
  Widget build(BuildContext context) {
    if (isPickup) {
      return Column(
        children: [
          Icon(Icons.location_on,
              size: 22, color: const Color(0xFF1B7A3A)),
          Container(
            width: 2,
            height: 6,
            color: const Color(0xFF1B7A3A),
          ),
        ],
      );
    }
    return Container(
      margin: const EdgeInsets.only(top: 2),
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.red00, width: 3),
        color: AppColors.white,
      ),
    );
  }
}

class _DashedDivider extends StatelessWidget {
  final Color color;

  const _DashedDivider({required this.color});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const dashWidth = 4.0;
        const dashSpace = 3.0;
        final count =
            (constraints.maxWidth / (dashWidth + dashSpace)).floor();
        return Row(
          children: List.generate(count, (_) {
            return Container(
              width: dashWidth,
              height: 1,
              margin:
                  const EdgeInsets.symmetric(horizontal: dashSpace / 2),
              color: color,
            );
          }),
        );
      },
    );
  }
}

class _SwapPill extends StatelessWidget {
  final VoidCallback onTap;

  const _SwapPill({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Material(
        color: AppColors.white,
        elevation: 4,
        shadowColor: const Color(0x22000000),
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.swap_vert,
                    size: 18, color: AppColors.black),
                SizedBox(width: 4),
                CustomText(
                  'Switch',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.black,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Trusted Contacts CTA card ──────────────────────────────────────────────

class _TrustedContactsButton extends StatelessWidget {
  final List<TrustedContact> contacts;
  final VoidCallback onTap;

  const _TrustedContactsButton({
    required this.contacts,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasAny = contacts.isNotEmpty;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.whiteE5),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.red00.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.shield_outlined,
                  size: 20, color: AppColors.red00),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CustomText(
                    'Add Emergency Contacts',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.black,
                  ),
                  const SizedBox(height: 2),
                  CustomText(
                    hasAny
                        ? '${contacts.length}/$kMaxTrustedContacts trusted contacts'
                        : 'Pick up to $kMaxTrustedContacts people we can reach if needed',
                    fontSize: 12,
                    color: AppColors.grayText,
                  ),
                ],
              ),
            ),
            Icon(
              hasAny ? Icons.edit_outlined : Icons.add,
              size: 18,
              color: AppColors.primaryColor,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Continue button ────────────────────────────────────────────────────────

class _ContinueBar extends StatelessWidget {
  final bool enabled;
  final VoidCallback onTap;

  const _ContinueBar({required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: enabled
                ? AppColors.primaryColor
                : AppColors.primaryColor.withValues(alpha: 0.6),
            foregroundColor: AppColors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
          ),
          child: const Text(
            'Continue',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
