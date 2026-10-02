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
import 'dart:async' as _ida;
import 'package:http/http.dart' as _i85jenna;
import 'package:nexo_client/src/protocol/modules/content/models/media_upload_ticket.dart'
    as _ifucagw2;
import 'package:nexo_client/src/protocol/modules/content/models/post_draft.dart'
    as _it7ut2rl;
import 'package:nexo_client/src/protocol/modules/content/models/post_edit.dart'
    as _iyn04n5o;
import 'package:nexo_client/src/protocol/modules/content/models/post_media_kind.dart'
    as _i7u7o075;
import 'package:nexo_client/src/protocol/modules/content/models/post_page.dart'
    as _i9cr6dtc;
import 'package:nexo_client/src/protocol/modules/content/models/post_view.dart'
    as _ibqqifwv;
import 'package:nexo_client/src/protocol/modules/identity/models/account_view.dart'
    as _i0b9qmvw;
import 'package:nexo_client/src/protocol/modules/identity/models/profile_edit.dart'
    as _ih9nymjn;
import 'package:nexo_client/src/protocol/modules/identity/models/profile_view.dart'
    as _iaqpe3js;
import 'package:nexo_client/src/protocol/modules/moderation/models/moderation_reason.dart'
    as _ie0oo619;
import 'package:nexo_client/src/protocol/modules/moderation/models/report_decision.dart'
    as _i4p633df;
import 'package:nexo_client/src/protocol/modules/moderation/models/report_queue_item.dart'
    as _ij26twz2;
import 'package:nexo_client/src/protocol/modules/moderation/models/report_target_type.dart'
    as _iajbeibr;
import 'package:nexo_client/src/protocol/modules/social/models/like_state.dart'
    as _ijckcjl1;
import 'package:nexo_client/src/protocol/modules/social/models/post_comment_page.dart'
    as _ierqnby7;
import 'package:nexo_client/src/protocol/modules/social/models/post_comment_view.dart'
    as _iejiodsx;
import 'package:nexo_client/src/protocol/modules/social/models/post_liker_page.dart'
    as _i0mxqz4u;
import 'package:nexo_client/src/protocol/shared/pagination/page_cursor.dart'
    as _ir35iwx2;
import 'package:serverpod_auth_core_client/serverpod_auth_core_client.dart'
    as _iacc;
import 'package:serverpod_auth_idp_client/serverpod_auth_idp_client.dart'
    as _iaic;
import 'package:serverpod_client/serverpod_client.dart' as _isc;
import 'protocol.dart' as _il2as5qe;

