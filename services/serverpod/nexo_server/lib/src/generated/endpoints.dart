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
import 'package:nexo_server/src/generated/modules/content/models/post_draft.dart'
    as _icfvomj1;
import 'package:nexo_server/src/generated/modules/content/models/post_edit.dart'
    as _i79bwqkw;
import 'package:nexo_server/src/generated/modules/content/models/post_media_kind.dart'
    as _iwuw8bb0;
import 'package:nexo_server/src/generated/modules/identity/models/profile_edit.dart'
    as _iu4itgek;
import 'package:nexo_server/src/generated/modules/moderation/models/moderation_reason.dart'
    as _ixmgs13r;
import 'package:nexo_server/src/generated/modules/moderation/models/report_decision.dart'
    as _i9lv11ja;
import 'package:nexo_server/src/generated/modules/moderation/models/report_target_type.dart'
    as _ixsrdbzg;
import 'package:nexo_server/src/generated/shared/pagination/page_cursor.dart'
    as _iwd7ajf0;
import 'package:serverpod/serverpod.dart' as _is;
import 'package:serverpod_auth_core_server/serverpod_auth_core_server.dart'
    as _iacs;
import 'package:serverpod_auth_idp_server/serverpod_auth_idp_server.dart'
    as _iais;
import '../auth/email_idp_endpoint.dart' as _iuc1hd5t;
import '../auth/jwt_refresh_endpoint.dart' as _inwq3ztq;
import '../modules/content/endpoints/posts_endpoint.dart' as _i14rwr4t;
import '../modules/identity/endpoints/profiles_endpoint.dart' as _ijchdihn;
import '../modules/moderation/endpoints/moderation_endpoint.dart' as _ityzuh2k;
import '../modules/social/endpoints/comments_endpoint.dart' as _iiig3ywm;
import '../modules/social/endpoints/likes_endpoint.dart' as _ippoapkl;
import '../shared/health/health_endpoint.dart' as _ill7uqua;

