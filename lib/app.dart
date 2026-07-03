import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music_app/core/app_router/app_routes.dart';
import 'package:music_app/core/bloc/locale_cubit.dart';
import 'package:music_app/core/data/offline/services/offline_service.dart';
import 'package:music_app/core/managers/auth/auth_manager.dart';
import 'package:music_app/core/services/audio_handler_service.dart';
import 'package:music_app/core/services/logger/app_logger.dart';
import 'package:music_app/core/theme/app_theme.dart';
import 'package:music_app/core/theme/theme_cubit.dart';
import 'package:music_app/features/dashboard/presentation/bloc/player_bloc_bloc.dart';
import 'package:music_app/features/downloads/domain/use_cases/check_download_status_use_case.dart';
import 'package:music_app/features/downloads/domain/use_cases/download_song_use_case.dart';
import 'package:music_app/features/downloads/domain/use_cases/get_downloaded_songs_use_case.dart';
import 'package:music_app/features/downloads/domain/use_cases/remove_download_use_case.dart';
import 'package:music_app/features/downloads/presentation/cubit/downloads_cubit.dart';
import 'package:music_app/features/favorites/presentation/cubit/favorite_cubit.dart';
import 'package:music_app/features/library/domain/use_cases/load_favorites_use_case.dart';
import 'package:music_app/features/library/domain/use_cases/toggle_favorite_use_case.dart';
import 'package:music_app/features/offline/domain/use_cases/delete_offline_playlist_use_case.dart';
import 'package:music_app/features/offline/domain/use_cases/get_offline_playlists_use_case.dart';
import 'package:music_app/features/offline/domain/use_cases/save_offline_playlist_use_case.dart';
import 'package:music_app/features/offline/presentation/cubit/playlist_offline_cubit.dart';
import 'package:music_app/features/player/domain/player_facade.dart';
import 'package:music_app/features/player/domain/repositories/player_repository.dart';
import 'package:music_app/features/player/domain/services/audio_session_controller.dart';
import 'package:music_app/features/player/domain/strategies/network_playback_strategy.dart';
import 'package:music_app/features/player/domain/strategies/offline_playback_strategy.dart';
import 'package:music_app/features/player/domain/usecases/manage_history_use_case.dart';
import 'package:music_app/features/player/infrastructure/just_audio_player_engine.dart';
import 'package:music_app/features/profile/domain/use_cases/get_profile_use_case.dart';
import 'package:music_app/features/profile/domain/use_cases/get_settings_use_case.dart';
import 'package:music_app/features/profile/domain/use_cases/logout_use_case.dart';
import 'package:music_app/features/profile/domain/use_cases/update_profile_use_case.dart';
import 'package:music_app/features/profile/domain/use_cases/update_settings_use_case.dart';
import 'package:music_app/features/profile/presentation/cubit/profile_cubit.dart';
import 'package:music_app/l10n/app_localizations.dart';
import 'package:music_app/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  final _router = getIt<AppRouter>();
  ThemeCubit? _themeCubit;
  LocaleCubit? _localeCubit;
  DownloadsCubit? _downloadsCubit;
  ProfileCubit? _profileCubit;
  PlayerBlocBloc? _playerBlocBloc;
  FavoriteCubit? _favoriteCubit;
  PlaylistOfflineCubit? _playlistOfflineCubit;

  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  @override
  void dispose() {
    _themeCubit?.close();
    _localeCubit?.close();
    _downloadsCubit?.close();
    _profileCubit?.close();
    _playerBlocBloc?.close();
    _favoriteCubit?.close();
    _playlistOfflineCubit?.close();
    super.dispose();
  }

  Future<void> _initApp() async {
    try {
      // Obtener dependencias async de GetIt (servicios, NO blocs)
      final prefs = await getIt.getAsync<SharedPreferences>();
      final authManager = await getIt.getAsync<AuthManager>();
      final offlineService = await getIt.getAsync<OfflineService>();

      // Crear los Blocs/Cubits directamente (NO desde GetIt)
      _themeCubit = ThemeCubit(prefs);
      _localeCubit = LocaleCubit(prefs);

      // Obtener AudioPlayerHandler y construir Motor
      final audioPlayerHandler = getIt<AudioPlayerHandler>();
      final engine = JustAudioPlayerEngine(audioPlayerHandler.player);

      final sessionController = AudioSessionController(
        engine: engine,
        repository: await getIt.getAsync<PlayerRepository>(),
        manageHistoryUseCase: getIt<ManageHistoryUseCase>(),
        playerHandler: audioPlayerHandler,
        strategies: [
          OfflinePlaybackStrategy(await getIt.getAsync<PlayerRepository>()),
          NetworkPlaybackStrategy(),
        ],
      );

      _playerBlocBloc = PlayerBlocBloc(sessionController: sessionController);

      // Conectar PlayerBlocBloc con AudioPlayerHandler para delegación de eventos
      audioPlayerHandler.playerBloc = _playerBlocBloc!;

      // Registrar PlayerFacade con el PlayerBlocBloc creado (para DownloadsCubit)
      if (!getIt.isRegistered<PlayerFacade>()) {
        getIt.registerLazySingleton<PlayerFacade>(
          () => PlayerFacade(_playerBlocBloc!),
        );
      }

      // Crear PlaylistOfflineCubit (depende de OfflineService y UseCases)
      _playlistOfflineCubit = PlaylistOfflineCubit(
        getOfflinePlaylistsUseCase: GetOfflinePlaylistsUseCase(offlineService),
        saveOfflinePlaylistUseCase: SaveOfflinePlaylistUseCase(offlineService),
        deleteOfflinePlaylistUseCase: DeleteOfflinePlaylistUseCase(
          offlineService,
        ),
        offlineService: offlineService,
      );

      // Crear FavoriteCubit (depende de UseCases, PlaylistOfflineCubit, OfflineService, PlayerBlocBloc)
      _favoriteCubit = FavoriteCubit(
        loadFavoritesUseCase: getIt<LoadFavoritesUseCase>(),
        toggleFavoriteUseCase: getIt<ToggleFavoriteUseCase>(),
        playlistOfflineCubit: _playlistOfflineCubit!,
        offlineService: offlineService,
        playerBloc: _playerBlocBloc!,
      );

      // Crear DownloadsCubit (depende de use cases async + PlayerFacade)
      _downloadsCubit = DownloadsCubit(
        await getIt.getAsync<DownloadSongUseCase>(),
        await getIt.getAsync<GetDownloadedSongsUseCase>(),
        await getIt.getAsync<RemoveDownloadUseCase>(),
        await getIt.getAsync<CheckDownloadStatusUseCase>(),
        getIt<PlayerFacade>(),
      );

      // Crear ProfileCubit (depende de use cases + AuthManager + OfflineService + FavoriteCubit)
      _profileCubit = ProfileCubit(
        getProfileUseCase: getIt<GetProfileUseCase>(),
        updateProfileUseCase: getIt<UpdateProfileUseCase>(),
        getSettingsUseCase: getIt<GetSettingsUseCase>(),
        updateSettingsUseCase: getIt<UpdateSettingsUseCase>(),
        logoutUseCase: getIt<LogoutUseCase>(),
        authManager: authManager,
        offlineService: offlineService,
        favoriteCubit: _favoriteCubit!,
      );

      // Conectar ProfileCubit con PlayerBlocBloc para autoPlay settings
      _playerBlocBloc!.profileCubit = _profileCubit!;

      // Cargar profile y settings si el usuario está logueado
      final isLoggedIn = await authManager.isUserLoggedIn();
      if (isLoggedIn) {
        await _profileCubit!.loadProfile();
        await _profileCubit!.loadSettings();
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error initializing app', e, stackTrace);
      rethrow;
    } finally {
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized ||
        _themeCubit == null ||
        _localeCubit == null ||
        _downloadsCubit == null ||
        _profileCubit == null ||
        _playerBlocBloc == null ||
        _favoriteCubit == null ||
        _playlistOfflineCubit == null) {
      return MaterialApp(
        title: 'Vibeat',
        theme:
            AppTheme.dark(), // Usar tema oscuro durante carga para consistencia
        home: const Scaffold(body: Center(child: CircularProgressIndicator())),
        debugShowCheckedModeBanner: false,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      );
    }

    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _themeCubit!),
        BlocProvider.value(value: _localeCubit!),
        BlocProvider.value(value: _downloadsCubit!),
        BlocProvider.value(value: _profileCubit!),
        BlocProvider.value(value: _playerBlocBloc!),
        BlocProvider.value(value: _favoriteCubit!),
        BlocProvider.value(value: _playlistOfflineCubit!),
      ],
      child: BlocBuilder<ThemeCubit, ThemeState>(
        builder: (context, themeState) {
          return BlocBuilder<LocaleCubit, LocaleState>(
            builder: (context, localeState) {
              return MaterialApp.router(
                title: 'Vibeat',
                theme: AppTheme.light(),
                darkTheme: AppTheme.dark(),
                themeMode: themeState.themeMode,
                routerConfig: _router.config(
                  navigatorObservers: () => [AutoRouteObserver()],
                ),
                debugShowCheckedModeBanner: false,
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                locale: localeState.isLoading ? null : localeState.locale,
              );
            },
          );
        },
      ),
    );
  }
}
