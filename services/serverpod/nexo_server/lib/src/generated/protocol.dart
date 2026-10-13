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
import 'package:nexo_server/src/generated/modules/identity/models/profile_view.dart'
    as _i43ck6sm;
import 'package:nexo_server/src/generated/modules/live/models/live_chat_message_view.dart'
    as _i22oo2zh;
import 'package:nexo_server/src/generated/modules/live/models/live_show_view.dart'
    as _iqa1l3vk;
import 'package:nexo_server/src/generated/modules/moderation/models/report_queue_item.dart'
    as _im11zuld;
import 'package:serverpod/protocol.dart' as _isp;
import 'package:serverpod/serverpod.dart' as _is;
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart'
    as _iacs;
import 'package:serverpod_auth_idp_server/serverpod_auth_idp_server.dart'
    as _iais;
import 'future_calls_generated_models/live_show_future_call_expire_model.dart'
    as _ie5d2xvy;
import 'future_calls_generated_models/live_show_future_call_publish_replay_model.dart'
    as _iy3z9iri;
import 'future_calls_generated_models/live_show_future_call_remind_model.dart'
    as _iqr7hhpp;
import 'modules/content/models/media_upload_ticket.dart' as _i4efb2h6;
import 'modules/content/models/post.dart' as _i99cc7k2;
import 'modules/content/models/post_draft.dart' as _i71ym97j;
import 'modules/content/models/post_edit.dart' as _ijy0en9v;
import 'modules/content/models/post_media.dart' as _iyaae07t;
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
import 'modules/identity/models/account_profile.dart' as _i85zfh3f;
import 'modules/identity/models/account_status.dart' as _i96mabue;
import 'modules/identity/models/account_view.dart' as _ig9ziu3q;
import 'modules/identity/models/profile_edit.dart' as _i3rezn75;
import 'modules/identity/models/profile_view.dart' as _i8sfv82t;
import 'modules/identity/models/verification_status.dart' as _i1f8s3dp;
import 'modules/live/models/live_chat_message.dart' as _i4vd7apv;
import 'modules/live/models/live_chat_message_view.dart' as _il6n38yd;
import 'modules/live/models/live_event.dart' as _i7dasvmg;
import 'modules/live/models/live_event_kind.dart' as _ilchcp3h;
import 'modules/live/models/live_hand_view.dart' as _igpp3v1h;
import 'modules/live/models/live_host_ban.dart' as _ib5s9fd2;
import 'modules/live/models/live_media_grant.dart' as _ij3uatdc;
import 'modules/live/models/live_media_grant_role.dart' as _ildi0w8j;
import 'modules/live/models/live_participant.dart' as _i7uaaqjc;
import 'modules/live/models/live_sanction.dart' as _izxcblzl;
import 'modules/live/models/live_sanction_kind.dart' as _i1t7par0;
import 'modules/live/models/live_show.dart' as _i1mej27o;
import 'modules/live/models/live_show_access.dart' as _irbd4xwy;
import 'modules/live/models/live_show_draft.dart' as _ixjiwb6f;
import 'modules/live/models/live_show_guest.dart' as _iavthlak;
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
import 'modules/messages/models/dm_conversation.dart' as _iaz5gpy6;
import 'modules/messages/models/dm_message.dart' as _i5w9zcei;
import 'modules/moderation/models/content_report.dart' as _iwkeo1oc;
import 'modules/moderation/models/moderation_reason.dart' as _ipkc12ge;
import 'modules/moderation/models/report_decision.dart' as _ib61hwyt;
import 'modules/moderation/models/report_queue_item.dart' as _itr0x2qd;
import 'modules/moderation/models/report_severity.dart' as _id3n49vv;
import 'modules/moderation/models/report_target_type.dart' as _i5s3tooi;
import 'modules/notifications/models/notification_kind.dart' as _iuphy7om;
import 'modules/notifications/models/notification_page.dart' as _ipp18xpo;
import 'modules/notifications/models/notification_view.dart' as _imgpiqz3;
import 'modules/notifications/models/user_notification.dart' as _idxf743i;
import 'modules/search/models/search_results.dart' as _il66wur0;
import 'modules/social/models/follow.dart' as _i9ykk824;
import 'modules/social/models/follow_page.dart' as _i6r55qgl;
import 'modules/social/models/follow_state.dart' as _ihy6a719;
import 'modules/social/models/like_state.dart' as _i0kd3w76;
import 'modules/social/models/post_comment.dart' as _ir2psgaa;
import 'modules/social/models/post_comment_page.dart' as _iov9osdu;
import 'modules/social/models/post_comment_view.dart' as _i5ho22g4;
import 'modules/social/models/post_like.dart' as _ipr9oc1t;
import 'modules/social/models/post_liker.dart' as _ignoub8u;
import 'modules/social/models/post_liker_page.dart' as _iyfhrk15;
import 'shared/audit/audit_log.dart' as _iu8by7md;
import 'shared/errors/nexo_error_code.dart' as _idt8nicn;
import 'shared/errors/nexo_exception.dart' as _invvqh96;
import 'shared/pagination/page_cursor.dart' as _ihkyxh72;
export 'modules/content/models/media_upload_ticket.dart';
export 'modules/content/models/post.dart';
export 'modules/content/models/post_draft.dart';
export 'modules/content/models/post_edit.dart';
export 'modules/content/models/post_media.dart';
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
export 'modules/identity/models/account_profile.dart';
export 'modules/identity/models/account_status.dart';
export 'modules/identity/models/account_view.dart';
export 'modules/identity/models/profile_edit.dart';
export 'modules/identity/models/profile_view.dart';
export 'modules/identity/models/verification_status.dart';
export 'modules/live/models/live_chat_message.dart';
export 'modules/live/models/live_chat_message_view.dart';
export 'modules/live/models/live_event.dart';
export 'modules/live/models/live_event_kind.dart';
export 'modules/live/models/live_hand_view.dart';
export 'modules/live/models/live_host_ban.dart';
export 'modules/live/models/live_media_grant.dart';
export 'modules/live/models/live_media_grant_role.dart';
export 'modules/live/models/live_participant.dart';
export 'modules/live/models/live_sanction.dart';
export 'modules/live/models/live_sanction_kind.dart';
export 'modules/live/models/live_show.dart';
export 'modules/live/models/live_show_access.dart';
export 'modules/live/models/live_show_draft.dart';
export 'modules/live/models/live_show_guest.dart';
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
export 'modules/messages/models/dm_conversation.dart';
export 'modules/messages/models/dm_message.dart';
export 'modules/moderation/models/content_report.dart';
export 'modules/moderation/models/moderation_reason.dart';
export 'modules/moderation/models/report_decision.dart';
export 'modules/moderation/models/report_queue_item.dart';
export 'modules/moderation/models/report_severity.dart';
export 'modules/moderation/models/report_target_type.dart';
export 'modules/notifications/models/notification_kind.dart';
export 'modules/notifications/models/notification_page.dart';
export 'modules/notifications/models/notification_view.dart';
export 'modules/notifications/models/user_notification.dart';
export 'modules/search/models/search_results.dart';
export 'modules/social/models/follow.dart';
export 'modules/social/models/follow_page.dart';
export 'modules/social/models/follow_state.dart';
export 'modules/social/models/like_state.dart';
export 'modules/social/models/post_comment.dart';
export 'modules/social/models/post_comment_page.dart';
export 'modules/social/models/post_comment_view.dart';
export 'modules/social/models/post_like.dart';
export 'modules/social/models/post_liker.dart';
export 'modules/social/models/post_liker_page.dart';
export 'shared/audit/audit_log.dart';
export 'shared/errors/nexo_error_code.dart';
export 'shared/errors/nexo_exception.dart';
export 'shared/pagination/page_cursor.dart';

