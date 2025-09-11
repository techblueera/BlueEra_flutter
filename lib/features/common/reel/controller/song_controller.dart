 import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/api/apiService/api_response.dart';
import 'package:BlueEra/core/api/apiService/response_model.dart';
import 'package:BlueEra/core/constants/app_strings.dart';
import 'package:BlueEra/core/constants/snackbar_helper.dart';
import 'package:BlueEra/features/common/reel/models/get_all_favourite_songs_model.dart';
import 'package:BlueEra/features/common/reel/models/get_all_songs_model.dart';
import 'package:BlueEra/features/common/reel/repo/song_repo.dart';
import 'package:get/get.dart';

class SongController extends GetxController{
  ApiResponse getAllSongsResponse = ApiResponse.initial('Initial');
  ApiResponse getFavouriteSongsResponse = ApiResponse.initial('Initial');
  ApiResponse addSongInFavouriteResponse = ApiResponse.initial('Initial');
  ApiResponse removeSongInFavouriteResponse = ApiResponse.initial('Initial');
  ApiResponse checkSongFavouriteByUserResponse = ApiResponse.initial('Initial');
  ApiResponse searchSongsResponse = ApiResponse.initial('Initial');
  ApiResponse searchFavouriteSongsResponse = ApiResponse.initial('Initial');

  RxBool isSongLoading = true.obs;
  RxBool isFavouriteLoading = true.obs;
  int page = 1;
  int limit = 10;
  RxList<Song> songs = <Song>[].obs;
  RxList<FavouriteSong> favouriteSongs = <FavouriteSong>[].obs;

  onInit(){
    super.onInit();
    getAllSongs();
  }

