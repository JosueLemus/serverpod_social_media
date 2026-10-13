import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_social/app/theme/app_theme.dart';
import 'package:nexo_social/core/errors/failures.dart';
import 'package:nexo_social/features/auth/domain/entities/app_user.dart';
import 'package:nexo_social/features/auth/domain/repositories/auth_repository.dart';
import 'package:nexo_social/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:nexo_social/features/auth/presentation/pages/auth_pages.dart';
import 'package:nexo_social/features/auth/presentation/pages/suspended_page.dart';
import 'package:nexo_social/features/moderation/domain/entities/moderation_action.dart';

const _user = AppUser(
  id: 'u-1',
  username: 'nueva',
  name: 'Nueva',
  role: UserRole.user,
);

/// Un servidor de acceso a mano: cuenta los pedidos, rechaza cuando se le
/// pide y puede dejar un inicio de sesión colgado.
class _AuthServer implements AuthRepository {
  int signIns = 0;
  int registrations = 0;
  int resets = 0;
  Object? signInError;
  Completer<void>? signInGate;
  ModerationReason? reason;

  @override
  Future<AppUser?> currentUser() async => null;

  @override
  Stream<AppUser?> watchSession() => const Stream.empty();

  @override
  Future<AppUser> signIn({
    required String email,
    required String password,
  }) async {
    signIns++;
    await signInGate?.future;
    final error = signInError;
    if (error != null) throw error;
    return _user;
  }

  @override
  Future<EmailVerificationRequest> startRegistration({
    required String email,
  }) async {
    registrations++;
    return EmailVerificationRequest('registration-$registrations');
  }

  @override
  Future<AppUser> finishRegistration({
    required EmailVerificationRequest request,
    required String verificationCode,
    required String password,
  }) async => _user;

  @override
  Future<EmailVerificationRequest> startPasswordReset({
    required String email,
  }) async {
    resets++;
    return EmailVerificationRequest('reset-$resets');
  }

  @override
  Future<void> finishPasswordReset({
    required EmailVerificationRequest request,
    required String verificationCode,
    required String newPassword,
  }) async {}

  @override
  Future<void> signOut() async {}

  @override
  Future<ModerationReason?> sanctionReason(String accountId) async => reason;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _AuthServer server;
  late AuthCubit cubit;

  setUp(() {
    server = _AuthServer();
    cubit = AuthCubit(server);
  });
  tearDown(() => cubit.close());

  group('AuthCubit.resetForm', () {
    test('borra el error y el paso que dejó otra pantalla', () async {
      await cubit.restore();
      server.signInError = const AuthenticationFailure(
        AuthFailureReason.invalidCredentials,
      );
      await cubit.signIn('a@b.co', 'x');
      expect(
        (cubit.state as AuthUnauthenticated).failure,
        AuthFailureReason.invalidCredentials,
      );

      cubit.resetForm();

      expect(cubit.state, const AuthUnauthenticated());
    });

    test('descarta el pedido de registro a medias', () async {
      await cubit.restore();
      await cubit.startRegistration('nueva@example.com');

      cubit.resetForm();
      expect(cubit.state, const AuthUnauthenticated());

      // Sin pedido, terminar el registro no puede usar el de antes.
      await cubit.finishRegistration(
        verificationCode: '12345678',
        password: 'Secreta-123',
      );
      expect(
        cubit.state,
        const AuthUnauthenticated(failure: AuthFailureReason.invalidCode),
      );
    });

    test('no toca una sesión activa', () async {
      await cubit.signIn('a@b.co', 'x');
      final signedIn = cubit.state;

      cubit.resetForm();

      expect(cubit.state, signedIn);
      expect(cubit.state, isA<AuthAuthenticated>());
    });

    test('no descarta un inicio de sesión en vuelo', () async {
      await cubit.restore();
      server.signInGate = Completer<void>();
      final signingIn = cubit.signIn('a@b.co', 'x');

      cubit.resetForm();
      server.signInGate!.complete();
      await signingIn;

      expect(cubit.state, const AuthAuthenticated(_user));
    });
  });

  group('la sanción que llega en el fallo', () {
    test('una cuenta dada de baja no lee que su sanción termina', () async {
      server
        ..signInError = const AccountSuspendedFailure(
          'signIn',
          sanction: AccountSanction.banned,
          accountId: 'u-1',
        )
        ..reason = ModerationReason.spam;

      await cubit.signIn('a@b.co', 'x');

      expect(
        cubit.state,
        const AuthSuspended(
          status: AccountStatus.banned,
          reason: ModerationReason.spam,
        ),
      );
    });

    test('sin sanción conocida no se asume suspensión', () async {
      server.signInError = const AccountSuspendedFailure('server');

      await cubit.signIn('a@b.co', 'x');

      expect(cubit.state, const AuthSuspended(status: null));
    });
  });

  group('AuthInput', () {
    test('valida correo, contraseña, confirmación y código', () {
      expect(
        AuthInput.check(email: 'sin-arroba', password: 'x'),
        AuthInputIssue.invalidEmail,
      );
      expect(
        AuthInput.check(email: 'a@b.co', password: ''),
        AuthInputIssue.emptyPassword,
      );
      expect(
        AuthInput.check(email: 'a@b.co', password: 'x', confirmation: 'y'),
        AuthInputIssue.passwordMismatch,
      );
      expect(
        AuthInput.check(email: 'a@b.co', code: '1234'),
        AuthInputIssue.invalidCode,
      );
      expect(
        AuthInput.check(
          email: ' a@b.co ',
          password: 'x',
          confirmation: 'x',
          code: '12345678',
        ),
        isNull,
      );
    });
  });

