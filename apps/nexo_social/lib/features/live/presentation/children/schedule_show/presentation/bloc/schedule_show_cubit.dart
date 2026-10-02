import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../../core/errors/failures.dart';
import '../../../../../domain/entities/live_session.dart';
import '../../domain/entities/show_draft.dart';
import '../../domain/repositories/show_schedule_repository.dart';
import '../../domain/usecases/schedule_show.dart';

export '../../domain/entities/show_draft.dart';

enum ScheduleShowStatus { loading, editing, submitting, scheduled }

enum ScheduleShowIssue {
  notVerified,
  forbidden,
  suspended,
  invalid,
  guestNotFound,
  guestIsHost,
  guestUnavailable,
  guestLimit,
  other,
}

class ScheduleShowState extends Equatable {
  const ScheduleShowState({
    this.status = ScheduleShowStatus.loading,
    this.draft,
    this.draftIssues = const {},
    this.draftSaved = false,
    this.hasChanges = false,
    this.session,
    this.issue,
    this.issueSerial = 0,
  });

  final ScheduleShowStatus status;

  final ShowDraft? draft;

  final Set<ShowDraftIssue> draftIssues;

  final bool draftSaved;

  final bool hasChanges;

  final LiveSession? session;

  final ScheduleShowIssue? issue;
  final int issueSerial;

  bool get canSubmit =>
      status == ScheduleShowStatus.editing &&
      draft != null &&
      draftIssues.isEmpty;

  ScheduleShowState copyWith({
    ScheduleShowStatus? status,
    ShowDraft? draft,
    Set<ShowDraftIssue>? draftIssues,
    bool? draftSaved,
    bool? hasChanges,
    LiveSession? session,
    ScheduleShowIssue? issue,
    int? issueSerial,
  }) => ScheduleShowState(
    status: status ?? this.status,
    draft: draft ?? this.draft,
    draftIssues: draftIssues ?? this.draftIssues,
    draftSaved: draftSaved ?? this.draftSaved,
    hasChanges: hasChanges ?? this.hasChanges,
    session: session ?? this.session,
    issue: issue ?? this.issue,
    issueSerial: issueSerial ?? this.issueSerial,
  );

  @override
  List<Object?> get props => [
    status,
    draft,
    draftIssues,
    draftSaved,
    hasChanges,
    session,
    issue,
    issueSerial,
  ];
}

class ScheduleShowCubit extends Cubit<ScheduleShowState> {
  ScheduleShowCubit(
    this._repository,
    this._scheduleShow, {
    DateTime Function()? now,
    this.autosaveDelay = const Duration(milliseconds: 600),
  }) : _now = now ?? DateTime.now,
       super(const ScheduleShowState());

  final ShowScheduleRepository _repository;
  final ScheduleShow _scheduleShow;
  final DateTime Function() _now;

  final Duration autosaveDelay;

  static const minDurationMinutes = 15;
  static const maxDurationMinutes = 240;

  Timer? _autosave;

  var _finished = false;

  ShowDraft? get _draft => state.draft;

  Future<void> load() async {
    ShowDraft? restored;
    try {
      restored = await _repository.loadDraft();
    } on Failure {
      restored = null;
    }
    if (isClosed) return;
    final draft = restored ?? ShowDraft.startingFrom(_now());
    emit(
      state.copyWith(
        status: ScheduleShowStatus.editing,
        draft: draft,
        draftIssues: draft.issuesAt(_now()),
        draftSaved: restored != null,
        hasChanges: restored != null,
      ),
    );
  }

  void setTitle(String title) =>
      _update((draft) => draft.copyWith(title: title));

  void setDescription(String description) =>
      _update((draft) => draft.copyWith(description: description));

  void setDate(DateTime day) => _update((draft) {
    final current = draft.startsAt;
    return draft.copyWith(
      startsAt: DateTime(
        day.year,
        day.month,
        day.day,
        current.hour,
        current.minute,
      ),
    );
  });

  void setTime({required int hour, required int minute}) => _update((draft) {
    final current = draft.startsAt;
    return draft.copyWith(
      startsAt: DateTime(
        current.year,
        current.month,
        current.day,
        hour,
        minute,
      ),
    );
  });

