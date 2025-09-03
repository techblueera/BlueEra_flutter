import 'package:BlueEra/core/constants/app_constant.dart';
import 'package:BlueEra/features/common/auth/views/screens/gst_verification_screen.dart';
import 'package:BlueEra/features/common/auth/views/screens/personal_account_screen.dart';
import 'package:BlueEra/features/common/auth/views/screens/recruiter_account_screen.dart';
import 'package:flutter/material.dart';

class CreateUserAccount extends StatefulWidget {
  const CreateUserAccount({super.key, required this.accountType});

  final String accountType;

  @override
  State<CreateUserAccount> createState() => _CreateUserAccountState();
}

class _CreateUserAccountState extends State<CreateUserAccount> {
  @override
  Widget build(BuildContext context) {
    return Material(
      child: (widget.accountType == AppConstants.individual)
          ? PersonalAccountScreen()
          : (widget.accountType == AppConstants.recruiter)
              ? RecruiterAccountScreen()
              : (widget.accountType == AppConstants.business)
                  ? GstNumberScreen()
                  : SizedBox(),
    );
  }
}
