import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../app/di/injection.dart';
import '../../../../core/layout/nexo_page.dart';
import '../bloc/moderation_cubit.dart';
import '../widgets/report_queue.dart';

/// Moderation console. Desktop-first, but it degrades to one column on a
/// phone so a moderator is not blocked while away from a desk.
class ModerationPage extends StatelessWidget {
  const ModerationPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => sl<ModerationCubit>()..load(),
    child: const _ModerationView(),
  );
}

class _ModerationView extends StatelessWidget {
  const _ModerationView();

  @override
  Widget build(BuildContext context) => NexoPage(
    title: 'Moderación',
    onRefresh: context.read<ModerationCubit>().load,
    children: const [ReportQueueSection()],
  );
}
