import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../../../app/di/injection.dart';
import '../../../../../../../app/theme/app_tokens.dart';
import '../../../../../../../core/animations/app_motion.dart';
import '../../../../../../auth/presentation/bloc/auth_cubit.dart';
import '../bloc/schedule_show_cubit.dart';
import '../utils/schedule_show_copy.dart';
import '../utils/show_date_format.dart';
import '../widgets/access_settings_card.dart';
import '../widgets/audience_notice_card.dart';
import '../widgets/duration_selector.dart';
import '../widgets/feed_preview_card.dart';
import '../widgets/guests_section.dart';
import '../widgets/show_datetime_row.dart';
import '../widgets/show_description_field.dart';
import '../widgets/show_title_field.dart';

class ScheduleShowPage extends StatelessWidget {
  const ScheduleShowPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => sl<ScheduleShowCubit>()..load(),
    child: const _ScheduleShowView(),
  );
}

class _ScheduleShowView extends StatefulWidget {
  const _ScheduleShowView();

  @override
  State<_ScheduleShowView> createState() => _ScheduleShowViewState();
}

class _ScheduleShowViewState extends State<_ScheduleShowView> {
  final _title = TextEditingController();
  final _description = TextEditingController();

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  ScheduleShowCubit get _cubit => context.read<ScheduleShowCubit>();

  Future<void> _pickDate(DateTime current) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: current.isBefore(today) ? today : current,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
      helpText: 'Fecha del show',
      cancelText: 'Cancelar',
      confirmText: 'Elegir',
    );
    if (picked != null) _cubit.setDate(picked);
  }

  Future<void> _pickTime(DateTime current) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
      helpText: 'Hora del show',
      cancelText: 'Cancelar',
      confirmText: 'Elegir',
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked != null) {
      _cubit.setTime(hour: picked.hour, minute: picked.minute);
    }
  }

  Future<void> _addGuest() async {
    final username = await showAddGuestSheet(context);
    if (username != null) unawaited(_cubit.addGuest(username));
  }

  Future<void> _discard(bool hasChanges) async {
    if (hasChanges) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('¿Descartar borrador?'),
          content: const Text(
            'Se borrará todo lo que escribiste para este show. No se puede '
            'deshacer.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Seguir editando'),
            ),
            TextButton(
              key: const Key('schedule-discard-confirm'),
              onPressed: () => Navigator.pop(dialogContext, true),
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              child: const Text('Descartar'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }
    await _cubit.discard();
    if (mounted) context.pop();
  }

  void _onState(BuildContext context, ScheduleShowState state) {
    final messenger = ScaffoldMessenger.of(context);
    if (state.status == ScheduleShowStatus.scheduled) {
      final startsAt = state.session?.scheduledAt ?? state.draft!.startsAt;
      context.pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Show agendado · ${ShowDateFormat.shortDate(startsAt)}, '
            '${ShowDateFormat.time(startsAt)}',
          ),
        ),
      );
      return;
    }
    if (state.issue case final issue?) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(issue.message)));
    }
  }

  @override
  Widget build(BuildContext context) => MultiBlocListener(
    listeners: [
      BlocListener<ScheduleShowCubit, ScheduleShowState>(
        listenWhen: (previous, current) =>
            previous.status == ScheduleShowStatus.loading &&
            current.status == ScheduleShowStatus.editing,
        listener: (context, state) {
          _title.text = state.draft!.title;
          _description.text = state.draft!.description;
        },
      ),
      BlocListener<ScheduleShowCubit, ScheduleShowState>(
        listenWhen: (previous, current) =>
            current.status == ScheduleShowStatus.scheduled ||
            current.issueSerial != previous.issueSerial,
        listener: _onState,
      ),
    ],
    child: BlocBuilder<ScheduleShowCubit, ScheduleShowState>(
      builder: (context, state) => Scaffold(
        appBar: AppBar(
          leading: IconButton(
            key: const Key('schedule-back'),
            tooltip: 'Volver',
            onPressed: context.pop,
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          titleSpacing: 0,
          centerTitle: false,
          title: _TitleBlock(state: state),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.xs),
              child: TextButton.icon(
                key: const Key('schedule-discard'),
                onPressed: state.status == ScheduleShowStatus.editing
                    ? () => _discard(state.hasChanges)
                    : null,
                iconAlignment: IconAlignment.end,
                icon: const Icon(Icons.close_rounded, size: 18),
                label: const Text('Descartar'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                  ),
                ),
              ),
            ),
          ],
        ),
        body: state.draft == null
            ? const Center(child: CircularProgressIndicator())
            : _Form(
                state: state,
                title: _title,
                description: _description,
                onPickDate: () => _pickDate(state.draft!.startsAt),
                onPickTime: () => _pickTime(state.draft!.startsAt),
                onAddGuest: _addGuest,
              ),
        bottomNavigationBar: _SubmitBar(state: state),
      ),
    ),
  );
}

