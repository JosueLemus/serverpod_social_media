/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member
// ignore_for_file: dead_code, unnecessary_type_check

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:nexo_client/src/protocol/modules/moderation/models/report_queue_item.dart'
    as _ij26twz2;
import 'package:serverpod_auth_core_client/serverpod_auth_core_client.dart'
    as _iacc;
import 'package:serverpod_auth_idp_client/serverpod_auth_idp_client.dart'
    as _iaic;
import 'package:serverpod_client/serverpod_client.dart' as _isc;
import 'modules/content/models/media_upload_ticket.dart' as _i4efb2h6;
import 'modules/content/models/post_draft.dart' as _i71ym97j;
import 'modules/content/models/post_edit.dart' as _ijy0en9v;
import 'modules/content/models/post_media_kind.dart' as _iqr0e776;
import 'modules/content/models/post_media_view.dart' as _ibyq15o7;
import 'modules/content/models/post_page.dart' as _idjwmytq;
import 'modules/content/models/post_view.dart' as _ixt78pt4;
import 'modules/content/models/post_visibility.dart' as _iu5xfvn4;
import 'modules/identity/models/account_status.dart' as _i96mabue;
import 'modules/identity/models/account_view.dart' as _ig9ziu3q;
import 'modules/identity/models/profile_edit.dart' as _i3rezn75;
import 'modules/identity/models/profile_view.dart' as _i8sfv82t;
import 'modules/identity/models/verification_status.dart' as _i1f8s3dp;
import 'modules/moderation/models/moderation_reason.dart' as _ipkc12ge;
import 'modules/moderation/models/report_decision.dart' as _ib61hwyt;
import 'modules/moderation/models/report_queue_item.dart' as _itr0x2qd;
import 'modules/moderation/models/report_severity.dart' as _id3n49vv;
import 'modules/moderation/models/report_target_type.dart' as _i5s3tooi;
import 'modules/social/models/like_state.dart' as _i0kd3w76;
import 'modules/social/models/post_comment_page.dart' as _iov9osdu;
import 'modules/social/models/post_comment_view.dart' as _i5ho22g4;
import 'modules/social/models/post_liker.dart' as _ignoub8u;
import 'modules/social/models/post_liker_page.dart' as _iyfhrk15;
import 'shared/errors/nexo_error_code.dart' as _idt8nicn;
import 'shared/errors/nexo_exception.dart' as _invvqh96;
import 'shared/pagination/page_cursor.dart' as _ihkyxh72;
export 'modules/content/models/media_upload_ticket.dart';
export 'modules/content/models/post_draft.dart';
export 'modules/content/models/post_edit.dart';
export 'modules/content/models/post_media_kind.dart';
export 'modules/content/models/post_media_view.dart';
export 'modules/content/models/post_page.dart';
export 'modules/content/models/post_view.dart';
export 'modules/content/models/post_visibility.dart';
export 'modules/identity/models/account_status.dart';
export 'modules/identity/models/account_view.dart';
export 'modules/identity/models/profile_edit.dart';
export 'modules/identity/models/profile_view.dart';
export 'modules/identity/models/verification_status.dart';
export 'modules/moderation/models/moderation_reason.dart';
export 'modules/moderation/models/report_decision.dart';
export 'modules/moderation/models/report_queue_item.dart';
export 'modules/moderation/models/report_severity.dart';
export 'modules/moderation/models/report_target_type.dart';
export 'modules/social/models/like_state.dart';
export 'modules/social/models/post_comment_page.dart';
export 'modules/social/models/post_comment_view.dart';
export 'modules/social/models/post_liker.dart';
export 'modules/social/models/post_liker_page.dart';
export 'shared/errors/nexo_error_code.dart';
export 'shared/errors/nexo_exception.dart';
export 'shared/pagination/page_cursor.dart';
export 'client.dart';

class Protocol extends _isc.SerializationManager {
  Protocol._();

  factory Protocol() => _instance;

  static final Protocol _instance = Protocol._().._registerHostProtocols();

  static String? getClassNameFromObjectJson(dynamic data) {
    if (data is! Map) return null;
    final className = data['__className__'] as String?;
    return className;
  }

