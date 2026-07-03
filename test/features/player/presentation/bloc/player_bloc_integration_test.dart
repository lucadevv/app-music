import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_app/features/dashboard/presentation/bloc/player_bloc_bloc.dart';
import 'package:music_app/features/player/domain/types/player_types.dart';

import '../../../../fakes/fake_player_engine.dart';
import '../../../../helpers/test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final track1 = createTestNowPlayingData(videoId: 'video1', title: 'Song 1');
  final track2 = createTestNowPlayingData(videoId: 'video2', title: 'Song 2');
  final track3 = createTestNowPlayingData(videoId: 'video3', title: 'Song 3');
  final playlist = [track1, track2, track3];

  group('PlayerBloc - Casos de Uso Principales', () {
    blocTest<PlayerBlocBloc, PlayerBlocState>(
      'Estado inicial es correcto',
      build: () => createTestPlayerBloc(engine: FakePlayerEngine()),
      verify: (bloc) {
        expect(bloc.state.playbackState, PlaybackState.stopped);
        expect(bloc.state.processingState, ProcessingStateType.idle);
        expect(bloc.state.playlist, isEmpty);
        expect(bloc.state.currentTrack, isNull);
        expect(bloc.state.currentIndex, isNull);
      },
    );

    blocTest<PlayerBlocBloc, PlayerBlocState>(
      'PlayRequestEvent(single) debe cargar track como single',
      build: () => createTestPlayerBloc(engine: FakePlayerEngine()),
      act: (bloc) => bloc.add(PlayRequestEvent(track1, playAsSingle: true)),
      wait: const Duration(milliseconds: 20),
      verify: (bloc) {
        expect(bloc.state.currentTrack?.videoId, 'video1');
        expect(bloc.state.playlist.length, 1);
      },
    );

    blocTest<PlayerBlocBloc, PlayerBlocState>(
      'LoadPlaylistEvent vacío debe setear error',
      build: () => createTestPlayerBloc(engine: FakePlayerEngine()),
      act: (bloc) => bloc.add(
        const LoadPlaylistEvent(playlist: [], startIndex: 0, sourceId: 'test'),
      ),
      wait: const Duration(milliseconds: 20),
      verify: (bloc) => expect(bloc.state.error, 'Playlist vacía'),
    );

    blocTest<PlayerBlocBloc, PlayerBlocState>(
      'LoadPlaylistEvent debe setear playlist y track actual',
      build: () => createTestPlayerBloc(engine: FakePlayerEngine()),
      act: (bloc) => bloc.add(
        LoadPlaylistEvent(playlist: playlist, startIndex: 2, sourceId: 'test'),
      ),
      wait: const Duration(milliseconds: 20),
      verify: (bloc) {
        expect(bloc.state.playlist.length, 3);
        expect(bloc.state.currentIndex, 2);
        expect(bloc.state.currentTrack?.videoId, 'video3');
      },
    );

    blocTest<PlayerBlocBloc, PlayerBlocState>(
      'PlayTrackAtIndexEvent debe actualizar índice/track (solo estado)',
      build: () => createTestPlayerBloc(engine: FakePlayerEngine()),
      seed: () => PlayerBlocState(
        playlist: playlist,
        currentTrack: track1,
        currentIndex: 0,
        playbackState: PlaybackState.playing,
        processingState: ProcessingStateType.ready,
      ),
      act: (bloc) => bloc.add(const PlayTrackAtIndexEvent(2)),
      wait: const Duration(milliseconds: 20),
      verify: (bloc) {
        expect(bloc.state.currentIndex, 2);
        expect(bloc.state.currentTrack?.videoId, 'video3');
      },
    );

    blocTest<PlayerBlocBloc, PlayerBlocState>(
      'RemoveFromPlaylistEvent (no actual) debe reducir playlist',
      build: () => createTestPlayerBloc(engine: FakePlayerEngine()),
      seed: () => PlayerBlocState(
        playlist: playlist,
        currentTrack: track1,
        currentIndex: 0,
      ),
      act: (bloc) => bloc.add(const RemoveFromPlaylistEvent(1)),
      wait: const Duration(milliseconds: 20),
      verify: (bloc) => expect(bloc.state.playlist.length, 2),
    );

    blocTest<PlayerBlocBloc, PlayerBlocState>(
      'RemoveFromPlaylistEvent (actual) debe mover track actual',
      build: () => createTestPlayerBloc(engine: FakePlayerEngine()),
      seed: () => PlayerBlocState(
        playlist: playlist,
        currentTrack: track2,
        currentIndex: 1,
      ),
      act: (bloc) => bloc.add(const RemoveFromPlaylistEvent(1)),
      wait: const Duration(milliseconds: 20),
      verify: (bloc) {
        expect(bloc.state.playlist.length, 2);
        expect(bloc.state.currentIndex, 1);
        expect(bloc.state.currentTrack?.videoId, 'video3');
      },
    );

    blocTest<PlayerBlocBloc, PlayerBlocState>(
      'RemoveFromPlaylistEvent (última) debe limpiar currentTrack',
      build: () => createTestPlayerBloc(engine: FakePlayerEngine()),
      seed: () => PlayerBlocState(
        playlist: [track1],
        currentTrack: track1,
        currentIndex: 0,
      ),
      act: (bloc) => bloc.add(const RemoveFromPlaylistEvent(0)),
      wait: const Duration(milliseconds: 20),
      verify: (bloc) {
        expect(bloc.state.playlist, isEmpty);
        expect(bloc.state.currentTrack, isNull);
      },
    );
  });
}
