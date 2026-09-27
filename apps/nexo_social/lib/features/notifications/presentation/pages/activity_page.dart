import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/activity_cubit.dart';
import '../../domain/entities/app_notification.dart';

class ActivityPage extends StatelessWidget {
  const ActivityPage({super.key});
  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => ActivityCubit(),
    child: BlocBuilder<ActivityCubit, ActivityState>(
      builder: (context, state) => ListView(
        children: [
          Text('Actividad', style: Theme.of(context).textTheme.displaySmall),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Todo'),
                selected: state.filter == null,
                onSelected: (_) => context.read<ActivityCubit>().filterBy(null),
              ),
              ...NotificationType.values.map(
                (type) => ChoiceChip(
                  label: Text(type.name),
                  selected: state.filter == type,
                  onSelected: (_) =>
                      context.read<ActivityCubit>().filterBy(type),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (state.visible.isEmpty)
            const Center(child: Text('No hay actividad para este filtro')),
          ...state.visible.map(
            (item) => Card(
              child: ListTile(
                leading: Icon(
                  item.read
                      ? Icons.notifications_none
                      : Icons.notifications_active,
                ),
                title: Text(item.title),
                subtitle: Text(item.detail),
                onTap: () => context.read<ActivityCubit>().markRead(item.id),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
