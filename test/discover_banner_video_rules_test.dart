import 'package:BlueEra/core/constants/app_image_assets.dart';
import 'package:BlueEra/features/common/Discover/widget/discover_profile_banner.dart';
import 'package:flutter_test/flutter_test.dart';

/// The two rules that decide what the Discover header banner shows a GUEST and
/// how long it shows it for.
///
/// Both were written inline inside `build` first, and both were wrong there in
/// ways nothing catches at compile time — see the individual groups. They are
/// pure functions now precisely so these cases can be pinned.
void main() {
  const goLive = AppImageAssets.goLiveIndividualAccount;
  const completeProfile = AppImageAssets.completeProfileBanner;
  const clip = 'https://example.test/intro.mp4';

  group('discoverBannerLeadingSlide', () {
    test('guest with a clip yields no artwork — the clip takes the slot', () {
      expect(
        discoverBannerLeadingSlide(
          guest: true,
          videoUrl: clip,
          goLiveSlide: null,
        ),
        isNull,
      );
    });

    test('guest with no clip keeps the complete-profile artwork', () {
      expect(
        discoverBannerLeadingSlide(
          guest: true,
          videoUrl: null,
          goLiveSlide: null,
        ),
        completeProfile,
      );
    });

    test('an offline account keeps its go-live slide', () {
      expect(
        discoverBannerLeadingSlide(
          guest: false,
          videoUrl: null,
          goLiveSlide: goLive,
        ),
        goLive,
      );
    });

    test('a live account gets no leading slide', () {
      expect(
        discoverBannerLeadingSlide(
          guest: false,
          videoUrl: null,
          goLiveSlide: null,
        ),
        isNull,
      );
    });

    /// The regression this function exists for.
    ///
    /// The first version lived in the slide list as
    /// `if (guest) if (videoUrl == null) art else if (goLive != null) goLive`.
    /// Dart binds that `else` to the INNER `if`, so the whole branch became
    /// guest-only and every signed-in account silently lost its go-live card.
    /// It is valid Dart, so the analyzer says nothing.
    test('a clip being available never affects a signed-in account', () {
      expect(
        discoverBannerLeadingSlide(
          guest: false,
          videoUrl: clip,
          goLiveSlide: goLive,
        ),
        goLive,
        reason: 'the clip is guest-only and must not displace the go-live card',
      );
    });
  });

  group('discoverBannerHoldsForVideo', () {
    test('holds while an unwatched clip is the slide on screen', () {
      expect(
        discoverBannerHoldsForVideo(videoUrl: clip, watched: false, index: 0),
        isTrue,
      );
    });

    /// The stuck-carousel regression.
    ///
    /// The hold used to be a flag latched when playback started and cleared
    /// when the clip ended. Swiping away mid-clip deactivates the slide, so the
    /// end never arrives, so the flag never cleared — auto-advance stayed off
    /// for the rest of the session. Deriving the hold from the index means
    /// leaving the slide releases it on the same frame.
    test('releases as soon as the viewer swipes to another slide', () {
      expect(
        discoverBannerHoldsForVideo(videoUrl: clip, watched: false, index: 1),
        isFalse,
        reason: 'a mid-clip swipe must not disable auto-advance permanently',
      );
    });

    test('does not re-hold once the clip has been watched', () {
      expect(
        discoverBannerHoldsForVideo(videoUrl: clip, watched: true, index: 0),
        isFalse,
      );
    });

    test('never holds when there is no clip', () {
      expect(
        discoverBannerHoldsForVideo(videoUrl: null, watched: false, index: 0),
        isFalse,
      );
    });
  });
}
