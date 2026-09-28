import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../live/domain/entities/live_session.dart';
import '../../../live/domain/repositories/live_repository.dart';
import '../../domain/entities/discovery.dart';
import '../../domain/repositories/discovery_repository.dart';

class ExploreState extends Equatable {
  const ExploreState({
    this.sessions = const [],
    this.topics = const [],
    this.creators = const [],
    this.isLoading = true,
    this.hasFailed = false,
  });

  final List<LiveSession> sessions;
  final List<TrendingTopic> topics;
  final List<SuggestedCreator> creators;
  final bool isLoading;

  /// Un fallo es su propio estado. Sin él, un endpoint caído se ve igual que
  /// uno lento: un spinner que nunca resuelve.
  final bool hasFailed;

  List<LiveSession> get onAir =>
      sessions.where((session) => session.status == LiveStatus.live).toList();

  List<LiveSession> get upcoming => sessions
      .where((session) => session.status == LiveStatus.scheduled)
      .toList();

  List<LiveSession> get replays => sessions
      .where(
        (session) =>
            session.status == LiveStatus.recorded ||
            session.status == LiveStatus.published,
      )
      .toList();

  ExploreState copyWith({
    List<LiveSession>? sessions,
    List<TrendingTopic>? topics,
    List<SuggestedCreator>? creators,
    bool? isLoading,
    bool? hasFailed,
  }) => ExploreState(
    sessions: sessions ?? this.sessions,
    topics: topics ?? this.topics,
    creators: creators ?? this.creators,
    isLoading: isLoading ?? this.isLoading,
    hasFailed: hasFailed ?? this.hasFailed,
  );

  @override
  List<Object?> get props => [sessions, topics, creators, isLoading, hasFailed];
}

class ExploreCubit extends Cubit<ExploreState> {
  ExploreCubit(this._live, this._discovery) : super(const ExploreState());

  final LiveRepository _live;
  final DiscoveryRepository _discovery;

  Future<void> load() async {
    emit(state.copyWith(isLoading: true, hasFailed: false));
    try {
      emit(
        state.copyWith(
          sessions: await _live.list(),
          topics: await _discovery.trending(),
          creators: await _discovery.suggestedCreators(),
          isLoading: false,
        ),
      );
    } catch (_) {
      emit(state.copyWith(isLoading: false, hasFailed: true));
    }
  }

  /// Optimista: el estado cambia en el turno del tap y la escritura va detrás.
  /// Seguir a alguien es reversible y barato, así que esperar al backend para
  /// pintar el cambio sólo hace que el botón se sienta roto.
  Future<void> toggleTopic(TrendingTopic topic) async {
    final following = !topic.isFollowed;
    emit(
      state.copyWith(
        topics: [
          for (final item in state.topics)
            item.tag == topic.tag ? item.copyWith(isFollowed: following) : item,
        ],
      ),
    );
    await _discovery.setFollowingTopic(topic.tag, following: following);
  }

  Future<void> toggleCreator(SuggestedCreator creator) async {
    final following = !creator.isFollowed;
    emit(
      state.copyWith(
        creators: [
          for (final item in state.creators)
            item.username == creator.username
                ? item.copyWith(isFollowed: following)
                : item,
        ],
      ),
    );
    await _discovery.setFollowingCreator(
      creator.username,
      following: following,
    );
  }
}
