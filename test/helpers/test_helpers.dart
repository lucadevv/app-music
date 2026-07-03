import 'package:dartz/dartz.dart';
import 'package:mocktail/mocktail.dart';
import 'package:music_app/core/domain/entities/song.dart';
import 'package:music_app/core/utils/exeptions/app_exceptions.dart';
import 'package:music_app/features/auth/data/models/oauth_request.dart';
import 'package:music_app/features/auth/data/services/oauth_service.dart';
import 'package:music_app/features/auth/domain/entities/login_request.dart';
import 'package:music_app/features/auth/domain/entities/register_request.dart';
import 'package:music_app/features/auth/domain/entities/register_response.dart';
import 'package:music_app/features/auth/domain/entities/user.dart';
import 'package:music_app/features/auth/domain/use_cases/oauth_sign_in_use_case.dart';
import 'package:music_app/features/dashboard/presentation/bloc/player_bloc_bloc.dart';
import 'package:music_app/features/downloads/domain/entities/downloaded_song.dart';
import 'package:music_app/features/home/domain/entities/chart_playlist.dart';
import 'package:music_app/features/home/domain/entities/home_content_item.dart';
import 'package:music_app/features/home/domain/entities/home_response.dart';
import 'package:music_app/features/home/domain/entities/home_section.dart';
import 'package:music_app/features/home/domain/entities/mood_genre.dart';
import 'package:music_app/features/player/domain/entities/now_playing_data.dart';
import 'package:music_app/features/player/domain/player_engine.dart';
import 'package:music_app/features/player/domain/services/audio_session_controller.dart';
import 'package:music_app/features/player/domain/strategies/network_playback_strategy.dart';
import 'package:music_app/features/player/domain/strategies/offline_playback_strategy.dart';
import 'package:music_app/features/search/domain/entities/album.dart' as album;
import 'package:music_app/features/search/domain/entities/artist.dart'
    as artist;
import 'package:music_app/features/search/domain/entities/search_request.dart';
import 'package:music_app/features/search/domain/entities/search_response.dart';
import 'package:music_app/features/search/domain/entities/thumbnail.dart'
    as thumb;

import 'mocks.dart';

// ============ OAuth Mock Classes ============

class MockGoogleSignInUseCase extends Mock implements GoogleSignInUseCase {}

class MockAppleSignInUseCase extends Mock implements AppleSignInUseCase {}

class MockOAuthService extends Mock implements OAuthService {}

class MockPlayerEngine extends Mock implements PlayerEngine {}

// ============ Register Fallback Values ============

/// Fake para mocktail — permite usar `any<Song>()` en tests
class FakeSong extends Fake implements Song {
  @override
  String get videoId => 'fake_video_id';
  @override
  String get id => videoId;
  @override
  String get title => 'Fake Song';
  @override
  String get artist => 'Fake Artist';
  @override
  List<String> get artistNames => ['Fake Artist'];
  @override
  String? get album => null;
  @override
  String? get thumbnail => null;
  @override
  String? get highThumbnail => null;
  @override
  List<Thumbnail> get thumbnails => const [];
  @override
  String? get streamUrl => null;
  @override
  int get durationSeconds => 0;
  @override
  String get duration => '0:00';
  @override
  String? get views => null;
  @override
  bool get isExplicit => false;
  @override
  bool get inLibrary => false;
  @override
  String? get localPath => null;
  @override
  int? get fileSize => null;
  @override
  DateTime? get downloadedAt => null;
  @override
  String? get bestThumbnail => null;
  @override
  bool get canPlay => false;
  @override
  bool get isDownloaded => false;
  @override
  String get durationFormatted => '0:00';
  @override
  String? get fileSizeFormatted => null;
  @override
  Duration get audioDuration => Duration.zero;
  @override
  List<Object?> get props => [];
}

