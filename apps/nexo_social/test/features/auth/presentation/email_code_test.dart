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

/// El servidor de verdad, en chico: un código correcto, un pedido que se
/// puede reintentar y la cuenta de pedidos que salieron.
class _CodeServer implements AuthRepository {
  static const code = '12345678';
  int registrations = 0;
  int resets = 0;

  @override
  Future<AppUser?> currentUser() async => null;

  @override
  Stream<AppUser?> watchSession() => const Stream.empty();

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
  }) async {
    if (verificationCode != code) {
      throw const AuthenticationFailure(AuthFailureReason.invalidCode);
    }
    return const AppUser(
      id: 'u-1',
      username: 'nueva',
      name: 'Nueva',
      role: UserRole.user,
    );
  }

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
  }) async {
    if (verificationCode != code) {
      throw const AuthenticationFailure(AuthFailureReason.invalidCode);
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('un código mal tipeado', () {
    late _CodeServer server;
    late AuthCubit cubit;

    setUp(() {
      server = _CodeServer();
      cubit = AuthCubit(server);
    });
    tearDown(() => cubit.close());

    test('en el registro deja reintentar sin pedir otro código', () async {
      await cubit.startRegistration('nueva@example.com');
      await cubit.finishRegistration(
        verificationCode: '11111111',
        password: 'Secreta-123',
      );

      expect(
        cubit.state,
        const AuthUnauthenticated(
          operation: AuthOperation.awaitingRegistrationCode,
          failure: AuthFailureReason.invalidCode,
        ),
      );

      await cubit.finishRegistration(
        verificationCode: '12345678',
        password: 'Secreta-123',
      );
      expect(cubit.state, isA<AuthAuthenticated>());
      expect(server.registrations, 1);
    });

    test('al restablecer la contraseña también deja reintentar', () async {
      await cubit.startPasswordReset('nueva@example.com');
      await cubit.finishPasswordReset(
        verificationCode: '11111111',
        newPassword: 'Secreta-123',
      );

      expect(
        cubit.state,
        const AuthUnauthenticated(
          operation: AuthOperation.awaitingResetCode,
          failure: AuthFailureReason.invalidCode,
        ),
      );
      expect(server.resets, 1);
    });
  });

  group('el formulario del código', () {
    late _CodeServer server;
    late AuthCubit cubit;

    setUp(() {
      server = _CodeServer();
      cubit = AuthCubit(server);
    });
    tearDown(() => cubit.close());

    Future<void> pumpSignUp(WidgetTester tester) async {
      tester.view.physicalSize = const Size(390, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        BlocProvider.value(
          value: cubit,
          child: MaterialApp(
            theme: AppTheme.nexo,
            home: const AuthForm(signUp: true),
          ),
        ),
      );
      await tester.enterText(
        find.byKey(const Key('auth-email')),
        'nueva@example.com ',
      );
      await tester.tap(find.byKey(const Key('auth-submit')));
      await tester.pump();
      await tester.pump();
    }

    testWidgets('dice a qué correo salió el código y que revise Spam', (
      tester,
    ) async {
      await pumpSignUp(tester);

      final hint = tester.widget<Text>(find.byKey(const Key('auth-code-hint')));
      expect(hint.data, contains('nueva@example.com.'));
      expect(hint.data, contains('Spam'));
    });

    testWidgets('el email no se edita mientras espera el código', (
      tester,
    ) async {
      await pumpSignUp(tester);

      final field = tester.widget<TextField>(
        find.byKey(const Key('auth-email')),
      );
      expect(field.readOnly, isTrue);
    });

    testWidgets('el código acepta sólo 8 dígitos', (tester) async {
      await pumpSignUp(tester);

      await tester.enterText(
        find.byKey(const Key('auth-verification-code')),
        '12a34 5678999',
      );
      final field = tester.widget<TextField>(
        find.byKey(const Key('auth-verification-code')),
      );
      expect(field.controller!.text, '12345678');
    });

    testWidgets('pedir otro código lo confirma y manda un solo pedido', (
      tester,
    ) async {
      await pumpSignUp(tester);
      expect(find.byKey(const Key('auth-code-resent')), findsNothing);

      await tester.tap(find.byKey(const Key('auth-resend-code')));
      await tester.pump();
      await tester.pump();

      expect(find.byKey(const Key('auth-code-resent')), findsOneWidget);
      expect(server.registrations, 2);
    });

    testWidgets('un código mal tipeado no vuelve al principio', (tester) async {
      await pumpSignUp(tester);

      await tester.enterText(
        find.byKey(const Key('auth-verification-code')),
        '11111111',
      );
      await tester.enterText(
        find.byKey(const Key('auth-password')),
        'Secreta-123',
      );
      await tester.tap(find.byKey(const Key('auth-submit')));
      await tester.pump();
      await tester.pump();

      expect(find.text('Confirma tu correo.'), findsOneWidget);
      expect(
        find.text('El código no es válido. Revísalo e inténtalo de nuevo.'),
        findsOneWidget,
      );
      expect(find.byKey(const Key('auth-verification-code')), findsOneWidget);
    });
  });
}
