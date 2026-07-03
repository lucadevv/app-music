// ignore_for_file: deprecated_member_use_from_same_package
import 'package:flutter_test/flutter_test.dart';
import 'package:music_app/core/domain/mappers/song_mapper.dart';
import 'package:music_app/features/downloads/domain/entities/downloaded_song.dart';
import 'package:music_app/features/home/domain/entities/chart_playlist.dart';
import 'package:music_app/features/search/domain/entities/song.dart' as search;
import 'package:music_app/features/search/domain/entities/thumbnail.dart';

void main() {
  group('SongMapper', () {
    group('fromSearchSong', () {
      test('should map search.Song to Song correctly', () {
        // Arrange
        const searchSong = search.Song(
          title: 'Test Song',
          videoId: 'abc123',
          duration: '3:45',
          durationSeconds: 225,
          views: '1M views',
          isExplicit: false,
          inLibrary: true,
          album: search.SearchAlbum(
            id: 'album1',
            name: 'Test Album',
            artists: [search.SearchArtist(id: 'artist1', name: 'Test Artist')],
          ),
          artists: [search.SearchArtist(id: 'artist1', name: 'Test Artist')],
          thumbnails: [
            search.Thumbnail(
              url: 'https://example.com/thumb1.jpg',
              width: 100,
              height: 100,
            ),
            search.Thumbnail(
              url: 'https://example.com/thumb2.jpg',
              width: 300,
              height: 300,
            ),
          ],
          streamUrl: 'https://stream.url',
        );

        // Act
        final result = SongMapper.fromSearchSong(searchSong);

        // Assert
        expect(result.videoId, 'abc123');
        expect(result.title, 'Test Song');
        expect(result.artist, 'Test Artist');
        expect(result.artistNames, ['Test Artist']);
        expect(result.album, 'Test Album');
        expect(result.durationSeconds, 225);
        expect(result.duration, '3:45');
        expect(result.views, '1M views');
        expect(result.isExplicit, false);
        expect(result.inLibrary, true);
        expect(result.streamUrl, 'https://stream.url');
        expect(result.thumbnails.length, 2);
      });

      test('should handle missing album artist', () {
        const searchSong = search.Song(
          title: 'Test Song',
          videoId: 'abc123',
          duration: '3:00',
          durationSeconds: 180,
          views: '0 views',
          isExplicit: false,
          inLibrary: false,
          album: search.SearchAlbum(id: 'album1', name: 'Album', artists: []),
          artists: [],
          thumbnails: [],
        );

        final result = SongMapper.fromSearchSong(searchSong);

        expect(result.artist, 'Unknown');
        expect(result.artistNames, isEmpty);
      });
    });

    group('fromDownloadedSong', () {
      test('should map DownloadedSong to Song correctly', () {
        // Arrange
        final downloadedSong = DownloadedSong(
          videoId: 'dl123',
          title: 'Downloaded Song',
          artist: 'Download Artist',
          album: 'Download Album',
          thumbnail: 'https://example.com/dl_thumb.jpg',
          localPath: '/path/to/song.mp3',
          fileSize: 5 * 1024 * 1024, // 5 MB
          duration: const Duration(minutes: 4, seconds: 30),
          downloadedAt: DateTime(2024, 1, 15),
        );

        // Act
        final result = SongMapper.fromDownloadedSong(downloadedSong);

        // Assert
        expect(result.videoId, 'dl123');
        expect(result.title, 'Downloaded Song');
        expect(result.artist, 'Download Artist');
        expect(result.album, 'Download Album');
        expect(result.thumbnail, 'https://example.com/dl_thumb.jpg');
        expect(result.localPath, '/path/to/song.mp3');
        expect(result.fileSize, 5 * 1024 * 1024);
        expect(result.durationSeconds, 270);
        expect(result.downloadedAt, DateTime(2024, 1, 15));
      });

      test('should format file size correctly', () {
        final downloadedSong = DownloadedSong(
          videoId: 'dl123',
          title: 'Test',
          artist: 'Artist',
          localPath: '/path',
          fileSize: 5 * 1024 * 1024,
          duration: const Duration(minutes: 3),
          downloadedAt: DateTime.now(),
        );

        final result = SongMapper.fromDownloadedSong(downloadedSong);

        expect(result.fileSizeFormatted, '5.0 MB');
      });
    });

    group('fromChartPlaylist', () {
      test('should map ChartPlaylist to Song correctly', () {
        const chartPlaylist = ChartPlaylist(
          playlistId: 'chart123',
          title: 'Chart Topper',
          thumbnails: [
            Thumbnail(
              url: 'https://example.com/chart.jpg',
              width: 300,
              height: 300,
            ),
          ],
        );

        final result = SongMapper.fromChartPlaylist(chartPlaylist);

        expect(result.videoId, 'chart123');
        expect(result.title, 'Chart Topper');
        expect(result.artist, '');
        expect(result.thumbnail, 'https://example.com/chart.jpg');
        expect(result.highThumbnail, 'https://example.com/chart.jpg');
        expect(result.thumbnails.length, 1);
      });

      test('should handle empty thumbnails', () {
        const chartPlaylist = ChartPlaylist(
          playlistId: 'chart456',
          title: 'No Thumb Playlist',
          thumbnails: [],
        );

        final result = SongMapper.fromChartPlaylist(chartPlaylist);

        expect(result.videoId, 'chart456');
        expect(result.title, 'No Thumb Playlist');
        expect(result.thumbnail, isNull);
        expect(result.thumbnails, isEmpty);
      });
    });

    group('fromRecentSong', () {
      test('should map RecentSong to Song correctly', () {
        // Arrange
        final recentSong = RecentSong(
          videoId: 'recent123',
          title: 'Recently Played',
          artist: 'Recent Artist',
          thumbnail: 'https://example.com/recent.jpg',
          duration: '2:30',
          durationSeconds: 150,
          playedAt: DateTime(2024, 1, 20),
        );

        // Act
        final result = SongMapper.fromRecentSong(recentSong);

        // Assert
        expect(result.videoId, 'recent123');
        expect(result.title, 'Recently Played');
        expect(result.artist, 'Recent Artist');
        expect(result.thumbnail, 'https://example.com/recent.jpg');
        expect(result.durationSeconds, 150);
      });

      test('should format duration correctly', () {
        const recentSong = RecentSong(
          videoId: 'test',
          title: 'Test',
          artist: 'Artist',
          duration: '2:30',
          durationSeconds: 150,
        );

        final result = SongMapper.fromRecentSong(recentSong);

        expect(result.durationFormatted, '2:30');
      });
    });

    group('List conversions', () {
      test('should convert list of search.Song to List<Song>', () {
        final searchSongs = [
          const search.Song(
            title: 'Song 1',
            videoId: 'id1',
            duration: '3:00',
            durationSeconds: 180,
            views: '100K',
            isExplicit: false,
            inLibrary: false,
            album: search.SearchAlbum(id: 'a1', name: 'Album', artists: []),
            artists: [search.SearchArtist(id: 'ar1', name: 'Artist')],
            thumbnails: [],
          ),
          const search.Song(
            title: 'Song 2',
            videoId: 'id2',
            duration: '4:00',
            durationSeconds: 240,
            views: '200K',
            isExplicit: false,
            inLibrary: false,
            album: search.SearchAlbum(id: 'a2', name: 'Album2', artists: []),
            artists: [search.SearchArtist(id: 'ar2', name: 'Artist2')],
            thumbnails: [],
          ),
        ];

        final result = SongMapper.fromSearchSongList(searchSongs);

        expect(result.length, 2);
        expect(result[0].videoId, 'id1');
        expect(result[1].videoId, 'id2');
      });
    });
  });
}
