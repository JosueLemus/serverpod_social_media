import 'package:equatable/equatable.dart';

import '../../../auth/domain/entities/app_user.dart';
import '../../../moderation/domain/entities/moderation_action.dart';

enum SanctionKind {
  mute('Silenciamiento'),
  suspension('Suspensión'),
  ban('Baneo');

  const SanctionKind(this.label);

  final String label;
}

class Sanction extends Equatable {
  const Sanction({
    required this.id,
    required this.kind,
    required this.reason,
    required this.createdBy,
    required this.createdAt,
    this.expiresAt,
    this.liftedAt,
  });

  final String id;
  final SanctionKind kind;
  final ModerationReason reason;

  /// Handle de quien la aplicó.
  final String createdBy;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final DateTime? liftedAt;

  bool isActiveAt(DateTime now) =>
      liftedAt == null && (expiresAt == null || expiresAt!.isAfter(now));

  @override
  List<Object?> get props => [
    id,
    kind,
    reason,
    createdBy,
    createdAt,
    expiresAt,
    liftedAt,
  ];
}

/// La ficha de una cuenta en la consola: quién es y qué historial tiene. El
/// historial es lo que permite ver reincidencia.
class AccountDetail extends Equatable {
  const AccountDetail({
    required this.user,
    required this.joinedAt,
    this.sanctions = const [],
    this.openReports = 0,
  });

  final AppUser user;
  final DateTime joinedAt;

  /// Más reciente primero.
  final List<Sanction> sanctions;
  final int openReports;

  @override
  List<Object?> get props => [user, joinedAt, sanctions, openReports];
}

/// Una página de resultados paginada por cursor. [nextCursor] es null en la
/// última.
class ResultPage<T> extends Equatable {
  const ResultPage(this.items, {this.nextCursor});

  final List<T> items;
  final String? nextCursor;

  @override
  List<Object?> get props => [items, nextCursor];
}
