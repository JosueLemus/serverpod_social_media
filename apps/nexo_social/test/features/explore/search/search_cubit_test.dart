import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_social/core/errors/failures.dart';
import 'package:nexo_social/features/explore/domain/repositories/search_repository.dart';
import 'package:nexo_social/features/explore/presentation/bloc/search_cubit.dart';
import 'package:nexo_social/features/profile/domain/entities/follow.dart';
import 'package:nexo_social/features/profile/domain/repositories/follow_repository.dart';

/// Contesta cuando el test lo decide: así se prueba qué pasa si una consulta
/// vieja llega después que una nueva.
class _ControlledSearch implements SearchRepository {
  final calls = <String>[];
  final pending = <String, Completer<SearchResults>>{};

  @override
  Future<SearchResults> search(String text) {
    calls.add(text);
    return (pending[text] = Completer<SearchResults>()).future;
  }

  void answer(String text, SearchResults results) =>
      pending[text]!.complete(results);

  void fail(String text) =>
      pending[text]!.completeError(const NetworkFailure('offline'));
}

class _FakeFollows implements FollowRepository {
  bool failNext = false;
  final followed = <String>[];

  @override
  Future<FollowState> follow(String userId) async {
    if (failNext) throw const NetworkFailure('offline');
    followed.add(userId);
    return FollowState(userId: userId, viewerFollows: true, followerCount: 4);
  }

  @override
  Future<FollowState> unfollow(String userId) async =>
      FollowState(userId: userId, viewerFollows: false, followerCount: 3);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _elena = ProfileSummary(
  id: 'u-elena',
  username: 'elena_ux',
  name: 'Elena Vega',
  followerCount: 3,
);

SearchResults _results(
  String query, {
  List<ProfileSummary> accounts = const [],
}) => SearchResults(query: query, accounts: accounts);

void main() {
  const debounce = Duration(milliseconds: 30);
  late _ControlledSearch search;
  late _FakeFollows follows;
  late SearchCubit cubit;

  setUp(() {
    search = _ControlledSearch();
    follows = _FakeFollows();
    cubit = SearchCubit(search, follows, debounce: debounce);
  });

  tearDown(() => cubit.close());

  Future<void> wait([Duration extra = Duration.zero]) =>
      Future<void>.delayed(debounce + const Duration(milliseconds: 20) + extra);

  test('waits for the typing to stop and asks once', () async {
    cubit
      ..changed('el')
      ..changed('ele')
      ..changed('elena');
    expect(search.calls, isEmpty);
    expect(cubit.state.status, SearchStatus.loading);

    await wait();

    expect(search.calls, ['elena']);
  });

  test('a late answer for an older text never replaces a newer one', () async {
    cubit.changed('ele');
    await wait();
    cubit.changed('elena');
    await wait();
    expect(search.calls, ['ele', 'elena']);

    search.answer('elena', _results('elena', accounts: [_elena]));
    await Future<void>.delayed(Duration.zero);
    search.answer('ele', _results('ele'));
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.status, SearchStatus.ready);
    expect(cubit.state.results?.query, 'elena');
    expect(cubit.state.results?.accounts, [_elena]);
  });

  test('typing again discards the answer still in flight', () async {
    cubit.changed('elena');
    await wait();
    // "elena" está en vuelo y el debounce de "elenav" todavía corre.
    cubit.changed('elenav');
    search.answer('elena', _results('elena', accounts: [_elena]));
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.status, SearchStatus.loading);
    expect(cubit.state.results, isNull);

    await wait();
    expect(search.calls, ['elena', 'elenav']);
    search.answer('elenav', _results('elenav'));
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.status, SearchStatus.ready);
    expect(cubit.state.results?.query, 'elenav');
  });

  test('less than two letters stops searching and clears', () async {
    cubit.changed('elena');
    await wait();
    search.answer('elena', _results('elena', accounts: [_elena]));
    await Future<void>.delayed(Duration.zero);

    cubit.changed('@e');

    expect(cubit.state.isSearching, isFalse);
    expect(cubit.state.results, isNull);
    expect(cubit.state.status, SearchStatus.idle);
  });

  test('a failure is a state, and retry asks again', () async {
    cubit.changed('elena');
    await wait();
    search.fail('elena');
    await Future<void>.delayed(Duration.zero);
    expect(cubit.state.status, SearchStatus.failed);

    final retried = cubit.retry();
    search.answer('elena', _results('elena', accounts: [_elena]));
    await retried;

    expect(cubit.state.status, SearchStatus.ready);
  });

  test('follow is painted at once and confirmed by the server', () async {
    cubit.changed('elena');
    await wait();
    search.answer('elena', _results('elena', accounts: [_elena]));
    await Future<void>.delayed(Duration.zero);

    await cubit.toggleFollow(_elena);

    final account = cubit.state.results!.accounts.single;
    expect(account.viewerFollows, isTrue);
    expect(account.followerCount, 4);
    expect(follows.followed, ['u-elena']);
  });

  test('a failed follow is undone and reported', () async {
    cubit.changed('elena');
    await wait();
    search.answer('elena', _results('elena', accounts: [_elena]));
    await Future<void>.delayed(Duration.zero);
    follows.failNext = true;

    await cubit.toggleFollow(_elena);

    expect(cubit.state.results!.accounts.single, _elena);
    expect(cubit.state.notice, SearchNotice.followFailed);
    expect(cubit.state.noticeSerial, 1);
  });
}
