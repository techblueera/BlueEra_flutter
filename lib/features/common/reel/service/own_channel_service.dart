import 'package:BlueEra/core/constants/shared_preference_utils.dart';
import 'package:BlueEra/features/common/reel/models/channel_model.dart';
import 'package:BlueEra/features/common/reel/repo/channel_repo.dart';

/// The signed-in individual's own channel, which the app keeps in the
/// `channelId` / `channelName` / `channelOwner` globals and secure storage.
class OwnChannelService {
  OwnChannelService({ChannelRepo? repo}) : _repo = repo ?? ChannelRepo();

  final ChannelRepo _repo;

  /// The channel for [userId], or null when there is none or the call failed.
  Future<ChannelModel?> fetch(String userId) async {
    try {
      final response = await _repo.getChannelDetails(channelOrUserId: userId);
      return response.statusCode == 200
          ? ChannelModel.fromJson(response.response?.data)
          : null;
    } catch (_) {
      return null;
    }
  }

  /// Looks up [userId]'s channel and remembers it, unless one is already
  /// known this session.
  Future<void> rememberOwnChannel(String userId) async {
    if (channelId.isNotEmpty) return;
    final data = (await fetch(userId))?.data;
    if (data == null) return;

    channelId = data.id;
    channelName = data.name;
    channelOwner = data.username;
    await Future.wait([
      SharedPreferenceUtils.setSecureValue(
          SharedPreferenceUtils.channel_Id, channelId),
      SharedPreferenceUtils.setSecureValue(
          SharedPreferenceUtils.channelName, channelName),
      SharedPreferenceUtils.setSecureValue(
          SharedPreferenceUtils.channelOwner, channelOwner),
    ]);
  }
}
