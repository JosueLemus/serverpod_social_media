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
import 'package:nexo_server/src/generated/modules/moderation/models/report_queue_item.dart'
    as _im11zuld;
import 'package:serverpod/protocol.dart' as _isp;
import 'package:serverpod/serverpod.dart' as _is;
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart'
    as _iacs;
import 'package:serverpod_auth_idp_server/serverpod_auth_idp_server.dart'
    as _iais;
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
import 'modules/identity/models/account_profile.dart' as _i85zfh3f;
import 'modules/identity/models/account_status.dart' as _i96mabue;
import 'modules/identity/models/account_view.dart' as _ig9ziu3q;
import 'modules/identity/models/profile_edit.dart' as _i3rezn75;
import 'modules/identity/models/profile_view.dart' as _i8sfv82t;
import 'modules/identity/models/verification_status.dart' as _i1f8s3dp;
import 'modules/moderation/models/content_report.dart' as _iwkeo1oc;
import 'modules/moderation/models/moderation_reason.dart' as _ipkc12ge;
import 'modules/moderation/models/report_decision.dart' as _ib61hwyt;
import 'modules/moderation/models/report_queue_item.dart' as _itr0x2qd;
import 'modules/moderation/models/report_severity.dart' as _id3n49vv;
import 'modules/moderation/models/report_target_type.dart' as _i5s3tooi;
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
export 'modules/identity/models/account_profile.dart';
export 'modules/identity/models/account_status.dart';
export 'modules/identity/models/account_view.dart';
export 'modules/identity/models/profile_edit.dart';
export 'modules/identity/models/profile_view.dart';
export 'modules/identity/models/verification_status.dart';
export 'modules/moderation/models/content_report.dart';
export 'modules/moderation/models/moderation_reason.dart';
export 'modules/moderation/models/report_decision.dart';
export 'modules/moderation/models/report_queue_item.dart';
export 'modules/moderation/models/report_severity.dart';
export 'modules/moderation/models/report_target_type.dart';
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
    if (t == List<_im11zuld.ReportQueueItem>) {
      return (data as List)
              .map((e) => deserialize<_im11zuld.ReportQueueItem>(e))
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
      _i85zfh3f.AccountProfile => 'AccountProfile',
      _i96mabue.AccountStatus => 'AccountStatus',
      _ig9ziu3q.AccountView => 'AccountView',
      _i3rezn75.ProfileEdit => 'ProfileEdit',
      _i8sfv82t.ProfileView => 'ProfileView',
      _i1f8s3dp.VerificationStatus => 'VerificationStatus',
      _iwkeo1oc.ContentReport => 'ContentReport',
      _ipkc12ge.ModerationReason => 'ModerationReason',
      _ib61hwyt.ReportDecision => 'ReportDecision',
      _itr0x2qd.ReportQueueItem => 'ReportQueueItem',
      _id3n49vv.ReportSeverity => 'ReportSeverity',
      _i5s3tooi.ReportTargetType => 'ReportTargetType',
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
      case _iwkeo1oc.ContentReport:
        return _iwkeo1oc.ContentReport.t;
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
