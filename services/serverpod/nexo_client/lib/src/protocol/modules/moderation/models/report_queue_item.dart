/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod_client/serverpod_client.dart' as _isc;
import '../../../modules/moderation/models/moderation_reason.dart' as _i9getqdy;
import '../../../modules/moderation/models/report_severity.dart' as _icd6twrz;
import '../../../modules/moderation/models/report_target_type.dart'
    as _ia1tgea5;

/// Un contenido reportado en la cola. Agrupa todos sus reportes abiertos:
/// [severity] es la más alta y [reportCount] cuántos hay. Para resolver se
/// usa [reportId].
abstract class ReportQueueItem
    implements _isc.SerializableModel, _isc.ProtocolSerialization {
  ReportQueueItem._({
    required this.reportId,
    required this.targetType,
    required this.targetId,
    required this.postId,
    required this.targetAuthorId,
    this.targetAuthorUsername,
    required this.excerpt,
    required this.targetRemoved,
    required this.reason,
    required this.severity,
    required this.reportCount,
    required this.firstReportedAt,
  });

  factory ReportQueueItem({
    required int reportId,
    required _ia1tgea5.ReportTargetType targetType,
    required int targetId,
    required int postId,
    required _isc.UuidValue targetAuthorId,
    String? targetAuthorUsername,
    required String excerpt,
    required bool targetRemoved,
    required _i9getqdy.ModerationReason reason,
    required _icd6twrz.ReportSeverity severity,
    required int reportCount,
    required DateTime firstReportedAt,
  }) = _ReportQueueItemImpl;

  factory ReportQueueItem.fromJson(Map<String, dynamic> jsonSerialization) {
    return ReportQueueItem(
      reportId: jsonSerialization['reportId'] as int,
      targetType: _ia1tgea5.ReportTargetType.fromJson(
        (jsonSerialization['targetType'] as String),
      ),
      targetId: jsonSerialization['targetId'] as int,
      postId: jsonSerialization['postId'] as int,
      targetAuthorId: _isc.UuidValueJsonExtension.fromJson(
        jsonSerialization['targetAuthorId'],
      ),
      targetAuthorUsername:
          jsonSerialization['targetAuthorUsername'] as String?,
      excerpt: jsonSerialization['excerpt'] as String,
      targetRemoved: _isc.BoolJsonExtension.fromJson(
        jsonSerialization['targetRemoved'],
      ),
      reason: _i9getqdy.ModerationReason.fromJson(
        (jsonSerialization['reason'] as String),
      ),
      severity: _icd6twrz.ReportSeverity.fromJson(
        (jsonSerialization['severity'] as int),
      ),
      reportCount: jsonSerialization['reportCount'] as int,
      firstReportedAt: _isc.DateTimeJsonExtension.fromJson(
        jsonSerialization['firstReportedAt'],
      ),
    );
  }

  int reportId;

  _ia1tgea5.ReportTargetType targetType;

  int targetId;

  /// El post del contenido: el mismo [targetId] si es un post, el post del
  /// comentario si es un comentario.
  int postId;

  _isc.UuidValue targetAuthorId;

  String? targetAuthorUsername;

  /// El texto tal como está ahora, para revisarlo sin abrir otra pantalla.
  String excerpt;

  /// `true` si su autor ya lo eliminó: solo queda descartar.
  bool targetRemoved;

  _i9getqdy.ModerationReason reason;

  _icd6twrz.ReportSeverity severity;

  int reportCount;

  DateTime firstReportedAt;

  /// Returns a shallow copy of this [ReportQueueItem]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  ReportQueueItem copyWith({
    int? reportId,
    _ia1tgea5.ReportTargetType? targetType,
    int? targetId,
    int? postId,
    _isc.UuidValue? targetAuthorId,
    String? targetAuthorUsername,
    String? excerpt,
    bool? targetRemoved,
    _i9getqdy.ModerationReason? reason,
    _icd6twrz.ReportSeverity? severity,
    int? reportCount,
    DateTime? firstReportedAt,
  });
  @override
  Map<String, dynamic> toJson() {
    return {
      '__className__': 'ReportQueueItem',
      'reportId': reportId,
      'targetType': targetType.toJson(),
      'targetId': targetId,
      'postId': postId,
      'targetAuthorId': targetAuthorId.toJson(),
      if (targetAuthorUsername != null)
        'targetAuthorUsername': targetAuthorUsername,
      'excerpt': excerpt,
      'targetRemoved': targetRemoved,
      'reason': reason.toJson(),
      'severity': severity.toJson(),
      'reportCount': reportCount,
      'firstReportedAt': firstReportedAt.toJson(),
    };
  }

  @override
  Map<String, dynamic> toJsonForProtocol() {
    return {
      '__className__': 'ReportQueueItem',
      'reportId': reportId,
      'targetType': targetType.toJson(),
      'targetId': targetId,
      'postId': postId,
      'targetAuthorId': targetAuthorId.toJson(),
      if (targetAuthorUsername != null)
        'targetAuthorUsername': targetAuthorUsername,
      'excerpt': excerpt,
      'targetRemoved': targetRemoved,
      'reason': reason.toJson(),
      'severity': severity.toJson(),
      'reportCount': reportCount,
      'firstReportedAt': firstReportedAt.toJson(),
    };
  }

  @override
  String toString() {
    return _isc.SerializationManager.encode(this);
  }
}

