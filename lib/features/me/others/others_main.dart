import 'package:BlueEra/features/me/others/view/v2/other_home_screen_v2.dart';
import 'package:flutter/material.dart';

/// Entry point for the "other" business Me screen.
///
/// It no longer pops anything on landing. The two sheets this screen can show
/// are now owned by the tab each one is ABOUT:
///
///  * **Add a service** — the Services tab (`OtherServicesTabV2`), opened once
///    its fetch comes back empty. That tab is where the screen lands, and a
///    missing service is what blocks the profile from going live, so it is the
///    first thing the merchant is asked for.
///  * **Live photos** — the Overview tab (`OtherHomeScreenV2._onTabChanged`),
///    opened when the merchant switches to it. Overview is where the photos
///    are; asking for them over the Services tab, as this screen used to,
///    covered a tab that had a different and more urgent gap of its own.
class OthersMain extends StatelessWidget {
  const OthersMain({super.key});

  @override
  Widget build(BuildContext context) {
    return const OtherHomeScreenV2();
  }
}
