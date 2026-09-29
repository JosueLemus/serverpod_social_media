import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/app_tokens.dart';
import '../../../../core/animations/app_motion.dart';
import '../../../../core/constants/environment.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/mock/demo_accounts.dart';
import '../../../../core/widgets/nexo_logo.dart';
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
            duration: const Duration(milliseconds: 650),
            child: const NexoLogo(size: 86),
          ),
          const SizedBox(height: AppSpacing.lg),
          FadeInUp(
            delay: const Duration(milliseconds: 260),
            child: const CircularProgressIndicator(),
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
              FadeInDown(
                duration: AppMotion.enterDuration,
                child: const Center(child: NexoLogo(size: 116)),
              ),
              const SizedBox(height: AppSpacing.lg),
              Enter(
                index: 1,
                child: Text(
                  'Encuentra tu comunidad.',
                  style: Theme.of(
                    context,
                  ).textTheme.displaySmall?.copyWith(fontSize: 32),
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
                  icon: const Icon(Icons.arrow_forward_rounded),
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
              const EnterStatic(index: 6, child: DemoAccountButton()),
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
              const Text(
                'Al continuar, confirmas que aceptas nuestros Términos de Servicio y nuestra Política de Privacidad.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  height: 1.35,
                  fontSize: 12,
                ),
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
/// vacío, y esa es la razón más común para no crearla.
class _SocialProof extends StatelessWidget {
  const _SocialProof();

  static const _names = ['Elena', 'Carlos', 'Lucía', 'Marcos'];

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(AppSpacing.sm),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: AppRadii.medium,
      border: Border.all(color: AppColors.border),
    ),
    child: Row(
      children: [
        SizedBox(
          width: 28 + 17.0 * (_names.length - 1),
          height: 30,
          child: Stack(
            children: [
              for (final (index, name) in _names.indexed)
                Positioned(
                  left: index * 17,
                  child: Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.fromBorderSide(
                        BorderSide(color: AppColors.surface, width: 2),
                      ),
                    ),
                    child: UserAvatar(name: name, size: 26),
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
                'Más de 24,000 creadores',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                'Compartiendo transmisiones hoy',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        const Icon(
          Icons.trending_up_rounded,
          size: 19,
          color: AppColors.tertiary,
        ),
      ],
    ),
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
      color: AppColors.primarySurface,
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
                    ? AppColors.surface
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
                      ? AppColors.textOnBrandSurface
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
      color: AppColors.primarySurface,
      borderRadius: AppRadii.large,
    ),
    child: const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.circle, size: 9, color: AppColors.tertiary),
        SizedBox(width: 6),
        Flexible(
          child: Text(
            'COMUNIDAD ACTIVA',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.tertiary,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
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
        icon: Icons.verified_rounded,
        color: AppColors.primary,
        label: 'Creadores verificados',
      ),
      _Highlight(
        icon: Icons.bolt_rounded,
        color: AppColors.warning,
        label: 'En vivos interactivos',
      ),
      _Highlight(
        icon: Icons.diamond_outlined,
        color: AppColors.tertiary,
        label: 'Membresías',
      ),
    ],
  );
}

class _Highlight extends StatelessWidget {
  const _Highlight({
    required this.icon,
    required this.label,
    this.color = AppColors.primary,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.sm,
      vertical: AppSpacing.xs,
    ),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: AppRadii.pill,
      border: Border.all(color: AppColors.border),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
          ),
        ),
      ],
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
            color: AppColors.textSecondary,
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

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: () {},
    icon: isApple
        ? const Icon(Icons.apple, color: AppColors.textPrimary)
        : Text(
            icon,
            style: const TextStyle(
              color: Color(0xFF4285F4),
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
    label: Text(label),
  );
}

void _showSignInSheet(BuildContext context) {
  // Captured while the context is alive. The sheet outlives the widget that
  // opened it, so reading the cubit inside the callback can hit a deactivated
  // element.
  final auth = context.read<AuthCubit>();
  final email = TextEditingController();
  final password = TextEditingController();
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) => BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated && Navigator.canPop(sheetContext)) {
          Navigator.pop(sheetContext);
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
              MediaQuery.viewInsetsOf(sheetContext).bottom + AppSpacing.lg,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Iniciar sesión',
                  style: Theme.of(sheetContext).textTheme.titleLarge,
                ),
                if (Environment.authSourceMode == AuthSourceMode.mock) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Modo demo: un correo desconocido entra como Elena. Para otro '
                    'rol usa ${DemoAccounts.operator.email} o '
                    '${DemoAccounts.moderator.email}.',
                    key: const Key('sign-in-demo-hint'),
                    textAlign: TextAlign.center,
                    style: Theme.of(sheetContext).textTheme.bodySmall,
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                TextField(
                  key: const Key('sheet-email'),
                  controller: email,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: password,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'Contraseña'),
                ),
                const SizedBox(height: AppSpacing.md),
                if (form?.failure != null) ...[
                  _AuthError(reason: form!.failure!),
                  const SizedBox(height: AppSpacing.sm),
                ],
                FilledButton(
                  onPressed: busy
                      ? null
                      : () => auth.signIn(email.text, password.text),
                  child: busy
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Continuar'),
                ),
              ],
            ),
          );
        },
      ),
    ),
  ).whenComplete(() {
    email.dispose();
    password.dispose();
  });
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
  final verificationCode = TextEditingController();
  bool _resetComplete = false;

  @override
  void dispose() {
    email.dispose();
    password.dispose();
    verificationCode.dispose();
    super.dispose();
  }

  Future<void> _submit(AuthOperation operation) async {
    final auth = context.read<AuthCubit>();
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
                  const Icon(
                    Icons.hub_outlined,
                    color: AppColors.primary,
                    size: 52,
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
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  if (awaitingCode) ...[
                    TextField(
                      key: const Key('auth-verification-code'),
                      controller: verificationCode,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Código de verificación',
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                  TextField(
                    key: const Key('auth-password'),
                    controller: password,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Contraseña'),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  if (authState?.failure != null) ...[
                    _AuthError(reason: authState!.failure!),
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
                      onPressed: busy
                          ? null
                          : () => isReset
                                ? context.read<AuthCubit>().startPasswordReset(
                                    email.text,
                                  )
                                : context.read<AuthCubit>().startRegistration(
                                    email.text,
                                  ),
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

class _AuthError extends StatelessWidget {
  const _AuthError({required this.reason});

  final AuthFailureReason reason;

  @override
  Widget build(BuildContext context) => Text(switch (reason) {
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
  }, style: const TextStyle(color: AppColors.error));
}