  void setDuration(int minutes) => _update(
    (draft) => draft.copyWith(
      durationMinutes: minutes.clamp(minDurationMinutes, maxDurationMinutes),
    ),
  );

  void setAccess(ShowAccess access) =>
      _update((draft) => draft.copyWith(access: access));

  void setAllowQuestions({required bool value}) =>
      _update((draft) => draft.copyWith(allowQuestions: value));

  void setRecordReplay({required bool value}) =>
      _update((draft) => draft.copyWith(recordReplay: value));

  Future<void> addGuest(String username) async {
    final draft = _draft;
    if (draft == null || state.status != ScheduleShowStatus.editing) return;
    if (!draft.canAddGuest) {
      _reject(ScheduleShowIssue.guestLimit);
      return;
    }

    final ShowGuest guest;
    try {
      guest = await _repository.findGuest(username);
    } on Failure catch (failure) {
      _reject(switch (failure) {
        NotFoundFailure() => ScheduleShowIssue.guestNotFound,
        ConflictFailure() => ScheduleShowIssue.guestIsHost,
        ForbiddenFailure() => ScheduleShowIssue.guestUnavailable,
        AccountSuspendedFailure() => ScheduleShowIssue.suspended,
        _ => ScheduleShowIssue.other,
      });
      return;
    }
    if (isClosed) return;
    if (_draft!.guests.any((existing) => existing.id == guest.id)) return;
    _update((draft) => draft.copyWith(guests: [...draft.guests, guest]));
  }

  void removeGuest(String id) => _update(
    (draft) => draft.copyWith(
      guests: [
        for (final guest in draft.guests)
          if (guest.id != id) guest,
      ],
    ),
  );

  Future<void> discard() async {
    _finished = true;
    _autosave?.cancel();
    await _repository.clearDraft();
  }

  Future<void> submit() async {
    final draft = _draft;
    if (!state.canSubmit || draft == null) return;
    _autosave?.cancel();
    emit(state.copyWith(status: ScheduleShowStatus.submitting));
    try {
      final session = await _scheduleShow(draft);
      _finished = true;
      if (isClosed) return;
      emit(
        state.copyWith(status: ScheduleShowStatus.scheduled, session: session),
      );
    } on Failure catch (failure) {
      if (isClosed) return;
      emit(state.copyWith(status: ScheduleShowStatus.editing));
      _reject(switch (failure) {
        CreatorNotVerifiedFailure() => ScheduleShowIssue.notVerified,
        ForbiddenFailure() => ScheduleShowIssue.forbidden,
        AccountSuspendedFailure() => ScheduleShowIssue.suspended,
        ConflictFailure() => ScheduleShowIssue.invalid,
        _ => ScheduleShowIssue.other,
      });
    }
  }

  void _update(ShowDraft Function(ShowDraft draft) change) {
    final draft = _draft;
    if (draft == null || state.status != ScheduleShowStatus.editing) return;
    final next = change(draft);
    if (next == draft) return;
    emit(
      state.copyWith(
        draft: next,
        draftIssues: next.issuesAt(_now()),
        draftSaved: false,
        hasChanges: true,
      ),
    );
    _autosave?.cancel();
    _autosave = Timer(autosaveDelay, () => unawaited(_save(next)));
  }

  Future<void> _save(ShowDraft draft) async {
    try {
      await _repository.saveDraft(draft);
    } on Failure {
      return;
    }
    if (isClosed || state.draft != draft) return;
    emit(state.copyWith(draftSaved: true));
  }

  void _reject(ScheduleShowIssue issue) {
    if (isClosed) return;
    emit(state.copyWith(issue: issue, issueSerial: state.issueSerial + 1));
  }

  @override
  Future<void> close() {
    final pending = _autosave?.isActive ?? false;
    _autosave?.cancel();
    final draft = _draft;
    if (pending && !_finished && draft != null) {
      unawaited(_repository.saveDraft(draft).catchError((Object _) {}));
    }
    return super.close();
  }
}
