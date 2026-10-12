import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../auth/presentation/bloc/auth_cubit.dart';
import '../../domain/entities/live_session.dart';

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

/// Abre un vivo: el host vuelve a su Studio y el resto entra a la sala.
///
/// Al Studio se vuelve sin `?show=`: el que está al aire es el que elige
/// `pickStudioShow`, y la misma ruta reusa el Studio que sigue transmitiendo
/// en su branch en vez de montar otro.
void openLive(BuildContext context, LiveSession session) =>
    isOwnLive(context, session)
    ? context.go(AppRoutes.studio)
    : context.go(AppRoutes.liveRoom(session.id));
