import 'package:BlueEra/core/api/model/location_data_model.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/controller/location_controller.dart';
import 'package:BlueEra/core/services/location_permission_handler.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

/// Resolves the device location, and when that fails explains what went wrong
/// and how to fix it — then retries, in place, as many times as the user is
/// willing to try.
///
/// This exists because a form that needs a location and gets none has nothing
/// useful to say from a snackbar. "Please enable your location permission and
/// GPS" is a single sentence covering four different failures with four
/// different fixes, in two different settings screens, and it disappears after
/// three seconds — so people sat on a filled-in signup form tapping Submit,
/// with no idea what was being asked of them. The sheet names the actual
/// failure, lists the steps for THAT one, and puts the button that opens the
/// right screen underneath them.
///
/// Returns the location, or null if the user gave up. Null is the only "no":
/// the sheet is always dismissible, and Not now is always on it. Whatever the
/// caller was doing, it is still on screen when this returns — nothing here
/// navigates.
///
/// [onBusyChanged] fires true around each attempt and false while the sheet is
/// up, so a Submit button can spin for the work and come back to life while
/// the user is reading.
Future<LocationDataModel?> resolveLocationWithGuidance({
  required BuildContext context,
  required LocationController controller,
  bool preferNativeGeocoding = false,
  String? purpose,
  ValueChanged<bool>? onBusyChanged,
}) async {
  while (true) {
    onBusyChanged?.call(true);
    LocationDataModel? locationData;
    try {
      locationData = await controller.checkPermissionAndSetData(
        preferNativeGeocoding: preferNativeGeocoding,
      );
    } finally {
      onBusyChanged?.call(false);
    }
    if (locationData != null) return locationData;
    if (!context.mounted) return null;

    final retry = await showLocationHelpSheet(
      context: context,
      reason: controller.lastErrorType,
      purpose: purpose,
    );
    if (!retry || !context.mounted) return null;
  }
}

/// Shows the guidance for [reason]. Returns true when the user wants another
/// attempt — either because they fixed the setting and tapped Try again, or
/// because the fix IS the next attempt (an OS permission prompt we can still
/// raise).
///
/// [purpose] is one line on why this particular screen needs the location. It
/// is worth passing: "so nearby customers can find your shop" is a reason, and
/// a reason is what turns a permission prompt from an obstacle into a choice.
Future<bool> showLocationHelpSheet({
  required BuildContext context,
  required LocationErrorType reason,
  String? purpose,
}) async {
  final granted = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _LocationHelpSheet(reason: reason, purpose: purpose),
  );
  return granted ?? false;
}

/// What the sheet's main button does, which is the only thing that really
/// differs between the failures.
enum _FixAction {
  /// Re-ask the OS. Only for a denial the system will still prompt on again —
  /// tapping it closes the sheet and the caller's retry raises the prompt.
  requestPermission,

  /// Open the app's own settings page, where a permanent denial is undone.
  openAppSettings,

  /// Open the device Location settings, where the master toggle lives.
  openLocationSettings,

  /// Nothing to change — permission and GPS are fine, the fix just failed.
  retryOnly,
}

class _LocationHelpSheet extends StatefulWidget {
  const _LocationHelpSheet({required this.reason, this.purpose});

  final LocationErrorType reason;
  final String? purpose;

  @override
  State<_LocationHelpSheet> createState() => _LocationHelpSheetState();
}

