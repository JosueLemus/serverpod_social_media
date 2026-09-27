import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:animate_do/animate_do.dart';
import '../../../../app/di/injection.dart';
import '../../../../app/theme/app_tokens.dart';
import '../../../../core/widgets/nexo_logo.dart';
import '../bloc/auth_cubit.dart';

class SplashPage extends StatelessWidget {
  const SplashPage({super.key});
  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => sl<AuthCubit>()..restore(),
    child: BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) context.go('/');
        if (state is AuthUnauthenticated) context.go('/sign-in');
      },
      child: Scaffold(
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
      ),
    ),
  );
}

class SignInPage extends StatelessWidget {
  const SignInPage({super.key});
  @override
  Widget build(BuildContext context) =>
      BlocProvider(create: (_) => sl<AuthCubit>(), child: const _WelcomePage());
}

class SignUpPage extends StatelessWidget {
  const SignUpPage({super.key});
  @override
  Widget build(BuildContext context) => const AuthForm(signUp: true);
}

class _WelcomePage extends StatelessWidget {
  const _WelcomePage();

  @override
  Widget build(BuildContext context) => BlocListener<AuthCubit, AuthState>(
    listener: (context, state) {
      if (state is AuthAuthenticated) context.go('/');
    },
    child: Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                children: [
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: _CommunityBadge(),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  FadeInDown(
                    duration: const Duration(milliseconds: 600),
                    child: const Center(child: NexoLogo(size: 116)),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  FadeInUp(
                    delay: const Duration(milliseconds: 120),
                    child: Text(
                      'Encuentra tu comunidad.',
                      style: Theme.of(
                        context,
                      ).textTheme.displaySmall?.copyWith(fontSize: 32),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  FadeInUp(
                    delay: const Duration(milliseconds: 220),
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
                  FadeInUp(
                    delay: const Duration(milliseconds: 310),
                    child: const _Highlights(),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  FadeInUp(
                    delay: const Duration(milliseconds: 390),
                    child: FilledButton.icon(
                      onPressed: () => context.go('/sign-up'),
                      iconAlignment: IconAlignment.end,
                      icon: const Icon(Icons.arrow_forward_rounded),
                      label: const Text('Crear cuenta'),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  FadeInUp(
                    delay: const Duration(milliseconds: 460),
                    child: OutlinedButton(
                      onPressed: () => _showSignInSheet(context),
                      child: const Text('Iniciar sesión'),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const _ContinueWith(),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: const [
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
                  const SizedBox(height: AppSpacing.md),
                  TextButton(
                    onPressed: () => context.read<AuthCubit>().guest(),
                    child: const Text('Explora como invitado sin registrarte'),
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
      ),
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
        Icon(Icons.circle, size: 9, color: AppColors.success),
        SizedBox(width: 6),
        Text(
          'COMUNIDAD ACTIVA',
          style: TextStyle(
            color: AppColors.success,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
          ),
        ),
      ],
    ),
  );
}

class _Highlights extends StatelessWidget {
  const _Highlights();
  @override
  Widget build(BuildContext context) => Wrap(
    alignment: WrapAlignment.center,
    spacing: AppSpacing.xs,
    runSpacing: AppSpacing.xs,
    children: const [
      _Highlight(icon: Icons.verified_outlined, label: 'Creadores verificados'),
      _Highlight(icon: Icons.bolt_rounded, label: 'En vivos interactivos'),
      _Highlight(icon: Icons.workspace_premium_outlined, label: 'Membresías'),
    ],
  );
}

class _Highlight extends StatelessWidget {
  const _Highlight({required this.icon, required this.label});
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(
      horizontal: AppSpacing.sm,
      vertical: AppSpacing.xs,
    ),
    decoration: const BoxDecoration(
      color: AppColors.surface,
      borderRadius: AppRadii.large,
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppColors.primary, size: 16),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
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
  final email = TextEditingController();
  final password = TextEditingController();
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) => Padding(
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
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: email,
            decoration: const InputDecoration(labelText: 'Email'),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: password,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Contraseña'),
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton(
            onPressed: () {
              Navigator.pop(sheetContext);
              context.read<AuthCubit>().signIn(email.text, password.text);
            },
            child: const Text('Continuar'),
          ),
        ],
      ),
    ),
  ).whenComplete(() {
    email.dispose();
    password.dispose();
  });
}

class AuthForm extends StatefulWidget {
  const AuthForm({super.key, required this.signUp});
  final bool signUp;
  @override
  State<AuthForm> createState() => _AuthFormState();
}

class _AuthFormState extends State<AuthForm> {
  final email = TextEditingController();
  final password = TextEditingController();
  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AuthCubit>(),
      child: Builder(
        builder: (context) {
          return Scaffold(
            body: SafeArea(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        const Icon(
                          Icons.hub_outlined,
                          color: AppColors.primary,
                          size: 52,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          widget.signUp
                              ? 'Crea tu comunidad.'
                              : 'Encuentra tu comunidad.',
                          style: Theme.of(context).textTheme.displaySmall,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        TextField(
                          key: const Key('auth-email'),
                          controller: email,
                          decoration: const InputDecoration(labelText: 'Email'),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        TextField(
                          controller: password,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Contraseña',
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        BlocListener<AuthCubit, AuthState>(
                          listener: (context, state) {
                            if (state is AuthAuthenticated) context.go('/');
                          },
                          child: FilledButton(
                            key: const Key('auth-submit'),
                            onPressed: () => widget.signUp
                                ? context.read<AuthCubit>().signUp(
                                    name: 'Creador Nexo',
                                    username: 'creador',
                                    email: email.text,
                                    password: password.text,
                                  )
                                : context.read<AuthCubit>().signIn(
                                    email.text,
                                    password.text,
                                  ),
                            child: Text(
                              widget.signUp ? 'Crear cuenta' : 'Iniciar sesión',
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.read<AuthCubit>().guest(),
                          child: const Text('Explora como invitado'),
                        ),
                        TextButton(
                          onPressed: () => context.go(
                            widget.signUp ? '/sign-in' : '/sign-up',
                          ),
                          child: Text(
                            widget.signUp
                                ? 'Ya tengo cuenta'
                                : 'Crear una cuenta',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
