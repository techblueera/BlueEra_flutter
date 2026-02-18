import 'package:BlueEra/core/api/model/personal_profile_details_model.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/features/business/auth/model/viewBusinessProfileModel.dart';
import 'package:BlueEra/features/common/visiting_card/view/visiting_card_eight.dart';
import 'package:BlueEra/features/common/visiting_card/view/visiting_card_eleven.dart';
import 'package:BlueEra/features/common/visiting_card/view/visiting_card_five.dart';
import 'package:BlueEra/features/common/visiting_card/view/visiting_card_four.dart';
import 'package:BlueEra/features/common/visiting_card/view/visiting_card_nine.dart';
import 'package:BlueEra/features/common/visiting_card/view/visiting_card_one.dart';
import 'package:BlueEra/features/common/visiting_card/view/visiting_card_seven.dart';
import 'package:BlueEra/features/common/visiting_card/view/visiting_card_six.dart';
import 'package:BlueEra/features/common/visiting_card/view/visiting_card_ten.dart';
import 'package:BlueEra/features/common/visiting_card/view/visiting_card_thirteen.dart';
import 'package:BlueEra/features/common/visiting_card/view/visiting_card_three.dart';
import 'package:BlueEra/features/common/visiting_card/view/visiting_card_twelve.dart';
import 'package:BlueEra/features/common/visiting_card/view/visiting_card_two.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:flutter/material.dart';

class AllVisitingCards extends StatefulWidget {
  final ScrollController? scrollController;
  final BusinessProfileDetails? businessDetails;
  final PersonalProfileDetailsModel? personalDetails;
  final bool? showAppBar;

  const AllVisitingCards({
    super.key,
    this.scrollController,
    this.businessDetails,
    this.personalDetails,
    this.showAppBar});

  @override
  State<AllVisitingCards> createState() => _AllVisitingCardsState();
}

class _AllVisitingCardsState extends State<AllVisitingCards> {

  bool _isReady = false;

  @override
  void initState() {
    super.initState();
    // Allow the bottom sheet animation to finish before building heavy UI
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 150), () {
        if (mounted) setState(() => _isReady = true);
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isReady) return const Center(child: CircularProgressIndicator());

    return Scaffold(
      appBar: (widget.showAppBar!=null) ? CommonBackAppBar(
        title: 'Visiting Cards',
      ) : null,
      body: SingleChildScrollView(
        controller: widget.scrollController,
        padding: EdgeInsets.only(
            left: SizeConfig.size8,
            right: SizeConfig.size8,
            top: SizeConfig.size10,
            bottom: SizeConfig.size50,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          VisitingCardThirteen(
                cardKey: GlobalKey(),
                showShareButton: true
          ),
          SizedBox(height: SizeConfig.paddingXSL),
          VisitingCardOne(
            businessDetails: widget.businessDetails,
            personalDetails: widget.personalDetails,
          ),
          SizedBox(height: SizeConfig.paddingXSL),
          VisitingCardTwo(
            businessDetails: widget.businessDetails,
            personalDetails: widget.personalDetails,
          ),
          SizedBox(height: SizeConfig.paddingXSL),
          VisitingCardThree(
            businessDetails: widget.businessDetails,
            personalDetails: widget.personalDetails,
          ),
          SizedBox(height: SizeConfig.paddingXSL),
          VisitingCardFour(
            businessDetails: widget.businessDetails,
            personalDetails: widget.personalDetails
          ),
          SizedBox(height: SizeConfig.paddingXSL),
          VisitingCardFive(
            businessDetails: widget.businessDetails,
            personalDetails: widget.personalDetails
          ),
          SizedBox(height: SizeConfig.paddingXSL),
          VisitingCardSix(
            businessDetails: widget.businessDetails,
            personalDetails: widget.personalDetails
          ),
          SizedBox(height: SizeConfig.paddingXSL),
          VisitingCardSeven(
            businessDetails: widget.businessDetails,
            personalDetails: widget.personalDetails,
          ),
          SizedBox(height: SizeConfig.paddingXSL),
          VisitingCardEight(
            businessDetails: widget.businessDetails,
            personalDetails: widget.personalDetails,
          ),
          SizedBox(height: SizeConfig.paddingXSL),
          VisitingCardNine(
            businessDetails: widget.businessDetails,
            personalDetails: widget.personalDetails,
          ),
          SizedBox(height: SizeConfig.paddingXSL),
          VisitingCardTen(
            businessDetails: widget.businessDetails,
            personalDetails: widget.personalDetails,
          ),
          SizedBox(height: SizeConfig.paddingXSL),
          VisitingCardEleven(
            businessDetails: widget.businessDetails,
            personalDetails: widget.personalDetails,
          ),
          SizedBox(height: SizeConfig.paddingXSL),
          VisitingCardTwelve(
            businessDetails: widget.businessDetails,
            personalDetails: widget.personalDetails,
          ),

          ],
        ),
      ),
    );
  }
}
