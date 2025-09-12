import 'package:BlueEra/core/api/apiService/api_base_helper.dart';
import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/base_service.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';

class SongRepo extends BaseService{

  ///GET ALL Songs...
  Future<ResponseModel> getAllSongs(
      {required Map<String, dynamic> queryParams}) async {
    final response = await ApiBaseHelper().getHTTP(
      songs,
      params: queryParams,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  ///GET FAVOURITE Songs...
  Future<ResponseModel> getAllFavouriteSongs(
      {required Map<String, dynamic> queryParams}) async {
    final response = await ApiBaseHelper().getHTTP(
      favourite,
      params: queryParams,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  ///ADD SONG IN FAVOURITE...
  Future<ResponseModel> addSongInFavourite(
      {required Map<String, dynamic> params}) async {
    final response = await ApiBaseHelper().postHTTP(
      favourite,
      params: params,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  ///REMOVE SONG FROM FAVOURITE...
  Future<ResponseModel> removeSongFromFavourite(
      {required String songId}) async {
    Map<String, dynamic> params = {
      ApiKeys.songId: songId,
    };
    final response = await ApiBaseHelper().deleteHTTP(
      favourite + '/$songId',
      params: params,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  ///CHECK SONG FAVOURITE BY USER...
  Future<ResponseModel> checkSongFavouriteByUser(
      {required String songId}) async {
    // Map<String, dynamic> params = {
    //   'songId' : songId,
    // };
    final response = await ApiBaseHelper().getHTTP(
      checkFavourite + '/$songId',
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  ///SEARCH SONGS...
  Future<ResponseModel> searchSongs(
      {required Map<String, dynamic> params}) async {
    final response = await ApiBaseHelper().getHTTP(
      songsSearch,
      params: params,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  ///SEARCH FAVOURITE SONGS...
  Future<ResponseModel> searchFavouriteSongs(
      {required Map<String, dynamic> params}) async {
    final response = await ApiBaseHelper().getHTTP(
      favouriteSearch,
      params: params,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  ///GET ALL Songs...
  Future<ResponseModel> getAllSongPost(
      {required Map<String, dynamic> queryParams}) async {
    final response = await ApiBaseHelper().getHTTP(
      songsPost,
      params: queryParams,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  ///GET FAVOURITE Songs...
  Future<ResponseModel> getAllFavouriteSongPost(
      {required Map<String, dynamic> queryParams}) async {
    final response = await ApiBaseHelper().getHTTP(
      favouriteSongPost,
      params: queryParams,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  ///ADD SONG IN FAVOURITE...
  Future<ResponseModel> addSongInFavouritePost(
      {required Map<String, dynamic> params}) async {
    final response = await ApiBaseHelper().postHTTP(
      favouriteSongPost,
      params: params,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  ///REMOVE SONG FROM FAVOURITE...
  Future<ResponseModel> removeSongFromFavouritePost(
      {required String songId}) async {
    Map<String, dynamic> params = {
      ApiKeys.songId: songId,
    };
    final response = await ApiBaseHelper().deleteHTTP(
      favouriteSongPost + '/$songId',
      params: params,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  ///CHECK SONG FAVOURITE BY USER...
  Future<ResponseModel> checkSongFavouriteByUserPost(
      {required String songId}) async {
    final response = await ApiBaseHelper().getHTTP(
      checkFavouriteSongPost + '/$songId',
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  ///SEARCH SONGS...
  Future<ResponseModel> searchSongPost(
      {required Map<String, dynamic> params}) async {
    final response = await ApiBaseHelper().getHTTP(
      songsSearchSongPost,
      params: params,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }

  ///SEARCH FAVOURITE SONGS...
  Future<ResponseModel> searchFavouriteSongPost(
      {required Map<String, dynamic> params}) async {
    final response = await ApiBaseHelper().getHTTP(
      favouriteSearchSongPost,
      params: params,
      showProgress: false,
      onError: (error) {},
      onSuccess: (data) {},
    );
    return response;
  }



}