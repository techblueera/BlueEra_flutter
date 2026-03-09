import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/common_methods.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/shared_preference_utils.dart';
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

class AddHotelServiceScreen extends StatefulWidget {
  AddHotelServiceScreen({super.key});

  @override
  State<AddHotelServiceScreen> createState() => _AddHotelServiceScreenState();
}

class _AddHotelServiceScreenState extends State<AddHotelServiceScreen> {
  final List<Map<String, String>> menuList = [
    {"name": "Room Details", "key": "ROOM_DETAILS"},
    {"name": "Room Amenities", "key": "ROOM_AMENITIES"},
    {"name": "Hotel Amenities", "key": "HOTEL_AMENITIES"},
    {"name": "Hotel Policies", "key": "HOTEL_POLICIES"},
    {"name": "Property Photos", "key": "PROPERTY_PHOTOS"},
    {"name": "Career", "key": "CAREER"},
    {"name": "Contact Us", "key": "CONTACT_US"},
  ];

  final myDocumentsController = getOrPut(() => MyDocumentsController());

  @override
  void initState() {
    // TODO: implement initState
    getAllDocumentsData();
    super.initState();
  }

  Future<void> getAllDocumentsData() async {
    myDocumentsController.fetchAllDocumentApi();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildMyDocumentWidget(),
            ListView.builder(
              itemCount: menuList.length,
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemBuilder: (context, index) {
                final item = menuList[index];

                return InkWell(
                  onTap: () {
                    handleNavigation({'key': item['key']});
                  },
                  child: CommonCardWidget(
                      borderColorColor: AppColors.whiteE5,
                      cardMargin: 7,
                      child: Row(
                        children: [
                          LocalAssets(
                              imagePath:
                                  "assets/category/hotel_service/${item['key']}.svg"),
                          SizedBox(
                            width: SizeConfig.size10,
                          ),
                          CustomText(
                            item['name'],
                            color: AppColors.secondaryTextColor,
                            fontSize: 18,
                          )
                        ],
                      )),
                );
              },
            ),
            SizedBox(height: kBottomNavigationBarHeight+30,)
          ],
        ),
      ),
    );
  }

  Widget _buildMyDocumentWidget() {
    return CustomFormCard(
      margin: EdgeInsets.only(right: 20,left: 20,top: 20),
        child: Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                _buildCircleIcon(AppIconAssets.UPLOAD_DOCUMENT),
                SizedBox(width: SizeConfig.size6),
                _buildTitleWidget(AppStrings.myDocuments),
              ],
            ),
            SizedBox(width: SizeConfig.size6),
            PositiveCustomBtn(
              onTap: () {
                Get.toNamed(
                    RouteHelper.getAddDocumentScreenRoute(),
                    arguments: {ApiKeys.argDocumentVia: AppConstants.hotelServiceScreen}
                );
              },
              title: AppStrings.addDocument,
              padding: EdgeInsets.symmetric(horizontal: 3),
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
        ),
        SizedBox(height: SizeConfig.size16),
        Obx(() {
          return Container(
            margin: EdgeInsets.symmetric(vertical: SizeConfig.size8),
            decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.whiteE0),
                boxShadow: [AppShadows.textFieldShadow]),
            child: (myDocumentsController.documents.isEmpty)
                ? ListTile(
                    dense: true,
                    onTap: () {
                      Get.toNamed(
                          RouteHelper.getAddDocumentScreenRoute(),
                          arguments: {ApiKeys.argDocumentVia: AppConstants.hotelServiceScreen}
                      );
                    },
                    leading: Icon(
                      Icons.folder_open,
                      color: AppColors.primaryColor,
                    ),
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
                  )
                : ExpansionTile(
                    dense: true,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    collapsedShape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    title: CustomText(
                      AppStrings.myDocuments,
                      fontSize: SizeConfig.medium,
                      fontWeight: FontWeight.w600,
                      color: AppColors.secondaryTextColor,
                    ),
                    childrenPadding: EdgeInsets.only(bottom: SizeConfig.size8),
                    children: [
                        for (int i = 0;
                            i < myDocumentsController.documents.length;
                            i++) ...[
                          _buildDocumentCard(
                            myDocumentsController.documents[i],
                            myDocumentsController,
                          ),
                          if (i != myDocumentsController.documents.length - 1)
                            CommonHorizontalDivider(
                              color: AppColors.greyE5, // <-- your colour
                            ),
                        ]
                      ]),
          );
        })
      ],
    ));
  }

  Widget _buildCircleIcon(String iconImage) {
    return LocalAssets(
      imagePath: iconImage,
    );
  }

  Widget _buildTitleWidget(String text) {
    return CustomText(
      text,
      fontSize: SizeConfig.medium,
      fontWeight: FontWeight.w600,
      color: AppColors.secondaryTextColor,
    );
  }

  Widget _buildDocumentCard(
      DocumentsResponse document, MyDocumentsController controller) {
    return Container(
      padding: EdgeInsets.symmetric(
          vertical: SizeConfig.size12, horizontal: SizeConfig.size15),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(SizeConfig.size6),
            decoration: BoxDecoration(
                color: AppColors.whiteFE,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: AppColors.greyE5,
                  width: 1,
                ),
                boxShadow: [AppShadows.textFieldShadow]),
            child: LocalAssets(
              imagePath: AppIconAssets.outlinedDocument,
              width: SizeConfig.size20,
              height: SizeConfig.size20,
            ),
          ),
          SizedBox(width: SizeConfig.size10),

          // Document Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CustomText(
                  controller.getDocumentName(document.documentType ?? ''),
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

          // Action Buttons
          GestureDetector(
            onTap: () {
              Get.bottomSheet(
                CommonDocumentBottomSheet(
                  title:
                      controller.getDocumentName(document.documentType ?? ''),
                  child: (document.isVerified ?? false)
                      ? ViewDocumentWidget(
                          document: document,
                        )
                      : DocumentVerificationPendingWidget(
                          documentName: controller
                              .getDocumentName(document.documentType ?? ''),
                        ),
                ),
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
              );
            },
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

  void handleNavigation(dynamic data) {
    // Access the key from the data object (assuming Map or Object with .key)
    final String? key = data is Map ? data['key'] : data.key;

    final Map<String, Widget Function()> routeMap = {
      "ROOM_DETAILS": () => RoomSelectionScreen(),
      "ROOM_AMENITIES": () => RoomAmenitiesScreen(),
      "HOTEL_AMENITIES": () => HotelAmenitiesScreen(),
      "HOTEL_POLICIES": () => HotelPoliciesScreen(),
      "CAREER": () => const HotelJobListingScreen(),
      "PROPERTY_PHOTOS": () => PropertyPhotoScreen(),
      // "RESTAURANT_MENU": () => const ComingSoon(),
      "CONTACT_US": () => const HotelContactUs(),
      // "ABOUT_PROPERTY": () => const ComingSoon(),

    };

    final routeBuilder = routeMap[key];

    if (routeBuilder != null) {
      Get.to(routeBuilder());
    } else {
      print("Route not found for key: $key");
    }
  }
}
