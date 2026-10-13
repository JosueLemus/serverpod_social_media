import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/bloc/auth_cubit.dart';
import '../features/messages/presentation/bloc/unread_messages_cubit.dart';
import '../features/notifications/presentation/bloc/unread_activity_cubit.dart';
import 'di/injection.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

class NexoApp extends StatefulWidget {
  const NexoApp({super.key});

  @override
  State<NexoApp> createState() => _NexoAppState();
}

class _NexoAppState extends State<NexoApp> {
  late final AuthCubit _auth;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    // Built once and held, not created in `build`. The router owns navigation
    // history, so rebuilding it — which a hot reload or any ancestor rebuild
    // would do — resets the user to the initial location mid-session.
    _auth = sl<AuthCubit>();
    // El conteo de la campana sigue a la sesión desde que arranca la app, no
    // desde que alguien abre Actividad.
    _router = createRouter(_auth, unread: sl<UnreadActivityCubit>());
    // Not awaited: the redirect keeps the user on the splash while the state
    // is AuthLoading and moves them on by itself once the session resolves.
    _auth.restore();
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MultiBlocProvider(
    providers: [
      // Above MaterialApp so the shell, the profile and the router redirect
      // all read one session.
      BlocProvider.value(value: _auth),
      // El badge de "Mensajes" de la barra del feed: uno para toda la app.
      BlocProvider.value(value: sl<UnreadMessagesCubit>()),
    ],
    child: MaterialApp.router(
      title: 'Nexo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.nexo,
      routerConfig: _router,
    ),
  );
}