  @override
  T deserialize<T>(
    dynamic data, [
    Type? t,
  ]) {
    t ??= T;

    final dataClassName = getClassNameFromObjectJson(data);
    if (dataClassName != null && dataClassName != getClassNameForType(t)) {
      try {
        return deserializeByClassName({
          'className': dataClassName,
          'data': data,
        });
      } on _isc.DeserializationClassNameNotFoundException catch (_) {
        // If the className is not recognized (e.g., older client receiving
        // data with a new subtype), fall back to deserializing without the
        // className, using the expected type T.
      }
    }

    if (t == _i4efb2h6.MediaUploadTicket) {
      return _i4efb2h6.MediaUploadTicket.fromJson(data) as T;
    }
    if (t == _i71ym97j.PostDraft) {
      return _i71ym97j.PostDraft.fromJson(data) as T;
    }
    if (t == _ijy0en9v.PostEdit) {
      return _ijy0en9v.PostEdit.fromJson(data) as T;
    }
    if (t == _iqr0e776.PostMediaKind) {
      return _iqr0e776.PostMediaKind.fromJson(data) as T;
    }
    if (t == _ibyq15o7.PostMediaView) {
      return _ibyq15o7.PostMediaView.fromJson(data) as T;
    }
    if (t == _idjwmytq.PostPage) {
      return _idjwmytq.PostPage.fromJson(data) as T;
    }
    if (t == _ixt78pt4.PostView) {
      return _ixt78pt4.PostView.fromJson(data) as T;
    }
    if (t == _iu5xfvn4.PostVisibility) {
      return _iu5xfvn4.PostVisibility.fromJson(data) as T;
    }
    if (t == _i96mabue.AccountStatus) {
      return _i96mabue.AccountStatus.fromJson(data) as T;
    }
    if (t == _ig9ziu3q.AccountView) {
      return _ig9ziu3q.AccountView.fromJson(data) as T;
    }
    if (t == _i3rezn75.ProfileEdit) {
      return _i3rezn75.ProfileEdit.fromJson(data) as T;
    }
    if (t == _i8sfv82t.ProfileView) {
      return _i8sfv82t.ProfileView.fromJson(data) as T;
    }
    if (t == _i1f8s3dp.VerificationStatus) {
      return _i1f8s3dp.VerificationStatus.fromJson(data) as T;
    }
    if (t == _ipkc12ge.ModerationReason) {
      return _ipkc12ge.ModerationReason.fromJson(data) as T;
    }
    if (t == _ib61hwyt.ReportDecision) {
      return _ib61hwyt.ReportDecision.fromJson(data) as T;
    }
    if (t == _itr0x2qd.ReportQueueItem) {
      return _itr0x2qd.ReportQueueItem.fromJson(data) as T;
    }
    if (t == _id3n49vv.ReportSeverity) {
      return _id3n49vv.ReportSeverity.fromJson(data) as T;
    }
    if (t == _i5s3tooi.ReportTargetType) {
      return _i5s3tooi.ReportTargetType.fromJson(data) as T;
    }
    if (t == _i0kd3w76.LikeState) {
      return _i0kd3w76.LikeState.fromJson(data) as T;
    }
    if (t == _iov9osdu.PostCommentPage) {
      return _iov9osdu.PostCommentPage.fromJson(data) as T;
    }
    if (t == _i5ho22g4.PostCommentView) {
      return _i5ho22g4.PostCommentView.fromJson(data) as T;
    }
    if (t == _ignoub8u.PostLiker) {
      return _ignoub8u.PostLiker.fromJson(data) as T;
    }
    if (t == _iyfhrk15.PostLikerPage) {
      return _iyfhrk15.PostLikerPage.fromJson(data) as T;
    }
    if (t == _idt8nicn.NexoErrorCode) {
      return _idt8nicn.NexoErrorCode.fromJson(data) as T;
    }
    if (t == _invvqh96.NexoException) {
      return _invvqh96.NexoException.fromJson(data) as T;
    }
    if (t == _ihkyxh72.PageCursor) {
      return _ihkyxh72.PageCursor.fromJson(data) as T;
    }
    if (t == _isc.getType<_i4efb2h6.MediaUploadTicket?>()) {
      return (data != null ? _i4efb2h6.MediaUploadTicket.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_i71ym97j.PostDraft?>()) {
      return (data != null ? _i71ym97j.PostDraft.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_ijy0en9v.PostEdit?>()) {
      return (data != null ? _ijy0en9v.PostEdit.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_iqr0e776.PostMediaKind?>()) {
      return (data != null ? _iqr0e776.PostMediaKind.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_ibyq15o7.PostMediaView?>()) {
      return (data != null ? _ibyq15o7.PostMediaView.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_idjwmytq.PostPage?>()) {
      return (data != null ? _idjwmytq.PostPage.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_ixt78pt4.PostView?>()) {
      return (data != null ? _ixt78pt4.PostView.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_iu5xfvn4.PostVisibility?>()) {
      return (data != null ? _iu5xfvn4.PostVisibility.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_i96mabue.AccountStatus?>()) {
      return (data != null ? _i96mabue.AccountStatus.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_ig9ziu3q.AccountView?>()) {
      return (data != null ? _ig9ziu3q.AccountView.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_i3rezn75.ProfileEdit?>()) {
      return (data != null ? _i3rezn75.ProfileEdit.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_i8sfv82t.ProfileView?>()) {
      return (data != null ? _i8sfv82t.ProfileView.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_i1f8s3dp.VerificationStatus?>()) {
      return (data != null ? _i1f8s3dp.VerificationStatus.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_ipkc12ge.ModerationReason?>()) {
      return (data != null ? _ipkc12ge.ModerationReason.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_ib61hwyt.ReportDecision?>()) {
      return (data != null ? _ib61hwyt.ReportDecision.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_itr0x2qd.ReportQueueItem?>()) {
      return (data != null ? _itr0x2qd.ReportQueueItem.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_id3n49vv.ReportSeverity?>()) {
      return (data != null ? _id3n49vv.ReportSeverity.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_i5s3tooi.ReportTargetType?>()) {
      return (data != null ? _i5s3tooi.ReportTargetType.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_i0kd3w76.LikeState?>()) {
      return (data != null ? _i0kd3w76.LikeState.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_iov9osdu.PostCommentPage?>()) {
      return (data != null ? _iov9osdu.PostCommentPage.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_i5ho22g4.PostCommentView?>()) {
      return (data != null ? _i5ho22g4.PostCommentView.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_ignoub8u.PostLiker?>()) {
      return (data != null ? _ignoub8u.PostLiker.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_iyfhrk15.PostLikerPage?>()) {
      return (data != null ? _iyfhrk15.PostLikerPage.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_idt8nicn.NexoErrorCode?>()) {
      return (data != null ? _idt8nicn.NexoErrorCode.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_invvqh96.NexoException?>()) {
      return (data != null ? _invvqh96.NexoException.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_ihkyxh72.PageCursor?>()) {
      return (data != null ? _ihkyxh72.PageCursor.fromJson(data) : null) as T;
    }
    if (t == List<String>) {
      return (data as List).map((e) => deserialize<String>(e)).toList() as T;
    }
    if (t == _isc.getType<List<String>?>()) {
      return (data != null
              ? (data as List).map((e) => deserialize<String>(e)).toList()
              : null)
          as T;
    }
    if (t == List<_ixt78pt4.PostView>) {
      return (data as List)
              .map((e) => deserialize<_ixt78pt4.PostView>(e))
              .toList()
          as T;
    }
    if (t == List<_ibyq15o7.PostMediaView>) {
      return (data as List)
              .map((e) => deserialize<_ibyq15o7.PostMediaView>(e))
              .toList()
          as T;
    }
    if (t == List<_i5ho22g4.PostCommentView>) {
      return (data as List)
              .map((e) => deserialize<_i5ho22g4.PostCommentView>(e))
              .toList()
          as T;
    }
    if (t == List<_ignoub8u.PostLiker>) {
      return (data as List)
              .map((e) => deserialize<_ignoub8u.PostLiker>(e))
              .toList()
          as T;
    }
    if (t == List<_ij26twz2.ReportQueueItem>) {
      return (data as List)
              .map((e) => deserialize<_ij26twz2.ReportQueueItem>(e))
              .toList()
          as T;
    }
    try {
      return _iaic.Protocol().deserialize<T>(data, t);
    } on _isc.DeserializationTypeNotFoundException catch (_) {}
    try {
      return _iacc.Protocol().deserialize<T>(data, t);
    } on _isc.DeserializationTypeNotFoundException catch (_) {}
    return super.deserialize<T>(data, t);
  }

  static String? getClassNameForType(Type type) {
    return switch (type) {
      _i4efb2h6.MediaUploadTicket => 'MediaUploadTicket',
      _i71ym97j.PostDraft => 'PostDraft',
      _ijy0en9v.PostEdit => 'PostEdit',
      _iqr0e776.PostMediaKind => 'PostMediaKind',
      _ibyq15o7.PostMediaView => 'PostMediaView',
      _idjwmytq.PostPage => 'PostPage',
      _ixt78pt4.PostView => 'PostView',
      _iu5xfvn4.PostVisibility => 'PostVisibility',
      _i96mabue.AccountStatus => 'AccountStatus',
      _ig9ziu3q.AccountView => 'AccountView',
      _i3rezn75.ProfileEdit => 'ProfileEdit',
      _i8sfv82t.ProfileView => 'ProfileView',
      _i1f8s3dp.VerificationStatus => 'VerificationStatus',
      _ipkc12ge.ModerationReason => 'ModerationReason',
      _ib61hwyt.ReportDecision => 'ReportDecision',
      _itr0x2qd.ReportQueueItem => 'ReportQueueItem',
      _id3n49vv.ReportSeverity => 'ReportSeverity',
      _i5s3tooi.ReportTargetType => 'ReportTargetType',
      _i0kd3w76.LikeState => 'LikeState',
      _iov9osdu.PostCommentPage => 'PostCommentPage',
      _i5ho22g4.PostCommentView => 'PostCommentView',
      _ignoub8u.PostLiker => 'PostLiker',
      _iyfhrk15.PostLikerPage => 'PostLikerPage',
      _idt8nicn.NexoErrorCode => 'NexoErrorCode',
      _invvqh96.NexoException => 'NexoException',
      _ihkyxh72.PageCursor => 'PageCursor',
      _ => null,
    };
  }

  @override
  String? getClassNameForObject(Object? data) {
    String? className = super.getClassNameForObject(data);
    if (className != null) return className;

    if (data is Map<String, dynamic> && data['__className__'] is String) {
      return (data['__className__'] as String).replaceFirst('nexo.', '');
    }

    switch (data) {
      case _i4efb2h6.MediaUploadTicket():
        return 'MediaUploadTicket';
      case _i71ym97j.PostDraft():
        return 'PostDraft';
      case _ijy0en9v.PostEdit():
        return 'PostEdit';
      case _iqr0e776.PostMediaKind():
        return 'PostMediaKind';
      case _ibyq15o7.PostMediaView():
        return 'PostMediaView';
      case _idjwmytq.PostPage():
        return 'PostPage';
      case _ixt78pt4.PostView():
        return 'PostView';
      case _iu5xfvn4.PostVisibility():
        return 'PostVisibility';
      case _i96mabue.AccountStatus():
        return 'AccountStatus';
      case _ig9ziu3q.AccountView():
        return 'AccountView';
      case _i3rezn75.ProfileEdit():
        return 'ProfileEdit';
      case _i8sfv82t.ProfileView():
        return 'ProfileView';
      case _i1f8s3dp.VerificationStatus():
        return 'VerificationStatus';
      case _ipkc12ge.ModerationReason():
        return 'ModerationReason';
      case _ib61hwyt.ReportDecision():
        return 'ReportDecision';
      case _itr0x2qd.ReportQueueItem():
        return 'ReportQueueItem';
      case _id3n49vv.ReportSeverity():
        return 'ReportSeverity';
      case _i5s3tooi.ReportTargetType():
        return 'ReportTargetType';
      case _i0kd3w76.LikeState():
        return 'LikeState';
      case _iov9osdu.PostCommentPage():
        return 'PostCommentPage';
      case _i5ho22g4.PostCommentView():
        return 'PostCommentView';
      case _ignoub8u.PostLiker():
        return 'PostLiker';
      case _iyfhrk15.PostLikerPage():
        return 'PostLikerPage';
      case _idt8nicn.NexoErrorCode():
        return 'NexoErrorCode';
      case _invvqh96.NexoException():
        return 'NexoException';
      case _ihkyxh72.PageCursor():
        return 'PageCursor';
    }
    className = _iaic.Protocol().getClassNameForObject(data);
    if (className != null) {
      return className.contains('.')
          ? className
          : 'serverpod_auth_idp.$className';
    }
    className = _iacc.Protocol().getClassNameForObject(data);
    if (className != null) {
      return className.contains('.')
          ? className
          : 'serverpod_auth_core.$className';
    }
    return null;
  }

  @override
  dynamic deserializeByClassName(Map<String, dynamic> data) {
    var dataClassName = data['className'];
    if (dataClassName is! String) {
      return super.deserializeByClassName(data);
    }
    if (dataClassName == 'MediaUploadTicket') {
      return deserialize<_i4efb2h6.MediaUploadTicket>(data['data']);
    }
    if (dataClassName == 'PostDraft') {
      return deserialize<_i71ym97j.PostDraft>(data['data']);
    }
    if (dataClassName == 'PostEdit') {
      return deserialize<_ijy0en9v.PostEdit>(data['data']);
    }
    if (dataClassName == 'PostMediaKind') {
      return deserialize<_iqr0e776.PostMediaKind>(data['data']);
    }
    if (dataClassName == 'PostMediaView') {
      return deserialize<_ibyq15o7.PostMediaView>(data['data']);
    }
    if (dataClassName == 'PostPage') {
      return deserialize<_idjwmytq.PostPage>(data['data']);
    }
    if (dataClassName == 'PostView') {
      return deserialize<_ixt78pt4.PostView>(data['data']);
    }
    if (dataClassName == 'PostVisibility') {
      return deserialize<_iu5xfvn4.PostVisibility>(data['data']);
    }
    if (dataClassName == 'AccountStatus') {
      return deserialize<_i96mabue.AccountStatus>(data['data']);
    }
    if (dataClassName == 'AccountView') {
      return deserialize<_ig9ziu3q.AccountView>(data['data']);
    }
    if (dataClassName == 'ProfileEdit') {
      return deserialize<_i3rezn75.ProfileEdit>(data['data']);
    }
    if (dataClassName == 'ProfileView') {
      return deserialize<_i8sfv82t.ProfileView>(data['data']);
    }
    if (dataClassName == 'VerificationStatus') {
      return deserialize<_i1f8s3dp.VerificationStatus>(data['data']);
    }
    if (dataClassName == 'ModerationReason') {
      return deserialize<_ipkc12ge.ModerationReason>(data['data']);
    }
    if (dataClassName == 'ReportDecision') {
      return deserialize<_ib61hwyt.ReportDecision>(data['data']);
    }
    if (dataClassName == 'ReportQueueItem') {
      return deserialize<_itr0x2qd.ReportQueueItem>(data['data']);
    }
    if (dataClassName == 'ReportSeverity') {
      return deserialize<_id3n49vv.ReportSeverity>(data['data']);
    }
    if (dataClassName == 'ReportTargetType') {
      return deserialize<_i5s3tooi.ReportTargetType>(data['data']);
    }
    if (dataClassName == 'LikeState') {
      return deserialize<_i0kd3w76.LikeState>(data['data']);
    }
    if (dataClassName == 'PostCommentPage') {
      return deserialize<_iov9osdu.PostCommentPage>(data['data']);
    }
    if (dataClassName == 'PostCommentView') {
      return deserialize<_i5ho22g4.PostCommentView>(data['data']);
    }
    if (dataClassName == 'PostLiker') {
      return deserialize<_ignoub8u.PostLiker>(data['data']);
    }
    if (dataClassName == 'PostLikerPage') {
      return deserialize<_iyfhrk15.PostLikerPage>(data['data']);
    }
    if (dataClassName == 'NexoErrorCode') {
      return deserialize<_idt8nicn.NexoErrorCode>(data['data']);
    }
    if (dataClassName == 'NexoException') {
      return deserialize<_invvqh96.NexoException>(data['data']);
    }
    if (dataClassName == 'PageCursor') {
      return deserialize<_ihkyxh72.PageCursor>(data['data']);
    }
    if (dataClassName.startsWith('serverpod_auth_idp.')) {
      data['className'] = dataClassName.substring(19);
      return _iaic.Protocol().deserializeByClassName(data);
    }
    if (dataClassName.startsWith('serverpod_auth_core.')) {
      data['className'] = dataClassName.substring(20);
      return _iacc.Protocol().deserializeByClassName(data);
    }
    return super.deserializeByClassName(data);
  }

  void _registerHostProtocols() {
    _iaic.Protocol().registerHostProtocol('nexo', this);
    _iacc.Protocol().registerHostProtocol('nexo', this);
  }

  @override
  String getModuleName() => 'nexo';

  /// Maps any `Record`s known to this [Protocol] to their JSON representation
  ///
  /// Throws in case the record type is not known.
  ///
  /// This method will return `null` (only) for `null` inputs.
  Map<String, dynamic>? mapRecordToJson(Record? record) {
    if (record == null) {
      return null;
    }
    try {
      return _iaic.Protocol().mapRecordToJson(record);
    } catch (_) {}
    try {
      return _iacc.Protocol().mapRecordToJson(record);
    } catch (_) {}
    throw Exception('Unsupported record type ${record.runtimeType}');
  }
}