void registerFallbackValues() {
  registerFallbackValue(const SearchRequest(query: 'test'));
  registerFallbackValue(
    const LoginRequest(email: 'test@test.com', password: 'test'),
  );
  registerFallbackValue(
    const RegisterRequest(
      email: 'test@test.com',
      password: 'test123',
      firstName: 'Test',
      lastName: 'User',
    ),
  );
  registerFallbackValue(
    const OAuthRequest(provider: 'google', accessToken: 'test_access_token'),
  );
  registerFallbackValue(const NetworkException('test'));
  registerFallbackValue(const ServerException('test'));
  registerFallbackValue(const AuthenticationException('test'));
  registerFallbackValue(const ValidationException('test'));
  registerFallbackValue(const UnknownException('test'));
  registerFallbackValue(Duration.zero);
  registerFallbackValue(FakeSong());
}

// ============ Test Exceptions ============

AppException createTestNetworkException([String message = 'Network error']) {
  return NetworkException(message);
}

AppException createTestServerException([String message = 'Server error']) {
  return ServerException(message);
}

AppException createTestAuthException([String message = 'Auth error']) {
  return AuthenticationException(message);
}

AppException createTestValidationException([
  String message = 'Validation error',
]) {
  return ValidationException(message);
}

AppException createTestUnknownException([String message = 'Unknown error']) {
  return UnknownException(message);
}

// ============ Test Data - Thumbnails ============

List<thumb.Thumbnail> createTestThumbnails() {
  return [
    const thumb.Thumbnail(
      url: 'https://example.com/thumb1.jpg',
      width: 120,
      height: 120,
    ),
    const thumb.Thumbnail(
      url: 'https://example.com/thumb2.jpg',
      width: 300,
      height: 300,
    ),
    const thumb.Thumbnail(
      url: 'https://example.com/thumb3.jpg',
      width: 544,
      height: 544,
    ),
  ];
}

thumb.Thumbnail createTestThumbnail() {
  return const thumb.Thumbnail(
    url: 'https://example.com/thumb.jpg',
    width: 544,
    height: 544,
  );
}

// ============ Test Data - Artists & Albums ============

List<artist.SearchArtist> createTestArtists() {
  return [
    const artist.SearchArtist(name: 'Test Artist 1', id: 'artist1'),
    const artist.SearchArtist(name: 'Test Artist 2', id: 'artist2'),
  ];
}

artist.SearchArtist createTestArtist() {
  return const artist.SearchArtist(name: 'Test Artist', id: 'artist123');
}

album.SearchAlbum createTestAlbum() {
  return const album.SearchAlbum(name: 'Test Album', id: 'album123');
}

// ============ Test Data - Songs (from search feature) ============
// NOTE: Disabled due to duplicate type conflicts between search/song/album/artist entities
// Tests requiring Song data should define their own test data or use core/domain/entities/song.dart

// ============ Test Data - Search Response ============

// SearchResponse requires Song - tests should create their own
SearchResponse createTestSearchResponse({
  String query = 'test query',
  int resultCount = 3,
}) {
  // Return empty response - tests needing songs should create their own
  return SearchResponse(results: const [], query: query);
}

// ============ Test Data - Recent Search ============

// NOTE: createTestRecentSearch disabled - uses createTestSong which has type conflicts
// createTestRecentSearches also disabled for same reason

// ============ Test Data - Home Response ============

// ============ Test Data - Home Response ============

MoodGenre createTestMoodGenre({
  String title = 'Test Mood',
  String params = 'test_params',
}) {
  return MoodGenre(title: title, params: params);
}

ChartPlaylist createTestChartPlaylist({
  String playlistId = 'chart123',
  String title = 'Chart Playlist',
}) {
  return ChartPlaylist(
    playlistId: playlistId,
    title: title,
    thumbnails: createTestThumbnails(),
  );
}

