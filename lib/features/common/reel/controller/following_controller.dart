import 'package:BlueEra/features/common/reel/models/following_model.dart';
import 'package:BlueEra/features/common/reel/repo/following_repo.dart';
import 'package:get/get.dart';

class FollowingController extends GetxController {
  List<Following>? _followingList;
  bool _isLoading = false;
  String? _errorMessage;

  List<Following>? get followerList => _followingList;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchList({required int userId, required int limit, required int offset}) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      update();

      final response = await FollowingRepo.getList(userId: userId, limit: limit, offset: offset);
      if (response.isSuccess) {
        final list = FollowingModel.fromJson(response.response?.data);
        _followingList ??= [];
        if (list.data?.isNotEmpty == true) _followingList?.addAll(list.data!);
      }
    } catch (e) {
      _errorMessage = '$e';
    } finally {
      _isLoading = false;
      update();
    }
  }

  Future<void> pagination({required int userId, required int limit, required int offset}) async {
    try {
      _isLoading = true;
      _errorMessage = null;
      update();

      final response = await FollowingRepo.getList(userId: userId, limit: limit, offset: offset);
      if (response.isSuccess) {
        final list = FollowingModel.fromJson(response.response?.data);
        if (list.data?.isNotEmpty == true) _followingList?.addAll(list.data!);
      }
    } catch (e) {
      _errorMessage = '$e';
    } finally {
      _isLoading = false;
      update();
    }
  }
}