class Protocol extends _is.DatabaseSerializationManager {
  Protocol._();

  factory Protocol() => _instance;

  static final Protocol _instance = Protocol._().._registerHostProtocols();

  static List<_isp.TableDefinition> get targetTableDefinitions => [
    _isp.TableDefinition(
      name: 'account_profile',
      dartName: 'AccountProfile',
      schema: 'public',
      module: 'nexo',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'authUserId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'username',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'bio',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'avatarKey',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'coverKey',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'website',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'isCreator',
          columnType: _isp.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'false',
        ),
        _isp.ColumnDefinition(
          name: 'verification',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:VerificationStatus',
          columnDefault: '\'none\'',
        ),
        _isp.ColumnDefinition(
          name: 'status',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:AccountStatus',
          columnDefault: '\'active\'',
        ),
        _isp.ColumnDefinition(
          name: 'followerCount',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '0',
        ),
        _isp.ColumnDefinition(
          name: 'followingCount',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '0',
        ),
        _isp.ColumnDefinition(
          name: 'createdAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
          columnDefault: 'now',
        ),
        _isp.ColumnDefinition(
          name: 'updatedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'account_profile_user_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'authUserId',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'account_profile_username_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'username',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'audit_log',
      dartName: 'AuditLog',
      schema: 'public',
      module: 'nexo',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'actorId',
          columnType: _isp.ColumnType.uuid,
          isNullable: true,
          dartType: 'UuidValue?',
        ),
        _isp.ColumnDefinition(
          name: 'action',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'entityType',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'entityId',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'metadataJson',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'createdAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
          columnDefault: 'now',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'audit_log_entity_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'entityType',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'entityId',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'audit_log_actor_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'actorId',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'content_report',
      dartName: 'ContentReport',
      schema: 'public',
      module: 'nexo',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'targetType',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:ReportTargetType',
        ),
        _isp.ColumnDefinition(
          name: 'targetId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'targetAuthorId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'reporterId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'reason',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:ModerationReason',
        ),
        _isp.ColumnDefinition(
          name: 'severity',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'protocol:ReportSeverity',
        ),
        _isp.ColumnDefinition(
          name: 'details',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'String?',
        ),
        _isp.ColumnDefinition(
          name: 'createdAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
          columnDefault: 'now',
        ),
        _isp.ColumnDefinition(
          name: 'resolvedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _isp.ColumnDefinition(
          name: 'resolvedBy',
          columnType: _isp.ColumnType.uuid,
          isNullable: true,
          dartType: 'UuidValue?',
        ),
        _isp.ColumnDefinition(
          name: 'decision',
          columnType: _isp.ColumnType.text,
          isNullable: true,
          dartType: 'protocol:ReportDecision?',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'content_report_target_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'targetType',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'targetId',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'content_report_open_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'resolvedAt',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'severity',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'dm_conversation',
      dartName: 'DmConversation',
      schema: 'public',
      module: 'nexo',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'userA',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'userB',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'lastReadA',
          columnType: _isp.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _isp.ColumnDefinition(
          name: 'lastReadB',
          columnType: _isp.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _isp.ColumnDefinition(
          name: 'lastMessageId',
          columnType: _isp.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _isp.ColumnDefinition(
          name: 'lastActivityAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
          columnDefault: 'now',
        ),
        _isp.ColumnDefinition(
          name: 'createdAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
          columnDefault: 'now',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'dm_conversation_pair_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'userA',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'userB',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'dm_conversation_a_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'userA',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'lastActivityAt',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'dm_conversation_b_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'userB',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'lastActivityAt',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'dm_message',
      dartName: 'DmMessage',
      schema: 'public',
      module: 'nexo',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'conversationId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'authorId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'body',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'createdAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
          columnDefault: 'now',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'dm_message_fk_0',
          columns: ['conversationId'],
          referenceTable: 'dm_conversation',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'dm_message_thread_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'conversationId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'follow',
      dartName: 'Follow',
      schema: 'public',
      module: 'nexo',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'followerId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'followeeId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'createdAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
          columnDefault: 'now',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'follow_pair_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'followerId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'followeeId',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'follow_followee_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'followeeId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'createdAt',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'follow_follower_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'followerId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'createdAt',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'live_chat_message',
      dartName: 'LiveChatMessage',
      schema: 'public',
      module: 'nexo',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'showId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'authorId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'body',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'createdAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
          columnDefault: 'now',
        ),
        _isp.ColumnDefinition(
          name: 'hiddenAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _isp.ColumnDefinition(
          name: 'hiddenBy',
          columnType: _isp.ColumnType.uuid,
          isNullable: true,
          dartType: 'UuidValue?',
        ),
        _isp.ColumnDefinition(
          name: 'deletedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _isp.ColumnDefinition(
          name: 'deletedBy',
          columnType: _isp.ColumnType.uuid,
          isNullable: true,
          dartType: 'UuidValue?',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'live_chat_message_fk_0',
          columns: ['showId'],
          referenceTable: 'live_show',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'live_chat_message_show_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'showId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'live_host_ban',
      dartName: 'LiveHostBan',
      schema: 'public',
      module: 'nexo',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'hostId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'userId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'actorId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'createdAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
          columnDefault: 'now',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'live_host_ban_unique_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'hostId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'userId',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'live_participant',
      dartName: 'LiveParticipant',
      schema: 'public',
      module: 'nexo',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'showId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'userId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'role',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:LiveShowRole',
        ),
        _isp.ColumnDefinition(
          name: 'onStage',
          columnType: _isp.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'false',
        ),
        _isp.ColumnDefinition(
          name: 'handRaisedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _isp.ColumnDefinition(
          name: 'micMuted',
          columnType: _isp.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'false',
        ),
        _isp.ColumnDefinition(
          name: 'cameraOn',
          columnType: _isp.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'false',
        ),
        _isp.ColumnDefinition(
          name: 'updatedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
          columnDefault: 'now',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'live_participant_fk_0',
          columns: ['showId'],
          referenceTable: 'live_show',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'live_participant_unique_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'showId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'userId',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'live_sanction',
      dartName: 'LiveSanction',
      schema: 'public',
      module: 'nexo',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'showId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'targetId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'kind',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:LiveSanctionKind',
        ),
        _isp.ColumnDefinition(
          name: 'until',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _isp.ColumnDefinition(
          name: 'actorId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'createdAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
          columnDefault: 'now',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'live_sanction_fk_0',
          columns: ['showId'],
          referenceTable: 'live_show',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'live_sanction_target_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'showId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'targetId',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'live_show',
      dartName: 'LiveShow',
      schema: 'public',
      module: 'nexo',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'hostId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'title',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'description',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
          columnDefault: '\'\'',
        ),
        _isp.ColumnDefinition(
          name: 'startsAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
        ),
        _isp.ColumnDefinition(
          name: 'durationMinutes',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '60',
        ),
        _isp.ColumnDefinition(
          name: 'access',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:LiveShowAccess',
        ),
        _isp.ColumnDefinition(
          name: 'allowQuestions',
          columnType: _isp.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'true',
        ),
        _isp.ColumnDefinition(
          name: 'recordReplay',
          columnType: _isp.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'true',
        ),
        _isp.ColumnDefinition(
          name: 'status',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:LiveShowStatus',
        ),
        _isp.ColumnDefinition(
          name: 'startedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _isp.ColumnDefinition(
          name: 'endedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _isp.ColumnDefinition(
          name: 'endedBy',
          columnType: _isp.ColumnType.uuid,
          isNullable: true,
          dartType: 'UuidValue?',
        ),
        _isp.ColumnDefinition(
          name: 'endedByModeration',
          columnType: _isp.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'false',
        ),
        _isp.ColumnDefinition(
          name: 'viewerPeak',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '0',
        ),
        _isp.ColumnDefinition(
          name: 'pinnedMessageId',
          columnType: _isp.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _isp.ColumnDefinition(
          name: 'highlightedMessageId',
          columnType: _isp.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _isp.ColumnDefinition(
          name: 'createdAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
          columnDefault: 'now',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'live_show_status_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'status',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'startsAt',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'live_show_host_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'hostId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'startsAt',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'live_show_guest',
      dartName: 'LiveShowGuest',
      schema: 'public',
      module: 'nexo',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'showId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'userId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'status',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:LiveShowGuestStatus',
        ),
        _isp.ColumnDefinition(
          name: 'createdAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
          columnDefault: 'now',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'live_show_guest_fk_0',
          columns: ['showId'],
          referenceTable: 'live_show',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'live_show_guest_unique_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'showId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'userId',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'post',
      dartName: 'Post',
      schema: 'public',
      module: 'nexo',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'authorId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'body',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'tags',
          columnType: _isp.ColumnType.json,
          isNullable: false,
          dartType: 'List<String>',
        ),
        _isp.ColumnDefinition(
          name: 'visibility',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:PostVisibility',
        ),
        _isp.ColumnDefinition(
          name: 'allowComments',
          columnType: _isp.ColumnType.boolean,
          isNullable: false,
          dartType: 'bool',
          columnDefault: 'true',
        ),
        _isp.ColumnDefinition(
          name: 'likeCount',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '0',
        ),
        _isp.ColumnDefinition(
          name: 'commentCount',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
          columnDefault: '0',
        ),
        _isp.ColumnDefinition(
          name: 'createdAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
          columnDefault: 'now',
        ),
        _isp.ColumnDefinition(
          name: 'editedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _isp.ColumnDefinition(
          name: 'deletedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _isp.ColumnDefinition(
          name: 'deletedBy',
          columnType: _isp.ColumnType.uuid,
          isNullable: true,
          dartType: 'UuidValue?',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'post_feed_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'createdAt',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'post_author_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'authorId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'createdAt',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'post_comment',
      dartName: 'PostComment',
      schema: 'public',
      module: 'nexo',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'postId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'authorId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'body',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'createdAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
          columnDefault: 'now',
        ),
        _isp.ColumnDefinition(
          name: 'deletedAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _isp.ColumnDefinition(
          name: 'deletedBy',
          columnType: _isp.ColumnType.uuid,
          isNullable: true,
          dartType: 'UuidValue?',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'post_comment_fk_0',
          columns: ['postId'],
          referenceTable: 'post',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'post_comment_thread_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'postId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'createdAt',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'id',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'post_like',
      dartName: 'PostLike',
      schema: 'public',
      module: 'nexo',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'postId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'userId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'createdAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
          columnDefault: 'now',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'post_like_fk_0',
          columns: ['postId'],
          referenceTable: 'post',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'post_like_user_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'postId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'userId',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'post_like_recent_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'postId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'createdAt',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'post_media',
      dartName: 'PostMedia',
      schema: 'public',
      module: 'nexo',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'postId',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
        _isp.ColumnDefinition(
          name: 'kind',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:PostMediaKind',
        ),
        _isp.ColumnDefinition(
          name: 'storageKey',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'contentType',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'String',
        ),
        _isp.ColumnDefinition(
          name: 'position',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int',
        ),
      ],
      foreignKeys: [
        _isp.ForeignKeyDefinition(
          constraintName: 'post_media_fk_0',
          columns: ['postId'],
          referenceTable: 'post',
          referenceTableSchema: 'public',
          referenceColumns: ['id'],
          onUpdate: _isp.ForeignKeyAction.noAction,
          onDelete: _isp.ForeignKeyAction.cascade,
          matchType: null,
        ),
      ],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'post_media_storage_key_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'storageKey',
            ),
          ],
          type: 'btree',
          isUnique: true,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'post_media_post_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'postId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'position',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    _isp.TableDefinition(
      name: 'user_notification',
      dartName: 'UserNotification',
      schema: 'public',
      module: 'nexo',
      columns: [
        _isp.ColumnDefinition(
          name: 'id',
          columnType: _isp.ColumnType.bigint,
          isNullable: false,
          dartType: 'int?',
          columnDefault: 'serial',
        ),
        _isp.ColumnDefinition(
          name: 'userId',
          columnType: _isp.ColumnType.uuid,
          isNullable: false,
          dartType: 'UuidValue',
        ),
        _isp.ColumnDefinition(
          name: 'kind',
          columnType: _isp.ColumnType.text,
          isNullable: false,
          dartType: 'protocol:NotificationKind',
        ),
        _isp.ColumnDefinition(
          name: 'actorId',
          columnType: _isp.ColumnType.uuid,
          isNullable: true,
          dartType: 'UuidValue?',
        ),
        _isp.ColumnDefinition(
          name: 'postId',
          columnType: _isp.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _isp.ColumnDefinition(
          name: 'showId',
          columnType: _isp.ColumnType.bigint,
          isNullable: true,
          dartType: 'int?',
        ),
        _isp.ColumnDefinition(
          name: 'readAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: true,
          dartType: 'DateTime?',
        ),
        _isp.ColumnDefinition(
          name: 'createdAt',
          columnType: _isp.ColumnType.timestampWithoutTimeZone,
          isNullable: false,
          dartType: 'DateTime',
          columnDefault: 'now',
        ),
      ],
      foreignKeys: [],
      indexes: [
        _isp.IndexDefinition(
          indexName: 'user_notification_feed_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'userId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'createdAt',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
        _isp.IndexDefinition(
          indexName: 'user_notification_unread_idx',
          tableSpace: null,
          elements: [
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'userId',
            ),
            _isp.IndexElementDefinition(
              type: _isp.IndexElementDefinitionType.column,
              definition: 'readAt',
            ),
          ],
          type: 'btree',
          isUnique: false,
          isPrimary: false,
        ),
      ],
      managed: true,
    ),
    ..._iais.Protocol.targetTableDefinitions,
    ..._iacs.Protocol.targetTableDefinitions,
    ..._isp.Protocol.targetTableDefinitions,
  ];

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
      } on _is.DeserializationClassNameNotFoundException catch (_) {
        // If the className is not recognized (e.g., older client receiving
        // data with a new subtype), fall back to deserializing without the
        // className, using the expected type T.
      }
    }

    if (t == _ie5d2xvy.LiveShowFutureCallExpireModel) {
      return _ie5d2xvy.LiveShowFutureCallExpireModel.fromJson(data) as T;
    }
    if (t == _iy3z9iri.LiveShowFutureCallPublishReplayModel) {
      return _iy3z9iri.LiveShowFutureCallPublishReplayModel.fromJson(data) as T;
    }
    if (t == _iqr7hhpp.LiveShowFutureCallRemindModel) {
      return _iqr7hhpp.LiveShowFutureCallRemindModel.fromJson(data) as T;
    }
    if (t == _i4efb2h6.MediaUploadTicket) {
      return _i4efb2h6.MediaUploadTicket.fromJson(data) as T;
    }
    if (t == _i99cc7k2.Post) {
      return _i99cc7k2.Post.fromJson(data) as T;
    }
    if (t == _i71ym97j.PostDraft) {
      return _i71ym97j.PostDraft.fromJson(data) as T;
    }
    if (t == _ijy0en9v.PostEdit) {
      return _ijy0en9v.PostEdit.fromJson(data) as T;
    }
    if (t == _iyaae07t.PostMedia) {
      return _iyaae07t.PostMedia.fromJson(data) as T;
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
    if (t == _i85zfh3f.AccountProfile) {
      return _i85zfh3f.AccountProfile.fromJson(data) as T;
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
    if (t == _i4vd7apv.LiveChatMessage) {
      return _i4vd7apv.LiveChatMessage.fromJson(data) as T;
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
    if (t == _ib5s9fd2.LiveHostBan) {
      return _ib5s9fd2.LiveHostBan.fromJson(data) as T;
    }
    if (t == _ij3uatdc.LiveMediaGrant) {
      return _ij3uatdc.LiveMediaGrant.fromJson(data) as T;
    }
    if (t == _ildi0w8j.LiveMediaGrantRole) {
      return _ildi0w8j.LiveMediaGrantRole.fromJson(data) as T;
    }
    if (t == _i7uaaqjc.LiveParticipant) {
      return _i7uaaqjc.LiveParticipant.fromJson(data) as T;
    }
    if (t == _izxcblzl.LiveSanction) {
      return _izxcblzl.LiveSanction.fromJson(data) as T;
    }
    if (t == _i1t7par0.LiveSanctionKind) {
      return _i1t7par0.LiveSanctionKind.fromJson(data) as T;
    }
    if (t == _i1mej27o.LiveShow) {
      return _i1mej27o.LiveShow.fromJson(data) as T;
    }
    if (t == _irbd4xwy.LiveShowAccess) {
      return _irbd4xwy.LiveShowAccess.fromJson(data) as T;
    }
    if (t == _ixjiwb6f.LiveShowDraft) {
      return _ixjiwb6f.LiveShowDraft.fromJson(data) as T;
    }
    if (t == _iavthlak.LiveShowGuest) {
      return _iavthlak.LiveShowGuest.fromJson(data) as T;
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
    if (t == _iaz5gpy6.DmConversation) {
      return _iaz5gpy6.DmConversation.fromJson(data) as T;
    }
    if (t == _i5w9zcei.DmMessage) {
      return _i5w9zcei.DmMessage.fromJson(data) as T;
    }
    if (t == _iwkeo1oc.ContentReport) {
      return _iwkeo1oc.ContentReport.fromJson(data) as T;
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
    if (t == _idxf743i.UserNotification) {
      return _idxf743i.UserNotification.fromJson(data) as T;
    }
    if (t == _il66wur0.SearchResults) {
      return _il66wur0.SearchResults.fromJson(data) as T;
    }
    if (t == _i9ykk824.Follow) {
      return _i9ykk824.Follow.fromJson(data) as T;
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
    if (t == _ir2psgaa.PostComment) {
      return _ir2psgaa.PostComment.fromJson(data) as T;
    }
    if (t == _iov9osdu.PostCommentPage) {
      return _iov9osdu.PostCommentPage.fromJson(data) as T;
    }
    if (t == _i5ho22g4.PostCommentView) {
      return _i5ho22g4.PostCommentView.fromJson(data) as T;
    }
    if (t == _ipr9oc1t.PostLike) {
      return _ipr9oc1t.PostLike.fromJson(data) as T;
    }
    if (t == _ignoub8u.PostLiker) {
      return _ignoub8u.PostLiker.fromJson(data) as T;
    }
    if (t == _iyfhrk15.PostLikerPage) {
      return _iyfhrk15.PostLikerPage.fromJson(data) as T;
    }
    if (t == _iu8by7md.AuditLog) {
      return _iu8by7md.AuditLog.fromJson(data) as T;
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
    if (t == _is.getType<_ie5d2xvy.LiveShowFutureCallExpireModel?>()) {
      return (data != null
              ? _ie5d2xvy.LiveShowFutureCallExpireModel.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_iy3z9iri.LiveShowFutureCallPublishReplayModel?>()) {
      return (data != null
              ? _iy3z9iri.LiveShowFutureCallPublishReplayModel.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_iqr7hhpp.LiveShowFutureCallRemindModel?>()) {
      return (data != null
              ? _iqr7hhpp.LiveShowFutureCallRemindModel.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_i4efb2h6.MediaUploadTicket?>()) {
      return (data != null ? _i4efb2h6.MediaUploadTicket.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_i99cc7k2.Post?>()) {
      return (data != null ? _i99cc7k2.Post.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_i71ym97j.PostDraft?>()) {
      return (data != null ? _i71ym97j.PostDraft.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_ijy0en9v.PostEdit?>()) {
      return (data != null ? _ijy0en9v.PostEdit.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_iyaae07t.PostMedia?>()) {
      return (data != null ? _iyaae07t.PostMedia.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_iqr0e776.PostMediaKind?>()) {
      return (data != null ? _iqr0e776.PostMediaKind.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_ibyq15o7.PostMediaView?>()) {
      return (data != null ? _ibyq15o7.PostMediaView.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_idjwmytq.PostPage?>()) {
      return (data != null ? _idjwmytq.PostPage.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_ixt78pt4.PostView?>()) {
      return (data != null ? _ixt78pt4.PostView.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_iu5xfvn4.PostVisibility?>()) {
      return (data != null ? _iu5xfvn4.PostVisibility.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_ipgmhy3o.FeedItem?>()) {
      return (data != null ? _ipgmhy3o.FeedItem.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_ibecfnye.FeedItemKind?>()) {
      return (data != null ? _ibecfnye.FeedItemKind.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_it29bb7l.FeedSection?>()) {
      return (data != null ? _it29bb7l.FeedSection.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_iebgsa3d.FeedSectionKind?>()) {
      return (data != null ? _iebgsa3d.FeedSectionKind.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_in19kjfm.HomeFeedCursor?>()) {
      return (data != null ? _in19kjfm.HomeFeedCursor.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_ihgqdd8m.HomeFeedPage?>()) {
      return (data != null ? _ihgqdd8m.HomeFeedPage.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_i85zfh3f.AccountProfile?>()) {
      return (data != null ? _i85zfh3f.AccountProfile.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_i96mabue.AccountStatus?>()) {
      return (data != null ? _i96mabue.AccountStatus.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_ig9ziu3q.AccountView?>()) {
      return (data != null ? _ig9ziu3q.AccountView.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_i3rezn75.ProfileEdit?>()) {
      return (data != null ? _i3rezn75.ProfileEdit.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_i8sfv82t.ProfileView?>()) {
      return (data != null ? _i8sfv82t.ProfileView.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_i1f8s3dp.VerificationStatus?>()) {
      return (data != null ? _i1f8s3dp.VerificationStatus.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_i4vd7apv.LiveChatMessage?>()) {
      return (data != null ? _i4vd7apv.LiveChatMessage.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_il6n38yd.LiveChatMessageView?>()) {
      return (data != null
              ? _il6n38yd.LiveChatMessageView.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_i7dasvmg.LiveEvent?>()) {
      return (data != null ? _i7dasvmg.LiveEvent.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_ilchcp3h.LiveEventKind?>()) {
      return (data != null ? _ilchcp3h.LiveEventKind.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_igpp3v1h.LiveHandView?>()) {
      return (data != null ? _igpp3v1h.LiveHandView.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_ib5s9fd2.LiveHostBan?>()) {
      return (data != null ? _ib5s9fd2.LiveHostBan.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_ij3uatdc.LiveMediaGrant?>()) {
      return (data != null ? _ij3uatdc.LiveMediaGrant.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_ildi0w8j.LiveMediaGrantRole?>()) {
      return (data != null ? _ildi0w8j.LiveMediaGrantRole.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_i7uaaqjc.LiveParticipant?>()) {
      return (data != null ? _i7uaaqjc.LiveParticipant.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_izxcblzl.LiveSanction?>()) {
      return (data != null ? _izxcblzl.LiveSanction.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_i1t7par0.LiveSanctionKind?>()) {
      return (data != null ? _i1t7par0.LiveSanctionKind.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_i1mej27o.LiveShow?>()) {
      return (data != null ? _i1mej27o.LiveShow.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_irbd4xwy.LiveShowAccess?>()) {
      return (data != null ? _irbd4xwy.LiveShowAccess.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_ixjiwb6f.LiveShowDraft?>()) {
      return (data != null ? _ixjiwb6f.LiveShowDraft.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_iavthlak.LiveShowGuest?>()) {
      return (data != null ? _iavthlak.LiveShowGuest.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_ixmm5757.LiveShowGuestStatus?>()) {
      return (data != null
              ? _ixmm5757.LiveShowGuestStatus.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_ibpln05y.LiveShowRole?>()) {
      return (data != null ? _ibpln05y.LiveShowRole.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_i60g3ahg.LiveShowStatus?>()) {
      return (data != null ? _i60g3ahg.LiveShowStatus.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_iky3rvks.LiveShowView?>()) {
      return (data != null ? _iky3rvks.LiveShowView.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_iafzpzjd.LiveSpeakerView?>()) {
      return (data != null ? _iafzpzjd.LiveSpeakerView.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_ivrg75i3.LiveStageView?>()) {
      return (data != null ? _ivrg75i3.LiveStageView.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_i54ek7if.ConversationPage?>()) {
      return (data != null ? _i54ek7if.ConversationPage.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_iea0s5ku.ConversationView?>()) {
      return (data != null ? _iea0s5ku.ConversationView.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_i56rpfla.DirectMessageEvent?>()) {
      return (data != null ? _i56rpfla.DirectMessageEvent.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_ixoqahhg.DirectMessageEventKind?>()) {
      return (data != null
              ? _ixoqahhg.DirectMessageEventKind.fromJson(data)
              : null)
          as T;
    }
    if (t == _is.getType<_igwk6oho.DirectMessagePage?>()) {
      return (data != null ? _igwk6oho.DirectMessagePage.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_ikbrq2q8.DirectMessageView?>()) {
      return (data != null ? _ikbrq2q8.DirectMessageView.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_iaz5gpy6.DmConversation?>()) {
      return (data != null ? _iaz5gpy6.DmConversation.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_i5w9zcei.DmMessage?>()) {
      return (data != null ? _i5w9zcei.DmMessage.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_iwkeo1oc.ContentReport?>()) {
      return (data != null ? _iwkeo1oc.ContentReport.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_ipkc12ge.ModerationReason?>()) {
      return (data != null ? _ipkc12ge.ModerationReason.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_ib61hwyt.ReportDecision?>()) {
      return (data != null ? _ib61hwyt.ReportDecision.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_itr0x2qd.ReportQueueItem?>()) {
      return (data != null ? _itr0x2qd.ReportQueueItem.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_id3n49vv.ReportSeverity?>()) {
      return (data != null ? _id3n49vv.ReportSeverity.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_i5s3tooi.ReportTargetType?>()) {
      return (data != null ? _i5s3tooi.ReportTargetType.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_iuphy7om.NotificationKind?>()) {
      return (data != null ? _iuphy7om.NotificationKind.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_ipp18xpo.NotificationPage?>()) {
      return (data != null ? _ipp18xpo.NotificationPage.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_imgpiqz3.NotificationView?>()) {
      return (data != null ? _imgpiqz3.NotificationView.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_idxf743i.UserNotification?>()) {
      return (data != null ? _idxf743i.UserNotification.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_il66wur0.SearchResults?>()) {
      return (data != null ? _il66wur0.SearchResults.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_i9ykk824.Follow?>()) {
      return (data != null ? _i9ykk824.Follow.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_i6r55qgl.FollowPage?>()) {
      return (data != null ? _i6r55qgl.FollowPage.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_ihy6a719.FollowState?>()) {
      return (data != null ? _ihy6a719.FollowState.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_i0kd3w76.LikeState?>()) {
      return (data != null ? _i0kd3w76.LikeState.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_ir2psgaa.PostComment?>()) {
      return (data != null ? _ir2psgaa.PostComment.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_iov9osdu.PostCommentPage?>()) {
      return (data != null ? _iov9osdu.PostCommentPage.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_i5ho22g4.PostCommentView?>()) {
      return (data != null ? _i5ho22g4.PostCommentView.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_ipr9oc1t.PostLike?>()) {
      return (data != null ? _ipr9oc1t.PostLike.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_ignoub8u.PostLiker?>()) {
      return (data != null ? _ignoub8u.PostLiker.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_iyfhrk15.PostLikerPage?>()) {
      return (data != null ? _iyfhrk15.PostLikerPage.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_iu8by7md.AuditLog?>()) {
      return (data != null ? _iu8by7md.AuditLog.fromJson(data) : null) as T;
    }
    if (t == _is.getType<_idt8nicn.NexoErrorCode?>()) {
      return (data != null ? _idt8nicn.NexoErrorCode.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_invvqh96.NexoException?>()) {
      return (data != null ? _invvqh96.NexoException.fromJson(data) : null)
          as T;
    }
    if (t == _is.getType<_ihkyxh72.PageCursor?>()) {
      return (data != null ? _ihkyxh72.PageCursor.fromJson(data) : null) as T;
    }
    if (t == List<String>) {
      return (data as List).map((e) => deserialize<String>(e)).toList() as T;
    }
    if (t == List<_iyaae07t.PostMedia>) {
      return (data as List)
              .map((e) => deserialize<_iyaae07t.PostMedia>(e))
              .toList()
          as T;
    }
    if (t == _is.getType<List<_iyaae07t.PostMedia>?>()) {
      return (data != null
              ? (data as List)
                    .map((e) => deserialize<_iyaae07t.PostMedia>(e))
                    .toList()
              : null)
          as T;
    }
    if (t == _is.getType<List<String>?>()) {
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
    if (t == _is.getType<List<_il6n38yd.LiveChatMessageView>?>()) {
      return (data != null
              ? (data as List)
                    .map((e) => deserialize<_il6n38yd.LiveChatMessageView>(e))
                    .toList()
              : null)
          as T;
    }
    if (t == List<_is.UuidValue>) {
      return (data as List).map((e) => deserialize<_is.UuidValue>(e)).toList()
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
    if (t == List<_iqa1l3vk.LiveShowView>) {
      return (data as List)
              .map((e) => deserialize<_iqa1l3vk.LiveShowView>(e))
              .toList()
          as T;
    }
    if (t == List<_i22oo2zh.LiveChatMessageView>) {
      return (data as List)
              .map((e) => deserialize<_i22oo2zh.LiveChatMessageView>(e))
              .toList()
          as T;
    }
    if (t == List<_im11zuld.ReportQueueItem>) {
      return (data as List)
              .map((e) => deserialize<_im11zuld.ReportQueueItem>(e))
              .toList()
          as T;
    }
    if (t == List<int>) {
      return (data as List).map((e) => deserialize<int>(e)).toList() as T;
    }
    if (t == List<_i43ck6sm.ProfileView>) {
      return (data as List)
              .map((e) => deserialize<_i43ck6sm.ProfileView>(e))
              .toList()
          as T;
    }
    try {
      return _iais.Protocol().deserialize<T>(data, t);
    } on _is.DeserializationTypeNotFoundException catch (_) {}
    try {
      return _iacs.Protocol().deserialize<T>(data, t);
    } on _is.DeserializationTypeNotFoundException catch (_) {}
    try {
      return _isp.Protocol().deserialize<T>(data, t);
    } on _is.DeserializationTypeNotFoundException catch (_) {}
    return super.deserialize<T>(data, t);
  }

  static String? getClassNameForType(Type type) {
    return switch (type) {
      _ie5d2xvy.LiveShowFutureCallExpireModel =>
        'LiveShowFutureCallExpireModel',
      _iy3z9iri.LiveShowFutureCallPublishReplayModel =>
        'LiveShowFutureCallPublishReplayModel',
      _iqr7hhpp.LiveShowFutureCallRemindModel =>
        'LiveShowFutureCallRemindModel',
      _i4efb2h6.MediaUploadTicket => 'MediaUploadTicket',
      _i99cc7k2.Post => 'Post',
      _i71ym97j.PostDraft => 'PostDraft',
      _ijy0en9v.PostEdit => 'PostEdit',
      _iyaae07t.PostMedia => 'PostMedia',
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
      _i85zfh3f.AccountProfile => 'AccountProfile',
      _i96mabue.AccountStatus => 'AccountStatus',
      _ig9ziu3q.AccountView => 'AccountView',
      _i3rezn75.ProfileEdit => 'ProfileEdit',
      _i8sfv82t.ProfileView => 'ProfileView',
      _i1f8s3dp.VerificationStatus => 'VerificationStatus',
      _i4vd7apv.LiveChatMessage => 'LiveChatMessage',
      _il6n38yd.LiveChatMessageView => 'LiveChatMessageView',
      _i7dasvmg.LiveEvent => 'LiveEvent',
      _ilchcp3h.LiveEventKind => 'LiveEventKind',
      _igpp3v1h.LiveHandView => 'LiveHandView',
      _ib5s9fd2.LiveHostBan => 'LiveHostBan',
      _ij3uatdc.LiveMediaGrant => 'LiveMediaGrant',
      _ildi0w8j.LiveMediaGrantRole => 'LiveMediaGrantRole',
      _i7uaaqjc.LiveParticipant => 'LiveParticipant',
      _izxcblzl.LiveSanction => 'LiveSanction',
      _i1t7par0.LiveSanctionKind => 'LiveSanctionKind',
      _i1mej27o.LiveShow => 'LiveShow',
      _irbd4xwy.LiveShowAccess => 'LiveShowAccess',
      _ixjiwb6f.LiveShowDraft => 'LiveShowDraft',
      _iavthlak.LiveShowGuest => 'LiveShowGuest',
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
      _iaz5gpy6.DmConversation => 'DmConversation',
      _i5w9zcei.DmMessage => 'DmMessage',
      _iwkeo1oc.ContentReport => 'ContentReport',
      _ipkc12ge.ModerationReason => 'ModerationReason',
      _ib61hwyt.ReportDecision => 'ReportDecision',
      _itr0x2qd.ReportQueueItem => 'ReportQueueItem',
      _id3n49vv.ReportSeverity => 'ReportSeverity',
      _i5s3tooi.ReportTargetType => 'ReportTargetType',
      _iuphy7om.NotificationKind => 'NotificationKind',
      _ipp18xpo.NotificationPage => 'NotificationPage',
      _imgpiqz3.NotificationView => 'NotificationView',
      _idxf743i.UserNotification => 'UserNotification',
      _il66wur0.SearchResults => 'SearchResults',
      _i9ykk824.Follow => 'Follow',
      _i6r55qgl.FollowPage => 'FollowPage',
      _ihy6a719.FollowState => 'FollowState',
      _i0kd3w76.LikeState => 'LikeState',
      _ir2psgaa.PostComment => 'PostComment',
      _iov9osdu.PostCommentPage => 'PostCommentPage',
      _i5ho22g4.PostCommentView => 'PostCommentView',
      _ipr9oc1t.PostLike => 'PostLike',
      _ignoub8u.PostLiker => 'PostLiker',
      _iyfhrk15.PostLikerPage => 'PostLikerPage',
      _iu8by7md.AuditLog => 'AuditLog',
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
      case _ie5d2xvy.LiveShowFutureCallExpireModel():
        return 'LiveShowFutureCallExpireModel';
      case _iy3z9iri.LiveShowFutureCallPublishReplayModel():
        return 'LiveShowFutureCallPublishReplayModel';
      case _iqr7hhpp.LiveShowFutureCallRemindModel():
        return 'LiveShowFutureCallRemindModel';
      case _i4efb2h6.MediaUploadTicket():
        return 'MediaUploadTicket';
      case _i99cc7k2.Post():
        return 'Post';
      case _i71ym97j.PostDraft():
        return 'PostDraft';
      case _ijy0en9v.PostEdit():
        return 'PostEdit';
      case _iyaae07t.PostMedia():
        return 'PostMedia';
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
      case _i85zfh3f.AccountProfile():
        return 'AccountProfile';
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
      case _i4vd7apv.LiveChatMessage():
        return 'LiveChatMessage';
      case _il6n38yd.LiveChatMessageView():
        return 'LiveChatMessageView';
      case _i7dasvmg.LiveEvent():
        return 'LiveEvent';
      case _ilchcp3h.LiveEventKind():
        return 'LiveEventKind';
      case _igpp3v1h.LiveHandView():
        return 'LiveHandView';
      case _ib5s9fd2.LiveHostBan():
        return 'LiveHostBan';
      case _ij3uatdc.LiveMediaGrant():
        return 'LiveMediaGrant';
      case _ildi0w8j.LiveMediaGrantRole():
        return 'LiveMediaGrantRole';
      case _i7uaaqjc.LiveParticipant():
        return 'LiveParticipant';
      case _izxcblzl.LiveSanction():
        return 'LiveSanction';
      case _i1t7par0.LiveSanctionKind():
        return 'LiveSanctionKind';
      case _i1mej27o.LiveShow():
        return 'LiveShow';
      case _irbd4xwy.LiveShowAccess():
        return 'LiveShowAccess';
      case _ixjiwb6f.LiveShowDraft():
        return 'LiveShowDraft';
      case _iavthlak.LiveShowGuest():
        return 'LiveShowGuest';
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
      case _iaz5gpy6.DmConversation():
        return 'DmConversation';
      case _i5w9zcei.DmMessage():
        return 'DmMessage';
      case _iwkeo1oc.ContentReport():
        return 'ContentReport';
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
      case _idxf743i.UserNotification():
        return 'UserNotification';
      case _il66wur0.SearchResults():
        return 'SearchResults';
      case _i9ykk824.Follow():
        return 'Follow';
      case _i6r55qgl.FollowPage():
        return 'FollowPage';
      case _ihy6a719.FollowState():
        return 'FollowState';
      case _i0kd3w76.LikeState():
        return 'LikeState';
      case _ir2psgaa.PostComment():
        return 'PostComment';
      case _iov9osdu.PostCommentPage():
        return 'PostCommentPage';
      case _i5ho22g4.PostCommentView():
        return 'PostCommentView';
      case _ipr9oc1t.PostLike():
        return 'PostLike';
      case _ignoub8u.PostLiker():
        return 'PostLiker';
      case _iyfhrk15.PostLikerPage():
        return 'PostLikerPage';
      case _iu8by7md.AuditLog():
        return 'AuditLog';
      case _idt8nicn.NexoErrorCode():
        return 'NexoErrorCode';
      case _invvqh96.NexoException():
        return 'NexoException';
      case _ihkyxh72.PageCursor():
        return 'PageCursor';
    }
    className = _iais.Protocol().getClassNameForObject(data);
    if (className != null) {
      return className.contains('.')
          ? className
          : 'serverpod_auth_idp.$className';
    }
    className = _iacs.Protocol().getClassNameForObject(data);
    if (className != null) {
      return className.contains('.')
          ? className
          : 'serverpod_auth_core.$className';
    }
    className = _isp.Protocol().getClassNameForObject(data);
    if (className != null) {
      return className.contains('.') ? className : 'serverpod.$className';
    }
    return null;
  }

  @override
  dynamic deserializeByClassName(Map<String, dynamic> data) {
    var dataClassName = data['className'];
    if (dataClassName is! String) {
      return super.deserializeByClassName(data);
    }
    if (dataClassName == 'LiveShowFutureCallExpireModel') {
      return deserialize<_ie5d2xvy.LiveShowFutureCallExpireModel>(data['data']);
    }
    if (dataClassName == 'LiveShowFutureCallPublishReplayModel') {
      return deserialize<_iy3z9iri.LiveShowFutureCallPublishReplayModel>(
        data['data'],
      );
    }
    if (dataClassName == 'LiveShowFutureCallRemindModel') {
      return deserialize<_iqr7hhpp.LiveShowFutureCallRemindModel>(data['data']);
    }
    if (dataClassName == 'MediaUploadTicket') {
      return deserialize<_i4efb2h6.MediaUploadTicket>(data['data']);
    }
    if (dataClassName == 'Post') {
      return deserialize<_i99cc7k2.Post>(data['data']);
    }
    if (dataClassName == 'PostDraft') {
      return deserialize<_i71ym97j.PostDraft>(data['data']);
    }
    if (dataClassName == 'PostEdit') {
      return deserialize<_ijy0en9v.PostEdit>(data['data']);
    }
    if (dataClassName == 'PostMedia') {
      return deserialize<_iyaae07t.PostMedia>(data['data']);
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
    if (dataClassName == 'AccountProfile') {
      return deserialize<_i85zfh3f.AccountProfile>(data['data']);
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
    if (dataClassName == 'LiveChatMessage') {
      return deserialize<_i4vd7apv.LiveChatMessage>(data['data']);
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
    if (dataClassName == 'LiveHostBan') {
      return deserialize<_ib5s9fd2.LiveHostBan>(data['data']);
    }
    if (dataClassName == 'LiveMediaGrant') {
      return deserialize<_ij3uatdc.LiveMediaGrant>(data['data']);
    }
    if (dataClassName == 'LiveMediaGrantRole') {
      return deserialize<_ildi0w8j.LiveMediaGrantRole>(data['data']);
    }
    if (dataClassName == 'LiveParticipant') {
      return deserialize<_i7uaaqjc.LiveParticipant>(data['data']);
    }
    if (dataClassName == 'LiveSanction') {
      return deserialize<_izxcblzl.LiveSanction>(data['data']);
    }
    if (dataClassName == 'LiveSanctionKind') {
      return deserialize<_i1t7par0.LiveSanctionKind>(data['data']);
    }
    if (dataClassName == 'LiveShow') {
      return deserialize<_i1mej27o.LiveShow>(data['data']);
    }
    if (dataClassName == 'LiveShowAccess') {
      return deserialize<_irbd4xwy.LiveShowAccess>(data['data']);
    }
    if (dataClassName == 'LiveShowDraft') {
      return deserialize<_ixjiwb6f.LiveShowDraft>(data['data']);
    }
    if (dataClassName == 'LiveShowGuest') {
      return deserialize<_iavthlak.LiveShowGuest>(data['data']);
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
    if (dataClassName == 'DmConversation') {
      return deserialize<_iaz5gpy6.DmConversation>(data['data']);
    }
    if (dataClassName == 'DmMessage') {
      return deserialize<_i5w9zcei.DmMessage>(data['data']);
    }
    if (dataClassName == 'ContentReport') {
      return deserialize<_iwkeo1oc.ContentReport>(data['data']);
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
    if (dataClassName == 'UserNotification') {
      return deserialize<_idxf743i.UserNotification>(data['data']);
    }
    if (dataClassName == 'SearchResults') {
      return deserialize<_il66wur0.SearchResults>(data['data']);
    }
    if (dataClassName == 'Follow') {
      return deserialize<_i9ykk824.Follow>(data['data']);
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
    if (dataClassName == 'PostComment') {
      return deserialize<_ir2psgaa.PostComment>(data['data']);
    }
    if (dataClassName == 'PostCommentPage') {
      return deserialize<_iov9osdu.PostCommentPage>(data['data']);
    }
    if (dataClassName == 'PostCommentView') {
      return deserialize<_i5ho22g4.PostCommentView>(data['data']);
    }
    if (dataClassName == 'PostLike') {
      return deserialize<_ipr9oc1t.PostLike>(data['data']);
    }
    if (dataClassName == 'PostLiker') {
      return deserialize<_ignoub8u.PostLiker>(data['data']);
    }
    if (dataClassName == 'PostLikerPage') {
      return deserialize<_iyfhrk15.PostLikerPage>(data['data']);
    }
    if (dataClassName == 'AuditLog') {
      return deserialize<_iu8by7md.AuditLog>(data['data']);
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
      return _iais.Protocol().deserializeByClassName(data);
    }
    if (dataClassName.startsWith('serverpod_auth_core.')) {
      data['className'] = dataClassName.substring(20);
      return _iacs.Protocol().deserializeByClassName(data);
    }
    if (dataClassName.startsWith('serverpod.')) {
      data['className'] = dataClassName.substring(10);
      return _isp.Protocol().deserializeByClassName(data);
    }
    return super.deserializeByClassName(data);
  }

  void _registerHostProtocols() {
    _iais.Protocol().registerHostProtocol('nexo', this);
    _iacs.Protocol().registerHostProtocol('nexo', this);
  }

  @override
  _is.Table? getTableForType(Type t) {
    {
      var table = _iais.Protocol().getTableForType(t);
      if (table != null) {
        return table;
      }
    }
    {
      var table = _iacs.Protocol().getTableForType(t);
      if (table != null) {
        return table;
      }
    }
    {
      var table = _isp.Protocol().getTableForType(t);
      if (table != null) {
        return table;
      }
    }
    switch (t) {
      case _i99cc7k2.Post:
        return _i99cc7k2.Post.t;
      case _iyaae07t.PostMedia:
        return _iyaae07t.PostMedia.t;
      case _i85zfh3f.AccountProfile:
        return _i85zfh3f.AccountProfile.t;
      case _i4vd7apv.LiveChatMessage:
        return _i4vd7apv.LiveChatMessage.t;
      case _ib5s9fd2.LiveHostBan:
        return _ib5s9fd2.LiveHostBan.t;
      case _i7uaaqjc.LiveParticipant:
        return _i7uaaqjc.LiveParticipant.t;
      case _izxcblzl.LiveSanction:
        return _izxcblzl.LiveSanction.t;
      case _i1mej27o.LiveShow:
        return _i1mej27o.LiveShow.t;
      case _iavthlak.LiveShowGuest:
        return _iavthlak.LiveShowGuest.t;
      case _iaz5gpy6.DmConversation:
        return _iaz5gpy6.DmConversation.t;
      case _i5w9zcei.DmMessage:
        return _i5w9zcei.DmMessage.t;
      case _iwkeo1oc.ContentReport:
        return _iwkeo1oc.ContentReport.t;
      case _idxf743i.UserNotification:
        return _idxf743i.UserNotification.t;
      case _i9ykk824.Follow:
        return _i9ykk824.Follow.t;
      case _ir2psgaa.PostComment:
        return _ir2psgaa.PostComment.t;
      case _ipr9oc1t.PostLike:
        return _ipr9oc1t.PostLike.t;
      case _iu8by7md.AuditLog:
        return _iu8by7md.AuditLog.t;
    }
    return null;
  }

  @override
  List<_isp.TableDefinition> getTargetTableDefinitions() =>
      targetTableDefinitions;

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
      return _iais.Protocol().mapRecordToJson(record);
    } catch (_) {}
    try {
      return _iacs.Protocol().mapRecordToJson(record);
    } catch (_) {}
    throw Exception('Unsupported record type ${record.runtimeType}');
  }
}
