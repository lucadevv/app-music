import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_app/features/dashboard/presentation/bloc/player_bloc_bloc.dart';
import 'package:music_app/features/player/domain/entities/now_playing_data.dart';
import 'package:music_app/features/player/presentation/player_screen.dart';
import 'package:music_app/features/player/presentation/widgets/organisms/mini_player.dart';
import 'package:music_app/features/queue/presentation/queue_screen.dart';
import 'package:music_app/l10n/app_localizations.dart';

import '../fakes/fake_player_engine.dart';
import '../helpers/test_helpers.dart';

Widget _wrapWithApp(Widget child, PlayerBlocBloc bloc) {
  return MaterialApp(
    locale: const Locale('es'),
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    home: BlocProvider<PlayerBlocBloc>.value(
      value: bloc,
      child: Scaffold(body: Center(child: child)),
    ),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(registerFallbackValues);

  group('Player widgets (deterministic, fake engine)', () {
    testWidgets('MiniPlayer is hidden when there is no currentTrack', (
      tester,
    ) async {
      final engine = FakePlayerEngine();
      final bloc = createTestPlayerBloc(engine: engine);
      addTearDown(() async {
        await bloc.close();
        await engine.dispose();
      });

      await tester.pumpWidget(
        _wrapWithApp(const MiniPlayer(showFavoriteButton: false), bloc),
      );
      expect(find.byType(MiniPlayer), findsOneWidget);
      expect(find.textContaining('search.Song'), findsNothing);
    });

    testWidgets('MiniPlayer shows track title after LoadTrackEvent', (
      tester,
    ) async {
      final engine = FakePlayerEngine();
      final bloc = createTestPlayerBloc(engine: engine);
      addTearDown(() async {
        await bloc.close();
        await engine.dispose();
      });

      await tester.pumpWidget(
        _wrapWithApp(const MiniPlayer(showFavoriteButton: false), bloc),
      );

      final track = NowPlayingData.fromBasic(
        videoId: 'v_widget',
        title: 'Song W',
        artistNames: const ['Artist'],
        albumName: 'Album',
        duration: '3:00',
        durationSeconds: 180,
        streamUrl: 'https://example.com/stream.m4a',
      );
      bloc.add(LoadTrackEvent(track, sourceId: 'single:${track.videoId}'));

      await tester.pump(const Duration(milliseconds: 30));
      expect(find.text('Song W'), findsOneWidget);
    });

    testWidgets('QueueScreen builds with localization (smoke)', (tester) async {
      final engine = FakePlayerEngine();
      final bloc = createTestPlayerBloc(engine: engine);
      addTearDown(() async {
        await bloc.close();
        await engine.dispose();
      });

      await tester.pumpWidget(_wrapWithApp(const QueueScreen(), bloc));
      await tester.pump();
      expect(find.text('Cola'), findsOneWidget);
    });

    testWidgets('PlayerScreen (playAsSingle) drives bloc to currentTrack', (
      tester,
    ) async {
      final engine = FakePlayerEngine();
      final bloc = createTestPlayerBloc(engine: engine);
      addTearDown(() async {
        await bloc.close();
        await engine.dispose();
      });

      final track = createTestNowPlayingData(
        videoId: 'ps1',
        title: 'Player Song',
      );

      await tester.pumpWidget(
        _wrapWithApp(
          PlayerScreen(
            nowPlayingData: track,
            playAsSingle: true,
            showFavoriteButton: false,
            showExtras: false,
          ),
          bloc,
        ),
      );

      await tester.pump(const Duration(milliseconds: 30));
      expect(find.text('Player Song'), findsWidgets);
    });
  });
}
