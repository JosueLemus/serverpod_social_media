import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/app_notification.dart';

class ActivityState {
  const ActivityState(this.items, {this.filter});
  final List<AppNotification> items;
  final NotificationType? filter;
  List<AppNotification> get visible => filter == null
      ? items
      : items.where((item) => item.type == filter).toList();
}

class ActivityCubit extends Cubit<ActivityState> {
  ActivityCubit()
    : super(
        const ActivityState([
          AppNotification(
            id: '1',
            type: NotificationType.follow,
            title: 'Marcos comenzó a seguirte',
            detail: 'Hace 25 min',
          ),
          AppNotification(
            id: '2',
            type: NotificationType.comment,
            title: 'Sofía comentó tu publicación',
            detail: 'Excelente tip para Flutter',
          ),
          AppNotification(
            id: '3',
            type: NotificationType.liveReminder,
            title: 'Elena inicia un live en 15 min',
            detail: 'Activa un recordatorio',
          ),
          AppNotification(
            id: '4',
            type: NotificationType.membership,
            title: 'Nueva membresía activa',
            detail: 'Valentina se unió a tu Pase Pro',
          ),
        ]),
      );
  void filterBy(NotificationType? type) =>
      emit(ActivityState(state.items, filter: type));
  void markRead(String id) => emit(
    ActivityState(
      state.items
          .map((item) => item.id == id ? item.copyWith(read: true) : item)
          .toList(),
      filter: state.filter,
    ),
  );
}