  ///GET ALL Songs...
  Future<void> getAllSongs() async {
    try {
      isSongLoading.value = true;
      Map<String, dynamic> queryParams = {
        ApiKeys.page : page,
        ApiKeys.limit: limit
      };
      ResponseModel response;
     response = await SongRepo().getAllSongs(queryParams: queryParams);

      if (response.statusCode == 200) {
        GetAllSongsModel getAllSongsModel = GetAllSongsModel.fromJson(response.response?.data);
        songs.value = getAllSongsModel.data;
        getAllSongsResponse = ApiResponse.complete(response);
      } else {
        commonSnackBar(message: response.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      getAllSongsResponse = ApiResponse.error('error');
      commonSnackBar(message: AppStrings.somethingWentWrong);
    } finally{
      isSongLoading.value = false;
    }
  }

  ///GET FAVOURITE Songs...
  Future<void> getAllFavouriteSongs() async {
    try {
      isFavouriteLoading.value = true;
      Map<String, dynamic> queryParams = {
        ApiKeys.page : page,
        ApiKeys.limit: limit
      };

      ResponseModel response = await SongRepo().getAllFavouriteSongs(queryParams: queryParams);

      if (response.statusCode == 200) {
        FavouriteSongsResponse favouriteSongsResponse = FavouriteSongsResponse.fromJson(response.response?.data);

        // ✅ Assign parsed list to observable
        favouriteSongs.value = favouriteSongsResponse.data;

        // ✅ Optional: show success message
        // commonSnackBar(message: response.message ?? AppStrings.success);

        getFavouriteSongsResponse = ApiResponse.complete(response);
      } else {
        commonSnackBar(message: response.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      getFavouriteSongsResponse = ApiResponse.error('error');
      commonSnackBar(message: AppStrings.somethingWentWrong);
    } finally {
      isFavouriteLoading.value = false;
    }
  }


  /// ADD SONG TO FAVOURITES (no isAllSongs flag)
  Future<void> addSongInFavourite({required String songId}) async {
    try {
      Map<String, dynamic> params = {ApiKeys.songId: songId};

      ResponseModel response = await SongRepo().addSongInFavourite(params: params);

      if (response.isSuccess) {
        commonSnackBar(message: response.message ?? AppStrings.success);

        // ✅ 1. Update in songs list
        int allIndex = songs.indexWhere((song) => song.id == songId);
        Song? updatedSong;
        if (allIndex != -1) {
          updatedSong = songs[allIndex].copyWith(isFavourite: true);
          songs[allIndex] = updatedSong;
        }

        // ✅ 2. Check if already in favourites
        bool alreadyInFav = favouriteSongs.any((fav) => fav.song.id == songId);

        if (!alreadyInFav) {
          // Either use the updatedSong or fallback to find from all songs
          final Song songToAdd = updatedSong ??
              songs.firstWhere((song) => song.id == songId);

          favouriteSongs.add(FavouriteSong(
            id: 'local_${songId}', // Or get from response if returned
            userId: 'yourUserId',  // Set current user ID if needed
            song: songToAdd.copyWith(isFavourite: true),
          ));
        }

        addSongInFavouriteResponse = ApiResponse.complete(response);
      } else {
        commonSnackBar(message: response.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      addSongInFavouriteResponse = ApiResponse.error('error');
      commonSnackBar(message: AppStrings.somethingWentWrong);
    } finally {
      // isLoading.value = false;
    }
  }

  /// REMOVE SONG FROM FAVOURITES
  Future<void> removeSongFromFavourite({required String songId}) async {
    try {
      ResponseModel response = await SongRepo().removeSongFromFavourite(songId: songId);

      if (response.statusCode == 200) {
        commonSnackBar(message: response.message ?? AppStrings.success);

        // ✅ 1. Remove from favouriteSongs list if exists
        int favIndex = favouriteSongs.indexWhere((favouriteSong) => favouriteSong.song.id == songId);
        if (favIndex != -1) {
          favouriteSongs.removeAt(favIndex);
        }

        removeSongInFavouriteResponse = ApiResponse.complete(response);
      } else {
        commonSnackBar(message: response.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      removeSongInFavouriteResponse = ApiResponse.error('error');
      commonSnackBar(message: AppStrings.somethingWentWrong);
    } finally {
      // isLoading.value = false;
    }
  }

  /// REMOVE SONG FROM FAVOURITES
  Future<void> removeSongFromFavouriteItemList({required String songId}) async {
    try {
      ResponseModel response = await SongRepo().removeSongFromFavourite(songId: songId);

      if (response.statusCode == 200) {
        commonSnackBar(message: response.message ?? AppStrings.success);

        // ✅ 1. Remove from favouriteSongs list if exists
        favouriteSongs.removeWhere((song) => song.id == songId);

        // ✅ 2. Also remove from songs list completely if required
        songs.removeWhere((song) => song.id == songId);

        removeSongInFavouriteResponse = ApiResponse.complete(response);
      } else {
        commonSnackBar(message: response.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      removeSongInFavouriteResponse = ApiResponse.error('error');
      commonSnackBar(message: AppStrings.somethingWentWrong);
    } finally {
      // isLoading.value = false;
    }
  }


  // ///CHECK SONG FAVOURITE BY USER...
  // Future<void> checkSongFavouriteByUser({required String songId}) async {
  //   try {
  //     Map<String, dynamic> params = {
  //       'query' : '',
  //       'page' : page,
  //       'limit': limit
  //     };
  //
  //     ResponseModel response = await SongRepo().searchSongs(params: params);
  //
  //     if (response.statusCode == 200) {
  //       commonSnackBar(message: response.message ?? AppStrings.success);
  //       FavoriteStatusModel favoriteStatusModel = FavoriteStatusModel.fromJson(response.response?.data);
  //       bool isFavorite = favoriteStatusModel.isFavorite;
  //       if(isFavorite){
  //         removeSongFromFavourite(songId: songId, isAllSongs: null);
  //       }else{
  //         addSongInFavourite(songId: songId, isAllSongs: null);
  //       }
  //       checkSongFavouriteByUserResponse = ApiResponse.complete(response);
  //     } else {
  //       commonSnackBar(message: response.message ?? AppStrings.somethingWentWrong);
  //     }
  //   } catch (e) {
  //     checkSongFavouriteByUserResponse = ApiResponse.error('error');
  //     commonSnackBar(message: AppStrings.somethingWentWrong);
  //   } finally{
  //     isLoading.value = false;
  //   }
  // }

  ///SEARCH SONGS...
  Future<void> searchSongs({required String query}) async {
    try {
      Map<String, dynamic> params = {
        ApiKeys.query : query,
        ApiKeys.page : page,
        ApiKeys.limit: limit
      };

      ResponseModel response = await SongRepo().searchSongs(params: params);

      if (response.statusCode == 200) {
        commonSnackBar(message: response.message ?? AppStrings.success);
        GetAllSongsModel getAllSongsModel = GetAllSongsModel.fromJson(response.response?.data);
        songs.value = getAllSongsModel.data;
        searchSongsResponse = ApiResponse.complete(response);
      } else {
        commonSnackBar(message: response.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      searchSongsResponse = ApiResponse.error('error');
      commonSnackBar(message: AppStrings.somethingWentWrong);
    } finally{
      // isLoading.value = false;
    }
  }

  ///SEARCH SONGS...
  Future<void> searchFavouriteSongs({required String query}) async {
    try {
      Map<String, dynamic> params = {
        ApiKeys.q : query,
        ApiKeys.page : page,
        ApiKeys.limit: limit
      };

      ResponseModel response = await SongRepo().searchFavouriteSongs(params: params);

      if (response.statusCode == 200) {
        commonSnackBar(message: response.message ?? AppStrings.success);
        FavouriteSongsResponse favouriteSongsResponse = FavouriteSongsResponse.fromJson(response.response?.data);
        favouriteSongs.value = favouriteSongsResponse.data;
        searchFavouriteSongsResponse = ApiResponse.complete(response);
      } else {
        commonSnackBar(message: response.message ?? AppStrings.somethingWentWrong);
      }
    } catch (e) {
      searchFavouriteSongsResponse = ApiResponse.error('error');
      commonSnackBar(message: AppStrings.somethingWentWrong);
    } finally{
      // isLoading.value = false;
    }
  }

}