/// By extending [EmailIdpBaseEndpoint], the email identity provider endpoints
/// are made available on the server and enable the corresponding sign-in widget
/// on the client.
/// {@category Endpoint}
class EndpointEmailIdp extends _iaic.EndpointEmailIdpBase {
  EndpointEmailIdp(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'emailIdp';

  /// Logs in the user and returns a new session.
  ///
  /// Throws an [EmailAccountLoginException] in case of errors, with reason:
  /// - [EmailAccountLoginExceptionReason.invalidCredentials] if the email or
  ///   password is incorrect.
  /// - [EmailAccountLoginExceptionReason.tooManyAttempts] if there have been
  ///   too many failed login attempts.
  ///
  /// Throws an [AuthUserBlockedException] if the auth user is blocked.
  @override
  _ida.Future<_iacc.AuthSuccess> login({
    required String email,
    required String password,
  }) => caller.callServerEndpoint<_iacc.AuthSuccess>(
    'emailIdp',
    'login',
    {
      'email': email,
      'password': password,
    },
  );

  /// Starts the registration for a new user account with an email-based login
  /// associated to it.
  ///
  /// Upon successful completion of this method, an email will have been
  /// sent to [email] with a verification link, which the user must open to
  /// complete the registration.
  ///
  /// Always returns a account request ID, which can be used to complete the
  /// registration. If the email is already registered, the returned ID will not
  /// be valid.
  @override
  _ida.Future<_isc.UuidValue> startRegistration({required String email}) =>
      caller.callServerEndpoint<_isc.UuidValue>(
        'emailIdp',
        'startRegistration',
        {'email': email},
      );

  /// Verifies an account request code and returns a token
  /// that can be used to complete the account creation.
  ///
  /// Throws an [EmailAccountRequestException] in case of errors, with reason:
  /// - [EmailAccountRequestExceptionReason.expired] if the account request has
  ///   already expired.
  /// - [EmailAccountRequestExceptionReason.policyViolation] if the password
  ///   does not comply with the password policy.
  /// - [EmailAccountRequestExceptionReason.invalid] if no request exists
  ///   for the given [accountRequestId] or [verificationCode] is invalid.
  @override
  _ida.Future<String> verifyRegistrationCode({
    required _isc.UuidValue accountRequestId,
    required String verificationCode,
  }) => caller.callServerEndpoint<String>(
    'emailIdp',
    'verifyRegistrationCode',
    {
      'accountRequestId': accountRequestId,
      'verificationCode': verificationCode,
    },
  );

  /// Completes a new account registration, creating a new auth user with a
  /// profile and attaching the given email account to it.
  ///
  /// Throws an [EmailAccountRequestException] in case of errors, with reason:
  /// - [EmailAccountRequestExceptionReason.expired] if the account request has
  ///   already expired.
  /// - [EmailAccountRequestExceptionReason.policyViolation] if the password
  ///   does not comply with the password policy.
  /// - [EmailAccountRequestExceptionReason.invalid] if the [registrationToken]
  ///   is invalid.
  ///
  /// Throws an [AuthUserBlockedException] if the auth user is blocked.
  ///
  /// Returns a session for the newly created user.
  @override
  _ida.Future<_iacc.AuthSuccess> finishRegistration({
    required String registrationToken,
    required String password,
  }) => caller.callServerEndpoint<_iacc.AuthSuccess>(
    'emailIdp',
    'finishRegistration',
    {
      'registrationToken': registrationToken,
      'password': password,
    },
  );

  /// Requests a password reset for [email].
  ///
  /// If the email address is registered, an email with reset instructions will
  /// be send out. If the email is unknown, this method will have no effect.
  ///
  /// Always returns a password reset request ID, which can be used to complete
  /// the reset. If the email is not registered, the returned ID will not be
  /// valid.
  ///
  /// Throws an [EmailAccountPasswordResetException] in case of errors, with reason:
  /// - [EmailAccountPasswordResetExceptionReason.tooManyAttempts] if the user has
  ///   made too many attempts trying to request a password reset.
  ///
  @override
  _ida.Future<_isc.UuidValue> startPasswordReset({required String email}) =>
      caller.callServerEndpoint<_isc.UuidValue>(
        'emailIdp',
        'startPasswordReset',
        {'email': email},
      );

  /// Verifies a password reset code and returns a finishPasswordResetToken
  /// that can be used to finish the password reset.
  ///
  /// Throws an [EmailAccountPasswordResetException] in case of errors, with reason:
  /// - [EmailAccountPasswordResetExceptionReason.expired] if the password reset
  ///   request has already expired.
  /// - [EmailAccountPasswordResetExceptionReason.tooManyAttempts] if the user has
  ///   made too many attempts trying to verify the password reset.
  /// - [EmailAccountPasswordResetExceptionReason.invalid] if no request exists
  ///   for the given [passwordResetRequestId] or [verificationCode] is invalid.
  ///
  /// If multiple steps are required to complete the password reset, this endpoint
  /// should be overridden to return credentials for the next step instead
  /// of the credentials for setting the password.
  @override
  _ida.Future<String> verifyPasswordResetCode({
    required _isc.UuidValue passwordResetRequestId,
    required String verificationCode,
  }) => caller.callServerEndpoint<String>(
    'emailIdp',
    'verifyPasswordResetCode',
    {
      'passwordResetRequestId': passwordResetRequestId,
      'verificationCode': verificationCode,
    },
  );

  /// Completes a password reset request by setting a new password.
  ///
  /// The [verificationCode] returned from [verifyPasswordResetCode] is used to
  /// validate the password reset request.
  ///
  /// Throws an [EmailAccountPasswordResetException] in case of errors, with reason:
  /// - [EmailAccountPasswordResetExceptionReason.expired] if the password reset
  ///   request has already expired.
  /// - [EmailAccountPasswordResetExceptionReason.policyViolation] if the new
  ///   password does not comply with the password policy.
  /// - [EmailAccountPasswordResetExceptionReason.invalid] if no request exists
  ///   for the given [passwordResetRequestId] or [verificationCode] is invalid.
  ///
  /// Throws an [AuthUserBlockedException] if the auth user is blocked.
  @override
  _ida.Future<void> finishPasswordReset({
    required String finishPasswordResetToken,
    required String newPassword,
  }) => caller.callServerEndpoint<void>(
    'emailIdp',
    'finishPasswordReset',
    {
      'finishPasswordResetToken': finishPasswordResetToken,
      'newPassword': newPassword,
    },
  );

  @override
  _ida.Future<bool> hasAccount() => caller.callServerEndpoint<bool>(
    'emailIdp',
    'hasAccount',
    {},
  );
}

/// By extending [RefreshJwtTokensEndpoint], the JWT token refresh endpoint
/// is made available on the server and enables automatic token refresh on the client.
/// {@category Endpoint}
class EndpointJwtRefresh extends _iacc.EndpointRefreshJwtTokens {
  EndpointJwtRefresh(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'jwtRefresh';

  /// Creates a new token pair for the given [refreshToken].
  ///
  /// If [refreshToken] is omitted, cookie-mode web clients fall back to the
  /// configured HttpOnly refresh cookie. When neither source is present this
  /// throws [RefreshTokenNotFoundException], the same public "no usable refresh
  /// credential" exception used for unknown refresh tokens.
  ///
  /// Can throw the following exceptions:
  /// -[RefreshTokenMalformedException]: refresh token is malformed and could
  ///   not be parsed. Not expected to happen for tokens issued by the server.
  /// -[RefreshTokenNotFoundException]: refresh token is unknown to the server.
  ///   Either the token was deleted or generated by a different server.
  /// -[RefreshTokenExpiredException]: refresh token has expired. Will happen
  ///   only if it has not been used within configured `refreshTokenLifetime`.
  /// -[RefreshTokenInvalidSecretException]: refresh token is incorrect, meaning
  ///   it does not refer to the current secret refresh token. This indicates
  ///   either a malfunctioning client or a malicious attempt by someone who has
  ///   obtained the refresh token. In this case the underlying refresh token
  ///   will be deleted, and access to it will expire fully when the last access
  ///   token is elapsed.
  ///
  /// This endpoint is unauthenticated, meaning the client won't include any
  /// authentication information with the call.
  @override
  _ida.Future<_iacc.AuthSuccess> refreshAccessToken({String? refreshToken}) =>
      caller.callServerEndpoint<_iacc.AuthSuccess>(
        'jwtRefresh',
        'refreshAccessToken',
        {'refreshToken': refreshToken},
        authenticated: false,
      );
}

/// Publicaciones: leer el feed, publicar con fotos o videos, editar y
/// eliminar. Desde Flutter: `client.posts`.
///
/// Leer es público: un invitado ve los posts públicos. Todo lo que escribe
/// exige sesión y responde [NexoException] con el código del motivo.
/// {@category Endpoint}
class EndpointPosts extends _isc.EndpointRef {
  EndpointPosts(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'posts';

  /// Feed principal, del más nuevo al más viejo. Pasar el `nextCursor` de la
  /// página anterior como [after] para seguir. [limit] va de 1 a 50 (20 por
  /// defecto).
  _ida.Future<_i9cr6dtc.PostPage> feed({
    _ir35iwx2.PageCursor? after,
    int? limit,
  }) => caller.callServerEndpoint<_i9cr6dtc.PostPage>(
    'posts',
    'feed',
    {
      'after': after,
      'limit': limit,
    },
  );

  /// Posts de un autor, para su perfil. Misma paginación que [feed].
  _ida.Future<_i9cr6dtc.PostPage> byAuthor(
    _isc.UuidValue authorId, {
    _ir35iwx2.PageCursor? after,
    int? limit,
  }) => caller.callServerEndpoint<_i9cr6dtc.PostPage>(
    'posts',
    'byAuthor',
    {
      'authorId': authorId,
      'after': after,
      'limit': limit,
    },
  );

  /// Un post. `notFound` si no existe, se eliminó o no se puede ver.
  _ida.Future<_ibqqifwv.PostView> get(int postId) =>
      caller.callServerEndpoint<_ibqqifwv.PostView>(
        'posts',
        'get',
        {'postId': postId},
      );

  /// Paso 1 de publicar con un archivo: pide permiso para subirlo. Se sube
  /// con `FileUploader(ticket.uploadDescription)` y la `ticket.key` va en
  /// [PostDraft.mediaKeys]. Imágenes JPEG, PNG, WebP o GIF de hasta 10 MB;
  /// videos MP4, MOV o WebM de hasta 50 MB.
  _ida.Future<_ifucagw2.MediaUploadTicket> requestMediaUpload({
    required _i7u7o075.PostMediaKind kind,
    required String contentType,
    required int sizeBytes,
  }) => caller.callServerEndpoint<_ifucagw2.MediaUploadTicket>(
    'posts',
    'requestMediaUpload',
    {
      'kind': kind,
      'contentType': contentType,
      'sizeBytes': sizeBytes,
    },
  );

  /// Paso 2: publica. Necesita texto, archivos o ambos (hasta 4 archivos).
  _ida.Future<_ibqqifwv.PostView> create(_it7ut2rl.PostDraft draft) =>
      caller.callServerEndpoint<_ibqqifwv.PostView>(
        'posts',
        'create',
        {'draft': draft},
      );

  /// Edita texto, etiquetas, visibilidad o comentarios. Solo el autor.
  _ida.Future<_ibqqifwv.PostView> update(
    int postId,
    _iyn04n5o.PostEdit edit,
  ) => caller.callServerEndpoint<_ibqqifwv.PostView>(
    'posts',
    'update',
    {
      'postId': postId,
      'edit': edit,
    },
  );

  /// Elimina un post. El autor, un moderador o un operador. Queda auditado.
  _ida.Future<void> delete(int postId) => caller.callServerEndpoint<void>(
    'posts',
    'delete',
    {'postId': postId},
  );
}

/// Perfiles de Nexo. Desde Flutter: `client.profiles`.
///
/// La primera llamada a [me] de una cuenta nueva le crea su perfil con un
/// nombre de usuario libre, así que la app siempre tiene algo que mostrar.
/// {@category Endpoint}
class EndpointProfiles extends _isc.EndpointRef {
  EndpointProfiles(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'profiles';

  /// La cuenta de la sesión, con sus roles. Exige sesión.
  _ida.Future<_i0b9qmvw.AccountView> me() =>
      caller.callServerEndpoint<_i0b9qmvw.AccountView>(
        'profiles',
        'me',
        {},
      );

  /// Cambia nombre de usuario, nombre visible o bio. Exige sesión.
  /// `conflict` si el nombre de usuario ya está en uso.
  _ida.Future<_i0b9qmvw.AccountView> update(_ih9nymjn.ProfileEdit edit) =>
      caller.callServerEndpoint<_i0b9qmvw.AccountView>(
        'profiles',
        'update',
        {'edit': edit},
      );

  /// Declara la cuenta como creadora. La verificación la da un operador.
  _ida.Future<_i0b9qmvw.AccountView> becomeCreator() =>
      caller.callServerEndpoint<_i0b9qmvw.AccountView>(
        'profiles',
        'becomeCreator',
        {},
      );

  /// El perfil público de [username]. Público: lo ve un invitado.
  _ida.Future<_iaqpe3js.ProfileView> byUsername(String username) =>
      caller.callServerEndpoint<_iaqpe3js.ProfileView>(
        'profiles',
        'byUsername',
        {'username': username},
      );
}

/// Reportes y cola de moderación. Desde Flutter: `client.moderation`.
///
/// Reportar lo puede hacer cualquiera con sesión. La cola y resolver exigen
/// el scope `moderator` o `admin`; si no, `forbidden`.
/// {@category Endpoint}
class EndpointModeration extends _isc.EndpointRef {
  EndpointModeration(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'moderation';

  /// Reporta un post o un comentario. La severidad la decide el servidor
  /// según [reason]. Repetir el mismo reporte no crea otro. No se puede
  /// reportar contenido propio.
  _ida.Future<void> report({
    required _iajbeibr.ReportTargetType targetType,
    required int targetId,
    required _ie0oo619.ModerationReason reason,
    String? details,
  }) => caller.callServerEndpoint<void>(
    'moderation',
    'report',
    {
      'targetType': targetType,
      'targetId': targetId,
      'reason': reason,
      'details': details,
    },
  );

  /// Contenidos con reportes abiertos, uno por contenido, primero los más
  /// graves. Staff de moderación.
  _ida.Future<List<_ij26twz2.ReportQueueItem>> queue({int? limit}) =>
      caller.callServerEndpoint<List<_ij26twz2.ReportQueueItem>>(
        'moderation',
        'queue',
        {'limit': limit},
      );

  /// Oculta el contenido o descarta, y cierra todos sus reportes abiertos en
  /// un paso. Queda auditado. Staff de moderación.
  _ida.Future<void> resolve(
    int reportId,
    _i4p633df.ReportDecision decision,
  ) => caller.callServerEndpoint<void>(
    'moderation',
    'resolve',
    {
      'reportId': reportId,
      'decision': decision,
    },
  );
}

/// Comentarios de posts. Desde Flutter: `client.comments`.
/// {@category Endpoint}
class EndpointComments extends _isc.EndpointRef {
  EndpointComments(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'comments';

  /// Comentarios de un post, del más viejo al más nuevo. Público si el post
  /// lo es. Misma paginación que `posts.feed`.
  _ida.Future<_ierqnby7.PostCommentPage> list(
    int postId, {
    _ir35iwx2.PageCursor? after,
    int? limit,
  }) => caller.callServerEndpoint<_ierqnby7.PostCommentPage>(
    'comments',
    'list',
    {
      'postId': postId,
      'after': after,
      'limit': limit,
    },
  );

  /// Comenta, hasta 1000 caracteres. Requiere sesión. `forbidden` si el
  /// autor del post desactivó los comentarios.
  _ida.Future<_iejiodsx.PostCommentView> create(
    int postId,
    String body,
  ) => caller.callServerEndpoint<_iejiodsx.PostCommentView>(
    'comments',
    'create',
    {
      'postId': postId,
      'body': body,
    },
  );

  /// Elimina un comentario: su autor, el autor del post o un moderador.
  /// Queda auditado.
  _ida.Future<void> delete(int commentId) => caller.callServerEndpoint<void>(
    'comments',
    'delete',
    {'commentId': commentId},
  );
}

/// Likes de posts. Desde Flutter: `client.likes`.
///
/// Dar y quitar devuelven el estado final con el contador ya actualizado, y
/// se pueden repetir sin efecto: dos `like` seguidos dejan un solo like.
/// {@category Endpoint}
class EndpointLikes extends _isc.EndpointRef {
  EndpointLikes(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'likes';

  /// Da like. Requiere sesión.
  _ida.Future<_ijckcjl1.LikeState> like(int postId) =>
      caller.callServerEndpoint<_ijckcjl1.LikeState>(
        'likes',
        'like',
        {'postId': postId},
      );

  /// Quita el like. Requiere sesión.
  _ida.Future<_ijckcjl1.LikeState> unlike(int postId) =>
      caller.callServerEndpoint<_ijckcjl1.LikeState>(
        'likes',
        'unlike',
        {'postId': postId},
      );

  /// Quién dio like, del más reciente al más viejo. Público si el post lo es.
  /// Misma paginación que `posts.feed`.
  _ida.Future<_i0mxqz4u.PostLikerPage> likers(
    int postId, {
    _ir35iwx2.PageCursor? after,
    int? limit,
  }) => caller.callServerEndpoint<_i0mxqz4u.PostLikerPage>(
    'likes',
    'likers',
    {
      'postId': postId,
      'after': after,
      'limit': limit,
    },
  );
}

/// Endpoint público para comprobar que el servidor responde.
/// Desde Flutter: `client.health.ping()`.
/// {@category Endpoint}
class EndpointHealth extends _isc.EndpointRef {
  EndpointHealth(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'health';

  _ida.Future<String> ping() => caller.callServerEndpoint<String>(
    'health',
    'ping',
    {},
  );
}

class Modules {
  Modules(Client client) {
    serverpod_auth_idp = _iaic.Caller(client);
    serverpod_auth_core = _iacc.Caller(client);
  }