HomeContentItem createTestHomeContentItem({
  String title = 'Home Content',
  String? videoId = 'content123',
  String? playlistId,
}) {
  if (videoId != null && videoId.isNotEmpty) {
    return HomeSongItem(
      title: title,
      videoId: videoId,
      thumbnails: createTestThumbnails(),
      isExplicit: false,
      artists: createTestArtists(),
      views: '500000',
      album: createTestAlbum(),
    );
  } else if (playlistId != null && playlistId.isNotEmpty) {
    return HomePlaylistItem(
      title: title,
      playlistId: playlistId,
      thumbnails: createTestThumbnails(),
      isExplicit: false,
      artists: createTestArtists(),
      views: '500000',
    );
  } else {
    return HomeUnknownItem(
      title: title,
      thumbnails: createTestThumbnails(),
      isExplicit: false,
      artists: createTestArtists(),
      views: '500000',
    );
  }
}

HomeSection createTestHomeSection({
  String title = 'Test Section',
  int itemCount = 3,
}) {
  return HomeSection(
    title: title,
    contents: List.generate(
      itemCount,
      (i) => createTestHomeContentItem(title: 'Item $i', videoId: 'item$i'),
    ),
  );
}

Charts createTestCharts() {
  return Charts(
    topSongs: List.generate(
      3,
      (i) => createTestChartPlaylist(
        playlistId: 'top$i',
        title: 'Top Playlist $i',
      ),
    ),
    trending: List.generate(
      3,
      (i) => createTestChartPlaylist(
        playlistId: 'trend$i',
        title: 'Trending Playlist $i',
      ),
    ),
  );
}

HomeResponse createTestHomeResponse() {
  return HomeResponse(
    moods: [createTestMoodGenre(title: 'Happy', params: 'happy')],
    genres: [createTestMoodGenre(title: 'Pop', params: 'pop')],
    charts: createTestCharts(),
    sections: [createTestHomeSection(title: 'Trending Now')],
  );
}

// ============ Test Data - Downloaded Song ============

DownloadedSong createTestDownloadedSong({
  String videoId = 'downloaded123',
  String title = 'Downloaded Song',
  String artist = 'Download Artist',
  String localPath = '/path/to/song.m4a',
  int fileSize = 5000000,
}) {
  return DownloadedSong(
    videoId: videoId,
    title: title,
    artist: artist,
    album: 'Test Album',
    thumbnail: 'https://example.com/thumb.jpg',
    localPath: localPath,
    fileSize: fileSize,
    duration: const Duration(minutes: 3, seconds: 45),
    downloadedAt: DateTime(2024, 1, 1, 12, 0),
  );
}

List<DownloadedSong> createTestDownloadedSongs({int count = 3}) {
  return List.generate(
    count,
    (i) => createTestDownloadedSong(
      videoId: 'downloaded$i',
      title: 'Downloaded Song $i',
    ),
  );
}

// ============ Test Data - Auth ============

User createTestUser({
  String id = 'user123',
  String email = 'test@test.com',
  String firstName = 'Test',
  String lastName = 'User',
  bool isEmailVerified = true,
}) {
  return User(
    id: id,
    email: email,
    firstName: firstName,
    lastName: lastName,
    avatar: 'https://example.com/avatar.jpg',
    role: 'user',
    isEmailVerified: isEmailVerified,
  );
}

RegisterResponse createTestRegisterResponse({
  String accessToken = 'access_token_123',
  String refreshToken = 'refresh_token_123',
  bool isEmailVerified = true,
}) {
  return RegisterResponse(
    accessToken: accessToken,
    refreshToken: refreshToken,
    expiresIn: 3600,
    user: createTestUser(isEmailVerified: isEmailVerified),
  );
}

RegisterRequest createTestRegisterRequest({
  String email = 'test@test.com',
  String password = 'password123',
  String firstName = 'Test',
  String lastName = 'User',
}) {
  return RegisterRequest(
    email: email,
    password: password,
    firstName: firstName,
    lastName: lastName,
  );
}

LoginRequest createTestLoginRequest({
  String email = 'test@test.com',
  String password = 'password123',
}) {
  return LoginRequest(email: email, password: password);
}

// ============ Test Data - Now Playing Data ============

