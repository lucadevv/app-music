// ignore_for_file: deprecated_member_use_from_same_package
import 'package:auto_route/auto_route.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:music_app/core/theme/app_colors_dark.dart';
import 'package:music_app/core/utils/bottom_sheet_visibility.dart';
import 'package:music_app/core/utils/extension/url_validation_extension.dart';
import 'package:music_app/features/search/domain/entities/search_request.dart';
import 'package:music_app/features/search/domain/entities/song.dart';
import 'package:music_app/features/search/domain/repositories/search_repository.dart';

class AddSongsDialogOrganism extends StatefulWidget {
  final Function(
    String videoId,
    String title,
    String artist,
    String? thumbnail,
    int? duration,
  )
  onAddSong;
  final int songsToAdd;

  const AddSongsDialogOrganism({
    required this.onAddSong,
    this.songsToAdd = 0,
    super.key,
  });

  static Future<void> show(
    BuildContext context, {
    required Function(
      String videoId,
      String title,
      String artist,
      String? thumbnail,
      int? duration,
    )
    onAddSong,
  }) async {
    await BottomSheetVisibility().showBottomSheet(
      context: context,
      builder: (bottomSheetContext) =>
          AddSongsDialogOrganism(onAddSong: onAddSong),
    );
  }

  @override
  State<AddSongsDialogOrganism> createState() => _AddSongsDialogOrganismState();
}

class _AddSongsDialogOrganismState extends State<AddSongsDialogOrganism> {
  final _searchController = TextEditingController();
  final _searchRepository = GetIt.I<SearchRepository>();
  List<Song> _searchResults = [];
  bool _isLoading = false;
  String? _error;
  final Set<String> _selectedVideoIds = {};

  String _getArtistNames(Song song) {
    return song.artists.map((a) => a.name).join(', ');
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _error = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final result = await _searchRepository.search(
        SearchRequest(query: query, filter: 'songs'),
      );

      result.fold(
        (failure) {
          setState(() {
            _error = failure.toString();
            _searchResults = [];
          });
        },
        (response) {
          setState(() {
            _searchResults = response.results;
          });
        },
      );
    } catch (e) {
      setState(() {
        _error = e.toString();
        _searchResults = [];
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _addSelectedSongs() async {
    for (final song in _searchResults) {
      final videoId = song.videoId;
      if (_selectedVideoIds.contains(videoId)) {
        widget.onAddSong(
          videoId,
          song.title,
          _getArtistNames(song),
          song.thumbnail?.url,
          song.durationSeconds,
        );
      }
    }

    if (!mounted) return;
    await context.router.maybePop();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${_selectedVideoIds.length} canción(es) agregada(s)'),
        backgroundColor: AppColorsDark.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      padding: EdgeInsets.only(
        top: 16,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Agregar canciones',
                  style: TextStyle(
                    color: AppColorsDark.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    if (_selectedVideoIds.isNotEmpty)
                      TextButton(
                        onPressed: _addSelectedSongs,
                        child: Text(
                          'Agregar (${_selectedVideoIds.length})',
                          style: const TextStyle(
                            color: AppColorsDark.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        color: AppColorsDark.onSurface,
                      ),
                      onPressed: () => context.router.maybePop(),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(color: AppColorsDark.onSurface24),
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: AppColorsDark.onSurface),
              decoration: InputDecoration(
                hintText: 'Buscar canciones...',
                hintStyle: TextStyle(
                  color: AppColorsDark.onSurface.withValues(alpha: 0.5),
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: AppColorsDark.onSurface.withValues(alpha: 0.5),
                ),
                filled: true,
                fillColor: AppColorsDark.surfaceContainerLow,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
              onSubmitted: _performSearch,
            ),
          ),
          const SizedBox(height: 8),
          _buildContent(),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Expanded(
        child: Center(
          child: CircularProgressIndicator(color: AppColorsDark.primary),
        ),
      );
    }

    if (_error != null) {
      return Expanded(
        child: Center(
          child: Text(
            _error!,
            style: const TextStyle(color: AppColorsDark.error),
          ),
        ),
      );
    }

    if (_searchResults.isEmpty) {
      return Expanded(
        child: Center(
          child: Text(
            _searchController.text.isEmpty
                ? 'Busca una canción para agregar'
                : 'No se encontraron resultados',
            style: TextStyle(
              color: AppColorsDark.onSurface.withValues(alpha: 0.7),
            ),
          ),
        ),
      );
    }

    return Expanded(
      child: ListView.builder(
        itemCount: _searchResults.length,
        itemBuilder: (context, index) {
          final song = _searchResults[index];
          final videoId = song.videoId;
          final isSelected = _selectedVideoIds.contains(videoId);

          return ListTile(
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Container(
                width: 48,
                height: 48,
                color: AppColorsDark.primaryContainer,
                child:
                    song.thumbnail?.url != null &&
                        song.thumbnail!.url.isValidImageUrl
                    ? CachedNetworkImage(
                        imageUrl: song.thumbnail!.url,
                        fit: BoxFit.cover,
                        errorWidget: (_, _, _) => const Icon(Icons.music_note),
                      )
                    : const Icon(
                        Icons.music_note,
                        color: AppColorsDark.primary,
                      ),
              ),
            ),
            title: Text(
              song.title,
              style: const TextStyle(color: AppColorsDark.onSurface),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              _getArtistNames(song),
              style: TextStyle(
                color: AppColorsDark.onSurface.withValues(alpha: 0.6),
                fontSize: 12,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: IconButton(
              icon: Icon(
                isSelected ? Icons.check_circle : Icons.add_circle_outline,
                color: isSelected
                    ? AppColorsDark.primary
                    : AppColorsDark.onSurface70,
              ),
              onPressed: () {
                setState(() {
                  if (isSelected) {
                    _selectedVideoIds.remove(videoId);
                  } else {
                    _selectedVideoIds.add(videoId);
                  }
                });
              },
            ),
            onTap: () {
              setState(() {
                if (isSelected) {
                  _selectedVideoIds.remove(videoId);
                } else {
                  _selectedVideoIds.add(videoId);
                }
              });
            },
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
