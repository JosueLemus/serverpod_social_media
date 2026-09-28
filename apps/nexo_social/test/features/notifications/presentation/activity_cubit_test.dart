import 'package:flutter_test/flutter_test.dart';
import 'package:nexo_social/features/notifications/domain/entities/app_notification.dart';
import 'package:nexo_social/features/notifications/presentation/bloc/activity_cubit.dart';

void main() {
  late ActivityCubit cubit;

  setUp(() => cubit = ActivityCubit());

  test('shows everything with no filter', () {
    expect(cubit.state.visible, hasLength(cubit.state.items.length));
  });

  test('filtering narrows to one kind', () {
    cubit.filterBy(NotificationType.follow);

    expect(
      cubit.state.visible.every((item) => item.type == NotificationType.follow),
      isTrue,
    );
  });

  test('clearing the filter restores the full list', () {
    cubit.filterBy(NotificationType.follow);
    cubit.filterBy(null);

    expect(cubit.state.visible, hasLength(cubit.state.items.length));
  });

  test('marking one read leaves the others alone', () {
    final before = cubit.state.unreadCount;
    final target = cubit.state.items.first;
    cubit.markRead(target.id);

    final updated = cubit.state.items.firstWhere(
      (item) => item.id == target.id,
    );
    expect(updated.read, isTrue);
    // Una menos de las que ya estaban sin leer antes del tap.
    expect(cubit.state.unreadCount, before - 1);
  });

  /// With a filter active, skipping the hidden items leaves a badge the user
  /// believes they cleared.
  test('"marcar todo" marks items the current filter hides', () {
    cubit.filterBy(NotificationType.follow);
    cubit.markAllRead();

    expect(cubit.state.unreadCount, 0);
    expect(cubit.state.items.every((item) => item.read), isTrue);
  });

  test('every notification kind has a label that is not its identifier', () {
    for (final type in NotificationType.values) {
      expect(type.label, isNotEmpty);
      expect(type.label, isNot(type.name));
    }
  });
}