NowPlayingData createTestNowPlayingData({
  String videoId = 'playing123',
  String title = 'Now Playing search.Song',
  String? streamUrl = 'https://example.com/stream.m4a',
}) {
  return NowPlayingData.fromBasic(
    videoId: videoId,
    title: title,
    artistNames: const ['Artist 1', 'Artist 2'],
    albumName: 'Test Album',
    duration: '3:45',
    durationSeconds: 225,
    views: '1000000',
    thumbnailUrl: 'https://example.com/thumb.jpg',
    streamUrl: streamUrl,
  );
}

List<NowPlayingData> createTestNowPlayingList({int count = 3}) {
  return List.generate(
    count,
    (i) => createTestNowPlayingData(
      videoId: 'playing$i',
      title: 'search.Song $i',
      streamUrl: 'https://example.com/stream$i.m4a',
    ),
  );
}

// ============ Helper Functions for Either Results ============

Either<AppException, T> createLeftResult<T>(AppException exception) {
  return Left(exception);
}

Either<AppException, T> createRightResult<T>(T value) {
  return Right(value);
}

// ============ Test Data - OAuth ============

OAuthRequest createTestOAuthRequest({
  String provider = 'google',
  String accessToken = 'oauth_access_token_123',
  String? idToken = 'oauth_id_token_123',
  String? email = 'test@test.com',
  String? name = 'Test User',
}) {
  return OAuthRequest(
    provider: provider,
    accessToken: accessToken,
    idToken: idToken,
    email: email,
    name: name,
  );
}

OAuthResponse createTestOAuthResponse({
  String accessToken = 'oauth_access_token_123',
  String refreshToken = 'oauth_refresh_token_123',
  int expiresIn = 3600,
  bool isNewUser = false,
  bool isEmailVerified = true,
}) {
  return OAuthResponse(
    accessToken: accessToken,
    refreshToken: refreshToken,
    expiresIn: expiresIn,
    user: createTestUser(isEmailVerified: isEmailVerified),
    isNewUser: isNewUser,
  );
}

// ============ Test Data - OAuth Result ============

OAuthResult createTestOAuthResult({
  OAuthProvider provider = OAuthProvider.google,
  String accessToken = 'test_access_token',
  String? idToken = 'test_id_token',
  String? email = 'test@gmail.com',
  String? name = 'Test User',
  String? photoUrl = 'https://example.com/photo.jpg',
}) {
  return OAuthResult(
    accessToken: accessToken,
    idToken: idToken,
    email: email,
    name: name,
    photoUrl: photoUrl,
    provider: provider,
  );
}

// ============ PlayerBlocBloc Test Helpers ============

PlayerBlocBloc createTestPlayerBloc({
  PlayerEngine? engine,
  MockPlayerRepository? mockRepository,
  MockManageHistoryUseCase? mockManageHistoryUseCase,
}) {
  // Registrar fallback para Song — necesario para mocktail con any<Song>()
  registerFallbackValue(FakeSong());

  final repo = mockRepository ?? MockPlayerRepository();
  final historyUseCase = mockManageHistoryUseCase ?? MockManageHistoryUseCase();

  when(
    () => repo.getLocalAudioPath(any()),
  ).thenAnswer((_) async => const Right(null));
  when(
    () => repo.recordListen(any()),
  ).thenAnswer((_) async => const Right(null));
  when(
    () => historyUseCase.startNewEntry(any()),
  ).thenAnswer((_) async => const Right('test_history_id'));
  when(
    () => historyUseCase.updatePlayedDuration(any()),
  ).thenAnswer((_) async => const Right(null));
  when(
    historyUseCase.finalizeCurrent,
  ).thenAnswer((_) async => const Right(null));

  final sessionController = AudioSessionController(
    engine: engine ?? MockPlayerEngine(),
    repository: repo,
    manageHistoryUseCase: historyUseCase,
    playerHandler:
        null, // Mocks are easier with null if we don't need real handler functionality in pure bloc tests
    strategies: [OfflinePlaybackStrategy(repo), NetworkPlaybackStrategy()],
  );

  return PlayerBlocBloc(sessionController: sessionController);
}
