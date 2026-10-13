import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../features/appearance/presentation/bloc/theme_cubit.dart';
import '../features/auth/presentation/bloc/auth_cubit.dart';
import '../features/messages/presentation/bloc/unread_messages_cubit.dart';
import '../features/notifications/presentation/bloc/unread_activity_cubit.dart';
import 'di/injection.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';
import 'theme/nexo_themes.dart';

class NexoApp extends StatefulWidget {
  const NexoApp({super.key});

  @override
  State<NexoApp> createState() => _NexoAppState();
}

class _NexoAppState extends State<NexoApp> {
  late final AuthCubit _auth;
  late final ThemeCubit _theme;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    // Built once and held, not created in `build`. The router owns navigation
    // history, so rebuilding it — which a hot reload or any ancestor rebuild
    // would do — resets the user to the initial location mid-session.
    _auth = sl<AuthCubit>();
    // El tema guardado se activa antes del primer frame: la app no pinta el
    // de por defecto para saltar al elegido medio segundo después.
    _theme = sl<ThemeCubit>();
    NexoThemes.activate(NexoThemes.byId(_theme.state.themeId));
    // El conteo de la campana sigue a la sesión desde que arranca la app, no
    // desde que alguien abre Actividad.
    _router = createRouter(
      _auth,
      unread: sl<UnreadActivityCubit>(),
      unreadMessages: sl<UnreadMessagesCubit>(),
    );
    // Not awaited: the redirect keeps the user on the splash while the state
    // is AuthLoading and moves them on by itself once the session resolves.
    _auth.restore();
  }

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  /// Cambia el tema de toda la app sin perder la navegación.
  ///
  /// `AppColors` y `AppFonts` son getters sobre el tema activo, no
  /// dependencias del árbol: un widget que los lee no se entera solo de que
  /// cambiaron. Un `ThemeData` nuevo sólo reconstruye lo que llama a
  /// `Theme.of`, así que se marca **todo** el subárbol para reconstruir. Es
  /// un frame caro, una vez, cuando el usuario toca un tema; a cambio, ningún
  /// widget de la app tiene que saber que los temas existen.
  ///
  /// No se usa una `Key` nueva en `MaterialApp`: remontaría el Navigator y
  /// cada pantalla perdería su estado (scroll, formularios, cubits).
  void _applyTheme(ThemeState state) {
    NexoThemes.activate(NexoThemes.byId(state.themeId));
    void rebuild(Element element) {
      element.markNeedsBuild();
      element.visitChildren(rebuild);
    }

    (context as Element).visitChildren(rebuild);
  }

  @override
  Widget build(BuildContext context) => MultiBlocProvider(
    providers: [
      // Above MaterialApp so the shell, the profile and the router redirect
      // all read one session, and the Themes screen changes the cubit this
      // listens to.
      BlocProvider.value(value: _auth),
      BlocProvider.value(value: _theme),
      // El badge de "Mensajes" de la barra del feed: uno para toda la app.
      BlocProvider.value(value: sl<UnreadMessagesCubit>()),
    ],
    child: BlocConsumer<ThemeCubit, ThemeState>(
      bloc: _theme,
      listener: (context, state) => _applyTheme(state),
      builder: (context, state) => MaterialApp.router(
        title: 'Nexo',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.of(NexoThemes.active),
        // Sin la interpolación de Material: los colores que no salen del
        // `ThemeData` cambian en el acto, y 200 ms de mitad y mitad se ven
        // como un parpadeo.
        themeAnimationDuration: Duration.zero,
        routerConfig: _router,
      ),
    ),
  );
}
