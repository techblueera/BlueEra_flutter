// import 'package:BlueEra/core/constants/app_colors.dart';
// import 'package:BlueEra/core/constants/app_strings.dart';
// import 'package:BlueEra/core/constants/shared_preference_utils.dart';
// import 'package:BlueEra/core/constants/size_config.dart';
// import 'package:BlueEra/core/services/address_cache_service.dart';
// import 'package:BlueEra/core/services/location/location_service.dart';
// import 'package:BlueEra/features/chat/auth/model/get_adress_details_model.dart';
// import 'package:BlueEra/features/common/Discover/view/grocery_self_pickup_cart_screen.dart';
// import 'package:BlueEra/features/me/grocery/controller/grocery_selfpickup_consumer_controller.dart';
// import 'package:BlueEra/widgets/custom_text_cm.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:get/get.dart';
//
// class YourCartScreen extends StatefulWidget {
//   const YourCartScreen({super.key});
//
//   @override
//   State<YourCartScreen> createState() => _YourCartScreenState();
// }
//
// class _YourCartScreenState extends State<YourCartScreen> {
//   final _addressCache = AddressCacheService();
//
//   final Rx<AddressDetails?> _selectedAddress = Rx<AddressDetails?>(null);
//   final RxList<AddressDetails> _addresses = <AddressDetails>[].obs;
//
//   String get _userId => userId;
//
//   @override
//   void initState() {
//     super.initState();
//     _refreshAddresses();
//   }
//
//   void _refreshAddresses() {
//     _addresses.assignAll(_addressCache.getAddresses(_userId));
//     _selectedAddress.value = _addressCache.getSelectedAddress(_userId);
//   }
//
//   // ─── Add Address ───────────────────────────────────────────────
//
//   void _openAddAddressForm() {
//     if (_addresses.length >= AddressCacheService.maxAddresses) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(
//               'Maximum ${AddressCacheService.maxAddresses} addresses allowed. Delete one to add new.'),
//           behavior: SnackBarBehavior.floating,
//         ),
//       );
//       return;
//     }
//
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Colors.transparent,
//       builder: (_) => _AddAddressForm(
//         onSaved: (address) async {
//           final success = await _addressCache.addAddress(_userId, address);
//           if (success) {
//             _refreshAddresses();
//             if (mounted) Navigator.pop(context);
//           }
//         },
//       ),
//     );
//   }
//
//   // ─── Change Address ────────────────────────────────────────────
//
//   void _openChangeAddress() {
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Colors.transparent,
//       builder: (_) => _AddressSelectionSheet(
//         addresses: _addresses,
//         selectedAddressId: _selectedAddress.value?.id,
//         onSelect: (address) {
//           _selectedAddress.value = address;
//           _addressCache.saveSelectedAddressId(_userId, address.id ?? '');
//           Navigator.pop(context);
//         },
//         onDelete: (addressId) async {
//           await _addressCache.deleteAddress(_userId, addressId);
//           _refreshAddresses();
//         },
//         onAddNew: () {
//           Navigator.pop(context);
//           _openAddAddressForm();
//         },
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.transparent,
//       appBar: AppBar(
//         backgroundColor: AppColors.white,
//         surfaceTintColor: AppColors.white,
//         elevation: 0,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back_ios_new_rounded,
//               color: AppColors.mainTextColor, size: 20),
//           onPressed: () => Navigator.pop(context),
//         ),
//         title: CustomText(
//           'Your Cart',
//           fontSize: SizeConfig.extraLarge,
//           fontWeight: FontWeight.w700,
//           color: AppColors.mainTextColor,
//         ),
//         bottom: PreferredSize(
//           preferredSize: const Size.fromHeight(1),
//           child: Container(color: AppColors.appBackgroundColor, height: 1),
//         ),
//       ),
//       body: Column(
//         children: [
//           Expanded(
//             child: SingleChildScrollView(
//               padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
//               child: Column(
//                 children: [
//                   _buildDeliveryTypeCard(
//                     context,
//                     deliveryType: 'SELF',
//                     title: 'Self Pick-Up',
//                     accentColor: const Color(0xFFE6A800),
//                     bgGradientStart: const Color(0xFFFFFDF5),
//                     bgGradientEnd: const Color(0xFFFFF8E1),
//                     iconData: Icons.shopping_bag_outlined,
//                     iconBgColor: const Color(0xFFFFF0B3),
//                   ),
//                   const SizedBox(height: 14),
//                   _buildDeliveryTypeCard(
//                     context,
//                     deliveryType: 'RIDER',
//                     title: 'Book Rider',
//                     accentColor: const Color(0xFF1565C0),
//                     bgGradientStart: const Color(0xFFF5FAFF),
//                     bgGradientEnd: const Color(0xFFE3F2FD),
//                     iconData: Icons.delivery_dining,
//                     iconBgColor: const Color(0xFFBBDEFB),
//                   ),
//                   const SizedBox(height: 14),
//                   _buildDeliveryTypeCard(
//                     context,
//                     deliveryType: 'PARTNER',
//                     title: 'Order Via Partner',
//                     accentColor: const Color(0xFFE65100),
//                     bgGradientStart: const Color(0xFFFFFBF5),
//                     bgGradientEnd: const Color(0xFFFFF3E0),
//                     iconData: Icons.local_shipping_outlined,
//                     iconBgColor: const Color(0xFFFFE0B2),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//
//           /// Bottom address section
//           _buildAddressSection(),
//         ],
//       ),
//     );
//   }
//
//   // ─── Address Section ───────────────────────────────────────────
//
//   Widget _buildAddressSection() {
//     return Obx(() {
//       final address = _selectedAddress.value;
//       final hasAddresses = _addresses.isNotEmpty;
//
//       return Container(
//         decoration: BoxDecoration(
//           color: AppColors.white,
//           boxShadow: [
//             BoxShadow(
//               color: AppColors.black.withValues(alpha: 0.08),
//               blurRadius: 12,
//               offset: const Offset(0, -4),
//             ),
//           ],
//           borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
//         ),
//         child: SafeArea(
//           top: false,
//           child: Padding(
//             padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
//             child: hasAddresses && address != null
//                 ? _addressAvailableWidget(address)
//                 : _noAddressWidget(),
//           ),
//         ),
//       );
//     });
//   }
//
//   Widget _buildDeliveryTypeCard(
//     BuildContext context, {
//     required String deliveryType,
//     required String title,
//     required Color accentColor,
//     required Color bgGradientStart,
//     required Color bgGradientEnd,
//     required IconData iconData,
//     required Color iconBgColor,
//   }) {
//     final bool hasController =
//         Get.isRegistered<GroceryCustomerController>();
//
//     if (!hasController) {
//       return _CartCard(
//         title: title,
//         subtitle: '0 Shops - 0 Items',
//         accentColor: accentColor,
//         bgGradientStart: bgGradientStart,
//         bgGradientEnd: bgGradientEnd,
//         iconData: iconData,
//         iconBgColor: iconBgColor,
//         payPrice: '\u20B90',
//         payOriginalPrice: '\u20B90',
//         savePrice: '\u20B90',
//         discountPercent: '0% Off',
//         onTap: () {
//           Navigator.push(
//             context,
//             MaterialPageRoute(
//               builder: (_) => SelfPickUpCartScreen(deliveryType: deliveryType),
//             ),
//           );
//         },
//       );
//     }
//
//     final controller = Get.find<GroceryCustomerController>();
//
//     return Obx(() {
//       final int shopCount = controller.shopCountByDeliveryType(deliveryType);
//       final int totalItems = controller.itemsCountByDeliveryType(deliveryType);
//       final double totalSellingPrice = controller.totalSellingPriceByDeliveryType(deliveryType);
//       final double totalMRP = controller.totalMRPByDeliveryType(deliveryType);
//       final double totalSavings = controller.totalSavingsByDeliveryType(deliveryType);
//       final double discountPct = controller.totalDiscountPercentageByDeliveryType(deliveryType);
//
//       return _CartCard(
//         title: title,
//         subtitle: '$shopCount ${shopCount == 1 ? 'Shop' : 'Shops'} - $totalItems ${totalItems == 1 ? 'Item' : 'Items'}',
//         accentColor: accentColor,
//         bgGradientStart: bgGradientStart,
//         bgGradientEnd: bgGradientEnd,
//         iconData: iconData,
//         iconBgColor: iconBgColor,
//         payPrice: '\u20B9${totalSellingPrice.toStringAsFixed(0)}',
//         payOriginalPrice: '\u20B9${totalMRP.toStringAsFixed(0)}',
//         savePrice: '\u20B9${totalSavings.toStringAsFixed(0)}',
//         discountPercent: '${discountPct.toStringAsFixed(0)}% Off',
//         onTap: () {
//           Navigator.push(
//             context,
//             MaterialPageRoute(
//               builder: (_) => SelfPickUpCartScreen(deliveryType: deliveryType),
//             ),
//           );
//         },
//       );
//     });
//   }
//
//   Widget _noAddressWidget() {
//     return Row(
//       children: [
//         _iconBox(Icons.location_on_rounded, AppColors.primaryColor),
//         const SizedBox(width: 12),
//         Expanded(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               CustomText(
//                 'No delivery address',
//                 fontSize: SizeConfig.medium,
//                 color: AppColors.mainTextColor,
//                 fontWeight: FontWeight.w600,
//               ),
//               const SizedBox(height: 2),
//               CustomText(
//                 'Add an address to proceed',
//                 fontSize: SizeConfig.small,
//                 color: AppColors.secondaryTextColor,
//               ),
//             ],
//           ),
//         ),
//         const SizedBox(width: 8),
//         _actionChip(
//           icon: Icons.add,
//           label: AppStrings.addAddress,
//           filled: true,
//           onTap: _openAddAddressForm,
//         ),
//       ],
//     );
//   }
//
//   Widget _addressAvailableWidget(AddressDetails address) {
//     return Column(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         Row(
//           children: [
//             _iconBox(Icons.location_on_rounded, AppColors.primaryColor),
//             const SizedBox(width: 12),
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Row(
//                     children: [
//                       CustomText(
//                         'Deliver to',
//                         fontSize: SizeConfig.small,
//                         color: AppColors.secondaryTextColor,
//                         fontWeight: FontWeight.w500,
//                       ),
//                       if (address.isDefault == true) ...[
//                         const SizedBox(width: 8),
//                         Container(
//                           padding: const EdgeInsets.symmetric(
//                               horizontal: 6, vertical: 2),
//                           decoration: BoxDecoration(
//                             color: AppColors.green1A.withValues(alpha: 0.12),
//                             borderRadius: BorderRadius.circular(4),
//                           ),
//                           child: CustomText(
//                             AppStrings.defaultAddress,
//                             fontSize: SizeConfig.extraSmall8,
//                             color: AppColors.green1A,
//                             fontWeight: FontWeight.w600,
//                           ),
//                         ),
//                       ],
//                     ],
//                   ),
//                   const SizedBox(height: 2),
//                   CustomText(
//                     _formatTitle(address),
//                     fontSize: SizeConfig.medium,
//                     color: AppColors.mainTextColor,
//                     fontWeight: FontWeight.w600,
//                     maxLines: 1,
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                 ],
//               ),
//             ),
//             const SizedBox(width: 8),
//             _actionChip(
//               label: 'Change',
//               onTap: _openChangeAddress,
//             ),
//           ],
//         ),
//         const SizedBox(height: 10),
//         Container(
//           width: double.infinity,
//           padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
//           decoration: BoxDecoration(
//             color: AppColors.fillColor,
//             borderRadius: BorderRadius.circular(10),
//           ),
//           child: Row(
//             children: [
//               Icon(_typeIcon(address.type),
//                   size: 16, color: AppColors.secondaryTextColor),
//               const SizedBox(width: 8),
//               Expanded(
//                 child: CustomText(
//                   _buildFullAddress(address),
//                   fontSize: SizeConfig.small,
//                   color: AppColors.secondaryTextColor,
//                   maxLines: 2,
//                   overflow: TextOverflow.ellipsis,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }
//
//   // ─── Shared helpers ────────────────────────────────────────────
//
//   Widget _iconBox(IconData icon, Color color) {
//     return Container(
//       padding: const EdgeInsets.all(8),
//       decoration: BoxDecoration(
//         color: color.withValues(alpha: 0.1),
//         borderRadius: BorderRadius.circular(10),
//       ),
//       child: Icon(icon, color: color, size: 20),
//     );
//   }
//
//   Widget _actionChip({
//     IconData? icon,
//     required String label,
//     bool filled = false,
//     required VoidCallback onTap,
//   }) {
//     return InkWell(
//       onTap: onTap,
//       borderRadius: BorderRadius.circular(8),
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//         decoration: BoxDecoration(
//           color: filled ? AppColors.primaryColor : null,
//           border: filled ? null : Border.all(color: AppColors.primaryColor),
//           borderRadius: BorderRadius.circular(8),
//         ),
//         child: Row(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             if (icon != null) ...[
//               Icon(icon,
//                   size: 16,
//                   color: filled ? AppColors.white : AppColors.primaryColor),
//               const SizedBox(width: 4),
//             ],
//             CustomText(
//               label,
//               fontSize: SizeConfig.small,
//               color: filled ? AppColors.white : AppColors.primaryColor,
//               fontWeight: FontWeight.w600,
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   String _formatTitle(AddressDetails a) {
//     final parts = <String>[];
//     if (a.name != null && a.name!.isNotEmpty) parts.add(a.name!);
//     if (a.type != null && a.type!.isNotEmpty) parts.add('(${a.type})');
//     return parts.join(' ');
//   }
//
//   static String _buildFullAddress(AddressDetails a) {
//     final parts = <String>[];
//     if (a.houseNo != null && a.houseNo!.isNotEmpty) parts.add(a.houseNo!);
//     if (a.street != null && a.street!.isNotEmpty) parts.add(a.street!);
//     if (a.landmark != null && a.landmark!.isNotEmpty) parts.add(a.landmark!);
//     if (a.city != null && a.city!.isNotEmpty) parts.add(a.city!);
//     if (a.state != null && a.state!.isNotEmpty) parts.add(a.state!);
//     if (a.zipCode != null && a.zipCode!.isNotEmpty) {
//       parts.add('- ${a.zipCode}');
//     }
//     return parts.join(', ');
//   }
//
//   static IconData _typeIcon(String? type) {
//     switch (type?.toLowerCase()) {
//       case 'home':
//         return Icons.home_outlined;
//       case 'office':
//       case 'work':
//         return Icons.business_outlined;
//       default:
//         return Icons.location_on_outlined;
//     }
//   }
// }
//
// // ═══════════════════════════════════════════════════════════════════
// //  ADD ADDRESS FORM (BOTTOM SHEET)
// // ═══════════════════════════════════════════════════════════════════
//
// class _AddAddressForm extends StatefulWidget {
//   final Future<void> Function(AddressDetails address) onSaved;
//
//   const _AddAddressForm({required this.onSaved});
//
//   @override
//   State<_AddAddressForm> createState() => _AddAddressFormState();
// }
//
// class _AddAddressFormState extends State<_AddAddressForm> {
//   final _formKey = GlobalKey<FormState>();
//   final _nameCtrl = TextEditingController();
//   final _phoneCtrl = TextEditingController();
//   final _houseCtrl = TextEditingController();
//   final _streetCtrl = TextEditingController();
//   final _landmarkCtrl = TextEditingController();
//   final _cityCtrl = TextEditingController();
//   final _stateCtrl = TextEditingController();
//   final _pincodeCtrl = TextEditingController();
//
//   String _selectedType = 'Home';
//   bool _isDefault = false;
//   bool _isFetchingLocation = false;
//   double? _lat;
//   double? _lng;
//
//   @override
//   void dispose() {
//     _nameCtrl.dispose();
//     _phoneCtrl.dispose();
//     _houseCtrl.dispose();
//     _streetCtrl.dispose();
//     _landmarkCtrl.dispose();
//     _cityCtrl.dispose();
//     _stateCtrl.dispose();
//     _pincodeCtrl.dispose();
//     super.dispose();
//   }
//
//   Future<void> _fetchCurrentLocation() async {
//     setState(() => _isFetchingLocation = true);
//     try {
//       final result = await LocationService.fetchLocation(openSettingsOnDeny: true);
//       if (result != null) {
//         final addr = LocationService.userCurrentAddress.value;
//         _lat = LocationService.lat;
//         _lng = LocationService.lng;
//         setState(() {
//           if (_streetCtrl.text.isEmpty) {
//             _streetCtrl.text = [addr.street, addr.subLocality]
//                 .where((e) => e.isNotEmpty)
//                 .join(', ');
//           }
//           if (_cityCtrl.text.isEmpty) _cityCtrl.text = addr.city;
//           if (_stateCtrl.text.isEmpty) _stateCtrl.text = addr.state;
//           if (_pincodeCtrl.text.isEmpty) _pincodeCtrl.text = addr.postalCode;
//         });
//       } else {
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(
//               content: Text('Could not fetch location. Please check permissions.'),
//               behavior: SnackBarBehavior.floating,
//             ),
//           );
//         }
//       }
//     } catch (_) {
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('Location fetch failed. Try again.'),
//             behavior: SnackBarBehavior.floating,
//           ),
//         );
//       }
//     } finally {
//       if (mounted) setState(() => _isFetchingLocation = false);
//     }
//   }
//
//   void _saveAddress() {
//     if (!_formKey.currentState!.validate()) return;
//
//     final address = AddressDetails(
//       name: _nameCtrl.text.trim(),
//       phone: _phoneCtrl.text.trim(),
//       houseNo: _houseCtrl.text.trim(),
//       street: _streetCtrl.text.trim(),
//       landmark: _landmarkCtrl.text.trim(),
//       city: _cityCtrl.text.trim(),
//       state: _stateCtrl.text.trim(),
//       zipCode: _pincodeCtrl.text.trim(),
//       country: 'India',
//       type: _selectedType,
//       isDefault: _isDefault,
//       lat: _lat ?? LocationService.lat,
//       lng: _lng ?? LocationService.lng,
//     );
//
//     widget.onSaved(address);
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final bottomInset = MediaQuery.of(context).viewInsets.bottom;
//
//     return Container(
//       constraints: BoxConstraints(
//         maxHeight: MediaQuery.of(context).size.height * 0.9,
//       ),
//       decoration: const BoxDecoration(
//         color: AppColors.white,
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//       ),
//       child: Padding(
//         padding: EdgeInsets.only(bottom: bottomInset),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             /// Handle + title
//             const SizedBox(height: 12),
//             Container(
//               width: 40,
//               height: 4,
//               decoration: BoxDecoration(
//                 color: AppColors.greyCA,
//                 borderRadius: BorderRadius.circular(2),
//               ),
//             ),
//             const SizedBox(height: 16),
//             Padding(
//               padding: const EdgeInsets.symmetric(horizontal: 16),
//               child: Row(
//                 children: [
//                   CustomText(
//                     AppStrings.addAddress,
//                     fontSize: SizeConfig.large,
//                     fontWeight: FontWeight.w700,
//                     color: AppColors.mainTextColor,
//                   ),
//                   const Spacer(),
//                   IconButton(
//                     onPressed: () => Navigator.pop(context),
//                     icon: const Icon(Icons.close, size: 22),
//                     padding: EdgeInsets.zero,
//                     constraints: const BoxConstraints(),
//                   ),
//                 ],
//               ),
//             ),
//             const SizedBox(height: 4),
//             Container(height: 1, color: AppColors.appBackgroundColor),
//
//             /// Use Current Location button
//             Padding(
//               padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
//               child: InkWell(
//                 onTap: _isFetchingLocation ? null : _fetchCurrentLocation,
//                 borderRadius: BorderRadius.circular(10),
//                 child: Container(
//                   width: double.infinity,
//                   padding: const EdgeInsets.symmetric(vertical: 12),
//                   decoration: BoxDecoration(
//                     color: AppColors.primaryColor.withValues(alpha: 0.06),
//                     border: Border.all(
//                         color: AppColors.primaryColor.withValues(alpha: 0.3)),
//                     borderRadius: BorderRadius.circular(10),
//                   ),
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       if (_isFetchingLocation)
//                         SizedBox(
//                           width: 18,
//                           height: 18,
//                           child: CircularProgressIndicator(
//                             strokeWidth: 2,
//                             color: AppColors.primaryColor,
//                           ),
//                         )
//                       else
//                         Icon(Icons.my_location_rounded,
//                             size: 18, color: AppColors.primaryColor),
//                       const SizedBox(width: 8),
//                       CustomText(
//                         _isFetchingLocation
//                             ? 'Fetching location...'
//                             : 'Use Current Location',
//                         fontSize: SizeConfig.medium,
//                         color: AppColors.primaryColor,
//                         fontWeight: FontWeight.w600,
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//
//             /// Form
//             Flexible(
//               child: SingleChildScrollView(
//                 padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
//                 child: Form(
//                   key: _formKey,
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       _buildField(
//                         controller: _nameCtrl,
//                         label: 'Full Name',
//                         hint: 'Enter your name',
//                         keyboardType: TextInputType.name,
//                         isRequired: true,
//                         textCapitalization: TextCapitalization.words,
//                       ),
//                       _buildField(
//                         controller: _phoneCtrl,
//                         label: 'Phone Number',
//                         hint: 'Enter 10-digit number',
//                         keyboardType: TextInputType.phone,
//                         isRequired: true,
//                         maxLength: 10,
//                         inputFormatters: [
//                           FilteringTextInputFormatter.digitsOnly
//                         ],
//                         validator: (v) {
//                           if (v == null || v.trim().isEmpty) {
//                             return 'Phone number is required';
//                           }
//                           if (v.trim().length != 10) {
//                             return 'Enter valid 10-digit number';
//                           }
//                           return null;
//                         },
//                       ),
//                       _buildField(
//                         controller: _houseCtrl,
//                         label: 'House / Flat No.',
//                         hint: 'e.g. B-101',
//                         keyboardType: TextInputType.text,
//                       ),
//                       _buildField(
//                         controller: _streetCtrl,
//                         label: 'Street / Area',
//                         hint: 'e.g. MG Road, Koramangala',
//                         keyboardType: TextInputType.streetAddress,
//                       ),
//                       _buildField(
//                         controller: _landmarkCtrl,
//                         label: 'Landmark',
//                         hint: 'Near temple, opposite park...',
//                         keyboardType: TextInputType.text,
//                       ),
//                       Row(
//                         children: [
//                           Expanded(
//                             child: _buildField(
//                               controller: _cityCtrl,
//                               label: 'City',
//                               hint: 'Mumbai',
//                               keyboardType: TextInputType.text,
//                               isRequired: true,
//                               textCapitalization: TextCapitalization.words,
//                             ),
//                           ),
//                           const SizedBox(width: 12),
//                           Expanded(
//                             child: _buildField(
//                               controller: _stateCtrl,
//                               label: 'State',
//                               hint: 'Maharashtra',
//                               keyboardType: TextInputType.text,
//                               isRequired: true,
//                               textCapitalization: TextCapitalization.words,
//                             ),
//                           ),
//                         ],
//                       ),
//                       _buildField(
//                         controller: _pincodeCtrl,
//                         label: 'Pincode',
//                         hint: '400001',
//                         keyboardType: TextInputType.number,
//                         isRequired: true,
//                         maxLength: 6,
//                         inputFormatters: [
//                           FilteringTextInputFormatter.digitsOnly
//                         ],
//                         validator: (v) {
//                           if (v == null || v.trim().isEmpty) {
//                             return 'Pincode is required';
//                           }
//                           if (!RegExp(r'^[1-9][0-9]{5}$')
//                               .hasMatch(v.trim())) {
//                             return 'Enter valid 6-digit pincode';
//                           }
//                           return null;
//                         },
//                       ),
//
//                       /// Address type selector
//                       const SizedBox(height: 4),
//                       CustomText(
//                         'Address Type',
//                         fontSize: SizeConfig.small,
//                         color: AppColors.secondaryTextColor,
//                         fontWeight: FontWeight.w500,
//                       ),
//                       const SizedBox(height: 8),
//                       Row(
//                         children: ['Home', 'Office', 'Other']
//                             .map((type) => Padding(
//                                   padding: const EdgeInsets.only(right: 10),
//                                   child: _typeChip(type),
//                                 ))
//                             .toList(),
//                       ),
//
//                       /// Default toggle
//                       const SizedBox(height: 12),
//                       Row(
//                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                         children: [
//                           CustomText(
//                             AppStrings.setDefaultAddress,
//                             fontSize: SizeConfig.medium,
//                             fontWeight: FontWeight.w500,
//                             color: AppColors.mainTextColor,
//                           ),
//                           Switch(
//                             value: _isDefault,
//                             activeTrackColor: AppColors.primaryColor,
//                             onChanged: (v) => setState(() => _isDefault = v),
//                           ),
//                         ],
//                       ),
//
//                       /// Save button
//                       const SizedBox(height: 16),
//                       SizedBox(
//                         width: double.infinity,
//                         height: 50,
//                         child: ElevatedButton(
//                           onPressed: _saveAddress,
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: AppColors.primaryColor,
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(12),
//                             ),
//                             elevation: 0,
//                           ),
//                           child: CustomText(
//                             AppStrings.saveAddress,
//                             color: AppColors.white,
//                             fontSize: SizeConfig.large,
//                             fontWeight: FontWeight.w600,
//                           ),
//                         ),
//                       ),
//                       const SizedBox(height: 8),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildField({
//     required TextEditingController controller,
//     required String label,
//     required String hint,
//     TextInputType keyboardType = TextInputType.text,
//     bool isRequired = false,
//     int? maxLength,
//     List<TextInputFormatter>? inputFormatters,
//     String? Function(String?)? validator,
//     TextCapitalization textCapitalization = TextCapitalization.none,
//   }) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 12),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           RichText(
//             text: TextSpan(
//               text: label,
//               style: TextStyle(
//                 fontSize: SizeConfig.small,
//                 fontWeight: FontWeight.w500,
//                 color: AppColors.secondaryTextColor,
//               ),
//               children: isRequired
//                   ? [
//                       TextSpan(
//                         text: ' *',
//                         style: TextStyle(color: AppColors.red),
//                       ),
//                     ]
//                   : null,
//             ),
//           ),
//           const SizedBox(height: 6),
//           TextFormField(
//             controller: controller,
//             keyboardType: keyboardType,
//             maxLength: maxLength,
//             inputFormatters: inputFormatters,
//             textCapitalization: textCapitalization,
//             style: TextStyle(
//               fontSize: SizeConfig.medium,
//               color: AppColors.mainTextColor,
//             ),
//             decoration: InputDecoration(
//               hintText: hint,
//               hintStyle: TextStyle(
//                 fontSize: SizeConfig.medium,
//                 color: AppColors.greyB3,
//               ),
//               counterText: '',
//               contentPadding:
//                   const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
//               filled: true,
//               fillColor: AppColors.fillColor,
//               border: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(10),
//                 borderSide: BorderSide(color: AppColors.greyCA),
//               ),
//               enabledBorder: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(10),
//                 borderSide: BorderSide(color: AppColors.greyCA),
//               ),
//               focusedBorder: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(10),
//                 borderSide:
//                     BorderSide(color: AppColors.primaryColor, width: 1.5),
//               ),
//               errorBorder: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(10),
//                 borderSide: BorderSide(color: AppColors.red),
//               ),
//             ),
//             validator: validator ??
//                 (isRequired
//                     ? (v) => (v == null || v.trim().isEmpty)
//                         ? '$label is required'
//                         : null
//                     : null),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _typeChip(String type) {
//     final isSelected = _selectedType == type;
//     return GestureDetector(
//       onTap: () => setState(() => _selectedType = type),
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//         decoration: BoxDecoration(
//           color: isSelected
//               ? AppColors.primaryColor
//               : AppColors.fillColor,
//           borderRadius: BorderRadius.circular(20),
//           border: Border.all(
//             color:
//                 isSelected ? AppColors.primaryColor : AppColors.greyCA,
//           ),
//         ),
//         child: Row(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Icon(
//               type == 'Home'
//                   ? Icons.home_outlined
//                   : type == 'Office'
//                       ? Icons.business_outlined
//                       : Icons.location_on_outlined,
//               size: 16,
//               color: isSelected ? AppColors.white : AppColors.secondaryTextColor,
//             ),
//             const SizedBox(width: 6),
//             CustomText(
//               type,
//               fontSize: SizeConfig.small,
//               fontWeight: FontWeight.w600,
//               color:
//                   isSelected ? AppColors.white : AppColors.secondaryTextColor,
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
// // ═══════════════════════════════════════════════════════════════════
// //  ADDRESS SELECTION BOTTOM SHEET
// // ═══════════════════════════════════════════════════════════════════
//
// class _AddressSelectionSheet extends StatelessWidget {
//   final RxList<AddressDetails> addresses;
//   final String? selectedAddressId;
//   final Function(AddressDetails) onSelect;
//   final Function(String addressId) onDelete;
//   final VoidCallback onAddNew;
//
//   const _AddressSelectionSheet({
//     required this.addresses,
//     required this.selectedAddressId,
//     required this.onSelect,
//     required this.onDelete,
//     required this.onAddNew,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       constraints: BoxConstraints(
//         maxHeight: MediaQuery.of(context).size.height * 0.65,
//       ),
//       decoration: const BoxDecoration(
//         color: AppColors.white,
//         borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//       ),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           const SizedBox(height: 12),
//           Container(
//             width: 40,
//             height: 4,
//             decoration: BoxDecoration(
//               color: AppColors.greyCA,
//               borderRadius: BorderRadius.circular(2),
//             ),
//           ),
//           const SizedBox(height: 16),
//
//           /// Title
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 16),
//             child: Row(
//               children: [
//                 CustomText(
//                   AppStrings.chooseDeliveryAddress,
//                   fontSize: SizeConfig.large,
//                   fontWeight: FontWeight.w700,
//                   color: AppColors.mainTextColor,
//                 ),
//                 const Spacer(),
//                 IconButton(
//                   onPressed: () => Navigator.pop(context),
//                   icon: const Icon(Icons.close, size: 22),
//                   padding: EdgeInsets.zero,
//                   constraints: const BoxConstraints(),
//                 ),
//               ],
//             ),
//           ),
//           const SizedBox(height: 8),
//           Container(height: 1, color: AppColors.appBackgroundColor),
//
//           /// List
//           Flexible(
//             child: Obx(() => ListView.separated(
//                   shrinkWrap: true,
//                   padding:
//                       const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//                   itemCount: addresses.length,
//                   separatorBuilder: (_, __) => const SizedBox(height: 10),
//                   itemBuilder: (_, index) {
//                     final address = addresses[index];
//                     final isSelected = address.id == selectedAddressId;
//                     return _addressTile(context, address, isSelected);
//                   },
//                 )),
//           ),
//
//           /// Add new address button
//           Obx(() {
//             if (addresses.length >= AddressCacheService.maxAddresses) {
//               return const SizedBox.shrink();
//             }
//             return Padding(
//               padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
//               child: OutlinedButton.icon(
//                 onPressed: onAddNew,
//                 icon: const Icon(Icons.add, color: AppColors.primaryColor),
//                 label: CustomText(
//                   AppStrings.addAddress,
//                   color: AppColors.primaryColor,
//                   fontWeight: FontWeight.w600,
//                 ),
//                 style: OutlinedButton.styleFrom(
//                   side: const BorderSide(color: AppColors.primaryColor),
//                   minimumSize: const Size.fromHeight(46),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                 ),
//               ),
//             );
//           }),
//
//           SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
//         ],
//       ),
//     );
//   }
//
//   Widget _addressTile(
//       BuildContext context, AddressDetails address, bool isSelected) {
//     return InkWell(
//       onTap: () => onSelect(address),
//       borderRadius: BorderRadius.circular(14),
//       child: AnimatedContainer(
//         duration: const Duration(milliseconds: 200),
//         padding: const EdgeInsets.all(14),
//         decoration: BoxDecoration(
//           color: isSelected
//               ? AppColors.primaryColor.withValues(alpha: 0.05)
//               : AppColors.white,
//           borderRadius: BorderRadius.circular(14),
//           border: Border.all(
//             color: isSelected ? AppColors.primaryColor : AppColors.greyCA,
//             width: isSelected ? 1.8 : 1,
//           ),
//         ),
//         child: Row(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             /// Radio
//             Padding(
//               padding: const EdgeInsets.only(top: 2),
//               child: Container(
//                 width: 22,
//                 height: 22,
//                 decoration: BoxDecoration(
//                   shape: BoxShape.circle,
//                   border: Border.all(
//                     color:
//                         isSelected ? AppColors.primaryColor : AppColors.greyCA,
//                     width: 2,
//                   ),
//                 ),
//                 child: isSelected
//                     ? Center(
//                         child: Container(
//                           width: 12,
//                           height: 12,
//                           decoration: const BoxDecoration(
//                             shape: BoxShape.circle,
//                             color: AppColors.primaryColor,
//                           ),
//                         ),
//                       )
//                     : null,
//               ),
//             ),
//             const SizedBox(width: 12),
//
//             /// Details
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Row(
//                     children: [
//                       Icon(
//                         _YourCartScreenState._typeIcon(address.type),
//                         size: 16,
//                         color: AppColors.mainTextColor,
//                       ),
//                       const SizedBox(width: 6),
//                       Expanded(
//                         child: CustomText(
//                           address.name ?? '',
//                           fontSize: SizeConfig.medium,
//                           fontWeight: FontWeight.w700,
//                           color: AppColors.mainTextColor,
//                           maxLines: 1,
//                           overflow: TextOverflow.ellipsis,
//                         ),
//                       ),
//                       if (address.isDefault == true) ...[
//                         const SizedBox(width: 6),
//                         Container(
//                           padding: const EdgeInsets.symmetric(
//                               horizontal: 6, vertical: 2),
//                           decoration: BoxDecoration(
//                             color: AppColors.green1A.withValues(alpha: 0.12),
//                             borderRadius: BorderRadius.circular(4),
//                           ),
//                           child: CustomText(
//                             AppStrings.defaultAddress,
//                             fontSize: SizeConfig.extraSmall8,
//                             color: AppColors.green1A,
//                             fontWeight: FontWeight.w600,
//                           ),
//                         ),
//                       ],
//                     ],
//                   ),
//                   if (address.phone != null &&
//                       address.phone!.isNotEmpty) ...[
//                     const SizedBox(height: 3),
//                     CustomText(
//                       address.phone!,
//                       fontSize: SizeConfig.small,
//                       color: AppColors.secondaryTextColor,
//                     ),
//                   ],
//                   const SizedBox(height: 4),
//                   CustomText(
//                     _YourCartScreenState._buildFullAddress(address),
//                     fontSize: SizeConfig.small,
//                     color: AppColors.secondaryTextColor,
//                     maxLines: 2,
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                 ],
//               ),
//             ),
//
//             /// Delete
//             const SizedBox(width: 8),
//             InkWell(
//               onTap: () {
//                 showDialog(
//                   context: context,
//                   builder: (_) => AlertDialog(
//                     title: CustomText(AppStrings.deleteAddress),
//                     content: CustomText(AppStrings.confirmDeleteAddress),
//                     actions: [
//                       TextButton(
//                         onPressed: () => Navigator.pop(context),
//                         child: CustomText(AppStrings.no),
//                       ),
//                       TextButton(
//                         onPressed: () {
//                           Navigator.pop(context); // close dialog
//                           onDelete(address.id ?? '');
//                         },
//                         child: CustomText(AppStrings.yes, color: AppColors.red),
//                       ),
//                     ],
//                   ),
//                 );
//               },
//               borderRadius: BorderRadius.circular(6),
//               child: Padding(
//                 padding: const EdgeInsets.all(4),
//                 child: Icon(Icons.delete_outline,
//                     size: 20, color: AppColors.red.withValues(alpha: 0.7)),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
// // ═══════════════════════════════════════════════════════════════════
// //  CART CARD WIDGET
// // ═══════════════════════════════════════════════════════════════════
//
// class _CartCard extends StatelessWidget {
//   final String title;
//   final String subtitle;
//   final Color accentColor;
//   final Color bgGradientStart;
//   final Color bgGradientEnd;
//   final IconData iconData;
//   final Color iconBgColor;
//   final String payPrice;
//   final String payOriginalPrice;
//   final String savePrice;
//   final String discountPercent;
//   final VoidCallback? onTap;
//
//   const _CartCard({
//     required this.title,
//     required this.subtitle,
//     required this.accentColor,
//     required this.bgGradientStart,
//     required this.bgGradientEnd,
//     required this.iconData,
//     required this.iconBgColor,
//     required this.payPrice,
//     required this.payOriginalPrice,
//     required this.savePrice,
//     required this.discountPercent,
//     this.onTap,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return GestureDetector(
//       onTap: onTap,
//       child: Container(
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//           colors: [bgGradientStart, bgGradientEnd],
//         ),
//         borderRadius: BorderRadius.circular(16),
//         border: Border.all(
//           color: accentColor.withValues(alpha: 0.15),
//           width: 1,
//         ),
//         boxShadow: [
//           BoxShadow(
//             color: accentColor.withValues(alpha: 0.08),
//             blurRadius: 12,
//             offset: const Offset(0, 4),
//           ),
//         ],
//       ),
//       child: Column(
//         children: [
//           Padding(
//             padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
//             child: Row(
//               children: [
//                 Container(
//                   width: 48,
//                   height: 48,
//                   decoration: BoxDecoration(
//                     color: iconBgColor,
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   child: Icon(iconData, color: accentColor, size: 26),
//                 ),
//                 const SizedBox(width: 12),
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       CustomText(title,
//                           fontSize: SizeConfig.large,
//                           fontWeight: FontWeight.w700,
//                           color: AppColors.mainTextColor),
//                       const SizedBox(height: 3),
//                       CustomText(subtitle,
//                           fontSize: SizeConfig.small,
//                           color: AppColors.secondaryTextColor,
//                           fontWeight: FontWeight.w400),
//                     ],
//                   ),
//                 ),
//                 InkWell(
//                   onTap: () {},
//                   borderRadius: BorderRadius.circular(20),
//                   child: Container(
//                     padding: const EdgeInsets.symmetric(
//                         horizontal: 18, vertical: 8),
//                     decoration: BoxDecoration(
//                       color: AppColors.white,
//                       border:
//                           Border.all(color: AppColors.green1A, width: 1.2),
//                       borderRadius: BorderRadius.circular(20),
//                     ),
//                     child: CustomText('View',
//                         fontSize: SizeConfig.small,
//                         fontWeight: FontWeight.w600,
//                         color: AppColors.green1A),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           const SizedBox(height: 14),
//           Container(
//             margin: const EdgeInsets.symmetric(horizontal: 16),
//             height: 1,
//             color: accentColor.withValues(alpha: 0.12),
//           ),
//           const SizedBox(height: 14),
//           Padding(
//             padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
//             child: Row(
//               children: [
//                 Expanded(child: _payCol(payPrice, payOriginalPrice)),
//                 const SizedBox(width: 14),
//                 Expanded(child: _saveCol()),
//               ],
//             ),
//           ),
//         ],
//       ),
//     ),
//     );
//   }
//
//   Widget _payCol(String price, String original) {
//     return Column(children: [
//       Container(
//         width: double.infinity,
//         padding: const EdgeInsets.symmetric(vertical: 10),
//         decoration: BoxDecoration(
//           color: AppColors.primaryColor,
//           borderRadius: BorderRadius.circular(10),
//           boxShadow: [
//             BoxShadow(
//                 color: AppColors.primaryColor.withValues(alpha: 0.25),
//                 blurRadius: 8,
//                 offset: const Offset(0, 3)),
//           ],
//         ),
//         alignment: Alignment.center,
//         child: CustomText('Pay',
//             fontSize: SizeConfig.medium,
//             fontWeight: FontWeight.w700,
//             color: AppColors.white),
//       ),
//       const SizedBox(height: 10),
//       Row(mainAxisAlignment: MainAxisAlignment.center, children: [
//         CustomText(price,
//             fontSize: SizeConfig.large,
//             fontWeight: FontWeight.w700,
//             color: AppColors.mainTextColor),
//         const SizedBox(width: 6),
//         CustomText(original,
//             fontSize: SizeConfig.small,
//             color: AppColors.secondaryTextColor,
//             decoration: TextDecoration.lineThrough,
//             decorationColor: AppColors.secondaryTextColor),
//       ]),
//     ]);
//   }
//
//   Widget _saveCol() {
//     return Column(children: [
//       Container(
//         width: double.infinity,
//         padding: const EdgeInsets.symmetric(vertical: 10),
//         decoration: BoxDecoration(
//           color: AppColors.white,
//           border: Border.all(color: AppColors.primaryColor, width: 1.5),
//           borderRadius: BorderRadius.circular(10),
//         ),
//         alignment: Alignment.center,
//         child: CustomText('Save',
//             fontSize: SizeConfig.medium,
//             fontWeight: FontWeight.w700,
//             color: AppColors.primaryColor),
//       ),
//       const SizedBox(height: 10),
//       Row(mainAxisAlignment: MainAxisAlignment.center, children: [
//         CustomText(savePrice,
//             fontSize: SizeConfig.large,
//             fontWeight: FontWeight.w700,
//             color: AppColors.green1A),
//         const SizedBox(width: 6),
//         Container(
//           padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
//           decoration: BoxDecoration(
//             color: const Color(0xFFE8F5E9),
//             borderRadius: BorderRadius.circular(12),
//           ),
//           child: Row(mainAxisSize: MainAxisSize.min, children: [
//             const Icon(Icons.local_offer_outlined,
//                 size: 11, color: AppColors.green1A),
//             const SizedBox(width: 3),
//             CustomText(discountPercent,
//                 fontSize: 11,
//                 fontWeight: FontWeight.w600,
//                 color: AppColors.green1A),
//           ]),
//         ),
//       ]),
//     ]);
//   }
// }
