import 'dart:async';
import 'dart:developer';

import 'package:BlueEra/core/api/apiService/api_keys.dart';
import 'package:BlueEra/core/constants/app_colors.dart';
import 'package:BlueEra/core/constants/app_icon_assets.dart';
import 'package:BlueEra/core/constants/size_config.dart';
import 'package:BlueEra/core/routes/route_helper.dart';
import 'package:BlueEra/features/common/reel/controller/song_controller.dart';
import 'package:BlueEra/features/common/reel/models/get_all_favourite_songs_model.dart';
import 'package:BlueEra/features/common/reel/models/get_all_songs_model.dart';
import 'package:BlueEra/widgets/common_back_app_bar.dart';
import 'package:BlueEra/widgets/common_search_bar.dart';
import 'package:BlueEra/widgets/custom_text_cm.dart';
import 'package:BlueEra/widgets/half_width_tab_indicator.dart';
import 'package:BlueEra/widgets/local_assets.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class GetAllSongsScreen extends StatefulWidget {
  final String videoPath;

  const GetAllSongsScreen({super.key, required this.videoPath});

  @override
  State<GetAllSongsScreen> createState() => _GetAllSongsScreenState();
}

class _GetAllSongsScreenState extends State<GetAllSongsScreen> with SingleTickerProviderStateMixin {
  final TextEditingController searchController = TextEditingController();
  Timer? _debounce;
  late TabController _tabController;
  // late PlayerController _waveformController;
  // late AudioPlayer _audioPlayer;
  SongController songController = Get.put(SongController());

