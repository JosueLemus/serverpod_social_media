import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_social/app/di/injection.dart';
import 'package:nexo_social/core/constants/environment.dart';
import 'package:nexo_social/app/theme/app_theme.dart';
import 'package:nexo_social/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Test entry point for the dependency graph.
///
/// **Never call `configureDependencies()` directly from a test.** It awaits
/// `SharedPreferences.getInstance()`, which has no platform side under
/// `flutter_test`: the future never completes, so the test hangs until the
/// suite's 10-minute timeout instead of failing. Two tests in this repo died
/// that way for weeks, and the suite still reported success because the
/// command was piped through `tail`, which swallows the exit code.
abstract final class AppHarness {
  /// Builds a clean graph over in-memory preferences.
  ///
  /// [initialPreferences] seeds storage — pass a saved session to start a test
  /// signed in.
  static Future<void> bootstrap({
    Map<String, Object> initialPreferences = const {},
  }) async {
    SharedPreferences.setMockInitialValues(initialPreferences);
    // The graph short-circuits when it is already registered, so without this
    // every test in the run would share one container and whatever the first
    // one wrote would leak into the rest.
    await resetDependencies();
    await configureDependencies(
      preferences: await SharedPreferences.getInstance(),
      // Widget tests exercise the deliberately explicit demo implementation;
      // they must never accidentally try localhost because production now
      // defaults to Serverpod authentication.
      authSourceMode: AuthSourceMode.mock,
    );
  }

  /// Wraps [child] in the ancestors a screen inside the shell expects: the
  /// theme, and the app-wide session.
  ///
  /// Uses `BlocProvider.value` because [AuthCubit] is a singleton — a
  /// `create:` provider closes what it builds on dispose, so the second test
  /// to run would get a closed cubit.
  static Widget wrap(Widget child, {AuthCubit? auth}) => BlocProvider.value(
    value: auth ?? sl<AuthCubit>(),
    child: MaterialApp(
      theme: AppTheme.light,
      home: Scaffold(body: child),
    ),
  );

  /// Settles a tree that contains `animate_do` and Google Fonts.
  ///
  /// `pumpAndSettle` is unsafe here: a repeating animation (the skeleton
  /// pulse, the live dot) always has a frame scheduled, so waiting for none
  /// hangs until the timeout. Advancing a bounded amount is what these tests
  /// actually need.
  static Future<void> settle(WidgetTester tester) async {
    for (var step = 0; step < 8; step++) {
      await tester.pump(const Duration(milliseconds: 120));
    }
  }
}
