import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nexo_social/app/router/app_routes.dart';
import 'package:nexo_social/app/theme/app_theme.dart';
import 'package:nexo_social/core/errors/failures.dart';
import 'package:nexo_social/features/auth/domain/entities/app_user.dart';
import 'package:nexo_social/features/profile/domain/entities/public_profile.dart';
import 'package:nexo_social/features/profile/domain/repositories/profile_repository.dart';
import 'package:nexo_social/features/subscriptions/data/repositories/mock_subscription_repository.dart';
import 'package:nexo_social/features/subscriptions/presentation/bloc/subscription_cubit.dart';
import 'package:nexo_social/features/subscriptions/presentation/pages/subscription_page.dart';

import '../../support/app_harness.dart';

class _MockProfiles extends Mock implements ProfileRepository {}

const _carlos = PublicProfile(
  id: 'uuid-carlos',
  username: 'carlos_mendez',
  name: 'Carlos Méndez',
  isCreator: true,
  verification: VerificationStatus.verified,
  followers: 1200,
);

void main() {
  group('SubscriptionCubit', () {
    late _MockProfiles profiles;
    late MockSubscriptionRepository subscriptions;

    setUp(() {
      profiles = _MockProfiles();
      subscriptions = MockSubscriptionRepository();
    });

    // Regresión: el muro era siempre el de Elena, se abriera desde el perfil
    // que se abriera.
    test('the hero is the creator the wall belongs to', () async {
      when(
        () => profiles.byUsername('carlos_mendez'),
      ).thenAnswer((_) async => _carlos);
      final cubit = SubscriptionCubit(
        subscriptions,
        'carlos_mendez',
        profiles,
      );

      await cubit.load();

      expect(cubit.state.creatorProfile, _carlos);
      expect(cubit.state.entitlement.creator, 'carlos_mendez');
      await cubit.close();
    });

    test('a profile that cannot be read leaves the wall usable', () async {
      when(
        () => profiles.byUsername('carlos_mendez'),
      ).thenThrow(const NetworkFailure('offline'));
      final cubit = SubscriptionCubit(
        subscriptions,
        'carlos_mendez',
        profiles,
      );

      await cubit.load();

      expect(cubit.state.creatorProfile, isNull);
      await cubit.subscribe();
      expect(cubit.state.entitlement.active, isTrue);
      await cubit.close();
    });

    // El mensaje de aliento se escribía y se tiraba.
    test('the donation carries its message', () async {
      final cubit = SubscriptionCubit(subscriptions, 'carlos_mendez');

      expect(await cubit.donate(message: '  ¡Gracias!  '), isTrue);
      expect(await cubit.donate(message: '   '), isTrue);

      expect(subscriptions.messages['carlos_mendez'], ['¡Gracias!']);
      expect(subscriptions.donations['carlos_mendez'], 10);
      expect(cubit.state.donationTotal, 10);
      expect(cubit.state.isDonating, isFalse);
      await cubit.close();
    });

    test('a second tap while sending is not a second donation', () async {
      final cubit = SubscriptionCubit(subscriptions, 'carlos_mendez');

      final first = cubit.donate();
      expect(cubit.state.isDonating, isTrue);
      expect(await cubit.donate(), isFalse);
      await first;

      expect(subscriptions.donations['carlos_mendez'], 5);
      await cubit.close();
    });
  });

  group('SubscriptionPage', () {
    setUp(AppHarness.bootstrap);

    Future<void> pump(WidgetTester tester, String location) async {
      final router = GoRouter(
        initialLocation: location,
        routes: [
          GoRoute(path: '/', builder: (_, _) => const Text('inicio')),
          GoRoute(
            path: AppRoutes.premium,
            builder: (_, _) => const SubscriptionPage(),
          ),
          GoRoute(
            path: AppRoutes.premiumPath,
            builder: (_, state) =>
                SubscriptionPage(creator: state.pathParameters['username']),
          ),
        ],
      );
      await tester.pumpWidget(
        MaterialApp.router(theme: AppTheme.nexo, routerConfig: router),
      );
      await AppHarness.settle(tester);
    }

    testWidgets('the hero names the creator from the route', (tester) async {
      await pump(tester, AppRoutes.premiumFor('elena_ux'));

      expect(
        tester.widget<Text>(find.byKey(const Key('premium-creator-name'))).data,
        'Elena Vega',
      );
      expect(find.textContaining('42.8k'), findsNothing);
    });

    testWidgets('an unknown creator shows only the username', (tester) async {
      await pump(tester, AppRoutes.premiumFor('nadie_aqui'));

      expect(
        tester.widget<Text>(find.byKey(const Key('premium-creator-name'))).data,
        '@nadie_aqui',
      );
      expect(find.text('Elena Vega'), findsNothing);
    });

    testWidgets('without a creator it explains where memberships live', (
      tester,
    ) async {
      await pump(tester, AppRoutes.premium);

      expect(find.text('Cada membresía es de un creador'), findsOneWidget);
      expect(find.byKey(const Key('subscribe-button')), findsNothing);
    });

    // Regresión: `context.pop` sin nada debajo (un enlace directo) revienta.
    testWidgets('closing from a direct link goes to the feed', (tester) async {
      await pump(tester, AppRoutes.premiumFor('elena_ux'));

      await tester.tap(find.byKey(const Key('premium-close')));
      await AppHarness.settle(tester);

      expect(find.text('inicio'), findsOneWidget);
    });
  });
}