class Endpoints extends _is.EndpointDispatch {
  @override
  void initializeEndpoints(_is.Server server) {
    var endpoints = <String, _is.Endpoint>{
      'emailIdp': _iuc1hd5t.EmailIdpEndpoint()
        ..initialize(
          server,
          'emailIdp',
          null,
        ),
      'jwtRefresh': _inwq3ztq.JwtRefreshEndpoint()
        ..initialize(
          server,
          'jwtRefresh',
          null,
        ),
      'posts': _i14rwr4t.PostsEndpoint()
        ..initialize(
          server,
          'posts',
          null,
        ),
      'profiles': _ijchdihn.ProfilesEndpoint()
        ..initialize(
          server,
          'profiles',
          null,
        ),
      'moderation': _ityzuh2k.ModerationEndpoint()
        ..initialize(
          server,
          'moderation',
          null,
        ),
      'comments': _iiig3ywm.CommentsEndpoint()
        ..initialize(
          server,
          'comments',
          null,
        ),
      'likes': _ippoapkl.LikesEndpoint()
        ..initialize(
          server,
          'likes',
          null,
        ),
      'health': _ill7uqua.HealthEndpoint()
        ..initialize(
          server,
          'health',
          null,
        ),
    };
    connectors['emailIdp'] = _is.EndpointConnector(
      name: 'emailIdp',
      endpoint: endpoints['emailIdp']!,
      methodConnectors: {
        'login': _is.MethodConnector(
          name: 'login',
          params: {
            'email': _is.ParameterDescription(
              name: 'email',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'password': _is.ParameterDescription(
              name: 'password',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['emailIdp'] as _iuc1hd5t.EmailIdpEndpoint).login(
                    session,
                    email: params['email'],
                    password: params['password'],
                  ),
        ),
        'startRegistration': _is.MethodConnector(
          name: 'startRegistration',
          params: {
            'email': _is.ParameterDescription(
              name: 'email',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['emailIdp'] as _iuc1hd5t.EmailIdpEndpoint)
                  .startRegistration(
                    session,
                    email: params['email'],
                  ),
        ),
        'verifyRegistrationCode': _is.MethodConnector(
          name: 'verifyRegistrationCode',
          params: {
            'accountRequestId': _is.ParameterDescription(
              name: 'accountRequestId',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'verificationCode': _is.ParameterDescription(
              name: 'verificationCode',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['emailIdp'] as _iuc1hd5t.EmailIdpEndpoint)
                  .verifyRegistrationCode(
                    session,
                    accountRequestId: params['accountRequestId'],
                    verificationCode: params['verificationCode'],
                  ),
        ),
        'finishRegistration': _is.MethodConnector(
          name: 'finishRegistration',
          params: {
            'registrationToken': _is.ParameterDescription(
              name: 'registrationToken',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'password': _is.ParameterDescription(
              name: 'password',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['emailIdp'] as _iuc1hd5t.EmailIdpEndpoint)
                  .finishRegistration(
                    session,
                    registrationToken: params['registrationToken'],
                    password: params['password'],
                  ),
        ),
        'startPasswordReset': _is.MethodConnector(
          name: 'startPasswordReset',
          params: {
            'email': _is.ParameterDescription(
              name: 'email',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['emailIdp'] as _iuc1hd5t.EmailIdpEndpoint)
                  .startPasswordReset(
                    session,
                    email: params['email'],
                  ),
        ),
        'verifyPasswordResetCode': _is.MethodConnector(
          name: 'verifyPasswordResetCode',
          params: {
            'passwordResetRequestId': _is.ParameterDescription(
              name: 'passwordResetRequestId',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'verificationCode': _is.ParameterDescription(
              name: 'verificationCode',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['emailIdp'] as _iuc1hd5t.EmailIdpEndpoint)
                  .verifyPasswordResetCode(
                    session,
                    passwordResetRequestId: params['passwordResetRequestId'],
                    verificationCode: params['verificationCode'],
                  ),
        ),
        'finishPasswordReset': _is.MethodConnector(
          name: 'finishPasswordReset',
          params: {
            'finishPasswordResetToken': _is.ParameterDescription(
              name: 'finishPasswordResetToken',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'newPassword': _is.ParameterDescription(
              name: 'newPassword',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['emailIdp'] as _iuc1hd5t.EmailIdpEndpoint)
                  .finishPasswordReset(
                    session,
                    finishPasswordResetToken:
                        params['finishPasswordResetToken'],
                    newPassword: params['newPassword'],
                  ),
        ),
        'hasAccount': _is.MethodConnector(
          name: 'hasAccount',
          params: {},
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['emailIdp'] as _iuc1hd5t.EmailIdpEndpoint)
                  .hasAccount(session),
        ),
      },
    );
    connectors['jwtRefresh'] = _is.EndpointConnector(
      name: 'jwtRefresh',
      endpoint: endpoints['jwtRefresh']!,
      methodConnectors: {
        'refreshAccessToken': _is.MethodConnector(
          name: 'refreshAccessToken',
          params: {
            'refreshToken': _is.ParameterDescription(
              name: 'refreshToken',
              type: _is.getType<String?>(),
              nullable: true,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['jwtRefresh'] as _inwq3ztq.JwtRefreshEndpoint)
                      .refreshAccessToken(
                        session,
                        refreshToken: params['refreshToken'],
                      ),
        ),
      },
    );
    connectors['posts'] = _is.EndpointConnector(
      name: 'posts',
      endpoint: endpoints['posts']!,
      methodConnectors: {
        'feed': _is.MethodConnector(
          name: 'feed',
          params: {
            'after': _is.ParameterDescription(
              name: 'after',
              type: _is.getType<_iwd7ajf0.PageCursor?>(),
              nullable: true,
            ),
            'limit': _is.ParameterDescription(
              name: 'limit',
              type: _is.getType<int?>(),
              nullable: true,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['posts'] as _i14rwr4t.PostsEndpoint).feed(
                session,
                after: params['after'],
                limit: params['limit'],
              ),
        ),
        'byAuthor': _is.MethodConnector(
          name: 'byAuthor',
          params: {
            'authorId': _is.ParameterDescription(
              name: 'authorId',
              type: _is.getType<_is.UuidValue>(),
              nullable: false,
            ),
            'after': _is.ParameterDescription(
              name: 'after',
              type: _is.getType<_iwd7ajf0.PageCursor?>(),
              nullable: true,
            ),
            'limit': _is.ParameterDescription(
              name: 'limit',
              type: _is.getType<int?>(),
              nullable: true,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['posts'] as _i14rwr4t.PostsEndpoint).byAuthor(
                    session,
                    params['authorId'],
                    after: params['after'],
                    limit: params['limit'],
                  ),
        ),
        'get': _is.MethodConnector(
          name: 'get',
          params: {
            'postId': _is.ParameterDescription(
              name: 'postId',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['posts'] as _i14rwr4t.PostsEndpoint).get(
                session,
                params['postId'],
              ),
        ),
        'requestMediaUpload': _is.MethodConnector(
          name: 'requestMediaUpload',
          params: {
            'kind': _is.ParameterDescription(
              name: 'kind',
              type: _is.getType<_iwuw8bb0.PostMediaKind>(),
              nullable: false,
            ),
            'contentType': _is.ParameterDescription(
              name: 'contentType',
              type: _is.getType<String>(),
              nullable: false,
            ),
            'sizeBytes': _is.ParameterDescription(
              name: 'sizeBytes',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['posts'] as _i14rwr4t.PostsEndpoint)
                  .requestMediaUpload(
                    session,
                    kind: params['kind'],
                    contentType: params['contentType'],
                    sizeBytes: params['sizeBytes'],
                  ),
        ),
        'create': _is.MethodConnector(
          name: 'create',
          params: {
            'draft': _is.ParameterDescription(
              name: 'draft',
              type: _is.getType<_icfvomj1.PostDraft>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['posts'] as _i14rwr4t.PostsEndpoint).create(
                session,
                params['draft'],
              ),
        ),
        'update': _is.MethodConnector(
          name: 'update',
          params: {
            'postId': _is.ParameterDescription(
              name: 'postId',
              type: _is.getType<int>(),
              nullable: false,
            ),
            'edit': _is.ParameterDescription(
              name: 'edit',
              type: _is.getType<_i79bwqkw.PostEdit>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['posts'] as _i14rwr4t.PostsEndpoint).update(
                session,
                params['postId'],
                params['edit'],
              ),
        ),
        'delete': _is.MethodConnector(
          name: 'delete',
          params: {
            'postId': _is.ParameterDescription(
              name: 'postId',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['posts'] as _i14rwr4t.PostsEndpoint).delete(
                session,
                params['postId'],
              ),
        ),
      },
    );
    connectors['profiles'] = _is.EndpointConnector(
      name: 'profiles',
      endpoint: endpoints['profiles']!,
      methodConnectors: {
        'me': _is.MethodConnector(
          name: 'me',
          params: {},
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['profiles'] as _ijchdihn.ProfilesEndpoint)
                  .me(session),
        ),
        'update': _is.MethodConnector(
          name: 'update',
          params: {
            'edit': _is.ParameterDescription(
              name: 'edit',
              type: _is.getType<_iu4itgek.ProfileEdit>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['profiles'] as _ijchdihn.ProfilesEndpoint).update(
                    session,
                    params['edit'],
                  ),
        ),
        'becomeCreator': _is.MethodConnector(
          name: 'becomeCreator',
          params: {},
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['profiles'] as _ijchdihn.ProfilesEndpoint)
                  .becomeCreator(session),
        ),
        'byUsername': _is.MethodConnector(
          name: 'byUsername',
          params: {
            'username': _is.ParameterDescription(
              name: 'username',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['profiles'] as _ijchdihn.ProfilesEndpoint)
                  .byUsername(
                    session,
                    params['username'],
                  ),
        ),
      },
    );
    connectors['moderation'] = _is.EndpointConnector(
      name: 'moderation',
      endpoint: endpoints['moderation']!,
      methodConnectors: {
        'report': _is.MethodConnector(
          name: 'report',
          params: {
            'targetType': _is.ParameterDescription(
              name: 'targetType',
              type: _is.getType<_ixsrdbzg.ReportTargetType>(),
              nullable: false,
            ),
            'targetId': _is.ParameterDescription(
              name: 'targetId',
              type: _is.getType<int>(),
              nullable: false,
            ),
            'reason': _is.ParameterDescription(
              name: 'reason',
              type: _is.getType<_ixmgs13r.ModerationReason>(),
              nullable: false,
            ),
            'details': _is.ParameterDescription(
              name: 'details',
              type: _is.getType<String?>(),
              nullable: true,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['moderation'] as _ityzuh2k.ModerationEndpoint)
                      .report(
                        session,
                        targetType: params['targetType'],
                        targetId: params['targetId'],
                        reason: params['reason'],
                        details: params['details'],
                      ),
        ),
        'queue': _is.MethodConnector(
          name: 'queue',
          params: {
            'limit': _is.ParameterDescription(
              name: 'limit',
              type: _is.getType<int?>(),
              nullable: true,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['moderation'] as _ityzuh2k.ModerationEndpoint)
                      .queue(
                        session,
                        limit: params['limit'],
                      ),
        ),
        'resolve': _is.MethodConnector(
          name: 'resolve',
          params: {
            'reportId': _is.ParameterDescription(
              name: 'reportId',
              type: _is.getType<int>(),
              nullable: false,
            ),
            'decision': _is.ParameterDescription(
              name: 'decision',
              type: _is.getType<_i9lv11ja.ReportDecision>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['moderation'] as _ityzuh2k.ModerationEndpoint)
                      .resolve(
                        session,
                        params['reportId'],
                        params['decision'],
                      ),
        ),
      },
    );
    connectors['comments'] = _is.EndpointConnector(
      name: 'comments',
      endpoint: endpoints['comments']!,
      methodConnectors: {
        'list': _is.MethodConnector(
          name: 'list',
          params: {
            'postId': _is.ParameterDescription(
              name: 'postId',
              type: _is.getType<int>(),
              nullable: false,
            ),
            'after': _is.ParameterDescription(
              name: 'after',
              type: _is.getType<_iwd7ajf0.PageCursor?>(),
              nullable: true,
            ),
            'limit': _is.ParameterDescription(
              name: 'limit',
              type: _is.getType<int?>(),
              nullable: true,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['comments'] as _iiig3ywm.CommentsEndpoint).list(
                    session,
                    params['postId'],
                    after: params['after'],
                    limit: params['limit'],
                  ),
        ),
        'create': _is.MethodConnector(
          name: 'create',
          params: {
            'postId': _is.ParameterDescription(
              name: 'postId',
              type: _is.getType<int>(),
              nullable: false,
            ),
            'body': _is.ParameterDescription(
              name: 'body',
              type: _is.getType<String>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['comments'] as _iiig3ywm.CommentsEndpoint).create(
                    session,
                    params['postId'],
                    params['body'],
                  ),
        ),
        'delete': _is.MethodConnector(
          name: 'delete',
          params: {
            'commentId': _is.ParameterDescription(
              name: 'commentId',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async =>
                  (endpoints['comments'] as _iiig3ywm.CommentsEndpoint).delete(
                    session,
                    params['commentId'],
                  ),
        ),
      },
    );
    connectors['likes'] = _is.EndpointConnector(
      name: 'likes',
      endpoint: endpoints['likes']!,
      methodConnectors: {
        'like': _is.MethodConnector(
          name: 'like',
          params: {
            'postId': _is.ParameterDescription(
              name: 'postId',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['likes'] as _ippoapkl.LikesEndpoint).like(
                session,
                params['postId'],
              ),
        ),
        'unlike': _is.MethodConnector(
          name: 'unlike',
          params: {
            'postId': _is.ParameterDescription(
              name: 'postId',
              type: _is.getType<int>(),
              nullable: false,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['likes'] as _ippoapkl.LikesEndpoint).unlike(
                session,
                params['postId'],
              ),
        ),
        'likers': _is.MethodConnector(
          name: 'likers',
          params: {
            'postId': _is.ParameterDescription(
              name: 'postId',
              type: _is.getType<int>(),
              nullable: false,
            ),
            'after': _is.ParameterDescription(
              name: 'after',
              type: _is.getType<_iwd7ajf0.PageCursor?>(),
              nullable: true,
            ),
            'limit': _is.ParameterDescription(
              name: 'limit',
              type: _is.getType<int?>(),
              nullable: true,
            ),
          },
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['likes'] as _ippoapkl.LikesEndpoint).likers(
                session,
                params['postId'],
                after: params['after'],
                limit: params['limit'],
              ),
        ),
      },
    );
    connectors['health'] = _is.EndpointConnector(
      name: 'health',
      endpoint: endpoints['health']!,
      methodConnectors: {
        'ping': _is.MethodConnector(
          name: 'ping',
          params: {},
          call:
              (
                _is.Session session,
                Map<String, dynamic> params,
              ) async => (endpoints['health'] as _ill7uqua.HealthEndpoint).ping(
                session,
              ),
        ),
      },
    );
    modules['serverpod_auth_idp'] = _iais.Endpoints()
      ..initializeEndpoints(server);
    modules['serverpod_auth_core'] = _iacs.Endpoints()
      ..initializeEndpoints(server);
  }
}