  group('el formulario', () {
    Future<void> pump(WidgetTester tester, Widget page) async {
      tester.view.physicalSize = const Size(390, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        BlocProvider.value(
          value: cubit,
          child: MaterialApp(theme: AppTheme.nexo, home: page),
        ),
      );
      await tester.pump();
    }

    Future<void> submit(WidgetTester tester) async {
      await tester.tap(find.byKey(const Key('auth-submit')));
      await tester.pump();
      await tester.pump();
    }

    /// El estado del formulario es uno para todas las pantallas: un error
    /// del login aparecía en "Recupera tu acceso".
    testWidgets('el error de otra pantalla no aparece en ésta', (tester) async {
      await cubit.restore();
      server.signInError = const AuthenticationFailure(
        AuthFailureReason.invalidCredentials,
      );
      await cubit.signIn('a@b.co', 'x');

      await pump(tester, const AuthForm(resetPassword: true));

      expect(find.text('Recupera tu acceso.'), findsOneWidget);
      expect(find.byKey(const Key('auth-error')), findsNothing);
    });

    testWidgets('el registro no abre en "Confirma tu correo"', (tester) async {
      await cubit.restore();
      await cubit.startPasswordReset('otra@example.com');

      await pump(tester, const AuthForm(signUp: true));

      expect(find.text('Crea tu comunidad.'), findsOneWidget);
      final email = tester.widget<TextField>(
        find.byKey(const Key('auth-email')),
      );
      expect(email.readOnly, isFalse);
    });

    testWidgets('el reset pide la nueva contraseña sólo junto al código', (
      tester,
    ) async {
      await cubit.restore();
      await pump(tester, const AuthForm(resetPassword: true));

      expect(find.byKey(const Key('auth-password')), findsNothing);
      expect(find.text('Contraseña'), findsNothing);

      await tester.enterText(
        find.byKey(const Key('auth-email')),
        'nueva@example.com',
      );
      await submit(tester);

      expect(find.text('Nueva contraseña'), findsOneWidget);
      expect(find.byKey(const Key('auth-password-confirm')), findsOneWidget);
    });

    testWidgets('registrarse pide confirmar la contraseña', (tester) async {
      await cubit.restore();
      await pump(tester, const AuthForm(signUp: true));
      await tester.enterText(
        find.byKey(const Key('auth-email')),
        'nueva@example.com',
      );
      await submit(tester);

      await tester.enterText(
        find.byKey(const Key('auth-verification-code')),
        '12345678',
      );
      await tester.enterText(find.byKey(const Key('auth-password')), 'Una-1');
      await tester.enterText(
        find.byKey(const Key('auth-password-confirm')),
        'Otra-2',
      );
      await submit(tester);

      expect(find.text('Las contraseñas no coinciden.'), findsOneWidget);
      expect(cubit.state, isA<AuthUnauthenticated>());
    });

    testWidgets('no llama al servidor con un correo o un código inválidos', (
      tester,
    ) async {
      await cubit.restore();
      await pump(tester, const AuthForm());

      await tester.enterText(find.byKey(const Key('auth-email')), 'sin-arroba');
      await tester.enterText(find.byKey(const Key('auth-password')), 'x');
      await submit(tester);
      expect(find.text('Escribe un correo válido.'), findsOneWidget);

      await tester.enterText(find.byKey(const Key('auth-email')), 'a@b.co');
      await tester.enterText(find.byKey(const Key('auth-password')), '');
      await submit(tester);
      expect(find.text('Escribe tu contraseña.'), findsOneWidget);
      expect(server.signIns, 0);
    });

    testWidgets('el ojo muestra y oculta la contraseña', (tester) async {
      await cubit.restore();
      await pump(tester, const AuthForm());
      TextField field() =>
          tester.widget<TextField>(find.byKey(const Key('auth-password')));

      expect(field().obscureText, isTrue);
      await tester.tap(find.byTooltip('Mostrar contraseña'));
      await tester.pump();
      expect(field().obscureText, isFalse);
    });
  });

  group('SuspendedPage', () {
    Future<void> pumpWith(WidgetTester tester, AuthSuspended state) async {
      final suspended = _SuspendedCubit(state);
      addTearDown(suspended.close);
      await tester.pumpWidget(
        BlocProvider<AuthCubit>.value(
          value: suspended,
          child: MaterialApp(theme: AppTheme.nexo, home: const SuspendedPage()),
        ),
      );
      await tester.pump(const Duration(seconds: 1));
    }

    testWidgets('una baja se lee definitiva', (tester) async {
      await pumpWith(
        tester,
        const AuthSuspended(
          status: AccountStatus.banned,
          reason: ModerationReason.spam,
        ),
      );

      expect(find.text('Tu cuenta fue dada de baja'), findsOneWidget);
      expect(find.textContaining('permanente'), findsOneWidget);
      expect(find.textContaining('Mientras dure'), findsNothing);
    });

    testWidgets('sin sanción conocida no promete que termina', (tester) async {
      await pumpWith(tester, const AuthSuspended(status: null));

      expect(find.text('Tu cuenta no está activa'), findsOneWidget);
      expect(find.textContaining('Mientras dure'), findsNothing);
    });
  });
}

/// Un [AuthCubit] parado en un estado, para dibujar la pantalla de
/// suspensión sin recorrer el flujo.
class _SuspendedCubit extends AuthCubit {
  _SuspendedCubit(AuthSuspended state) : super(_AuthServer()) {
    emit(state);
  }
}
