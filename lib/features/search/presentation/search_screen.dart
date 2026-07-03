import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:music_app/core/theme/app_colors_dark.dart';
import 'package:music_app/features/search/presentation/cubit/orquestador_search_cubit.dart';
import 'package:music_app/features/search/presentation/cubit/recent_searches_cubit.dart';
import 'package:music_app/features/search/presentation/cubit/search_cubit.dart'
    show SearchCubit, SearchStatus, SearchState;
import 'package:music_app/features/search/presentation/widgets/molecules/search_bar_widget.dart';
import 'package:music_app/features/search/presentation/widgets/organisms/categories_grid_widget.dart';
import 'package:music_app/features/search/presentation/widgets/organisms/search_loading_view.dart';
import 'package:music_app/features/search/presentation/widgets/organisms/search_results_widget.dart';
import 'package:music_app/features/search/presentation/widgets/organisms/trending_artists_widget.dart'
    show RecentSearchesWidget;
import 'package:music_app/features/search/presentation/widgets/search_listeners.dart';

@RoutePage()
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenContainerState();
}

/// CONTAINER COMPONENT
/// Maneja Controllers, BLoC integracion, ciclo de vida. No renderiza Slivers ni colores.
class _SearchScreenContainerState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Reiniciar estado de búsqueda al entrar
    context.read<OrquestadorSearchCubit>().resetSearchState();
    // Cargar búsquedas recientes al iniciar
    context.read<RecentSearchesCubit>().getRecentSearches();

    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    // Cancelar el debounce al salir
    context.read<SearchCubit>().cancelDebounce();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;

    final position = _scrollController.position;
    // umbral: 300px antes del fondo
    if (position.pixels >= position.maxScrollExtent - 300) {
      final state = context.read<OrquestadorSearchCubit>().state.searchState;
      if (state.query.isNotEmpty &&
          state.hasMore &&
          state.status != SearchStatus.loadingMore &&
          state.status != SearchStatus.loading) {
        context.read<SearchCubit>().loadMore();
      }
    }
  }

  void _onSearchChanged(String value) {
    // Usar el método con debounce del Cubit
    context.read<SearchCubit>().searchWithDebounce(value);
  }

  void _onLoadMore() {
    context.read<SearchCubit>().loadMore();
  }

  @override
  Widget build(BuildContext context) {
    return SearchListeners(
      child: BlocBuilder<OrquestadorSearchCubit, OrquestadorSearchState>(
        builder: (context, orquestadorState) {
          return SearchPresentationalView(
            searchState: orquestadorState.searchState,
            searchController: _searchController,
            scrollController: _scrollController,
            onSearchChanged: _onSearchChanged,
            onLoadMore: _onLoadMore,
          );
        },
      ),
    );
  }
}

/// PRESENTATIONAL VIEW
/// Componente Tonto (Dumb Component).
/// Solo recibe estado y callbacks. Renderiza la UI basándose en Props.
class SearchPresentationalView extends StatelessWidget {
  final SearchState searchState;
  final TextEditingController searchController;
  final ScrollController scrollController;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onLoadMore;

  const SearchPresentationalView({
    required this.searchState,
    required this.searchController,
    required this.scrollController,
    required this.onSearchChanged,
    required this.onLoadMore,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final hasQuery = searchState.query.isNotEmpty;
    final isLoading = searchState.status == SearchStatus.loading;
    final hasResults = searchState.status == SearchStatus.success &&
        searchState.responseEntity != null;

    return Scaffold(
      backgroundColor: AppColorsDark.surface,
      body: SafeArea(
        child: CustomScrollView(
          controller: scrollController,
          slivers: [
            // Search Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: SearchBarWidget(
                  controller: searchController,
                  onChanged: onSearchChanged,
                ),
              ),
            ),

            // Mostrar loading shimmer si está buscando
            if (isLoading) const SliverToBoxAdapter(child: SearchLoadingView()),

            // Mostrar resultados si hay búsqueda
            if (hasQuery && hasResults)
              SliverToBoxAdapter(
                child: SearchResultsWidget(
                  results: searchState.responseEntity!.results,
                  query: searchState.query,
                  hasMore: searchState.hasMore,
                  isLoadingMore: searchState.status == SearchStatus.loadingMore,
                  onLoadMore: onLoadMore,
                ),
              ),

            // Mostrar lista y grid cuando no hay búsqueda
            if (!hasQuery) ...[
              // Búsquedas recientes
              const SliverToBoxAdapter(child: RecentSearchesWidget()),

              // Categories grid
              const SliverToBoxAdapter(child: CategoriesGridWidget()),
            ],

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }
}