class _TitleBlock extends StatelessWidget {
  const _TitleBlock({required this.state});

  final ScheduleShowState state;

  @override
  Widget build(BuildContext context) {
    final saved = state.draftSaved;
    final (icon, label) = switch (state) {
      _ when saved => (Icons.check_circle_outline_rounded, 'Borrador guardado'),
      _ when state.hasChanges => (Icons.sync_rounded, 'Guardando…'),
      _ => (Icons.edit_outlined, 'Nuevo borrador'),
    };
    final color = saved ? AppColors.tertiary : AppColors.textSecondary;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Programar Show',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).appBarTheme.titleTextStyle,
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: AppSpacing.xxs),
            Flexible(
              child: Text(
                label,
                key: const Key('schedule-draft-status'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 11.5,
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _Form extends StatelessWidget {
  const _Form({
    required this.state,
    required this.title,
    required this.description,
    required this.onPickDate,
    required this.onPickTime,
    required this.onAddGuest,
  });

  final ScheduleShowState state;
  final TextEditingController title;
  final TextEditingController description;
  final VoidCallback onPickDate;
  final VoidCallback onPickTime;
  final VoidCallback onAddGuest;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ScheduleShowCubit>();
    final draft = state.draft!;
    final now = DateTime.now();
    final auth = context.watch<AuthCubit>().state;
    final username = auth is AuthAuthenticated ? auth.user.username : '';
    final sections = <Widget>[
      const AudienceNoticeCard(),
      ShowTitleField(
        controller: title,
        length: draft.titleLength,
        onChanged: cubit.setTitle,
      ),
      ShowDescriptionField(
        controller: description,
        onChanged: cubit.setDescription,
      ),
      ShowDateTimeRow(
        startsAt: draft.startsAt,
        now: now,
        onPickDate: onPickDate,
        onPickTime: onPickTime,
      ),
      DurationSelector(
        minutes: draft.durationMinutes,
        onChanged: cubit.setDuration,
      ),
      GuestsSection(
        guests: draft.guests,
        onAdd: onAddGuest,
        onRemove: cubit.removeGuest,
      ),
      AccessSettingsCard(
        access: draft.access,
        allowQuestions: draft.allowQuestions,
        recordReplay: draft.recordReplay,
        onAccess: cubit.setAccess,
        onAllowQuestions: (value) => cubit.setAllowQuestions(value: value),
        onRecordReplay: (value) => cubit.setRecordReplay(value: value),
      ),
      FeedPreviewCard(draft: draft, now: now, hostUsername: username),
    ];
    return SafeArea(
      bottom: false,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.xl,
            ),
            itemCount: sections.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.lg),
            itemBuilder: (context, index) =>
                EnterStatic(index: index, child: sections[index]),
          ),
        ),
      ),
    );
  }
}

class _SubmitBar extends StatelessWidget {
  const _SubmitBar({required this.state});

  final ScheduleShowState state;

  @override
  Widget build(BuildContext context) {
    final submitting = state.status == ScheduleShowStatus.submitting;
    final pending = state.draft == null || state.draftIssues.isEmpty
        ? null
        : state.draftIssues.first;
    return Material(
      color: AppColors.surface,
      elevation: 8,
      shadowColor: AppColors.shadow,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.sm,
          ),
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 640),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FilledButton.icon(
                    key: const Key('schedule-submit'),
                    onPressed: state.canSubmit
                        ? context.read<ScheduleShowCubit>().submit
                        : null,
                    icon: submitting
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.event_available_rounded, size: 20),
                    label: Text(
                      submitting ? 'Agendando…' : 'Confirmar y Agendar Show',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    pending?.hint ??
                        'Tu audiencia verá el show en Explorar apenas lo '
                            'confirmes.',
                    key: const Key('schedule-submit-hint'),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
