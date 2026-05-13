import 'package:BlueEra/core/constants/shared_preference_utils.dart';

/// All `channel-service/*` endpoint constants used by the app.
///
/// Mixed into [BaseService] alongside the other per-service API mixins.
///
/// Note: `socialLinks` lives here despite the name because it resolves to a
/// `channel-service/...` path — same for `bankDetails`. Anything that
/// targets `social-service/...` lives in `SocialServiceApi`.
mixin ChannelServiceApi {
  final String channels = 'channel-service/channels';
  final String socialLinks = 'channel-service/channels/$channelId/social-links';
  String viewChannelProfile(String channelId) =>
      "channel-service/channels/$channelId";
  String channelStats(String channelId) =>
      'channel-service/channels/$channelId/stats';

  String channelFollow(String channelId) =>
      "channel-service/follower/$channelId/follow";
  String channelUnFollow(String channelId) =>
      "channel-service/follower/$channelId/unfollow";

  String channelReports(String channelId) =>
      'channel-service/channels/$channelId/reports';
  String channelBlockUser(String channelId) =>
      'channel-service/channels/$channelId/block-user';
  String channelUnBlockUser(String channelId) =>
      'channel-service/channels/$channelId/unblock-user';
  String channelMuteUser(String channelId) =>
      'channel-service/channels/$channelId/mute-user';
  String channelUnMuteUser(String channelId) =>
      'channel-service/channels/$channelId/unmute-user';

  String bankDetails(String channelId) =>
      'channel-service/channels/$channelId/payment-details';

  String channelFollowingMe = "channel-service/follower/following/me";
  String channel_service_follower = "channel-service/follower/";
  final String channelsRecommendations =
      "channel-service/channels/recommendations/";
  final String channelServiceFollower = "channel-service/follower/";
  final String channelSearch = 'channel-service/channels/search/search';
}
