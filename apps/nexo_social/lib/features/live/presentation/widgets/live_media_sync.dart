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
///
/// La audiencia, además, sigue a la visibilidad de la pantalla. La sala vive
/// en el branch de Inicio, y `StatefulShellRoute.indexedStack` lo deja
/// montado al cambiar de pestaña: el audio de Agora seguía sonando en otra
/// pestaña y el servidor seguía contando un espectador que ya no miraba. El
/// shell apaga `TickerMode` en el branch oculto (y el `Overlay` en una ruta
/// tapada), así que eso es la señal: oculta, la sala sale del canal y deja
/// de escuchar; visible otra vez, vuelve a entrar. El host no: su Studio
/// sigue transmitiendo aunque mire otra pestaña.
class LiveMediaSync extends StatefulWidget {
  const LiveMediaSync({super.key, required this.role, required this.child});

  final LiveMediaRole role;
  final Widget child;

  @override
  State<LiveMediaSync> createState() => _LiveMediaSyncState();
}

class _LiveMediaSyncState extends State<LiveMediaSync> {
  /// Null hasta el primer `didChangeDependencies`: montarse no es volver.
  bool? _visible;

  bool get _followsVisibility => widget.role == LiveMediaRole.audience;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final visible = TickerMode.valuesOf(context).enabled;
    final previous = _visible;
    _visible = visible;
    if (previous == null || previous == visible || !_followsVisibility) return;
    // Después del frame: acá el árbol se está construyendo, y salir del
    // canal emite estados que redibujan la sala.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _visible != visible) return;
      final room = context.read<LiveRoomCubit>();
      if (visible) {
        room.resume();
        _sync(room.state);
      } else {
        room.pause();
        unawaited(context.read<LiveMediaCubit>().leave());
      }
    });
  }

  void _sync(LiveRoomState state) {
    final media = context.read<LiveMediaCubit>();
    final session = state.session;
    // El host no es audiencia de su propio vivo. Entrar desde la sala abría
    // un segundo motor de video, y Agora tiene uno por proceso: al salir, su
    // release cortaba la transmisión del Studio.
    final hostWatching =
        widget.role == LiveMediaRole.audience && state.role == LiveRole.host;
    final hidden = _followsVisibility && _visible == false;
    if (session != null &&
        !hostWatching &&
        !hidden &&
        !state.locked &&
        !state.handedOff &&
        _shouldBeInChannel(session)) {
      unawaited(media.join(session.id, widget.role));
    } else {
      unawaited(media.leave());
    }
  }

  @override
  Widget build(BuildContext context) =>
      BlocListener<LiveRoomCubit, LiveRoomState>(
        listenWhen: (previous, current) =>
            previous.session?.status != current.session?.status ||
            previous.session?.id != current.session?.id ||
            previous.role != current.role ||
            previous.locked != current.locked ||
            previous.handedOff != current.handedOff,
        listener: (context, state) => _sync(state),
        child: widget.child,
      );

  /// El host publica sólo al aire. La audiencia entra también a un show
  /// programado y espera la señal: es la sala de espera, y el video aparece
  /// en cuanto el host arranca, sin que nadie recargue.
  bool _shouldBeInChannel(LiveSession session) {
    if (session.endedByModeration) return false;
    return switch (widget.role) {
      LiveMediaRole.host => session.status.isOnAir,
      LiveMediaRole.audience =>
        session.status.isOnAir || session.status == LiveStatus.scheduled,
    };
  }
}
