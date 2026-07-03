import 'package:get_it/get_it.dart';
import 'package:music_app/core/services/network/api_services.dart';
import 'package:music_app/features/library/data/datasources/library_remote_data_source.dart';
import 'package:music_app/features/library/data/repositories/library_repository_impl.dart';
import 'package:music_app/features/library/domain/repositories/library_repository.dart';
import 'package:music_app/features/library/domain/use_cases/add_favorite_genre_use_case.dart';
import 'package:music_app/features/library/domain/use_cases/add_favorite_playlist_use_case.dart';
import 'package:music_app/features/library/domain/use_cases/add_favorite_song_use_case.dart';
import 'package:music_app/features/library/domain/use_cases/add_song_to_user_playlist_use_case.dart';
import 'package:music_app/features/library/domain/use_cases/create_user_playlist_use_case.dart';
import 'package:music_app/features/library/domain/use_cases/delete_user_playlist_use_case.dart';
import 'package:music_app/features/library/domain/use_cases/get_aggregated_library_use_case.dart';
import 'package:music_app/features/library/domain/use_cases/get_favorite_genres_use_case.dart';
import 'package:music_app/features/library/domain/use_cases/get_favorite_genres_with_mapping_use_case.dart';
import 'package:music_app/features/library/domain/use_cases/get_favorite_playlists_use_case.dart';
import 'package:music_app/features/library/domain/use_cases/get_favorite_playlists_with_mapping_use_case.dart';
import 'package:music_app/features/library/domain/use_cases/get_favorite_songs_use_case.dart';
import 'package:music_app/features/library/domain/use_cases/get_favorite_songs_with_mapping_use_case.dart';
import 'package:music_app/features/library/domain/use_cases/get_library_summary_use_case.dart';
import 'package:music_app/features/library/domain/use_cases/get_user_playlist_use_case.dart';
import 'package:music_app/features/library/domain/use_cases/get_user_playlists_use_case.dart'
    as lib_usecase;
import 'package:music_app/features/library/domain/use_cases/load_favorites_use_case.dart';
import 'package:music_app/features/library/domain/use_cases/remove_favorite_genre_use_case.dart';
import 'package:music_app/features/library/domain/use_cases/remove_favorite_playlist_use_case.dart';
import 'package:music_app/features/library/domain/use_cases/remove_favorite_song_use_case.dart';
import 'package:music_app/features/library/domain/use_cases/remove_song_from_user_playlist_use_case.dart';
import 'package:music_app/features/library/domain/use_cases/toggle_favorite_use_case.dart';
import 'package:music_app/features/library/domain/use_cases/update_user_playlist_use_case.dart';