  @override
  void initState() {
    super.initState();
    searchController.addListener(() {
      _onSearchChanged(searchController.text);
    }); // To show/hide clear icon
    _tabController = TabController(length: 2, vsync: this);

    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return; // wait for animation
      print('Selected Tab Index: ${_tabController.index}');

      // You can also trigger Bloc events or setState here
      if (_tabController.index == 0) {
        /// get All song api calling
        songController.getAllSongs();
        // Discover
      } else {
        /// favourite song api calling
        songController.getAllFavouriteSongs();
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    log("disposed");
    searchController.dispose();
    // _waveformController.dispose();
    // _audioPlayer.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce?.cancel();

    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (query.trim().isNotEmpty) {
        /// do search functionality or call search api
        if(_tabController.index == 0){
          songController.searchSongs(query: query);
        }else{
          songController.searchFavouriteSongs(query: query);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: CommonBackAppBar(
          title: 'Add Music',
        ),
        body: Column(
          children: [

            SizedBox(
              width: SizeConfig.screenWidth,
              child: Padding(
                padding: EdgeInsets.all(SizeConfig.size15),
                child: CommonSearchBar(
                  controller: searchController,
                  onSearchTap: () {
                    // handle search
                  },
                  onClearCallback: () {
                    searchController.clear();
                    if (_tabController.index == 0) {
                      /// get All song api calling
                      songController.favouriteSongs.clear();
                      songController.getAllSongs();
                      // Discover
                    } else {
                      /// favourite song api calling
                      songController.songs.clear();
                      songController.getAllFavouriteSongs();
                    }

                  },
                  backgroundColor: AppColors.greyD3,
                  hintText: "Search music..",
                  borderRadius: 100.0,
                ),
              ),
            ),

            // TabBar
            TabBar(
              controller: _tabController,
              unselectedLabelColor: AppColors.black,
              indicatorColor: Colors.transparent,
              // 🎯 Customize selected tab text
              labelStyle: TextStyle(
                  fontSize: SizeConfig.medium,
                  color: AppColors.primaryColor
              ),

              // 🎯 Customize unselected tab text
              unselectedLabelStyle: TextStyle(
                fontSize: SizeConfig.medium,
              ),
              indicator: const HalfScreenTabIndicator(
                color: AppColors.primaryColor, // Blue for selected
                thickness: 1.5,
              ),
              tabs: const [
                Tab(text: 'Discover'),
                Tab(text: 'Favorites'),
              ],
            ),

            Expanded(
              child: Obx(() {
                if(_tabController.index == 0)
                  return _buildSongList(songs: songController.songs);
                else
                  return _buildFavouriteSongList(favouriteSongs: songController.favouriteSongs);
              }),
            ),


          ],
        ),
      ),
    );
  }

  Widget _buildSongList({required List<Song> songs}) {
    if(songController.isSongLoading.isTrue){
      return Center(
        child: CircularProgressIndicator(),
      );
    }

    if (songs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            LocalAssets(imagePath: AppIconAssets.emptyIcon),
            SizedBox(height: SizeConfig.size20),
            CustomText(
              "No Result Found",
              fontSize: SizeConfig.extraLarge,
              color: AppColors.grey9A,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: songs.length,
      shrinkWrap: true,
      padding: EdgeInsets.symmetric(vertical: SizeConfig.size10),
      itemBuilder: (context, index) {
        final song = songs[index];

        return ListTile(
          onTap: () => Navigator.pushNamed(
            context,
            RouteHelper.getAddSongScreenRoute(),
            arguments: {
              ApiKeys.videoPath: widget.videoPath,
              ApiKeys.audioUrl: song.externalUrl,
              ApiKeys.song: {
                ApiKeys.id: song.id,
                ApiKeys.name: song.name,
                ApiKeys.artist: song.artist,
                ApiKeys.coverUrl: song.coverUrl
              }, // optional
            },
          ),
          minVerticalPadding: 12.0,
          leading: InkWell(
            child: Stack(
              alignment: Alignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: CachedNetworkImage(
                    imageUrl: song.coverUrl,
                    fit: BoxFit.cover,
                    height: SizeConfig.size50,
                    width: SizeConfig.size50,
                    errorWidget: (context, url, error) =>
                    const Icon(Icons.image),
                  ),
                ),
              ],
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: CustomText(
                  song.externalUrl,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  fontSize: SizeConfig.extraLarge,
                ),
              )
            ],
          ),
          subtitle: CustomText(
            song.artist,
            fontSize: SizeConfig.small,
          ),
          trailing: IconButton(
            icon: Icon(
              song.isFavourite
                  ? Icons.favorite
                  : Icons.favorite_border,
              color:  song.isFavourite
                  ? AppColors.primaryColor
                  : AppColors.black,
            ),
            onPressed: () {
              if (song.isFavourite) {
                songController.removeSongFromFavourite(
                  songId: song.id,
                );
              }
              else{
                songController.addSongInFavourite(
                  songId: song.id,
                );
              }
            },
          ),
        );
      },
    );
  }

  Widget _buildFavouriteSongList({required List<FavouriteSong> favouriteSongs}) {
    if(songController.isFavouriteLoading.isTrue){
      return Center(
        child: CircularProgressIndicator(),
      );
    }

    if (favouriteSongs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            LocalAssets(imagePath: AppIconAssets.emptyIcon),
            SizedBox(height: SizeConfig.size20),
            CustomText(
              "No Result Found",
              fontSize: SizeConfig.extraLarge,
              color: AppColors.grey9A,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: favouriteSongs.length,
      shrinkWrap: true,
      padding: EdgeInsets.symmetric(vertical: SizeConfig.size10),
      itemBuilder: (context, index) {
        final favouriteSong = favouriteSongs[index];

        return ListTile(
          onTap: () => Navigator.pushNamed(
            context,
            RouteHelper.getAddSongScreenRoute(),
            arguments: {
              ApiKeys.videoPath: widget.videoPath,
              ApiKeys.audioUrl: favouriteSong.song.externalUrl,
              ApiKeys.song: {
                "id": favouriteSong.id,
                "name": favouriteSong.song.name,
                "artist": favouriteSong.song.artist,
                "coverUrl": favouriteSong.song.coverUrl
              }, // optional
            },
          ),
          minVerticalPadding: 12.0,
          leading: InkWell(
            child: Stack(
              alignment: Alignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: CachedNetworkImage(
                    imageUrl: favouriteSong.song.coverUrl,
                    fit: BoxFit.cover,
                    height: SizeConfig.size50,
                    width: SizeConfig.size50,
                    errorWidget: (context, url, error) =>
                    const Icon(Icons.image),
                  ),
                ),
              ],
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: CustomText(
                  favouriteSong.song.externalUrl,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  fontSize: SizeConfig.extraLarge,
                ),
              )
            ],
          ),
          subtitle: CustomText(
            favouriteSong.song.artist,
            fontSize: SizeConfig.small,
          ),
          trailing: IconButton(
            icon: Icon(
              Icons.favorite,
              color: AppColors.primaryColor,
            ),
            onPressed: () {
              songController.removeSongFromFavourite(
                songId: favouriteSong.song.id,
              );
            },
          ),
        );
      },
    );
  }


}
