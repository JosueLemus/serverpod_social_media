import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/di/injection.dart';
import '../../../../app/theme/app_tokens.dart';
import '../../domain/entities/live_session.dart';
import '../../domain/repositories/live_repository.dart';
import '../bloc/live_list_cubit.dart';
import '../bloc/live_room_cubit.dart';

class LiveListPage extends StatelessWidget {
  const LiveListPage({super.key});
  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => sl<LiveListCubit>()..load(),
    child: BlocBuilder<LiveListCubit, LiveListState>(
      builder: (context, state) {
        if (state is! LiveListLoaded) {
          return const Center(child: CircularProgressIndicator());
        }
        return ListView(
          children: [
            Text('En vivos', style: Theme.of(context).textTheme.displaySmall),
            ...state.sessions.map(
              (item) => Card(
                child: ListTile(
                  title: Text(item.title),
                  subtitle: Text('${item.hostName} · ${item.status.name}'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.go('/live/${item.id}'),
                ),
              ),
            ),
          ],
        );
      },
    ),
  );
}

class LiveRoomPage extends StatelessWidget {
  const LiveRoomPage({super.key, required this.liveId});
  final String liveId;
  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => LiveRoomCubit(
      sl<LiveRepository>(),
      LiveSession(
        id: liveId,
        title: 'Masterclass de Diseño Mobile',
        hostName: 'Elena Vega',
        status: LiveStatus.live,
        viewers: 2845,
      ),
    ),
    child: const _Room(),
  );
}

class _Room extends StatelessWidget {
  const _Room();
  @override
  Widget build(BuildContext context) =>
      BlocBuilder<LiveRoomCubit, LiveRoomState>(
        builder: (context, state) => ListView(
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(
                color: AppColors.textPrimary,
                alignment: Alignment.center,
                child: const Text(
                  'Transmisión simulada · Agora pendiente',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              state.session.title,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            Text('${state.session.viewers} espectadores'),
            ...state.comments.map(
              (comment) => ListTile(
                title: Text(comment),
                trailing: IconButton(
                  icon: const Icon(Icons.visibility_off_outlined),
                  onPressed: () =>
                      context.read<LiveRoomCubit>().hideComment(comment),
                ),
              ),
            ),
            FilledButton.icon(
              onPressed: context.read<LiveRoomCubit>().toggleLove,
              icon: Icon(state.loved ? Icons.favorite : Icons.favorite_border),
              label: const Text('Dar amor'),
            ),
          ],
        ),
      );
}

class CreatorStudioPage extends StatelessWidget {
  const CreatorStudioPage({super.key});
  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => LiveRoomCubit(
      sl<LiveRepository>(),
      const LiveSession(
        id: 'studio-live',
        title: 'Mi próximo vivo',
        hostName: 'Elena Vega',
        status: LiveStatus.scheduled,
      ),
    ),
    child: BlocBuilder<LiveRoomCubit, LiveRoomState>(
      builder: (context, state) => ListView(
        children: [
          Text(
            'Creator Studio',
            style: Theme.of(context).textTheme.displaySmall,
          ),
          ListTile(
            title: Text(state.session.title),
            subtitle: Text('Estado: ${state.session.status.name}'),
            trailing: FilledButton(
              onPressed: () =>
                  context.read<LiveRoomCubit>().transition(LiveStatus.live),
              child: const Text('Iniciar'),
            ),
          ),
          ...state.guests.map(
            (guest) => ListTile(
              title: Text('Solicitud: $guest'),
              trailing: FilledButton(
                onPressed: () =>
                    context.read<LiveRoomCubit>().approveGuest(guest),
                child: const Text('Aceptar'),
              ),
            ),
          ),
          ...state.audit.map(
            (entry) => ListTile(
              leading: const Icon(Icons.verified_user_outlined),
              title: Text(entry),
            ),
          ),
          if (state.session.status == LiveStatus.live)
            FilledButton.tonal(
              onPressed: () =>
                  context.read<LiveRoomCubit>().transition(LiveStatus.recorded),
              child: const Text('Finalizar y crear replay'),
            ),
        ],
      ),
    ),
  );
}
