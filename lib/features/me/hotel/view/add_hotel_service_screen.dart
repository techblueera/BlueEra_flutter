import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/core/widgets/custom_form_card.dart';
import 'package:BlueEra/features/me/hotel/view/hotel_amenities_screen.dart';
import 'package:BlueEra/features/me/hotel/view/hotel_career_jobs/hotel_job_listing_screen.dart';
import 'package:BlueEra/features/me/hotel/view/hotel_contact_us/hotel_contact_us.dart';
import 'package:BlueEra/features/me/hotel/view/hotel_property_photos_screen.dart';
import 'package:BlueEra/features/me/hotel/view/hotel_property_screen.dart';
import 'package:BlueEra/features/me/hotel/view/room_amenities_screen.dart';
import 'package:BlueEra/features/me/hotel/view/room_detils_screen.dart';
import 'package:BlueEra/features/personal/personal_profile/view/my_documents/controller/my_documents_controller.dart';
import 'package:BlueEra/features/personal/personal_profile/view/my_documents/model/upload_document_response.dart';
import 'package:BlueEra/features/personal/personal_profile/view/my_documents/widget/common_document_bottom_sheet.dart';
import 'package:BlueEra/features/personal/personal_profile/view/my_documents/widget/doc_verification_pending_widget.dart';
import 'package:BlueEra/features/personal/personal_profile/view/my_documents/widget/view_document_widget.dart';
import 'package:BlueEra/widgets/common_box_shadow.dart';
import 'package:BlueEra/widgets/common_card_widget.dart';
import 'package:BlueEra/widgets/common_horizontal_divider.dart';
import 'package:BlueEra/widgets/custom_btn.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

/// Dashboard screen for a hotel business: lists the seven service-management
/// entry points (rooms, amenities, policies, ...) and surfaces the document
/// upload section at the top.
class AddHotelServiceScreen extends StatefulWidget {
  const AddHotelServiceScreen({super.key});

  @override
  State<AddHotelServiceScreen> createState() => _AddHotelServiceScreenState();
}

class _AddHotelServiceScreenState extends State<AddHotelServiceScreen> {
  /// Menu entries displayed in the dashboard list. Each entry maps to a route
  /// builder in [_routeFor]; the same key drives the leading SVG filename.
  static const List<_MenuItem> _menuItems = [
    _MenuItem(name: AppStrings.hotelRoomDetails, key: 'ROOM_DETAILS'),
    _MenuItem(name: AppStrings.hotelRoomAmenities, key: 'ROOM_AMENITIES'),
    _MenuItem(name: AppStrings.hotelAmenitiesTitle, key: 'HOTEL_AMENITIES'),
    _MenuItem(name: AppStrings.hotelPoliciesTitle, key: 'HOTEL_POLICIES'),
    _MenuItem(name: AppStrings.hotelPropertyPhotos, key: 'PROPERTY_PHOTOS'),
    _MenuItem(name: AppStrings.hotelCareer, key: 'CAREER'),
    _MenuItem(name: AppStrings.contactUs, key: 'CONTACT_US'),
  ];

  final myDocumentsController = getOrPut(() => MyDocumentsController());

  @override
  void initState() {
    super.initState();
    myDocumentsController.fetchAllDocumentApi();
  }

  /// Maps a menu key to the screen instance to push. Returns `null` for
  /// keys without a destination yet (e.g. "Coming soon" placeholders).
  Widget? _routeFor(String key) {
    switch (key) {
      case 'ROOM_DETAILS':
        return RoomSelectionScreen();
      case 'ROOM_AMENITIES':
        return RoomAmenitiesScreen();
      case 'HOTEL_AMENITIES':
        return HotelAmenitiesScreen();
      case 'HOTEL_POLICIES':
        return HotelPoliciesScreen();
      case 'CAREER':
        return const HotelJobListingScreen();
      case 'PROPERTY_PHOTOS':
        return PropertyPhotoScreen();
      case 'CONTACT_US':
        return const HotelContactUs();
      default:
        return null;
    }
  }

  void _openMenuItem(String key) {
    final destination = _routeFor(key);
    if (destination != null) {
      Get.to(destination);
    } else {
      logs('AddHotelServiceScreen: route not found for key=$key');
    }
  }

