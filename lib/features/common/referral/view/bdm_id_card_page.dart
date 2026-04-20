import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/getx_utils.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/common/referral/controller/referral_controller.dart';
import 'package:BlueEra/features/common/visiting_card/helper/visiting_card_helper.dart';
import 'package:BlueEra/features/personal/auth/controller/view_personal_details_controller.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class BdmIdCardPage extends StatefulWidget {
  const BdmIdCardPage({super.key});

  @override
  State<BdmIdCardPage> createState() => _BdmIdCardPageState();
}

class _BdmIdCardPageState extends State<BdmIdCardPage> {
  final GlobalKey _cardKey = GlobalKey();
  final _shareHelper = VisitingCardHelper();

  @override
  Widget build(BuildContext context) {
    final controller = getOrPut(() => ReferralController());
    final personal =
        getOrPut(() => ViewPersonalDetailsController(), permanent: true);

    return Scaffold(
      backgroundColor: AppColors.appBackgroundColor,
      appBar: CommonBackAppBar(
        title: "My BlueEra ID Card",
        isShadowShow: false,
        isShareButton: true,
        onShareTap: () => _shareHelper.shareVisitingCard(
          _cardKey,
          shareProfile: false,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(SizeConfig.size16),
          child: Obx(() {
            final bdm = controller.referralBdmDetails.value.data;
            final stats = controller.referralStatsData.value;
            final user = personal.personalProfileDetails.value.user;

            final fullName = (bdm?.fullName?.isNotEmpty ?? false)
                ? bdm!.fullName!
                : (user?.name ?? "");
            final phone = (bdm?.alternateMobileNo?.isNotEmpty ?? false)
                ? bdm!.alternateMobileNo!
                : (user?.contactNo ?? "");
            final refCode = stats.referralCode ?? "";
            final idNo = stats.serialCode ?? "";
            final dob = bdm?.dob;
            final dobStr = (dob?.day != null &&
                    dob?.month != null &&
                    dob?.year != null)
                ? "${dob!.year.toString().padLeft(2, '0')}/${dob.month.toString().padLeft(2, '0')}/${dob.day.toString().padLeft(4, '0')}"
                : "-";
            final loc = bdm?.location;
            final cityStatePin = [
              loc?.city,
              loc?.state,
              loc?.pincode,
            ].whereType<String>().where((s) => s.isNotEmpty).join(' - ');
            final address = (loc?.addressString?.isNotEmpty ?? false)
                ? [loc!.addressString!, cityStatePin]
                    .where((s) => s.isNotEmpty)
                    .join(', ')
                : cityStatePin;
            final photo = user?.profileImage ?? "";

            return Column(
              children: [
                RepaintBoundary(
                  key: _cardKey,
                  child: _IdCard(
                    name: fullName.toUpperCase(),
                    designation: "Relationship Manager",
                    photoUrl: photo,
                    idNo: idNo,
                    phone: phone,
                    refCode: refCode,
                    dob: dobStr,
                    address: address,
                  ),
                ),
                SizedBox(height: SizeConfig.size20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryColor,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        vertical: SizeConfig.size12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => _shareHelper.shareVisitingCard(
                      _cardKey,
                      shareProfile: false,
                    ),
                    icon: const Icon(Icons.share),
                    label: CustomText(
                      "Share ID Card",
                      fontSize: SizeConfig.medium,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}

class _IdCard extends StatelessWidget {
  final String name;
  final String designation;
  final String photoUrl;
  final String idNo;
  final String phone;
  final String refCode;
  final String dob;
  final String address;

  const _IdCard({
    required this.name,
    required this.designation,
    required this.photoUrl,
    required this.idNo,
    required this.phone,
    required this.refCode,
    required this.dob,
    required this.address,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: AspectRatio(
        aspectRatio: 751 / 1179,
        child: LayoutBuilder(
          builder: (context, c) {
            final w = c.maxWidth;
            final h = c.maxHeight;
            final photoSize = w * 0.44;
            final photoCenterX = w * 0.50;
            final photoCenterY = h * 0.385;
            return Stack(
              children: [
                Positioned.fill(
                  child: LocalAssets(
                      imagePath: 'assets/images/dummy_card.jpeg',
                      boxFix: BoxFit.fill),
                ),
                Positioned(
                  left: photoCenterX - photoSize / 2,
                  top: photoCenterY - photoSize / 2,
                  width: photoSize,
                  height: photoSize,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(
                        color: AppColors.blueLight,
                        width: photoSize * 0.05,
                      ),
                    ),
                    padding: EdgeInsets.all(photoSize * 0.015),
                    child: ClipOval(
                      child: photoUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: photoUrl,
                            fit: BoxFit.cover,
                            placeholder: (_, __) =>
                                Container(color: AppColors.greyE5),
                            errorWidget: (_, __, ___) => Container(
                              color: AppColors.greyE5,
                              child: Icon(
                                Icons.person,
                                size: photoSize * 0.5,
                                color: AppColors.greyA5,
                              ),
                            ),
                          )
                        : Container(
                            color: AppColors.greyE5,
                            child: Icon(
                              Icons.person,
                              size: photoSize * 0.5,
                              color: AppColors.greyA5,
                            ),
                          ),
                    ),
                  ),
                ),
                Positioned(
                  top: h * 0.57,
                  left: 0,
                  right: 0,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: w * 0.06),
                    child: CustomText(
                      name.isEmpty ? "—" : name,
                      fontSize: w * 0.07,
                      fontWeight: FontWeight.w800,
                      color: AppColors.black28,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                Positioned(
                  top: h * 0.645,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: w * 0.09,
                        vertical: w * 0.02,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(
                          color: AppColors.black28,
                          width: 1.2,
                        ),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: CustomText(
                        designation,
                        fontSize: w * 0.042,
                        fontWeight: FontWeight.w600,
                        color: AppColors.blueLight,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: w * 0.07,
                  right: w * 0.04,
                  top: h * 0.725,
                  bottom: h * 0.05,
                  child: ClipRect(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.topLeft,
                      child: SizedBox(
                        width: w * 0.89,
                        child: _DetailsGrid(
                          labelSize: w * 0.038,
                          valueSize: w * 0.04,
                          items: [
                            ["ID No.", idNo.isEmpty ? "-" : idNo],
                            ["Phone", phone.isEmpty ? "-" : phone],
                            ["Ref. Code", refCode.isEmpty ? "-" : refCode],
                            ["D.O.B", dob],
                            ["Address", address.isEmpty ? "-" : address],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

}

class _DetailsGrid extends StatelessWidget {
  final List<List<String>> items;
  final double labelSize;
  final double valueSize;

  const _DetailsGrid({
    required this.items,
    required this.labelSize,
    required this.valueSize,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: items.map((it) {
        return Padding(
          padding: EdgeInsets.symmetric(vertical: labelSize * 0.18),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: labelSize * 6.2,
                child: CustomText(
                  it[0],
                  fontSize: labelSize,
                  fontWeight: FontWeight.w700,
                  color: AppColors.blueLight,
                ),
              ),
              CustomText(
                ":  ",
                fontSize: valueSize,
                fontWeight: FontWeight.w700,
                color: AppColors.black28,
              ),
              Expanded(
                child: CustomText(
                  it[1],
                  fontSize: valueSize,
                  fontWeight: FontWeight.w700,
                  color: AppColors.black28,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
