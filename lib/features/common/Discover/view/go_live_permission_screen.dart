import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/permissionCentralize/go_live_permission_service.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:flutter/material.dart';

/// Rapido-style "Give all permissions to proceed" screen.
/// Each card requests its own permission on tap; the Submit button
/// is only enabled once every required permission has been granted.
class GoLivePermissionScreen extends StatefulWidget {
  const GoLivePermissionScreen({super.key});

  @override
  State<GoLivePermissionScreen> createState() => _GoLivePermissionScreenState();
}

class _GoLivePermissionScreenState extends State<GoLivePermissionScreen>
    with WidgetsBindingObserver {
  final Map<GoLivePermissionType, bool> _granted = {
    GoLivePermissionType.backgroundLocation: false,
    GoLivePermissionType.batteryOptimization: false,
    GoLivePermissionType.displayOverOtherApps: false,
  };

  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshAll();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // When the user returns from system settings, recheck statuses.
    if (state == AppLifecycleState.resumed) _refreshAll();
  }

  Future<void> _refreshAll() async {
    final result = await GoLivePermissionService.checkAll();
    if (!mounted) return;
    setState(() => _granted.addAll(result));
  }

  Future<void> _handleTap(GoLivePermissionType type) async {
    if (_busy) return;
    // Already granted — nothing to do.
    if (_granted[type] == true) return;

    // Show the Rapido-style explanation bottom sheet first.
    // Tapping "Okay" triggers the system permission flow / opens settings.
    await _showPermissionBottomSheet(type);
  }

  Future<void> _showPermissionBottomSheet(GoLivePermissionType type) async {
    late final String title;
    late final String message;
    switch (type) {
      case GoLivePermissionType.backgroundLocation:
        title = 'Allow Background activity';
        message =
            'Allow BlueEra to find content based on location while you are live.';
        break;
      case GoLivePermissionType.batteryOptimization:
        title = 'Battery Usage';
        message = 'Allow BlueEra to run in the background while you are live.';
        break;
      case GoLivePermissionType.displayOverOtherApps:
        title = 'Allow BlueEra to Display over other apps';
        message =
            'Permit app to display on top of other apps to get live alerts.';
        break;
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return SafeArea(
          top: false,
          child: Container(
          decoration: const BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          padding: EdgeInsets.fromLTRB(
            SizeConfig.size20,
            SizeConfig.size20,
            SizeConfig.size20,
            SizeConfig.size32,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.greyE5,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              SizedBox(height: SizeConfig.size20),
              CustomText(
                title,
                fontSize: SizeConfig.extraLarge,
                fontWeight: FontWeight.w700,
                color: AppColors.mainTextColor,
                maxLines: 2,
              ),
              SizedBox(height: SizeConfig.size12),
              CustomText(
                message,
                fontSize: SizeConfig.large,
                color: AppColors.mainTextColor,
                maxLines: 4,
              ),
              SizedBox(height: SizeConfig.size24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    foregroundColor: AppColors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 0,
                  ),
                  child: CustomText(
                    'Okay',
                    fontSize: SizeConfig.large,
                    fontWeight: FontWeight.w700,
                    color: AppColors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
        );
      },
    );

    if (!mounted) return;
    // After the user dismisses the bottom sheet, route them to the relevant
    // settings/system dialog so they can actually grant the permission.
    await _openPermissionSettings(type);
  }

  Future<void> _openPermissionSettings(GoLivePermissionType type) async {
    setState(() => _busy = true);
    bool ok = false;
    switch (type) {
      case GoLivePermissionType.backgroundLocation:
        ok = await GoLivePermissionService.requestBackgroundLocation();
        break;
      case GoLivePermissionType.batteryOptimization:
        ok = await GoLivePermissionService.requestBatteryOptimization();
        break;
      case GoLivePermissionType.displayOverOtherApps:
        ok = await GoLivePermissionService.requestDisplayOverOtherApps();
        break;
    }
    if (!mounted) return;
    setState(() {
      _granted[type] = ok;
      _busy = false;
    });
  }

  bool get _allGranted => true;

  void _onSubmit() {
    if (!_allGranted) {
      commonSnackBar(
        message: 'Please grant all required permissions to go live.',
      );
      return;
    }
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.whiteF1,
      body: SafeArea(
        child: Column(
          children: [
            // ---------- Top bar ----------
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: SizeConfig.size16,
                vertical: SizeConfig.size12,
              ),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(20),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.arrow_back,
                          color: AppColors.mainTextColor),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: SizeConfig.size12,
                      vertical: SizeConfig.size6,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.mainTextColor),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.headset_mic_outlined,
                            size: 18, color: AppColors.mainTextColor),
                        SizedBox(width: SizeConfig.size6),
                        CustomText(
                          'Help',
                          fontSize: SizeConfig.medium,
                          fontWeight: FontWeight.w600,
                          color: AppColors.mainTextColor,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ---------- Blue header banner ----------
            Container(
              width: double.infinity,
              color: AppColors.primaryColor,
              padding: EdgeInsets.symmetric(
                horizontal: SizeConfig.size20,
                vertical: SizeConfig.size20,
              ),
              child: CustomText(
                'Give all permissions to proceed',
                fontSize: SizeConfig.extraLarge,
                fontWeight: FontWeight.w700,
                color: AppColors.white,
                maxLines: 2,
              ),
            ),

            SizedBox(height: SizeConfig.size16),

            // ---------- Permission cards ----------
            Expanded(
              child: ListView(
                padding: EdgeInsets.symmetric(horizontal: SizeConfig.size16),
                children: [
                  _PermissionCard(
                    icon: Icons.location_on_outlined,
                    title: 'Background Location',
                    subtitle: 'Helps go live with location based content',
                    granted:
                        _granted[GoLivePermissionType.backgroundLocation]!,
                    onTap: () =>
                        _handleTap(GoLivePermissionType.backgroundLocation),
                  ),
                  SizedBox(height: SizeConfig.size12),
                  _PermissionCard(
                    icon: Icons.battery_charging_full,
                    title: 'Battery Usage',
                    subtitle: 'Helps app run in background',
                    granted:
                        _granted[GoLivePermissionType.batteryOptimization]!,
                    onTap: () =>
                        _handleTap(GoLivePermissionType.batteryOptimization),
                  ),
                  SizedBox(height: SizeConfig.size12),
                  _PermissionCard(
                    icon: Icons.dashboard_outlined,
                    title: 'Display over other apps',
                    subtitle:
                        'Permit app to display on top of other apps to get live alerts',
                    granted:
                        _granted[GoLivePermissionType.displayOverOtherApps]!,
                    onTap: () =>
                        _handleTap(GoLivePermissionType.displayOverOtherApps),
                  ),
                ],
              ),
            ),

            // ---------- Submit ----------
            Padding(
              padding: EdgeInsets.fromLTRB(
                SizeConfig.size16,
                SizeConfig.size8,
                SizeConfig.size16,
                SizeConfig.size20,
              ),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _allGranted ? _onSubmit : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryColor,
                    disabledBackgroundColor: AppColors.greyE5,
                    foregroundColor: AppColors.white,
                    disabledForegroundColor: AppColors.secondaryTextColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 0,
                  ),
                  child: CustomText(
                    'Submit',
                    fontSize: SizeConfig.large,
                    fontWeight: FontWeight.w700,
                    color: _allGranted
                        ? AppColors.white
                        : AppColors.secondaryTextColor,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PermissionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool granted;
  final VoidCallback onTap;

  const _PermissionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.granted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: granted ? null : onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: SizeConfig.size16,
          vertical: SizeConfig.size16,
        ),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: granted ? Colors.green : AppColors.greyE5,
            width: granted ? 1.2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.primaryColor, size: 22),
            ),
            SizedBox(width: SizeConfig.size12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomText(
                    title,
                    fontSize: SizeConfig.large,
                    fontWeight: FontWeight.w700,
                    color: AppColors.mainTextColor,
                  ),
                  SizedBox(height: SizeConfig.size4),
                  CustomText(
                    subtitle,
                    fontSize: SizeConfig.medium,
                    color: AppColors.secondaryTextColor,
                    maxLines: 2,
                  ),
                ],
              ),
            ),
            SizedBox(width: SizeConfig.size8),
            Icon(
              granted ? Icons.check_circle : Icons.chevron_right,
              color: granted ? Colors.green : AppColors.primaryColor,
              size: granted ? 24 : 26,
            ),
          ],
        ),
      ),
    );
  }
}