  void _openAddDocumentScreen() {
    Get.toNamed(
      RouteHelper.getAddDocumentScreenRoute(),
      arguments: {ApiKeys.argDocumentVia: AppConstants.hotelServiceScreen},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildMyDocumentSection(),
            _buildMenuList(),
            SizedBox(height: kBottomNavigationBarHeight + 30),
          ],
        ),
      ),
    );
  }

  // ---- Menu list ------------------------------------------------------------

  Widget _buildMenuList() {
    return ListView.builder(
      itemCount: _menuItems.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final item = _menuItems[index];
        return InkWell(
          onTap: () => _openMenuItem(item.key),
          child: CommonCardWidget(
            borderColorColor: AppColors.whiteE5,
            cardMargin: 7,
            child: Row(
              children: [
                LocalAssets(
                  imagePath: 'assets/category/hotel_service/${item.key}.svg',
                ),
                SizedBox(width: SizeConfig.size10),
                CustomText(
                  item.name.tr,
                  color: AppColors.secondaryTextColor,
                  fontSize: 18,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ---- Documents section ----------------------------------------------------

  Widget _buildMyDocumentSection() {
    return CustomFormCard(
      margin: const EdgeInsets.only(right: 20, left: 20, top: 20),
      child: Column(
        children: [
          _buildDocumentSectionHeader(),
          SizedBox(height: SizeConfig.size16),
          Obx(_buildDocumentList),
        ],
      ),
    );
  }

  Widget _buildDocumentSectionHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            LocalAssets(imagePath: AppIconAssets.UPLOAD_DOCUMENT),
            SizedBox(width: SizeConfig.size6),
            _sectionTitle(AppStrings.myDocuments),
          ],
        ),
        SizedBox(width: SizeConfig.size6),
        PositiveCustomBtn(
          onTap: _openAddDocumentScreen,
          title: AppStrings.addDocument,
          padding: const EdgeInsets.symmetric(horizontal: 3),
          textColor: AppColors.primaryColor,
          fontSize: SizeConfig.small,
          iconPath: AppIconAssets.add,
          iconColor: AppColors.primaryColor,
          width: SizeConfig.size120,
          height: SizeConfig.size30,
          bgColor: Colors.transparent,
          borderColor: AppColors.primaryColor,
          radius: 6.0,
        ),
      ],
    );
  }

  Widget _buildDocumentList() {
    final hasDocuments = myDocumentsController.documents.isNotEmpty;
    return Container(
      margin: EdgeInsets.symmetric(vertical: SizeConfig.size8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.whiteE0),
        boxShadow: [AppShadows.textFieldShadow],
      ),
      child: hasDocuments
          ? _buildDocumentsExpansionTile()
          : _buildEmptyDocumentsTile(),
    );
  }

  Widget _buildEmptyDocumentsTile() {
    return ListTile(
      dense: true,
      onTap: _openAddDocumentScreen,
      leading: Icon(Icons.folder_open, color: AppColors.primaryColor),
      title: CustomText(
        AppStrings.noDocumentsFound,
        fontSize: SizeConfig.medium,
        fontWeight: FontWeight.w400,
        color: AppColors.mainTextColor,
      ),
      subtitle: CustomText(
        AppStrings.addYourFirstDocument,
        fontSize: SizeConfig.small,
        fontWeight: FontWeight.w400,
        color: AppColors.secondaryTextColor,
      ),
    );
  }

  Widget _buildDocumentsExpansionTile() {
    final docs = myDocumentsController.documents;
    return ExpansionTile(
      dense: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      collapsedShape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      title: CustomText(
        AppStrings.myDocuments,
        fontSize: SizeConfig.medium,
        fontWeight: FontWeight.w600,
        color: AppColors.secondaryTextColor,
      ),
      childrenPadding: EdgeInsets.only(bottom: SizeConfig.size8),
      children: [
        for (var i = 0; i < docs.length; i++) ...[
          _buildDocumentCard(docs[i]),
          if (i != docs.length - 1)
            CommonHorizontalDivider(color: AppColors.greyE5),
        ],
      ],
    );
  }

  Widget _sectionTitle(String text) {
    return CustomText(
      text,
      fontSize: SizeConfig.medium,
      fontWeight: FontWeight.w600,
      color: AppColors.secondaryTextColor,
    );
  }

  Widget _buildDocumentCard(DocumentsResponse document) {
    final documentName =
        myDocumentsController.getDocumentName(document.documentType ?? '');

    return Container(
      padding: EdgeInsets.symmetric(
        vertical: SizeConfig.size12,
        horizontal: SizeConfig.size15,
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(SizeConfig.size6),
            decoration: BoxDecoration(
              color: AppColors.whiteFE,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.greyE5, width: 1),
              boxShadow: [AppShadows.textFieldShadow],
            ),
            child: LocalAssets(
              imagePath: AppIconAssets.outlinedDocument,
              width: SizeConfig.size20,
              height: SizeConfig.size20,
            ),
          ),
          SizedBox(width: SizeConfig.size10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  documentName,
                  fontSize: SizeConfig.small,
                  fontWeight: FontWeight.w400,
                  color: AppColors.mainTextColor,
                ),
                SizedBox(height: SizeConfig.size6),
                CustomText(
                  document.createdAt,
                  fontSize: SizeConfig.extraSmall,
                  fontWeight: FontWeight.w400,
                  color: AppColors.secondaryTextColor,
                ),
              ],
            ),
          ),
          SizedBox(width: SizeConfig.size12),
          GestureDetector(
            onTap: () => _showDocumentSheet(document, documentName),
            child: LocalAssets(
              imagePath: AppIconAssets.eyeIcon,
              height: 20,
              width: 20,
              imgColor: AppColors.secondaryTextColor,
            ),
          ),
        ],
      ),
    );
  }

  void _showDocumentSheet(DocumentsResponse document, String documentName) {
    Get.bottomSheet(
      CommonDocumentBottomSheet(
        title: documentName,
        child: (document.isVerified ?? false)
            ? ViewDocumentWidget(document: document)
            : DocumentVerificationPendingWidget(documentName: documentName),
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }
}

/// Lightweight typed pair so [AddHotelServiceScreen._menuItems] can be `const`
/// without sacrificing field-name clarity at the call sites.
class _MenuItem {
  final String name;
  final String key;
  const _MenuItem({required this.name, required this.key});
}
