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
import 'package:nexo_client/src/protocol/modules/identity/models/profile_view.dart'
    as _iaqpe3js;
import 'package:nexo_client/src/protocol/modules/live/models/live_chat_message_view.dart'
    as _iksujo4g;
import 'package:nexo_client/src/protocol/modules/live/models/live_show_view.dart'
    as _igcmn4rt;
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
import 'modules/feed/models/feed_item.dart' as _ipgmhy3o;
import 'modules/feed/models/feed_item_kind.dart' as _ibecfnye;
import 'modules/feed/models/feed_section.dart' as _it29bb7l;
import 'modules/feed/models/feed_section_kind.dart' as _iebgsa3d;
import 'modules/feed/models/home_feed_cursor.dart' as _in19kjfm;
import 'modules/feed/models/home_feed_page.dart' as _ihgqdd8m;
import 'modules/identity/models/account_status.dart' as _i96mabue;
import 'modules/identity/models/account_view.dart' as _ig9ziu3q;
import 'modules/identity/models/profile_edit.dart' as _i3rezn75;
import 'modules/identity/models/profile_view.dart' as _i8sfv82t;
import 'modules/identity/models/verification_status.dart' as _i1f8s3dp;
import 'modules/live/models/live_chat_message_view.dart' as _il6n38yd;
import 'modules/live/models/live_event.dart' as _i7dasvmg;
import 'modules/live/models/live_event_kind.dart' as _ilchcp3h;
import 'modules/live/models/live_hand_view.dart' as _igpp3v1h;
import 'modules/live/models/live_media_grant.dart' as _ij3uatdc;
import 'modules/live/models/live_media_grant_role.dart' as _ildi0w8j;
import 'modules/live/models/live_sanction_kind.dart' as _i1t7par0;
import 'modules/live/models/live_show_access.dart' as _irbd4xwy;
import 'modules/live/models/live_show_draft.dart' as _ixjiwb6f;
import 'modules/live/models/live_show_guest_status.dart' as _ixmm5757;
import 'modules/live/models/live_show_role.dart' as _ibpln05y;
import 'modules/live/models/live_show_status.dart' as _i60g3ahg;
import 'modules/live/models/live_show_view.dart' as _iky3rvks;
import 'modules/live/models/live_speaker_view.dart' as _iafzpzjd;
import 'modules/live/models/live_stage_view.dart' as _ivrg75i3;
import 'modules/messages/models/conversation_page.dart' as _i54ek7if;
import 'modules/messages/models/conversation_view.dart' as _iea0s5ku;
import 'modules/messages/models/direct_message_event.dart' as _i56rpfla;
import 'modules/messages/models/direct_message_event_kind.dart' as _ixoqahhg;
import 'modules/messages/models/direct_message_page.dart' as _igwk6oho;
import 'modules/messages/models/direct_message_view.dart' as _ikbrq2q8;
import 'modules/moderation/models/moderation_reason.dart' as _ipkc12ge;
import 'modules/moderation/models/report_decision.dart' as _ib61hwyt;
import 'modules/moderation/models/report_queue_item.dart' as _itr0x2qd;
import 'modules/moderation/models/report_severity.dart' as _id3n49vv;
import 'modules/moderation/models/report_target_type.dart' as _i5s3tooi;
import 'modules/notifications/models/notification_kind.dart' as _iuphy7om;
import 'modules/notifications/models/notification_page.dart' as _ipp18xpo;
import 'modules/notifications/models/notification_view.dart' as _imgpiqz3;
import 'modules/search/models/search_results.dart' as _il66wur0;
import 'modules/social/models/follow_page.dart' as _i6r55qgl;
import 'modules/social/models/follow_state.dart' as _ihy6a719;
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
export 'modules/feed/models/feed_item.dart';
export 'modules/feed/models/feed_item_kind.dart';
export 'modules/feed/models/feed_section.dart';
export 'modules/feed/models/feed_section_kind.dart';
export 'modules/feed/models/home_feed_cursor.dart';
export 'modules/feed/models/home_feed_page.dart';
export 'modules/identity/models/account_status.dart';
export 'modules/identity/models/account_view.dart';
export 'modules/identity/models/profile_edit.dart';
export 'modules/identity/models/profile_view.dart';
export 'modules/identity/models/verification_status.dart';
export 'modules/live/models/live_chat_message_view.dart';
export 'modules/live/models/live_event.dart';
export 'modules/live/models/live_event_kind.dart';
export 'modules/live/models/live_hand_view.dart';
export 'modules/live/models/live_media_grant.dart';
export 'modules/live/models/live_media_grant_role.dart';
export 'modules/live/models/live_sanction_kind.dart';
export 'modules/live/models/live_show_access.dart';
export 'modules/live/models/live_show_draft.dart';
export 'modules/live/models/live_show_guest_status.dart';
export 'modules/live/models/live_show_role.dart';
export 'modules/live/models/live_show_status.dart';
export 'modules/live/models/live_show_view.dart';
export 'modules/live/models/live_speaker_view.dart';
export 'modules/live/models/live_stage_view.dart';
export 'modules/messages/models/conversation_page.dart';
export 'modules/messages/models/conversation_view.dart';
export 'modules/messages/models/direct_message_event.dart';
export 'modules/messages/models/direct_message_event_kind.dart';
export 'modules/messages/models/direct_message_page.dart';
export 'modules/messages/models/direct_message_view.dart';
export 'modules/moderation/models/moderation_reason.dart';
export 'modules/moderation/models/report_decision.dart';
export 'modules/moderation/models/report_queue_item.dart';
export 'modules/moderation/models/report_severity.dart';
export 'modules/moderation/models/report_target_type.dart';
export 'modules/notifications/models/notification_kind.dart';
export 'modules/notifications/models/notification_page.dart';
export 'modules/notifications/models/notification_view.dart';
export 'modules/search/models/search_results.dart';
export 'modules/social/models/follow_page.dart';
export 'modules/social/models/follow_state.dart';
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
    if (t == _ipgmhy3o.FeedItem) {
      return _ipgmhy3o.FeedItem.fromJson(data) as T;
    }
    if (t == _ibecfnye.FeedItemKind) {
      return _ibecfnye.FeedItemKind.fromJson(data) as T;
    }
    if (t == _it29bb7l.FeedSection) {
      return _it29bb7l.FeedSection.fromJson(data) as T;
    }
    if (t == _iebgsa3d.FeedSectionKind) {
      return _iebgsa3d.FeedSectionKind.fromJson(data) as T;
    }
    if (t == _in19kjfm.HomeFeedCursor) {
      return _in19kjfm.HomeFeedCursor.fromJson(data) as T;
    }
    if (t == _ihgqdd8m.HomeFeedPage) {
      return _ihgqdd8m.HomeFeedPage.fromJson(data) as T;
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
    if (t == _il6n38yd.LiveChatMessageView) {
      return _il6n38yd.LiveChatMessageView.fromJson(data) as T;
    }
    if (t == _i7dasvmg.LiveEvent) {
      return _i7dasvmg.LiveEvent.fromJson(data) as T;
    }
    if (t == _ilchcp3h.LiveEventKind) {
      return _ilchcp3h.LiveEventKind.fromJson(data) as T;
    }
    if (t == _igpp3v1h.LiveHandView) {
      return _igpp3v1h.LiveHandView.fromJson(data) as T;
    }
    if (t == _ij3uatdc.LiveMediaGrant) {
      return _ij3uatdc.LiveMediaGrant.fromJson(data) as T;
    }
    if (t == _ildi0w8j.LiveMediaGrantRole) {
      return _ildi0w8j.LiveMediaGrantRole.fromJson(data) as T;
    }
    if (t == _i1t7par0.LiveSanctionKind) {
      return _i1t7par0.LiveSanctionKind.fromJson(data) as T;
    }
    if (t == _irbd4xwy.LiveShowAccess) {
      return _irbd4xwy.LiveShowAccess.fromJson(data) as T;
    }
    if (t == _ixjiwb6f.LiveShowDraft) {
      return _ixjiwb6f.LiveShowDraft.fromJson(data) as T;
    }
    if (t == _ixmm5757.LiveShowGuestStatus) {
      return _ixmm5757.LiveShowGuestStatus.fromJson(data) as T;
    }
    if (t == _ibpln05y.LiveShowRole) {
      return _ibpln05y.LiveShowRole.fromJson(data) as T;
    }
    if (t == _i60g3ahg.LiveShowStatus) {
      return _i60g3ahg.LiveShowStatus.fromJson(data) as T;
    }
    if (t == _iky3rvks.LiveShowView) {
      return _iky3rvks.LiveShowView.fromJson(data) as T;
    }
    if (t == _iafzpzjd.LiveSpeakerView) {
      return _iafzpzjd.LiveSpeakerView.fromJson(data) as T;
    }
    if (t == _ivrg75i3.LiveStageView) {
      return _ivrg75i3.LiveStageView.fromJson(data) as T;
    }
    if (t == _i54ek7if.ConversationPage) {
      return _i54ek7if.ConversationPage.fromJson(data) as T;
    }
    if (t == _iea0s5ku.ConversationView) {
      return _iea0s5ku.ConversationView.fromJson(data) as T;
    }
    if (t == _i56rpfla.DirectMessageEvent) {
      return _i56rpfla.DirectMessageEvent.fromJson(data) as T;
    }
    if (t == _ixoqahhg.DirectMessageEventKind) {
      return _ixoqahhg.DirectMessageEventKind.fromJson(data) as T;
    }
    if (t == _igwk6oho.DirectMessagePage) {
      return _igwk6oho.DirectMessagePage.fromJson(data) as T;
    }
    if (t == _ikbrq2q8.DirectMessageView) {
      return _ikbrq2q8.DirectMessageView.fromJson(data) as T;
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
    if (t == _iuphy7om.NotificationKind) {
      return _iuphy7om.NotificationKind.fromJson(data) as T;
    }
    if (t == _ipp18xpo.NotificationPage) {
      return _ipp18xpo.NotificationPage.fromJson(data) as T;
    }
    if (t == _imgpiqz3.NotificationView) {
      return _imgpiqz3.NotificationView.fromJson(data) as T;
    }
    if (t == _il66wur0.SearchResults) {
      return _il66wur0.SearchResults.fromJson(data) as T;
    }
    if (t == _i6r55qgl.FollowPage) {
      return _i6r55qgl.FollowPage.fromJson(data) as T;
    }
    if (t == _ihy6a719.FollowState) {
      return _ihy6a719.FollowState.fromJson(data) as T;
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
    if (t == _isc.getType<_ipgmhy3o.FeedItem?>()) {
      return (data != null ? _ipgmhy3o.FeedItem.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_ibecfnye.FeedItemKind?>()) {
      return (data != null ? _ibecfnye.FeedItemKind.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_it29bb7l.FeedSection?>()) {
      return (data != null ? _it29bb7l.FeedSection.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_iebgsa3d.FeedSectionKind?>()) {
      return (data != null ? _iebgsa3d.FeedSectionKind.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_in19kjfm.HomeFeedCursor?>()) {
      return (data != null ? _in19kjfm.HomeFeedCursor.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_ihgqdd8m.HomeFeedPage?>()) {
      return (data != null ? _ihgqdd8m.HomeFeedPage.fromJson(data) : null) as T;
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
    if (t == _isc.getType<_il6n38yd.LiveChatMessageView?>()) {
      return (data != null
              ? _il6n38yd.LiveChatMessageView.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_i7dasvmg.LiveEvent?>()) {
      return (data != null ? _i7dasvmg.LiveEvent.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_ilchcp3h.LiveEventKind?>()) {
      return (data != null ? _ilchcp3h.LiveEventKind.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_igpp3v1h.LiveHandView?>()) {
      return (data != null ? _igpp3v1h.LiveHandView.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_ij3uatdc.LiveMediaGrant?>()) {
      return (data != null ? _ij3uatdc.LiveMediaGrant.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_ildi0w8j.LiveMediaGrantRole?>()) {
      return (data != null ? _ildi0w8j.LiveMediaGrantRole.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_i1t7par0.LiveSanctionKind?>()) {
      return (data != null ? _i1t7par0.LiveSanctionKind.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_irbd4xwy.LiveShowAccess?>()) {
      return (data != null ? _irbd4xwy.LiveShowAccess.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_ixjiwb6f.LiveShowDraft?>()) {
      return (data != null ? _ixjiwb6f.LiveShowDraft.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_ixmm5757.LiveShowGuestStatus?>()) {
      return (data != null
              ? _ixmm5757.LiveShowGuestStatus.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_ibpln05y.LiveShowRole?>()) {
      return (data != null ? _ibpln05y.LiveShowRole.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_i60g3ahg.LiveShowStatus?>()) {
      return (data != null ? _i60g3ahg.LiveShowStatus.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_iky3rvks.LiveShowView?>()) {
      return (data != null ? _iky3rvks.LiveShowView.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_iafzpzjd.LiveSpeakerView?>()) {
      return (data != null ? _iafzpzjd.LiveSpeakerView.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_ivrg75i3.LiveStageView?>()) {
      return (data != null ? _ivrg75i3.LiveStageView.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_i54ek7if.ConversationPage?>()) {
      return (data != null ? _i54ek7if.ConversationPage.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_iea0s5ku.ConversationView?>()) {
      return (data != null ? _iea0s5ku.ConversationView.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_i56rpfla.DirectMessageEvent?>()) {
      return (data != null ? _i56rpfla.DirectMessageEvent.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_ixoqahhg.DirectMessageEventKind?>()) {
      return (data != null
              ? _ixoqahhg.DirectMessageEventKind.fromJson(data)
              : null)
          as T;
    }
    if (t == _isc.getType<_igwk6oho.DirectMessagePage?>()) {
      return (data != null ? _igwk6oho.DirectMessagePage.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_ikbrq2q8.DirectMessageView?>()) {
      return (data != null ? _ikbrq2q8.DirectMessageView.fromJson(data) : null)
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
    if (t == _isc.getType<_iuphy7om.NotificationKind?>()) {
      return (data != null ? _iuphy7om.NotificationKind.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_ipp18xpo.NotificationPage?>()) {
      return (data != null ? _ipp18xpo.NotificationPage.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_imgpiqz3.NotificationView?>()) {
      return (data != null ? _imgpiqz3.NotificationView.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_il66wur0.SearchResults?>()) {
      return (data != null ? _il66wur0.SearchResults.fromJson(data) : null)
          as T;
    }
    if (t == _isc.getType<_i6r55qgl.FollowPage?>()) {
      return (data != null ? _i6r55qgl.FollowPage.fromJson(data) : null) as T;
    }
    if (t == _isc.getType<_ihy6a719.FollowState?>()) {
      return (data != null ? _ihy6a719.FollowState.fromJson(data) : null) as T;
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
    if (t == List<_ipgmhy3o.FeedItem>) {
      return (data as List)
              .map((e) => deserialize<_ipgmhy3o.FeedItem>(e))
              .toList()
          as T;
    }
    if (t == List<_i8sfv82t.ProfileView>) {
      return (data as List)
              .map((e) => deserialize<_i8sfv82t.ProfileView>(e))
              .toList()
          as T;
    }
    if (t == List<_it29bb7l.FeedSection>) {
      return (data as List)
              .map((e) => deserialize<_it29bb7l.FeedSection>(e))
              .toList()
          as T;
    }
    if (t == List<_il6n38yd.LiveChatMessageView>) {
      return (data as List)
              .map((e) => deserialize<_il6n38yd.LiveChatMessageView>(e))
              .toList()
          as T;
    }
    if (t == _isc.getType<List<_il6n38yd.LiveChatMessageView>?>()) {
      return (data != null
              ? (data as List)
                    .map((e) => deserialize<_il6n38yd.LiveChatMessageView>(e))
                    .toList()
              : null)
          as T;
    }
    if (t == List<_isc.UuidValue>) {
      return (data as List).map((e) => deserialize<_isc.UuidValue>(e)).toList()
          as T;
    }
    if (t == List<_iafzpzjd.LiveSpeakerView>) {
      return (data as List)
              .map((e) => deserialize<_iafzpzjd.LiveSpeakerView>(e))
              .toList()
          as T;
    }
    if (t == List<_igpp3v1h.LiveHandView>) {
      return (data as List)
              .map((e) => deserialize<_igpp3v1h.LiveHandView>(e))
              .toList()
          as T;
    }
    if (t == List<_iea0s5ku.ConversationView>) {
      return (data as List)
              .map((e) => deserialize<_iea0s5ku.ConversationView>(e))
              .toList()
          as T;
    }
    if (t == List<_ikbrq2q8.DirectMessageView>) {
      return (data as List)
              .map((e) => deserialize<_ikbrq2q8.DirectMessageView>(e))
              .toList()
          as T;
    }
    if (t == List<_imgpiqz3.NotificationView>) {
      return (data as List)
              .map((e) => deserialize<_imgpiqz3.NotificationView>(e))
              .toList()
          as T;
    }
    if (t == List<_iky3rvks.LiveShowView>) {
      return (data as List)
              .map((e) => deserialize<_iky3rvks.LiveShowView>(e))
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
    if (t == List<_igcmn4rt.LiveShowView>) {
      return (data as List)
              .map((e) => deserialize<_igcmn4rt.LiveShowView>(e))
              .toList()
          as T;
    }
    if (t == List<_iksujo4g.LiveChatMessageView>) {
      return (data as List)
              .map((e) => deserialize<_iksujo4g.LiveChatMessageView>(e))
              .toList()
          as T;
    }
    if (t == List<_ij26twz2.ReportQueueItem>) {
      return (data as List)
              .map((e) => deserialize<_ij26twz2.ReportQueueItem>(e))
              .toList()
          as T;
    }
    if (t == List<int>) {
      return (data as List).map((e) => deserialize<int>(e)).toList() as T;
    }
    if (t == List<_iaqpe3js.ProfileView>) {
      return (data as List)
              .map((e) => deserialize<_iaqpe3js.ProfileView>(e))
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
      _ipgmhy3o.FeedItem => 'FeedItem',
      _ibecfnye.FeedItemKind => 'FeedItemKind',
      _it29bb7l.FeedSection => 'FeedSection',
      _iebgsa3d.FeedSectionKind => 'FeedSectionKind',
      _in19kjfm.HomeFeedCursor => 'HomeFeedCursor',
      _ihgqdd8m.HomeFeedPage => 'HomeFeedPage',
      _i96mabue.AccountStatus => 'AccountStatus',
      _ig9ziu3q.AccountView => 'AccountView',
      _i3rezn75.ProfileEdit => 'ProfileEdit',
      _i8sfv82t.ProfileView => 'ProfileView',
      _i1f8s3dp.VerificationStatus => 'VerificationStatus',
      _il6n38yd.LiveChatMessageView => 'LiveChatMessageView',
      _i7dasvmg.LiveEvent => 'LiveEvent',
      _ilchcp3h.LiveEventKind => 'LiveEventKind',
      _igpp3v1h.LiveHandView => 'LiveHandView',
      _ij3uatdc.LiveMediaGrant => 'LiveMediaGrant',
      _ildi0w8j.LiveMediaGrantRole => 'LiveMediaGrantRole',
      _i1t7par0.LiveSanctionKind => 'LiveSanctionKind',
      _irbd4xwy.LiveShowAccess => 'LiveShowAccess',
      _ixjiwb6f.LiveShowDraft => 'LiveShowDraft',
      _ixmm5757.LiveShowGuestStatus => 'LiveShowGuestStatus',
      _ibpln05y.LiveShowRole => 'LiveShowRole',
      _i60g3ahg.LiveShowStatus => 'LiveShowStatus',
      _iky3rvks.LiveShowView => 'LiveShowView',
      _iafzpzjd.LiveSpeakerView => 'LiveSpeakerView',
      _ivrg75i3.LiveStageView => 'LiveStageView',
      _i54ek7if.ConversationPage => 'ConversationPage',
      _iea0s5ku.ConversationView => 'ConversationView',
      _i56rpfla.DirectMessageEvent => 'DirectMessageEvent',
      _ixoqahhg.DirectMessageEventKind => 'DirectMessageEventKind',
      _igwk6oho.DirectMessagePage => 'DirectMessagePage',
      _ikbrq2q8.DirectMessageView => 'DirectMessageView',
      _ipkc12ge.ModerationReason => 'ModerationReason',
      _ib61hwyt.ReportDecision => 'ReportDecision',
      _itr0x2qd.ReportQueueItem => 'ReportQueueItem',
      _id3n49vv.ReportSeverity => 'ReportSeverity',
      _i5s3tooi.ReportTargetType => 'ReportTargetType',
      _iuphy7om.NotificationKind => 'NotificationKind',
      _ipp18xpo.NotificationPage => 'NotificationPage',
      _imgpiqz3.NotificationView => 'NotificationView',
      _il66wur0.SearchResults => 'SearchResults',
      _i6r55qgl.FollowPage => 'FollowPage',
      _ihy6a719.FollowState => 'FollowState',
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
      case _ipgmhy3o.FeedItem():
        return 'FeedItem';
      case _ibecfnye.FeedItemKind():
        return 'FeedItemKind';
      case _it29bb7l.FeedSection():
        return 'FeedSection';
      case _iebgsa3d.FeedSectionKind():
        return 'FeedSectionKind';
      case _in19kjfm.HomeFeedCursor():
        return 'HomeFeedCursor';
      case _ihgqdd8m.HomeFeedPage():
        return 'HomeFeedPage';
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
      case _il6n38yd.LiveChatMessageView():
        return 'LiveChatMessageView';
      case _i7dasvmg.LiveEvent():
        return 'LiveEvent';
      case _ilchcp3h.LiveEventKind():
        return 'LiveEventKind';
      case _igpp3v1h.LiveHandView():
        return 'LiveHandView';
      case _ij3uatdc.LiveMediaGrant():
        return 'LiveMediaGrant';
      case _ildi0w8j.LiveMediaGrantRole():
        return 'LiveMediaGrantRole';
      case _i1t7par0.LiveSanctionKind():
        return 'LiveSanctionKind';
      case _irbd4xwy.LiveShowAccess():
        return 'LiveShowAccess';
      case _ixjiwb6f.LiveShowDraft():
        return 'LiveShowDraft';
      case _ixmm5757.LiveShowGuestStatus():
        return 'LiveShowGuestStatus';
      case _ibpln05y.LiveShowRole():
        return 'LiveShowRole';
      case _i60g3ahg.LiveShowStatus():
        return 'LiveShowStatus';
      case _iky3rvks.LiveShowView():
        return 'LiveShowView';
      case _iafzpzjd.LiveSpeakerView():
        return 'LiveSpeakerView';
      case _ivrg75i3.LiveStageView():
        return 'LiveStageView';
      case _i54ek7if.ConversationPage():
        return 'ConversationPage';
      case _iea0s5ku.ConversationView():
        return 'ConversationView';
      case _i56rpfla.DirectMessageEvent():
        return 'DirectMessageEvent';
      case _ixoqahhg.DirectMessageEventKind():
        return 'DirectMessageEventKind';
      case _igwk6oho.DirectMessagePage():
        return 'DirectMessagePage';
      case _ikbrq2q8.DirectMessageView():
        return 'DirectMessageView';
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
      case _iuphy7om.NotificationKind():
        return 'NotificationKind';
      case _ipp18xpo.NotificationPage():
        return 'NotificationPage';
      case _imgpiqz3.NotificationView():
        return 'NotificationView';
      case _il66wur0.SearchResults():
        return 'SearchResults';
      case _i6r55qgl.FollowPage():
        return 'FollowPage';
      case _ihy6a719.FollowState():
        return 'FollowState';
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
    if (dataClassName == 'FeedItem') {
      return deserialize<_ipgmhy3o.FeedItem>(data['data']);
    }
    if (dataClassName == 'FeedItemKind') {
      return deserialize<_ibecfnye.FeedItemKind>(data['data']);
    }
    if (dataClassName == 'FeedSection') {
      return deserialize<_it29bb7l.FeedSection>(data['data']);
    }
    if (dataClassName == 'FeedSectionKind') {
      return deserialize<_iebgsa3d.FeedSectionKind>(data['data']);
    }
    if (dataClassName == 'HomeFeedCursor') {
      return deserialize<_in19kjfm.HomeFeedCursor>(data['data']);
    }
    if (dataClassName == 'HomeFeedPage') {
      return deserialize<_ihgqdd8m.HomeFeedPage>(data['data']);
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
    if (dataClassName == 'LiveChatMessageView') {
      return deserialize<_il6n38yd.LiveChatMessageView>(data['data']);
    }
    if (dataClassName == 'LiveEvent') {
      return deserialize<_i7dasvmg.LiveEvent>(data['data']);
    }
    if (dataClassName == 'LiveEventKind') {
      return deserialize<_ilchcp3h.LiveEventKind>(data['data']);
    }
    if (dataClassName == 'LiveHandView') {
      return deserialize<_igpp3v1h.LiveHandView>(data['data']);
    }
    if (dataClassName == 'LiveMediaGrant') {
      return deserialize<_ij3uatdc.LiveMediaGrant>(data['data']);
    }
    if (dataClassName == 'LiveMediaGrantRole') {
      return deserialize<_ildi0w8j.LiveMediaGrantRole>(data['data']);
    }
    if (dataClassName == 'LiveSanctionKind') {
      return deserialize<_i1t7par0.LiveSanctionKind>(data['data']);
    }
    if (dataClassName == 'LiveShowAccess') {
      return deserialize<_irbd4xwy.LiveShowAccess>(data['data']);
    }
    if (dataClassName == 'LiveShowDraft') {
      return deserialize<_ixjiwb6f.LiveShowDraft>(data['data']);
    }
    if (dataClassName == 'LiveShowGuestStatus') {
      return deserialize<_ixmm5757.LiveShowGuestStatus>(data['data']);
    }
    if (dataClassName == 'LiveShowRole') {
      return deserialize<_ibpln05y.LiveShowRole>(data['data']);
    }
    if (dataClassName == 'LiveShowStatus') {
      return deserialize<_i60g3ahg.LiveShowStatus>(data['data']);
    }
    if (dataClassName == 'LiveShowView') {
      return deserialize<_iky3rvks.LiveShowView>(data['data']);
    }
    if (dataClassName == 'LiveSpeakerView') {
      return deserialize<_iafzpzjd.LiveSpeakerView>(data['data']);
    }
    if (dataClassName == 'LiveStageView') {
      return deserialize<_ivrg75i3.LiveStageView>(data['data']);
    }
    if (dataClassName == 'ConversationPage') {
      return deserialize<_i54ek7if.ConversationPage>(data['data']);
    }
    if (dataClassName == 'ConversationView') {
      return deserialize<_iea0s5ku.ConversationView>(data['data']);
    }
    if (dataClassName == 'DirectMessageEvent') {
      return deserialize<_i56rpfla.DirectMessageEvent>(data['data']);
    }
    if (dataClassName == 'DirectMessageEventKind') {
      return deserialize<_ixoqahhg.DirectMessageEventKind>(data['data']);
    }
    if (dataClassName == 'DirectMessagePage') {
      return deserialize<_igwk6oho.DirectMessagePage>(data['data']);
    }
    if (dataClassName == 'DirectMessageView') {
      return deserialize<_ikbrq2q8.DirectMessageView>(data['data']);
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
    if (dataClassName == 'NotificationKind') {
      return deserialize<_iuphy7om.NotificationKind>(data['data']);
    }
    if (dataClassName == 'NotificationPage') {
      return deserialize<_ipp18xpo.NotificationPage>(data['data']);
    }
    if (dataClassName == 'NotificationView') {
      return deserialize<_imgpiqz3.NotificationView>(data['data']);
    }
    if (dataClassName == 'SearchResults') {
      return deserialize<_il66wur0.SearchResults>(data['data']);
    }
    if (dataClassName == 'FollowPage') {
      return deserialize<_i6r55qgl.FollowPage>(data['data']);
    }
    if (dataClassName == 'FollowState') {
      return deserialize<_ihy6a719.FollowState>(data['data']);
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
