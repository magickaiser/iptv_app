import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/api/xtream_client.dart';
import '../../core/api/models/channel.dart';
import '../../core/api/models/category.dart';
import '../../core/api/models/epg_program.dart';
import '../auth/login_provider.dart';

/// Manages live TV data: categories, channels, EPG.
class LiveTvProvider extends StateNotifier<LiveTvState> {
  final XtreamClient _client;

  LiveTvProvider(this._client) : super(const LiveTvState());

  XtreamClient get client => _client;

  Future<void> loadCategories() async {
    state = state.copyWith(loading: true);
    try {
      final categories = await _client.fetchLiveCategories();
      state = state.copyWith(categories: categories, loading: false, error: null);
    } catch (e) {
      state = state.copyWith(
        loading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> loadChannels() async {
    state = state.copyWith(loading: true);
    try {
      final channels = await _client.fetchLiveChannels();
      state = state.copyWith(channels: channels, loading: false, error: null);
    } catch (e) {
      state = state.copyWith(
        loading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> loadEpgForChannel(int streamId) async {
    state = state.copyWith(epgLoading: true);
    try {
      final programs = await _client.fetchShortEpg(streamId);
      state = state.copyWith(epgPrograms: programs, epgLoading: false);
    } catch (e) {
      state = state.copyWith(epgLoading: false);
    }
  }

  void selectCategory(int? categoryId) {
    state = state.copyWith(selectedCategoryId: categoryId);
  }

  List<Channel> get filteredChannels {
    final catId = state.selectedCategoryId;
    if (catId == null) return state.channels;
    return state.channels.where((c) => c.categoryId == catId).toList();
  }
}

class LiveTvState {
  final List<Category> categories;
  final List<Channel> channels;
  final List<EpgProgram> epgPrograms;
  final int? selectedCategoryId;
  final bool loading;
  final bool epgLoading;
  final String? error;

  const LiveTvState({
    this.categories = const [],
    this.channels = const [],
    this.epgPrograms = const [],
    this.selectedCategoryId,
    this.loading = false,
    this.epgLoading = false,
    this.error,
  });

  LiveTvState copyWith({
    List<Category>? categories,
    List<Channel>? channels,
    List<EpgProgram>? epgPrograms,
    int? selectedCategoryId,
    bool? loading,
    bool? epgLoading,
    String? error,
    bool clearCategory = false,
  }) {
    return LiveTvState(
      categories: categories ?? this.categories,
      channels: channels ?? this.channels,
      epgPrograms: epgPrograms ?? this.epgPrograms,
      selectedCategoryId:
          clearCategory ? null : (selectedCategoryId ?? this.selectedCategoryId),
      loading: loading ?? this.loading,
      epgLoading: epgLoading ?? this.epgLoading,
      error: error,
    );
  }
}

/// Provider that depends on the authenticated client.
final liveTvProvider =
    StateNotifierProvider<LiveTvProvider, LiveTvState>((ref) {
  final loginNotifier = ref.watch(loginProvider.notifier);
  final client = loginNotifier.client;
  if (client == null) {
    throw StateError('LiveTvProvider requires an authenticated client');
  }
  return LiveTvProvider(client);
});