class _Undefined {}

class _ReportQueueItemImpl extends ReportQueueItem {
  _ReportQueueItemImpl({
    required int reportId,
    required _ia1tgea5.ReportTargetType targetType,
    required int targetId,
    required int postId,
    required _isc.UuidValue targetAuthorId,
    String? targetAuthorUsername,
    required String excerpt,
    required bool targetRemoved,
    required _i9getqdy.ModerationReason reason,
    required _icd6twrz.ReportSeverity severity,
    required int reportCount,
    required DateTime firstReportedAt,
  }) : super._(
         reportId: reportId,
         targetType: targetType,
         targetId: targetId,
         postId: postId,
         targetAuthorId: targetAuthorId,
         targetAuthorUsername: targetAuthorUsername,
         excerpt: excerpt,
         targetRemoved: targetRemoved,
         reason: reason,
         severity: severity,
         reportCount: reportCount,
         firstReportedAt: firstReportedAt,
       );

  /// Returns a shallow copy of this [ReportQueueItem]
  /// with some or all fields replaced by the given arguments.
  @_isc.useResult
  @override
  ReportQueueItem copyWith({
    int? reportId,
    _ia1tgea5.ReportTargetType? targetType,
    int? targetId,
    int? postId,
    _isc.UuidValue? targetAuthorId,
    Object? targetAuthorUsername = _Undefined,
    String? excerpt,
    bool? targetRemoved,
    _i9getqdy.ModerationReason? reason,
    _icd6twrz.ReportSeverity? severity,
    int? reportCount,
    DateTime? firstReportedAt,
  }) {
    return ReportQueueItem(
      reportId: reportId ?? this.reportId,
      targetType: targetType ?? this.targetType,
      targetId: targetId ?? this.targetId,
      postId: postId ?? this.postId,
      targetAuthorId: targetAuthorId ?? this.targetAuthorId,
      targetAuthorUsername: targetAuthorUsername is String?
          ? targetAuthorUsername
          : this.targetAuthorUsername,
      excerpt: excerpt ?? this.excerpt,
      targetRemoved: targetRemoved ?? this.targetRemoved,
      reason: reason ?? this.reason,
      severity: severity ?? this.severity,
      reportCount: reportCount ?? this.reportCount,
      firstReportedAt: firstReportedAt ?? this.firstReportedAt,
    );
  }
}