class _LocationHelpSheetState extends State<_LocationHelpSheet>
    with WidgetsBindingObserver {
  /// Set once the user has been sent to a settings screen.
  ///
  /// Opening settings backgrounds the app, so the sheet cannot know whether
  /// anything was actually changed — and popping optimistically, before it
  /// knows, would retry while the user is still in Settings, fail again, and
  /// reopen this sheet behind their back. So the sheet stays put and Try again
  /// becomes the prominent button.
  ///
  /// That button is the FALLBACK, not the plan: [didChangeAppLifecycleState]
  /// checks the setting the moment the app comes back, and closes the sheet
  /// itself when it has been changed. Try again is what's left for the user
  /// who came back without fixing it, or whose device reports it late.
  bool _sentToSettings = false;

  /// Guards the on-return check. Resume can fire more than once for a single
  /// trip back (some launchers send it again after the first frame), and two
  /// overlapping checks could both decide to pop.
  bool _checkingOnReturn = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _closeIfFixed();
  }

  /// Re-reads the setting this sheet is about, now that the app is back in
  /// front, and closes with "retry" when it has been granted or switched on.
  ///
  /// This is the whole point of the trip to Settings: someone who has just
  /// turned GPS on has done the thing that was asked of them, and being met on
  /// their return by the same sheet — still saying their location is off, now
  /// with an extra button to press — reads as the app not having noticed. The
  /// caller's loop picks the retry straight up, so the submit they were in the
  /// middle of simply carries on.
  ///
  /// Only ever closes on a POSITIVE reading. A check that says "still not
  /// granted", or one that throws, leaves the sheet exactly as it was, with
  /// Try again available — the sheet is never dismissed on a guess.
  Future<void> _closeIfFixed() async {
    final isFixed = _fixedCheck;
    if (isFixed == null || _checkingOnReturn) return;
    _checkingOnReturn = true;
    try {
      if (await isFixed() && mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (_) {
      // A platform that won't answer is not evidence either way. Leave the
      // sheet up rather than close on a failed read.
    } finally {
      _checkingOnReturn = false;
    }
  }

  /// How to tell, on return, whether the fix actually happened — or null when
  /// there is no setting to read (nothing was wrong with permissions or GPS,
  /// the fix simply failed, so returning to the app proves nothing).
  Future<bool> Function()? get _fixedCheck {
    switch (_action) {
      case _FixAction.openLocationSettings:
        return Geolocator.isLocationServiceEnabled;
      case _FixAction.openAppSettings:
      case _FixAction.requestPermission:
        return () async {
          final status = await Permission.location.status;
          // `limited` is iOS's approximate location, which is enough for an
          // address line and a pincode — the same bar the handler applies.
          return status.isGranted || status.isLimited;
        };
      case _FixAction.retryOnly:
        return null;
    }
  }

  _FixAction get _action {
    switch (widget.reason) {
      case LocationErrorType.serviceDisabled:
        return _FixAction.openLocationSettings;
      case LocationErrorType.permissionPermanentlyDenied:
        return _FixAction.openAppSettings;
      case LocationErrorType.permissionDenied:
        return _FixAction.requestPermission;
      case LocationErrorType.addressLookupFailed:
      case LocationErrorType.timeout:
      case LocationErrorType.unknown:
      case LocationErrorType.none:
        return _FixAction.retryOnly;
    }
  }

  String get _title {
    switch (_action) {
      case _FixAction.openLocationSettings:
        return AppStrings.locationGpsOffTitle.tr;
      case _FixAction.openAppSettings:
        return AppStrings.locationBlockedTitle.tr;
      case _FixAction.requestPermission:
        return AppStrings.locationAllowTitle.tr;
      case _FixAction.retryOnly:
        return AppStrings.locationNotFoundTitle.tr;
    }
  }

  IconData get _icon {
    switch (_action) {
      case _FixAction.openLocationSettings:
        return Icons.location_disabled_rounded;
      case _FixAction.openAppSettings:
        return Icons.lock_outline_rounded;
      case _FixAction.requestPermission:
        return Icons.my_location_rounded;
      case _FixAction.retryOnly:
        return Icons.explore_off_rounded;
    }
  }

  List<String> get _steps {
    switch (_action) {
      case _FixAction.openLocationSettings:
        return [
          AppStrings.locationGpsStep1.tr,
          AppStrings.locationGpsStep2.tr,
          AppStrings.locationGpsStep3.tr,
        ];
      case _FixAction.openAppSettings:
        return [
          AppStrings.locationBlockedStep1.tr,
          AppStrings.locationBlockedStep2.tr,
          AppStrings.locationBlockedStep3.tr,
          AppStrings.locationBlockedStep4.tr,
        ];
      case _FixAction.requestPermission:
        return [
          AppStrings.locationAllowStep1.tr,
          AppStrings.locationAllowStep2.tr,
          AppStrings.locationAllowStep3.tr,
        ];
      case _FixAction.retryOnly:
        return [
          AppStrings.locationRetryStep1.tr,
          AppStrings.locationRetryStep2.tr,
          AppStrings.locationRetryStep3.tr,
        ];
    }
  }

  String get _actionLabel {
    switch (_action) {
      case _FixAction.openLocationSettings:
        return AppStrings.locationTurnOnGps.tr;
      case _FixAction.openAppSettings:
        return AppStrings.openSettings.tr;
      case _FixAction.requestPermission:
        return AppStrings.locationAllowAction.tr;
      case _FixAction.retryOnly:
        return AppStrings.locationTryAgain.tr;
    }
  }

  Future<void> _onAction() async {
    switch (_action) {
      case _FixAction.requestPermission:
      case _FixAction.retryOnly:
        // Both are just "go round again" — the OS prompt, if there is one to
        // show, comes up on the next attempt.
        Navigator.of(context).pop(true);
        return;
      case _FixAction.openAppSettings:
        await openAppSettings();
        break;
      case _FixAction.openLocationSettings:
        // NOT openAppSettings(): the GPS master toggle is a device setting and
        // does not appear anywhere on the app's own permissions page.
        await Geolocator.openLocationSettings();
        break;
    }
    if (mounted) setState(() => _sentToSettings = true);
  }

  @override
  Widget build(BuildContext context) {
    final steps = _steps;
    // Try again only earns a button of its own once the main button has
    // stopped being the thing to press — before that it is the same tap twice.
    final showRetry = _sentToSettings;

    // Bounded and scrollable, not a bare Column: the tallest variant is a
    // title, a reason, four numbered steps and three buttons, and on a short
    // handset — or any handset with the OS font scaled up — that is more than
    // fits. Overflowing would clip the buttons off the bottom, which on a
    // sheet whose whole purpose is "here is the way out" is the one failure
    // it cannot afford.
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.9,
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(
            left: SizeConfig.size16,
            right: SizeConfig.size16,
            top: SizeConfig.size12,
            bottom: MediaQuery.of(context).padding.bottom + SizeConfig.size16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: EdgeInsets.only(bottom: SizeConfig.size16),
                  decoration: BoxDecoration(
                    color: AppColors.greyE5,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              Center(
                child: Container(
                  width: 64,
                  height: 64,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.primaryColor.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primaryColor.withValues(alpha: 0.18),
                    ),
                  ),
                  child: Icon(_icon, size: 30, color: AppColors.primaryColor),
                ),
              ),
              SizedBox(height: SizeConfig.size16),
              CustomText(
                _title,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.mainTextColor,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: SizeConfig.size8),
              CustomText(
                widget.purpose ?? AppStrings.locationWhyGeneric.tr,
                fontSize: SizeConfig.medium,
                fontWeight: FontWeight.w400,
                color: AppColors.secondaryTextColor,
                textAlign: TextAlign.center,
                maxLines: 5,
              ),
              SizedBox(height: SizeConfig.size16),
              Container(
                padding: EdgeInsets.all(SizeConfig.size12),
                decoration: BoxDecoration(
                  color: AppColors.primaryColor.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CustomText(
                      AppStrings.locationStepsHeading.tr,
                      fontSize: SizeConfig.small,
                      fontWeight: FontWeight.w700,
                      color: AppColors.mainTextColor,
                    ),
                    SizedBox(height: SizeConfig.size8),
                    for (int i = 0; i < steps.length; i++)
                      Padding(
                        padding: EdgeInsets.only(
                          bottom: i == steps.length - 1 ? 0 : SizeConfig.size8,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 20,
                              height: 20,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: AppColors.primaryColor,
                                shape: BoxShape.circle,
                              ),
                              child: CustomText(
                                '${i + 1}',
                                fontSize: SizeConfig.small,
                                fontWeight: FontWeight.w700,
                                color: AppColors.white,
                              ),
                            ),
                            SizedBox(width: SizeConfig.size8),
                            Expanded(
                              child: CustomText(
                                steps[i],
                                fontSize: SizeConfig.small,
                                fontWeight: FontWeight.w400,
                                color: AppColors.mainTextColor,
                                maxLines: 4,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(height: SizeConfig.size20),
              GestureDetector(
                onTap: _onAction,
                child: Container(
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: showRetry
                        ? AppColors.white
                        : AppColors.primaryColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.primaryColor),
                  ),
                  child: CustomText(
                    _actionLabel,
                    fontSize: SizeConfig.medium,
                    fontWeight: FontWeight.w700,
                    color:
                        showRetry ? AppColors.primaryColor : AppColors.white,
                  ),
                ),
              ),
              if (showRetry) ...[
                SizedBox(height: SizeConfig.size8),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(true),
                  child: Container(
                    height: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.primaryColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: CustomText(
                      AppStrings.locationTryAgain.tr,
                      fontSize: SizeConfig.medium,
                      fontWeight: FontWeight.w700,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ],
              SizedBox(height: SizeConfig.size8),
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: CustomText(
                  AppStrings.notNow.tr,
                  fontSize: SizeConfig.medium,
                  fontWeight: FontWeight.w600,
                  color: AppColors.secondaryTextColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
