import 'dart:async';

import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/app_tokens.dart';
import '../../../../core/animations/app_motion.dart';
import '../../../../core/constants/environment.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/mock/demo_accounts.dart';
import '../../../../core/widgets/nexo_icon.dart';
import '../../../../core/widgets/nexo_logo.dart';
import '../../../../core/widgets/nexo_mascot.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../widgets/demo_account_picker.dart';
import '../bloc/auth_cubit.dart';

// None of these pages creates an AuthCubit. It is a singleton provided above
// MaterialApp, and `BlocProvider(create:)` closes whatever it built when it is
// disposed — a local provider here would shut the app-wide session down as
// soon as the user left the screen, and every later read would hit a closed
// cubit. They read it from the tree instead.
//
// None of them navigates on success either. Signing in changes the session,
// the router's refreshListenable sees it and the redirect moves the user. A
// listener doing the same thing would race the guard.

/// The loading state of the session read, nothing more.
class SplashPage extends StatelessWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ZoomIn(
            duration: const Duration(milliseconds: 420),
            child: const NexoLogo(size: 112),
          ),
          const SizedBox(height: AppSpacing.lg),
          FadeIn(
            delay: const Duration(milliseconds: 260),
            child: const SizedBox(
              width: 72,
              child: LinearProgressIndicator(
                minHeight: 4,
                borderRadius: AppRadii.pill,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class SignInPage extends StatelessWidget {
  const SignInPage({super.key});

  @override
  Widget build(BuildContext context) => const _WelcomePage();
}

class SignUpPage extends StatelessWidget {
  const SignUpPage({super.key});

  @override
  Widget build(BuildContext context) => const AuthForm(signUp: true);
}

class PasswordResetPage extends StatelessWidget {
  const PasswordResetPage({super.key});

  @override
  Widget build(BuildContext context) => const AuthForm(resetPassword: true);
}

class _WelcomePage extends StatelessWidget {
  const _WelcomePage();

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: ListView(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            children: [
              const Row(
                children: [
                  // Expanded + Align, y **sin** `Spacer`: el Spacer se lleva
                  // todo el espacio libre y deja al Flexible de la insignia en
                  // cero, así que se dibuja a su ancho mínimo y desborda
                  // igual. Expandir la insignia le da el resto de la fila y la
                  // deja elidir; el Align impide que la píldora se estire.
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: _CommunityBadge(),
                    ),
                  ),
                  SizedBox(width: AppSpacing.xs),
                  _LanguageToggle(),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              const _StickerSheetHero(),
              const SizedBox(height: AppSpacing.md),
              Enter(
                index: 1,
                child: Text(
                  'Encuentra tu comunidad.',
                  style: Theme.of(context).textTheme.displayMedium,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Enter(
                index: 2,
                child: Text(
                  'Conecta con creadores auténticos, accede a contenido exclusivo y participa en conversaciones en vivo.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.45,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              const Enter(index: 3, child: _Highlights()),
              const SizedBox(height: AppSpacing.md),
              const Enter(index: 4, child: _SocialProof()),
              const SizedBox(height: AppSpacing.lg),
              // Everything below is tappable, so it only fades in: a slide
              // would leave these controls offset from where they are drawn
              // while the user is already reaching for them.
              EnterStatic(
                index: 5,
                child: FilledButton.icon(
                  onPressed: () => context.go(AppRoutes.signUp),
                  iconAlignment: IconAlignment.end,
                  icon: const NexoIcon(NexoGlyph.forward, size: 18),
                  label: const Text('Crear cuenta'),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              EnterStatic(
                index: 6,
                child: OutlinedButton(
                  onPressed: () => _showSignInSheet(context),
                  child: const Text('Iniciar sesión'),
                ),
              ),
              // Arriba y no al pie: al pie quedaba fuera de pantalla en un
              // teléfono, y quien no lo veía entraba por "Iniciar sesión" con
              // su correo — que en el mock es siempre Elena. Todas las cuentas
              // parecían la misma porque eran la misma.
              // El acceso demo es un atajo, no la acción principal: con el
              // estilo del CTA quedaban dos stickers blancos compitiendo. El
              // tema local lo baja a una pastilla gris sin tocar el widget.
              EnterStatic(
                index: 6,
                child: Theme(
                  data: Theme.of(context).copyWith(
                    filledButtonTheme: FilledButtonThemeData(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.linerHigh,
                        foregroundColor: AppColors.textPrimary,
                        minimumSize: const Size.fromHeight(
                          AppSizes.buttonHeightDense,
                        ),
                        shape: const RoundedRectangleBorder(
                          borderRadius: AppRadii.pill,
                        ),
                        textStyle: Theme.of(context).textTheme.labelMedium,
                      ),
                    ),
                  ),
                  child: const DemoAccountButton(),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              const _ContinueWith(),
              const SizedBox(height: AppSpacing.md),
              const EnterStatic(
                index: 7,
                child: Row(
                  children: [
                    Expanded(
                      child: _SocialButton(icon: 'G', label: 'Google'),
                    ),
                    SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: _SocialButton(
                        icon: '',
                        label: 'Apple',
                        isApple: true,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              EnterStatic(
                index: 8,
                child: TextButton(
                  key: const Key('explore-as-guest'),
                  onPressed: () => _exploreAsGuest(context),
                  child: const Text('Explora como invitado sin registrarte'),
                ),
              ),

              const SizedBox(height: AppSpacing.sm),
              Text(
                'Al continuar, confirmas que aceptas nuestros Términos de Servicio y nuestra Política de Privacidad.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Starts a guest session and enters the app.
///
/// This is the one auth action that navigates by hand. Signing in or signing
/// up produces a real account, and the redirect moves those users off the
/// public routes on its own — but a visitor is deliberately *allowed* to stay
/// on sign-in, because that page is how they upgrade. The guard therefore
/// cannot tell "just tapped explore" from "bounced off a gated route", so the
/// caller has to say which one it is.
///
/// The router is resolved before the await: after it, this widget may already
/// be gone and looking a Navigator up from a dead element throws inside a null
/// check with no readable message.
Future<void> _exploreAsGuest(BuildContext context) async {
  final router = GoRouter.of(context);
  await context.read<AuthCubit>().guest();
  router.go(AppRoutes.feed);
}

/// La prueba social del onboarding.
///
/// Es lo único de esta pantalla que dice que del otro lado hay gente. Un muro
/// de acceso sin nadie detrás pide crear una cuenta para entrar a un lugar
/// vacío, y esa es la razón más común para no crearla. Nombra a las personas
/// que de verdad están en la demo: una cifra de "miles de creadores" sería
/// inventada.
class _SocialProof extends StatelessWidget {
  const _SocialProof();

  static const _names = ['Elena', 'Carlos', 'Lucía', 'Marcos'];

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.sm,
      AppSpacing.sm,
      AppSpacing.md,
      AppSpacing.sm,
    ),
    decoration: const BoxDecoration(
      color: AppColors.linerHigh,
      borderRadius: AppRadii.pill,
    ),
    child: Row(
      children: [
        // Cada sticker lleva un aro del color de la píldora: así se montan
        // como stickers pegados uno encima del otro y las iniciales no se
        // pisan.
        SizedBox(
          width: 36 + 28.0 * (_names.length - 1),
          height: 36,
          child: Stack(
            children: [
              for (final (index, name) in _names.indexed)
                Positioned(
                  left: index * 28,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: AppColors.linerHigh,
                      shape: BoxShape.circle,
                    ),
                    child: UserAvatar(name: name, size: 32),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Elena, Carlos y Lucía ya están creando',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              Text(
                'Únete y sigue sus vivos',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

/// La plancha de bienvenida: el gato del logo al centro y stickers pegados
/// alrededor, que caen uno por uno como si alguien los fuera pegando.
///
/// Nada de esto se toca, así que puede moverse y rotar: no hay hit test que
/// se corra.
class _StickerSheetHero extends StatelessWidget {
  const _StickerSheetHero();

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 220,
    child: LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final cx = w / 2;
        return Stack(
          clipBehavior: Clip.none,
          children: [
            _slap(
              index: 1,
              left: cx - 150,
              top: 22,
              angle: -.22,
              child: const _HeroSticker('assets/stickers/heart.webp', 58),
            ),
            _slap(
              index: 2,
              left: cx + 92,
              top: 8,
              angle: .2,
              child: const _HeroSticker('assets/stickers/star.webp', 54),
            ),
            _slap(
              index: 3,
              left: cx + 100,
              top: 128,
              angle: -.12,
              child: const _HeroSticker('assets/stickers/fire.webp', 60),
            ),
            _slap(
              index: 4,
              left: cx - 156,
              top: 120,
              angle: .14,
              child: const MascotIllustration(NexoMascot.mic, size: 76),
            ),
            Positioned(
              left: cx - 90,
              top: 10,
              child: ZoomIn(
                duration: const Duration(milliseconds: 380),
                child: const NexoLogo(size: 180),
              ),
            ),
          ],
        );
      },
    ),
  );

  static Widget _slap({
    required int index,
    required double left,
    required double top,
    required double angle,
    required Widget child,
  }) => Positioned(
    left: left,
    top: top,
    child: Transform.rotate(
      angle: angle,
      child: ZoomIn(
        duration: const Duration(milliseconds: 260),
        delay: Duration(milliseconds: 260 + 90 * index),
        child: child,
      ),
    ),
  );
}

class _HeroSticker extends StatelessWidget {
  const _HeroSticker(this.asset, this.size);

  final String asset;
  final double size;

  @override
  Widget build(BuildContext context) => Image.asset(
    asset,
    width: size,
    height: size,
    cacheWidth: (size * (MediaQuery.maybeDevicePixelRatioOf(context) ?? 3))
        .round(),
    excludeFromSemantics: true,
  );
}

/// El selector de idioma del diseño.
///
/// **Es presentacional: cambiar la selección no traduce nada.** La app no
/// tiene plumbing de locale —toda la copy está en español y en línea— y
/// montar `gen-l10n` es trabajo aparte, así que el control existe para que la
/// pantalla coincida con el mockup y la deuda quede a la vista en vez de
/// escondida.
///
/// Cuando llegue i18n, esto pasa a leer y escribir el `LocaleCubit`, y la
/// única otra cosa que cambia es que `_language` sale del estado en vez de
/// vivir en este widget. Nada más lee este valor hoy, así que no puede
/// desincronizarse con nada.
class _LanguageToggle extends StatefulWidget {
  const _LanguageToggle();

  @override
  State<_LanguageToggle> createState() => _LanguageToggleState();
}

class _LanguageToggleState extends State<_LanguageToggle> {
  static const _languages = ['ES', 'EN'];
  String _language = _languages.first;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(3),
    decoration: const BoxDecoration(
      color: AppColors.linerHigh,
      borderRadius: AppRadii.pill,
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final code in _languages)
          InkWell(
            key: Key('language-$code'),
            onTap: () => setState(() => _language = code),
            borderRadius: AppRadii.pill,
            child: AnimatedContainer(
              duration: AppMotion.feedbackDuration,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: 5,
              ),
              decoration: BoxDecoration(
                color: code == _language
                    ? AppColors.sticker
                    : Colors.transparent,
                borderRadius: AppRadii.pill,
              ),
              child: Text(
                code,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: .4,
                  color: code == _language
                      ? AppColors.ink
                      : AppColors.textSecondary,
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

class _CommunityBadge extends StatelessWidget {
  const _CommunityBadge();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.sm,
      vertical: AppSpacing.xs,
    ),
    decoration: const BoxDecoration(
      color: AppColors.successSurface,
      borderRadius: AppRadii.pill,
    ),
    child: const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.circle, size: 9, color: AppColors.tertiary),
        SizedBox(width: 6),
        Flexible(
          child: Text(
            'Comunidad activa',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.tertiary,
              fontSize: 12.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    ),
  );
}

class _Highlights extends StatelessWidget {
  const _Highlights();

  @override
  Widget build(BuildContext context) => const Wrap(
    alignment: WrapAlignment.center,
    spacing: AppSpacing.xs,
    runSpacing: AppSpacing.xs,
    children: [
      _Highlight(
        glyph: NexoGlyph.verified,
        color: AppColors.vinylCyan,
        label: 'Creadores verificados',
      ),
      _Highlight(
        glyph: NexoGlyph.live,
        color: AppColors.vinylMagenta,
        label: 'En vivos interactivos',
      ),
      _Highlight(
        glyph: NexoGlyph.crown,
        color: AppColors.vinylLime,
        label: 'Membresías',
      ),
    ],
  );
}

/// Un sticker chico de vinilo: color, tinta y su troquel blanco.
class _Highlight extends StatelessWidget {
  const _Highlight({
    required this.glyph,
    required this.label,
    required this.color,
  });

  final NexoGlyph glyph;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(2),
    decoration: const BoxDecoration(
      color: AppColors.sticker,
      borderRadius: AppRadii.pill,
    ),
    child: Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 6,
      ),
      decoration: BoxDecoration(color: color, borderRadius: AppRadii.pill),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          NexoIcon(glyph, filled: true, color: AppColors.ink, size: 15),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.labelMedium?.copyWith(color: AppColors.ink),
            ),
          ),
        ],
      ),
    ),
  );
}

class _ContinueWith extends StatelessWidget {
  const _ContinueWith();

  @override
  Widget build(BuildContext context) => const Row(
    children: [
      Expanded(child: Divider()),
      Padding(
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        child: Text(
          'O CONTINÚA CON',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: AppColors.textTertiary,
            letterSpacing: .8,
          ),
        ),
      ),
      Expanded(child: Divider()),
    ],
  );
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.icon,
    required this.label,
    this.isApple = false,
  });

  final String icon;
  final String label;
  final bool isApple;

  /// Sin proveedores de identidad externos todavía: el botón se ve, porque
  /// el diseño lo tiene, pero apagado y diciendo por qué. Activo y sin hacer
  /// nada se leía como un login roto (SDD 0007, F11).
  @override
  Widget build(BuildContext context) => Tooltip(
    message: 'Ingreso con $label: muy pronto',
    child: OutlinedButton.icon(
      onPressed: null,
      icon: isApple
          ? const Icon(Icons.apple, color: AppColors.textTertiary)
          : Text(
              icon,
              style: const TextStyle(
                color: Color(0xFF4285F4),
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
      label: Text(label),
    ),
  );
}

void _showSignInSheet(BuildContext context) {
  // El estado del formulario es uno para todas las pantallas de acceso: sin
  // limpiarlo, la hoja abría con el error o el paso de otra.
  context.read<AuthCubit>().resetForm();
  unawaited(
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _SignInSheet(
        onForgotPassword: () => context.go(AppRoutes.passwordReset),
      ),
    ),
  );
}

/// La hoja de inicio de sesión. `StatefulWidget` porque es dueña de sus
/// controllers: creados en la función que abre la hoja, se liberaban en
/// `whenComplete` mientras la hoja todavía animaba su salida con ellos.
class _SignInSheet extends StatefulWidget {
  const _SignInSheet({required this.onForgotPassword});

  /// Navega desde el contexto que abrió la hoja, que sigue vivo cuando ésta
  /// ya se cerró.
  final VoidCallback onForgotPassword;

  @override
  State<_SignInSheet> createState() => _SignInSheetState();
}

class _SignInSheetState extends State<_SignInSheet> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  AuthInputIssue? _inputIssue;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  void _submit() {
    final issue = AuthInput.check(
      email: _email.text,
      password: _password.text,
    );
    setState(() => _inputIssue = issue);
    if (issue != null) return;
    unawaited(context.read<AuthCubit>().signIn(_email.text, _password.text));
  }

  @override
  Widget build(BuildContext context) => BlocListener<AuthCubit, AuthState>(
    listener: (context, state) {
      if (state is AuthAuthenticated && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    },
    child: BlocBuilder<AuthCubit, AuthState>(
      builder: (context, state) {
        final form = state is AuthUnauthenticated ? state : null;
        final busy = form?.isBusy ?? false;
        return Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Iniciar sesión',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              if (Environment.authSourceMode == AuthSourceMode.mock) ...[
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Modo demo: un correo desconocido entra como Elena. Para otro '
                  'rol usa ${DemoAccounts.operator.email} o '
                  '${DemoAccounts.moderator.email}.',
                  key: const Key('sign-in-demo-hint'),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              TextField(
                key: const Key('sheet-email'),
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              const SizedBox(height: AppSpacing.sm),
              _PasswordField(
                fieldKey: const Key('sheet-password'),
                controller: _password,
                label: 'Contraseña',
              ),
              const SizedBox(height: AppSpacing.md),
              if (_inputIssue != null) ...[
                _AuthError(input: _inputIssue),
                const SizedBox(height: AppSpacing.sm),
              ] else if (form?.failure != null) ...[
                _AuthError(reason: form!.failure),
                const SizedBox(height: AppSpacing.sm),
              ],
              FilledButton(
                key: const Key('sheet-submit'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(AppSizes.buttonHeight),
                ),
                onPressed: busy ? null : _submit,
                child: busy
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Continuar'),
              ),
              // La única entrada al reset. Estaba en una variante de
              // `AuthForm` que ninguna ruta construye, así que el flujo
              // existía, conectado al servidor, y nadie podía llegar a él.
              TextButton(
                key: const Key('sheet-forgot-password'),
                onPressed: busy
                    ? null
                    : () {
                        Navigator.pop(context);
                        widget.onForgotPassword();
                      },
                child: const Text('Olvidé mi contraseña'),
              ),
            ],
          ),
        );
      },
    ),
  );
}

/// Un campo de contraseña con el ojo para mostrarla. Escribir a ciegas una
/// contraseña nueva, dos veces, es la forma de crear una que no se recuerda.
class _PasswordField extends StatefulWidget {
  const _PasswordField({
    required this.fieldKey,
    required this.controller,
    required this.label,
  });

  final Key fieldKey;
  final TextEditingController controller;
  final String label;

  @override
  State<_PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<_PasswordField> {
  var _obscured = true;

  @override
  Widget build(BuildContext context) => TextField(
    key: widget.fieldKey,
    controller: widget.controller,
    obscureText: _obscured,
    decoration: InputDecoration(
      labelText: widget.label,
      // Sin glifo propio para el ojo: va el de Material.
      suffixIcon: IconButton(
        key: ValueKey('${widget.fieldKey}-toggle'),
        tooltip: _obscured ? 'Mostrar contraseña' : 'Ocultar contraseña',
        onPressed: () => setState(() => _obscured = !_obscured),
        icon: Icon(
          _obscured ? Icons.visibility_outlined : Icons.visibility_off_outlined,
          color: AppColors.textSecondary,
        ),
      ),
    ),
  );
}

class AuthForm extends StatefulWidget {
  const AuthForm({super.key, this.signUp = false, this.resetPassword = false});

  final bool signUp;
  final bool resetPassword;

  @override
  State<AuthForm> createState() => _AuthFormState();
}

class _AuthFormState extends State<AuthForm> {
  final email = TextEditingController();
  final password = TextEditingController();
  final passwordConfirmation = TextEditingController();
  final verificationCode = TextEditingController();
  bool _resetComplete = false;

  /// La persona pidió otro código: se le confirma que salió, porque un
  /// botón que no da señal se toca dos veces y manda dos correos.
  bool _resent = false;

  /// Lo que el formulario rechazó antes de llamar al servidor.
  AuthInputIssue? _inputIssue;

  @override
  void initState() {
    super.initState();
    // Cada pantalla de acceso arranca de cero: el error o el paso que quedó
    // de otra no son de ésta.
    context.read<AuthCubit>().resetForm();
  }

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    passwordConfirmation.dispose();
    verificationCode.dispose();
    super.dispose();
  }

  /// La regla de cada paso: qué campos pide y cuáles se confirman.
  AuthInputIssue? _check(AuthOperation operation) {
    final awaitingCode =
        operation == AuthOperation.awaitingRegistrationCode ||
        operation == AuthOperation.awaitingResetCode;
    if (widget.resetPassword) {
      return AuthInput.check(
        email: email.text,
        code: awaitingCode ? verificationCode.text : null,
        password: awaitingCode ? password.text : null,
        confirmation: awaitingCode ? passwordConfirmation.text : null,
      );
    }
    if (widget.signUp) {
      // La contraseña viaja recién con el código: pedir el código no la
      // necesita, así que se valida en ese paso.
      return AuthInput.check(
        email: email.text,
        code: awaitingCode ? verificationCode.text : null,
        password: awaitingCode ? password.text : null,
        confirmation: awaitingCode ? passwordConfirmation.text : null,
      );
    }
    return AuthInput.check(email: email.text, password: password.text);
  }

  Future<void> _submit(AuthOperation operation) async {
    final auth = context.read<AuthCubit>();
    final issue = _check(operation);
    setState(() {
      _resent = false;
      _inputIssue = issue;
    });
    if (issue != null) return;
    if (widget.resetPassword) {
      if (operation == AuthOperation.awaitingResetCode) {
        await auth.finishPasswordReset(
          verificationCode: verificationCode.text,
          newPassword: password.text,
        );
        if (mounted &&
            auth.state is AuthUnauthenticated &&
            (auth.state as AuthUnauthenticated).failure == null) {
          setState(() => _resetComplete = true);
        }
      } else {
        await auth.startPasswordReset(email.text);
      }
    } else if (widget.signUp) {
      if (operation == AuthOperation.awaitingRegistrationCode) {
        await auth.finishRegistration(
          verificationCode: verificationCode.text,
          password: password.text,
        );
      } else {
        await auth.startRegistration(email.text);
      }
    } else {
      await auth.signIn(email.text, password.text);
    }
  }

  Future<void> _resend(bool isReset) async {
    final auth = context.read<AuthCubit>();
    verificationCode.clear();
    setState(() => _inputIssue = null);
    await (isReset
        ? auth.startPasswordReset(email.text)
        : auth.startRegistration(email.text));
    if (mounted) setState(() => _resent = true);
  }

  @override
  Widget build(BuildContext context) => BlocBuilder<AuthCubit, AuthState>(
    builder: (context, state) {
      final authState = state is AuthUnauthenticated ? state : null;
      final operation = authState?.operation ?? AuthOperation.idle;
      final awaitingCode =
          operation == AuthOperation.awaitingRegistrationCode ||
          operation == AuthOperation.awaitingResetCode;
      final busy = authState?.isBusy ?? false;
      final isReset = widget.resetPassword;
      // En el reset la contraseña es la nueva, y sólo se pide junto con el
      // código: en el primer paso era un campo que nadie leía.
      final showPassword = !isReset || awaitingCode;
      final confirmsPassword = widget.signUp || (isReset && awaitingCode);
      final title = isReset
          ? awaitingCode
                ? 'Confirma el código.'
                : 'Recupera tu acceso.'
          : widget.signUp
          ? awaitingCode
                ? 'Confirma tu correo.'
                : 'Crea tu comunidad.'
          : 'Encuentra tu comunidad.';
      return Scaffold(
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.all(AppSpacing.lg),
                children: [
                  Center(
                    child: MascotIllustration(
                      isReset ? NexoMascot.lock : NexoMascot.wave,
                      size: 132,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    title,
                    style: Theme.of(context).textTheme.displaySmall,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  TextField(
                    key: const Key('auth-email'),
                    controller: email,
                    // El código es de ese correo: cambiarlo a mitad de camino
                    // verificaría un pedido con otra dirección.
                    readOnly: awaitingCode,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  if (awaitingCode) ...[
                    Text(
                      key: const Key('auth-code-hint'),
                      'Te enviamos un código de 8 números a '
                      '${email.text.trim()}. Puede tardar un minuto: '
                      'revisa también Spam o Promociones.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    if (_resent && authState?.failure == null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        key: const Key('auth-code-resent'),
                        'Listo: te mandamos un código nuevo.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                    const SizedBox(height: AppSpacing.sm),
                    TextField(
                      key: const Key('auth-verification-code'),
                      controller: verificationCode,
                      keyboardType: TextInputType.number,
                      autofillHints: const [AutofillHints.oneTimeCode],
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(8),
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Código de verificación',
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                  if (showPassword) ...[
                    _PasswordField(
                      fieldKey: const Key('auth-password'),
                      controller: password,
                      label: isReset ? 'Nueva contraseña' : 'Contraseña',
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                  if (confirmsPassword) ...[
                    _PasswordField(
                      fieldKey: const Key('auth-password-confirm'),
                      controller: passwordConfirmation,
                      label: isReset
                          ? 'Repite la nueva contraseña'
                          : 'Repite la contraseña',
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                  const SizedBox(height: AppSpacing.xs),
                  // Lo que rechazó el formulario va primero: es lo último
                  // que la persona hizo, y el error del servidor es anterior.
                  if (_inputIssue != null) ...[
                    _AuthError(input: _inputIssue),
                    const SizedBox(height: AppSpacing.sm),
                  ] else if (authState?.failure != null) ...[
                    _AuthError(reason: authState!.failure),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                  if (_resetComplete) ...[
                    const Text(
                      'Contraseña actualizada. Ya puedes iniciar sesión.',
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                  FilledButton(
                    key: const Key('auth-submit'),
                    onPressed: busy ? null : () => _submit(operation),
                    child: busy
                        ? const SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            awaitingCode
                                ? (isReset
                                      ? 'Actualizar contraseña'
                                      : 'Verificar y crear cuenta')
                                : (isReset
                                      ? 'Enviar código'
                                      : widget.signUp
                                      ? 'Crear cuenta'
                                      : 'Iniciar sesión'),
                          ),
                  ),
                  if ((widget.signUp && awaitingCode) ||
                      (isReset && awaitingCode))
                    TextButton(
                      key: const Key('auth-resend-code'),
                      onPressed: busy ? null : () => _resend(isReset),
                      child: const Text('Solicitar un código nuevo'),
                    ),
                  if (!widget.signUp && !isReset)
                    TextButton(
                      onPressed: () => context.go(AppRoutes.passwordReset),
                      child: const Text('Olvidé mi contraseña'),
                    ),
                  TextButton(
                    onPressed: () => _exploreAsGuest(context),
                    child: const Text('Explora como invitado'),
                  ),
                  TextButton(
                    onPressed: () => context.go(
                      isReset || widget.signUp
                          ? AppRoutes.signIn
                          : AppRoutes.signUp,
                    ),
                    child: Text(
                      isReset || widget.signUp
                          ? 'Ya tengo cuenta'
                          : 'Crear una cuenta',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

/// Un error del formulario: del servidor ([reason]) o de lo escrito
/// ([input]). Uno de los dos.
class _AuthError extends StatelessWidget {
  const _AuthError({this.reason, this.input})
    : assert((reason == null) != (input == null));

  final AuthFailureReason? reason;
  final AuthInputIssue? input;

  @override
  Widget build(BuildContext context) => Container(
    key: const Key('auth-error'),
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.md,
      vertical: AppSpacing.sm,
    ),
    decoration: BoxDecoration(
      color: AppColors.error.withValues(alpha: .16),
      borderRadius: AppRadii.medium,
    ),
    child: Text(_message, style: Theme.of(context).textTheme.bodyMedium),
  );

  String get _message => switch (input) {
    AuthInputIssue.invalidEmail => 'Escribe un correo válido.',
    AuthInputIssue.emptyPassword => 'Escribe tu contraseña.',
    AuthInputIssue.passwordMismatch => 'Las contraseñas no coinciden.',
    AuthInputIssue.invalidCode =>
      'El código tiene 8 números. Revísalo en el correo.',
    null => _serverMessage(reason!),
  };

  static String _serverMessage(AuthFailureReason reason) => switch (reason) {
    AuthFailureReason.invalidCredentials =>
      'El correo o la contraseña no son correctos.',
    AuthFailureReason.invalidCode =>
      'El código no es válido. Revísalo e inténtalo de nuevo.',
    AuthFailureReason.expiredCode => 'El código venció. Solicita uno nuevo.',
    AuthFailureReason.tooManyAttempts =>
      'Has hecho muchos intentos. Espera un momento e inténtalo otra vez.',
    AuthFailureReason.passwordPolicy =>
      'La contraseña no cumple la política del servidor.',
    AuthFailureReason.storage =>
      'No pudimos guardar la sesión de forma segura.',
    AuthFailureReason.network =>
      'No pudimos conectar. Revisa tu conexión y reintenta.',
    AuthFailureReason.unavailable =>
      'No pudimos completar la operación. Inténtalo nuevamente.',
  };
}