void registerLibraryFeature(GetIt getIt) {
  // Data Source
  if (!getIt.isRegistered<LibraryRemoteDataSource>()) {
    getIt.registerLazySingleton<LibraryRemoteDataSource>(
      () => LibraryRemoteDataSource(getIt<ApiServices>()),
    );
  }

  // Repository
  if (!getIt.isRegistered<LibraryRepository>()) {
    getIt.registerLazySingleton<LibraryRepository>(
      () => LibraryRepositoryImpl(getIt<LibraryRemoteDataSource>()),
    );
  }

  // Use Cases
  if (!getIt.isRegistered<GetLibrarySummaryUseCase>()) {
    getIt.registerLazySingleton<GetLibrarySummaryUseCase>(
      () => GetLibrarySummaryUseCase(getIt<LibraryRepository>()),
    );
  }

  if (!getIt.isRegistered<GetFavoriteSongsUseCase>()) {
    getIt.registerLazySingleton<GetFavoriteSongsUseCase>(
      () => GetFavoriteSongsUseCase(getIt<LibraryRepository>()),
    );
  }

  if (!getIt.isRegistered<GetFavoritePlaylistsUseCase>()) {
    getIt.registerLazySingleton<GetFavoritePlaylistsUseCase>(
      () => GetFavoritePlaylistsUseCase(getIt<LibraryRepository>()),
    );
  }

  if (!getIt.isRegistered<GetFavoriteGenresUseCase>()) {
    getIt.registerLazySingleton<GetFavoriteGenresUseCase>(
      () => GetFavoriteGenresUseCase(getIt<LibraryRepository>()),
    );
  }

  if (!getIt.isRegistered<lib_usecase.GetUserPlaylistsUseCase>()) {
    getIt.registerLazySingleton<lib_usecase.GetUserPlaylistsUseCase>(
      () => lib_usecase.GetUserPlaylistsUseCase(getIt<LibraryRepository>()),
    );
  }

  if (!getIt.isRegistered<AddFavoriteSongUseCase>()) {
    getIt.registerLazySingleton<AddFavoriteSongUseCase>(
      () => AddFavoriteSongUseCase(getIt<LibraryRepository>()),
    );
  }

  if (!getIt.isRegistered<RemoveFavoriteSongUseCase>()) {
    getIt.registerLazySingleton<RemoveFavoriteSongUseCase>(
      () => RemoveFavoriteSongUseCase(getIt<LibraryRepository>()),
    );
  }

  if (!getIt.isRegistered<CreateUserPlaylistUseCase>()) {
    getIt.registerLazySingleton<CreateUserPlaylistUseCase>(
      () => CreateUserPlaylistUseCase(getIt<LibraryRepository>()),
    );
  }

  if (!getIt.isRegistered<GetUserPlaylistUseCase>()) {
    getIt.registerLazySingleton<GetUserPlaylistUseCase>(
      () => GetUserPlaylistUseCase(getIt<LibraryRepository>()),
    );
  }

  if (!getIt.isRegistered<UpdateUserPlaylistUseCase>()) {
    getIt.registerLazySingleton<UpdateUserPlaylistUseCase>(
      () => UpdateUserPlaylistUseCase(getIt<LibraryRepository>()),
    );
  }

  if (!getIt.isRegistered<DeleteUserPlaylistUseCase>()) {
    getIt.registerLazySingleton<DeleteUserPlaylistUseCase>(
      () => DeleteUserPlaylistUseCase(getIt<LibraryRepository>()),
    );
  }

  if (!getIt.isRegistered<AddSongToUserPlaylistUseCase>()) {
    getIt.registerLazySingleton<AddSongToUserPlaylistUseCase>(
      () => AddSongToUserPlaylistUseCase(getIt<LibraryRepository>()),
    );
  }

  if (!getIt.isRegistered<RemoveSongFromUserPlaylistUseCase>()) {
    getIt.registerLazySingleton<RemoveSongFromUserPlaylistUseCase>(
      () => RemoveSongFromUserPlaylistUseCase(getIt<LibraryRepository>()),
    );
  }

  // Aggregated Use Case (for LibraryCubit SRP)
  if (!getIt.isRegistered<GetAggregatedLibraryUseCase>()) {
    getIt.registerLazySingleton<GetAggregatedLibraryUseCase>(
      () => GetAggregatedLibraryUseCase(
        offlineService: getIt(),
        getLibrarySummaryUseCase: getIt(),
        getFavoriteSongsUseCase: getIt(),
        getFavoritePlaylistsUseCase: getIt(),
        getFavoriteGenresUseCase: getIt(),
        getUserPlaylistsUseCase: getIt(),
      ),
    );
  }

  // Use Cases with Mapping (for FavoriteCubit)
  if (!getIt.isRegistered<GetFavoriteSongsWithMappingUseCase>()) {
    getIt.registerLazySingleton<GetFavoriteSongsWithMappingUseCase>(
      () => GetFavoriteSongsWithMappingUseCase(getIt<LibraryRepository>()),
    );
  }

  if (!getIt.isRegistered<GetFavoriteGenresWithMappingUseCase>()) {
    getIt.registerLazySingleton<GetFavoriteGenresWithMappingUseCase>(
      () => GetFavoriteGenresWithMappingUseCase(getIt<LibraryRepository>()),
    );
  }

  if (!getIt.isRegistered<GetFavoritePlaylistsWithMappingUseCase>()) {
    getIt.registerLazySingleton<GetFavoritePlaylistsWithMappingUseCase>(
      () => GetFavoritePlaylistsWithMappingUseCase(getIt<LibraryRepository>()),
    );
  }

  // Load Favorites Facade
  if (!getIt.isRegistered<LoadFavoritesUseCase>()) {
    getIt.registerLazySingleton<LoadFavoritesUseCase>(
      () => LoadFavoritesUseCase(
        getFavoriteSongsWithMappingUseCase: getIt(),
        getFavoritePlaylistsWithMappingUseCase: getIt(),
        getFavoriteGenresWithMappingUseCase: getIt(),
      ),
    );
  }

  // Additional favorite UseCases (for FavoriteCubit)
  if (!getIt.isRegistered<AddFavoriteGenreUseCase>()) {
    getIt.registerLazySingleton<AddFavoriteGenreUseCase>(
      () => AddFavoriteGenreUseCase(getIt<LibraryRepository>()),
    );
  }

  if (!getIt.isRegistered<RemoveFavoriteGenreUseCase>()) {
    getIt.registerLazySingleton<RemoveFavoriteGenreUseCase>(
      () => RemoveFavoriteGenreUseCase(getIt<LibraryRepository>()),
    );
  }

  if (!getIt.isRegistered<AddFavoritePlaylistUseCase>()) {
    getIt.registerLazySingleton<AddFavoritePlaylistUseCase>(
      () => AddFavoritePlaylistUseCase(getIt<LibraryRepository>()),
    );
  }

  if (!getIt.isRegistered<RemoveFavoritePlaylistUseCase>()) {
    getIt.registerLazySingleton<RemoveFavoritePlaylistUseCase>(
      () => RemoveFavoritePlaylistUseCase(getIt<LibraryRepository>()),
    );
  }

  // Toggle Favorite Facade
  if (!getIt.isRegistered<ToggleFavoriteUseCase>()) {
    getIt.registerLazySingleton<ToggleFavoriteUseCase>(
      () => ToggleFavoriteUseCase(
        addFavoriteSongUseCase: getIt(),
        removeFavoriteSongUseCase: getIt(),
        addFavoritePlaylistUseCase: getIt(),
        removeFavoritePlaylistUseCase: getIt(),
        addFavoriteGenreUseCase: getIt(),
        removeFavoriteGenreUseCase: getIt(),
      ),
    );
  }

  // NOTA: LibraryCubit se crea ahora vía BlocProvider en LibraryScreen
  // Se elimina el registro de GetIt para mantener consistencia
}
