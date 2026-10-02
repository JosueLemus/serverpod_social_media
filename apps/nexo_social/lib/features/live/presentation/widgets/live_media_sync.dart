import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/live_media_cubit.dart';
import '../../domain/entities/live_session.dart';
import '../bloc/live_room_cubit.dart';
import '../utils/live_status_ui.dart';

/// Ata el video al estado del vivo: entra al canal cuando el vivo está al
/// aire y sale cuando deja de estarlo.
///
/// El estado lo decide el servidor (lo trae `LiveRoomCubit`); el video lo
/// sigue. Así, un vivo que el operador corta o que el host termina saca a
/// todos del canal sin que nadie toque nada.
class LiveMediaSync extends StatelessWidget {
  const LiveMediaSync({super.key, required this.role, required this.child});

  final LiveMediaRole role;
  final Widget child;

  @override
  Widget build(BuildContext context) =>
      BlocListener<LiveRoomCubit, LiveRoomState>(
        listenWhen: (previous, current) =>
            previous.session?.status != current.session?.status ||
            previous.session?.id != current.session?.id,
        listener: (context, state) {
          final media = context.read<LiveMediaCubit>();
          final session = state.session;
          if (session != null && _shouldBeInChannel(session)) {
            unawaited(media.join(session.id, role));
          } else {
            unawaited(media.leave());
          }
        },
        child: child,
      );

  /// El host publica sólo al aire. La audiencia entra también a un show
  /// programado y espera la señal: es la sala de espera, y el video aparece
  /// en cuanto el host arranca, sin que nadie recargue.
  bool _shouldBeInChannel(LiveSession session) {
    if (session.endedByModeration) return false;
    return switch (role) {
      LiveMediaRole.host => session.status.isOnAir,
      LiveMediaRole.audience =>
        session.status.isOnAir || session.status == LiveStatus.scheduled,
    };
  }
}
