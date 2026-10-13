import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../auth/presentation/bloc/auth_cubit.dart';
import '../../domain/entities/live_session.dart';
import 'live_status_ui.dart';

/// Si [session] la transmite la cuenta en sesión.
///
/// El host no es audiencia de su propio vivo: en la sala de espectador abría
/// un segundo motor de video, y Agora tiene uno solo por proceso, así que
/// salir de esa sala cortaba la transmisión del Studio.
bool isOwnLive(BuildContext context, LiveSession session) {
  final auth = context.read<AuthCubit>().state;
  return auth is AuthAuthenticated &&
      session.hostId.isNotEmpty &&
      session.hostId == auth.user.id;
}

/// La ruta del Studio para un show propio.
///
/// Con `?show=` para que el Studio abra **ese** show y no el próximo de la
/// agenda: tocar un programado para el viernes abría el de mañana. El que
/// está al aire va sin `?show=`: es el que `pickStudioShow` elige igual, y
/// la ruta sin parámetro reusa el Studio que sigue transmitiendo en su
/// branch; con otra key, el router lo reconstruiría y cortaría la señal.
String studioRouteFor(LiveSession session) =>
    session.status.isOnAir ? AppRoutes.studio : AppRoutes.studioFor(session.id);

/// Abre un vivo: el host vuelve a su Studio y el resto entra a la sala.
void openLive(BuildContext context, LiveSession session) =>
    isOwnLive(context, session)
    ? context.go(studioRouteFor(session))
    : context.go(AppRoutes.liveRoom(session.id));
