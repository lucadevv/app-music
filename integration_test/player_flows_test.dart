import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:music_app/features/dashboard/presentation/bloc/player_bloc_bloc.dart';
import 'package:music_app/features/player/domain/player_facade.dart';
import 'package:music_app/features/player/domain/repositories/player_repository.dart';
import 'package:music_app/features/player/domain/services/audio_session_controller.dart';
import 'package:music_app/features/player/domain/strategies/network_playback_strategy.dart';
import 'package:music_app/features/player/domain/strategies/offline_playback_strategy.dart';
import 'package:music_app/features/player/domain/usecases/manage_history_use_case.dart';
import 'package:music_app/features/player/presentation/widgets/organisms/mini_player.dart';
import 'package:music_app/features/queue/presentation/queue_screen.dart';

import '../test/fakes/fake_player_engine.dart';
import '../test/helpers/test_helpers.dart';

class MockPlayerRepository extends Mock implements PlayerRepository {}

class MockManageHistoryUseCase extends Mock implements ManageHistoryUseCase {}

class _HarnessApp extends StatelessWidget {
  final PlayerFacade player;
  const _HarnessApp({required this.player});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Column(
          children: [
            const SizedBox(height: 24),
            ElevatedButton(
              key: const Key('play_a'),
              onPressed: () {
                player.playSingle(
                  createTestNowPlayingData(videoId: 'A', title: 'Track A'),
                  sourceId: 'single:A',
                );
              },
              child: const Text('Play A'),
            ),
            ElevatedButton(
              key: const Key('play_b'),
              onPressed: () {
                player.playSingle(
                  createTestNowPlayingData(videoId: 'B', title: 'Track B'),
                  sourceId: 'single:B',
                );
              },
              child: const Text('Play B'),
            ),
            ElevatedButton(
              key: const Key('open_queue'),
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => const QueueScreen()),
                );
              },
              child: const Text('Open Queue'),
            ),
            const Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: MiniPlayer(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('last tap wins across UI harness (fake engine)', (tester) async {
    final mockEngine = FakePlayerEngine();
    final mockRepository = MockPlayerRepository();
    final mockHistoryUseCase = MockManageHistoryUseCase();

    when(
      () => mockRepository.getLocalAudioPath(any()),
    ).thenAnswer((_) async => const Right(null));
    when(
      () => mockRepository.recordListen(any()),
    ).thenAnswer((_) async => const Right(null));
    when(
      () => mockHistoryUseCase.startNewEntry(any()),
    ).thenAnswer((_) async => const Right('test_id'));
    when(
      () => mockHistoryUseCase.updatePlayedDuration(any()),
    ).thenAnswer((_) async => const Right(null));
    when(
      mockHistoryUseCase.finalizeCurrent,
    ).thenAnswer((_) async => const Right(null));

    final sessionController = AudioSessionController(
      engine: mockEngine,
      repository: mockRepository,
      manageHistoryUseCase: mockHistoryUseCase,
      playerHandler: null,
      strategies: [
        OfflinePlaybackStrategy(mockRepository),
        NetworkPlaybackStrategy(),
      ],
    );

    final bloc = PlayerBlocBloc(sessionController: sessionController);
    final facade = PlayerFacade(bloc);
    addTearDown(() async {
      await bloc.close();
      await mockEngine.dispose();
    });

    await tester.pumpWidget(
      BlocProvider<PlayerBlocBloc>.value(
        value: bloc,
        child: _HarnessApp(player: facade),
      ),
    );

    await tester.tap(find.byKey(const Key('play_a')));
    await tester.tap(find.byKey(const Key('play_b')));
    await tester.pump(const Duration(milliseconds: 120));

    expect(bloc.state.currentTrack?.videoId, equals('B'));
    expect(find.text('Track B'), findsOneWidget);
  });
}