  late final _iaic.Caller serverpod_auth_idp;

  late final _iacc.Caller serverpod_auth_core;
}

class Client extends _isc.ServerpodClientShared {
  Client(
    String host, {
    dynamic securityContext,
    Duration? streamingConnectionTimeout,
    Duration? connectionTimeout,
    Function(
      _isc.MethodCallContext,
      Object,
      StackTrace,
    )?
    onFailedCall,
    Function(_isc.MethodCallContext)? onSucceededCall,
    bool? disconnectStreamsOnLostInternetConnection,
    _i85jenna.Client? httpClientOverride,
  }) : super(
         host,
         _il2as5qe.Protocol(),
         securityContext: securityContext,
         streamingConnectionTimeout: streamingConnectionTimeout,
         connectionTimeout: connectionTimeout,
         onFailedCall: onFailedCall,
         onSucceededCall: onSucceededCall,
         disconnectStreamsOnLostInternetConnection:
             disconnectStreamsOnLostInternetConnection,
         httpClientOverride: httpClientOverride,
       ) {
    emailIdp = EndpointEmailIdp(this);
    jwtRefresh = EndpointJwtRefresh(this);
    posts = EndpointPosts(this);
    profiles = EndpointProfiles(this);
    moderation = EndpointModeration(this);
    comments = EndpointComments(this);
    likes = EndpointLikes(this);
    health = EndpointHealth(this);
    modules = Modules(this);
  }

  late final EndpointEmailIdp emailIdp;

  late final EndpointJwtRefresh jwtRefresh;

  late final EndpointPosts posts;

  late final EndpointProfiles profiles;

  late final EndpointModeration moderation;

  late final EndpointComments comments;

  late final EndpointLikes likes;

  late final EndpointHealth health;

  late final Modules modules;

  @override
  Map<String, _isc.EndpointRef> get endpointRefLookup => {
    'emailIdp': emailIdp,
    'jwtRefresh': jwtRefresh,
    'posts': posts,
    'profiles': profiles,
    'moderation': moderation,
    'comments': comments,
    'likes': likes,
    'health': health,
  };

  @override
  Map<String, _isc.ModuleEndpointCaller> get moduleLookup => {
    'serverpod_auth_idp': modules.serverpod_auth_idp,
    'serverpod_auth_core': modules.serverpod_auth_core,
  };
}
