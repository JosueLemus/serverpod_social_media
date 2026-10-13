import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../../profile/domain/entities/follow.dart';
import '../../../profile/domain/repositories/follow_repository.dart';
import '../../domain/entities/search_results.dart';
import '../../domain/repositories/search_repository.dart';

export '../../domain/entities/search_results.dart';

enum SearchStatus { idle, loading, ready, failed }

/// Por qué falló seguir desde los resultados. La View elige la copy.
enum SearchNotice { followFailed }

class SearchState extends Equatable {
  const SearchState({
    this.text = '',
    this.status = SearchStatus.idle,
    this.results,
    this.notice,
    this.noticeSerial = 0,
  });

  /// Lo que hay escrito en el buscador, tal cual.
  final String text;
  final SearchStatus status;

  /// Los de la última búsqueda que terminó. Se conservan mientras carga la
  /// siguiente, así la lista no parpadea vacía en cada tecla.
  final SearchResults? results;
  final SearchNotice? notice;
  final int noticeSerial;

  /// Hay texto suficiente para buscar: Explorar muestra resultados en vez de
  /// su contenido normal.
  bool get isSearching => SearchCubit.isSearchable(text);

  SearchState copyWith({
    String? text,
    SearchStatus? status,
    SearchResults? Function()? results,
    SearchNotice? notice,
    int? noticeSerial,
  }) => SearchState(
    text: text ?? this.text,
    status: status ?? this.status,
    results: results == null ? this.results : results(),
    notice: notice ?? this.notice,
    noticeSerial: noticeSerial ?? this.noticeSerial,
  );

  @override
  List<Object?> get props => [text, status, results, notice, noticeSerial];
}

/// El buscador de Explorar.
///
/// Espera [debounce] desde la última tecla antes de preguntar, y cada
/// consulta lleva un número: si una vieja contesta después que una nueva, se
/// descarta. Sin eso, "ele" que llega tarde pisa los resultados de "elena".
class SearchCubit extends Cubit<SearchState> {
  SearchCubit(
    this._search,
    this._follows, {
    this.debounce = const Duration(milliseconds: 300),
  }) : super(const SearchState());

  final SearchRepository _search;
  final FollowRepository _follows;
  final Duration debounce;

  Timer? _timer;
  int _request = 0;

  /// Mismo umbral que el servidor: con una letra no se busca.
  static bool isSearchable(String text) {
    var value = text.trim();
    while (value.startsWith('@') || value.startsWith('#')) {
      value = value.substring(1).trimLeft();
    }
    return value.length >= 2;
  }

  void changed(String text) {
    _timer?.cancel();
    if (!isSearchable(text)) {
      _request++; // Lo que estaba en vuelo ya no importa.
      emit(
        SearchState(
          text: text,
          notice: state.notice,
          noticeSerial: state.noticeSerial,
        ),
      );
      return;
    }
    emit(state.copyWith(text: text, status: SearchStatus.loading));
    _timer = Timer(debounce, () => unawaited(_run(text)));
  }

  /// Vuelve a buscar el texto actual sin esperar (reintentar).
  Future<void> retry() async {
    _timer?.cancel();
    if (isSearchable(state.text)) await _run(state.text);
  }

  Future<void> _run(String text) async {
    final request = ++_request;
    emit(state.copyWith(status: SearchStatus.loading));
    try {
      final results = await _search.search(text);
      if (isClosed || request != _request) return;
      emit(state.copyWith(status: SearchStatus.ready, results: () => results));
    } on Failure {
      if (isClosed || request != _request) return;
      emit(state.copyWith(status: SearchStatus.failed));
    }
  }

  /// Seguir o dejar de seguir desde los resultados. Se pinta antes de que
  /// conteste el servidor y se deshace si falla: el servidor es la autoridad.
  Future<void> toggleFollow(ProfileSummary account) async {
    final results = state.results;
    if (results == null) return;
    final following = !account.viewerFollows;
    _replace(
      account.id,
      (a) => a.copyWith(
        viewerFollows: following,
        followerCount: () => a.followerCount == null
            ? null
            : a.followerCount! + (following ? 1 : -1),
      ),
    );
    try {
      final confirmed = following
          ? await _follows.follow(account.id)
          : await _follows.unfollow(account.id);
      _replace(
        account.id,
        (a) => a.copyWith(
          viewerFollows: confirmed.viewerFollows,
          followerCount: () => confirmed.followerCount,
        ),
      );
    } on Failure {
      _replace(account.id, (_) => account);
      if (!isClosed) {
        emit(
          state.copyWith(
            notice: SearchNotice.followFailed,
            noticeSerial: state.noticeSerial + 1,
          ),
        );
      }
    }
  }

  void _replace(String id, ProfileSummary Function(ProfileSummary) change) {
    final results = state.results;
    if (isClosed || results == null) return;
    emit(
      state.copyWith(
        results: () => results.copyWith(
          accounts: [
            for (final a in results.accounts) a.id == id ? change(a) : a,
          ],
        ),
      ),
    );
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
