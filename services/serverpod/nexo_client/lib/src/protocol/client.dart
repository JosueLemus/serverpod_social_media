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
import 'package:nexo_client/src/protocol/modules/feed/models/home_feed_cursor.dart'
    as _iujuwyaw;
import 'package:nexo_client/src/protocol/modules/feed/models/home_feed_page.dart'
    as _igm2dp4q;
import 'package:nexo_client/src/protocol/modules/identity/models/account_view.dart'
    as _i0b9qmvw;
import 'package:nexo_client/src/protocol/modules/identity/models/profile_edit.dart'
    as _ih9nymjn;
import 'package:nexo_client/src/protocol/modules/identity/models/profile_view.dart'
    as _iaqpe3js;
import 'package:nexo_client/src/protocol/modules/live/models/live_chat_message_view.dart'
    as _iksujo4g;
import 'package:nexo_client/src/protocol/modules/live/models/live_event.dart'
    as _ihybkmik;
import 'package:nexo_client/src/protocol/modules/live/models/live_media_grant.dart'
    as _iio5lkou;
import 'package:nexo_client/src/protocol/modules/live/models/live_show_draft.dart'
    as _imx9qecc;
import 'package:nexo_client/src/protocol/modules/live/models/live_show_role.dart'
    as _iim040ig;
import 'package:nexo_client/src/protocol/modules/live/models/live_show_view.dart'
    as _igcmn4rt;
import 'package:nexo_client/src/protocol/modules/live/models/live_stage_view.dart'
    as _i27y29c3;
import 'package:nexo_client/src/protocol/modules/messages/models/conversation_page.dart'
    as _inyp06xy;
import 'package:nexo_client/src/protocol/modules/messages/models/conversation_view.dart'
    as _ij19srvj;
import 'package:nexo_client/src/protocol/modules/messages/models/direct_message_event.dart'
    as _i5xhp5ut;
import 'package:nexo_client/src/protocol/modules/messages/models/direct_message_page.dart'
    as _iqf2mvpx;
import 'package:nexo_client/src/protocol/modules/messages/models/direct_message_view.dart'
    as _ijlq9btc;
import 'package:nexo_client/src/protocol/modules/moderation/models/moderation_reason.dart'
    as _ie0oo619;
import 'package:nexo_client/src/protocol/modules/moderation/models/report_decision.dart'
    as _i4p633df;
import 'package:nexo_client/src/protocol/modules/moderation/models/report_queue_item.dart'
    as _ij26twz2;
import 'package:nexo_client/src/protocol/modules/moderation/models/report_target_type.dart'
    as _iajbeibr;
import 'package:nexo_client/src/protocol/modules/notifications/models/notification_page.dart'
    as _iu8vyvf0;
import 'package:nexo_client/src/protocol/modules/notifications/models/notification_view.dart'
    as _iloot1zz;
import 'package:nexo_client/src/protocol/modules/search/models/search_results.dart'
    as _iu557ba1;
import 'package:nexo_client/src/protocol/modules/social/models/follow_page.dart'
    as _ie4jjjxk;
import 'package:nexo_client/src/protocol/modules/social/models/follow_state.dart'
    as _iecu8iqi;
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

/// El feed de inicio por secciones. Desde Flutter: `client.feed`.
/// {@category Endpoint}
class EndpointFeed extends _isc.EndpointRef {
  EndpointFeed(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'feed';

  /// La primera página (sin [cursor]) trae las secciones con contenido:
  /// `liveNow`, `following`, `suggestedAccounts` y `discover`. Las
  /// siguientes, `following` hasta agotarse y después `discover`. Sin
  /// sesión, `following` no viene.
  _ida.Future<_igm2dp4q.HomeFeedPage> home({
    _iujuwyaw.HomeFeedCursor? cursor,
  }) => caller.callServerEndpoint<_igm2dp4q.HomeFeedPage>(
    'feed',
    'home',
    {'cursor': cursor},
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

  /// El permiso para subir un avatar: JPEG, PNG o WebP de hasta 5 MB. Se
  /// sube con `FileUploader(ticket.uploadDescription)` y se confirma con
  /// [setAvatar]. Exige sesión.
  _ida.Future<_ifucagw2.MediaUploadTicket> requestAvatarUpload({
    required String contentType,
    required int sizeBytes,
  }) => caller.callServerEndpoint<_ifucagw2.MediaUploadTicket>(
    'profiles',
    'requestAvatarUpload',
    {
      'contentType': contentType,
      'sizeBytes': sizeBytes,
    },
  );

  /// Confirma el avatar subido con [key], o lo quita con `null`. La clave
  /// tiene que ser de esta cuenta. Exige sesión.
  _ida.Future<_i0b9qmvw.AccountView> setAvatar(String? key) =>
      caller.callServerEndpoint<_i0b9qmvw.AccountView>(
        'profiles',
        'setAvatar',
        {'key': key},
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

/// Vivos: programar, iniciar, terminar, mirar y chatear. Desde Flutter:
/// `client.live`.
///
/// Mirar es público: un invitado ve los shows y su chat. Todo lo que escribe
/// exige sesión y responde [NexoException] con el código del motivo. Lo que
/// cambia llega en tiempo real por [watch] y [watchIndex].
/// {@category Endpoint}
class EndpointLive extends _isc.EndpointRef {
  EndpointLive(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'live';

  /// Programa un show. Sólo un creador verificado con la cuenta activa.
  _ida.Future<_igcmn4rt.LiveShowView> schedule(_imx9qecc.LiveShowDraft draft) =>
      caller.callServerEndpoint<_igcmn4rt.LiveShowView>(
        'live',
        'schedule',
        {'draft': draft},
      );

  /// Pone el show al aire. Sólo el host, creador verificado y activo, y sin
  /// otro vivo al aire.
  _ida.Future<_igcmn4rt.LiveShowView> start(int showId) =>
      caller.callServerEndpoint<_igcmn4rt.LiveShowView>(
        'live',
        'start',
        {'showId': showId},
      );

  /// Termina el vivo y lo deja como replay. El host o un operador.
  _ida.Future<_igcmn4rt.LiveShowView> end(int showId) =>
      caller.callServerEndpoint<_igcmn4rt.LiveShowView>(
        'live',
        'end',
        {'showId': showId},
      );

  /// Publica el replay. El host o un operador, si el show guarda replay.
  _ida.Future<_igcmn4rt.LiveShowView> publish(int showId) =>
      caller.callServerEndpoint<_igcmn4rt.LiveShowView>(
        'live',
        'publish',
        {'showId': showId},
      );

  /// Cancela un show que todavía no arrancó. El host o un operador.
  _ida.Future<_igcmn4rt.LiveShowView> cancel(int showId) =>
      caller.callServerEndpoint<_igcmn4rt.LiveShowView>(
        'live',
        'cancel',
        {'showId': showId},
      );

  /// "Transmitir ahora": crea el show y lo pone al aire en un paso. El mismo
  /// gate que [start]: creador verificado, activo y sin otro vivo al aire.
  _ida.Future<_igcmn4rt.LiveShowView> goLive(String title) =>
      caller.callServerEndpoint<_igcmn4rt.LiveShowView>(
        'live',
        'goLive',
        {'title': title},
      );

  /// La credencial para entrar al canal de video del show. El servidor
  /// decide el rol: publica sólo el host con el show al aire.
  _ida.Future<_iio5lkou.LiveMediaGrant> mediaToken(int showId) =>
      caller.callServerEndpoint<_iio5lkou.LiveMediaGrant>(
        'live',
        'mediaToken',
        {'showId': showId},
      );

  /// Un show. `notFound` si no existe o se retiró.
  _ida.Future<_igcmn4rt.LiveShowView> get(int showId) =>
      caller.callServerEndpoint<_igcmn4rt.LiveShowView>(
        'live',
        'get',
        {'showId': showId},
      );

  /// Al aire, programados y replays, en ese orden (hasta 50).
  _ida.Future<List<_igcmn4rt.LiveShowView>> list() =>
      caller.callServerEndpoint<List<_igcmn4rt.LiveShowView>>(
        'live',
        'list',
        {},
      );

  /// Los shows de la cuenta de la sesión, en cualquier estado.
  _ida.Future<List<_igcmn4rt.LiveShowView>> mine() =>
      caller.callServerEndpoint<List<_igcmn4rt.LiveShowView>>(
        'live',
        'mine',
        {},
      );

  /// El rol de quien pide dentro del show. Sin sesión, `audience`.
  _ida.Future<_iim040ig.LiveShowRole> roleIn(int showId) =>
      caller.callServerEndpoint<_iim040ig.LiveShowRole>(
        'live',
        'roleIn',
        {'showId': showId},
      );

  /// Chat sin los mensajes ocultos, del más viejo al más nuevo (50 por
  /// página). [beforeId] para pedir los anteriores.
  _ida.Future<List<_iksujo4g.LiveChatMessageView>> chatHistory(
    int showId, {
    int? beforeId,
  }) => caller.callServerEndpoint<List<_iksujo4g.LiveChatMessageView>>(
    'live',
    'chatHistory',
    {
      'showId': showId,
      'beforeId': beforeId,
    },
  );

  /// Manda un mensaje al chat. El show tiene que estar al aire; un mensaje
  /// por segundo por cuenta.
  _ida.Future<_iksujo4g.LiveChatMessageView> sendChat(
    int showId,
    String body,
  ) => caller.callServerEndpoint<_iksujo4g.LiveChatMessageView>(
    'live',
    'sendChat',
    {
      'showId': showId,
      'body': body,
    },
  );

  /// Oculta un mensaje. El host del show, un moderador o un operador.
  _ida.Future<void> hideChat(int messageId) => caller.callServerEndpoint<void>(
    'live',
    'hideChat',
    {'messageId': messageId},
  );

  /// Quién está en el escenario y quién pidió la palabra.
  _ida.Future<_i27y29c3.LiveStageView> stage(int showId) =>
      caller.callServerEndpoint<_i27y29c3.LiveStageView>(
        'live',
        'stage',
        {'showId': showId},
      );

  /// Pedir la palabra. Oyentes y moderador.
  _ida.Future<void> raiseHand(int showId) => caller.callServerEndpoint<void>(
    'live',
    'raiseHand',
    {'showId': showId},
  );

  /// Retirar el pedido propio.
  _ida.Future<void> lowerHand(int showId) => caller.callServerEndpoint<void>(
    'live',
    'lowerHand',
    {'showId': showId},
  );

  /// Subir a quien pidió la palabra. Host o moderador; `conflict` si no la
  /// pidió o si el escenario está lleno.
  _ida.Future<void> approveRequest(
    int showId,
    _isc.UuidValue userId,
  ) => caller.callServerEndpoint<void>(
    'live',
    'approveRequest',
    {
      'showId': showId,
      'userId': userId,
    },
  );

  /// Rechazar un pedido de palabra. Host o moderador.
  _ida.Future<void> denyRequest(
    int showId,
    _isc.UuidValue userId,
  ) => caller.callServerEndpoint<void>(
    'live',
    'denyRequest',
    {
      'showId': showId,
      'userId': userId,
    },
  );

  /// Subir a alguien directo. Sólo el host.
  _ida.Future<void> inviteToStage(
    int showId,
    _isc.UuidValue userId,
  ) => caller.callServerEndpoint<void>(
    'live',
    'inviteToStage',
    {
      'showId': showId,
      'userId': userId,
    },
  );

  /// Bajar a alguien del escenario. Sólo el host.
  _ida.Future<void> removeFromStage(
    int showId,
    _isc.UuidValue userId,
  ) => caller.callServerEndpoint<void>(
    'live',
    'removeFromStage',
    {
      'showId': showId,
      'userId': userId,
    },
  );

  /// Bajarse del escenario.
  _ida.Future<void> leaveStage(int showId) => caller.callServerEndpoint<void>(
    'live',
    'leaveStage',
    {'showId': showId},
  );

  /// El micrófono propio, o silenciar el de otro (host o moderador, sólo
  /// para apagarlo).
  _ida.Future<void> setMicMuted(
    int showId,
    _isc.UuidValue userId,
    bool muted,
  ) => caller.callServerEndpoint<void>(
    'live',
    'setMicMuted',
    {
      'showId': showId,
      'userId': userId,
      'muted': muted,
    },
  );

  /// La cámara propia, estando en el escenario.
  _ida.Future<void> setCamera(
    int showId,
    bool on,
  ) => caller.callServerEndpoint<void>(
    'live',
    'setCamera',
    {
      'showId': showId,
      'on': on,
    },
  );

  /// Nombra al moderador del vivo, o lo quita con [userId] null. Sólo el
  /// host; también antes de salir al aire.
  _ida.Future<void> assignModerator(
    int showId,
    _isc.UuidValue? userId,
  ) => caller.callServerEndpoint<void>(
    'live',
    'assignModerator',
    {
      'showId': showId,
      'userId': userId,
    },
  );

  /// Silencio en el chat por 5, 15 o 60 [minutes], o el resto del vivo con
  /// null. Host o moderador.
  _ida.Future<void> muteChat(
    int showId,
    _isc.UuidValue userId,
    int? minutes,
  ) => caller.callServerEndpoint<void>(
    'live',
    'muteChat',
    {
      'showId': showId,
      'userId': userId,
      'minutes': minutes,
    },
  );

  /// Levanta un silencio antes de tiempo.
  _ida.Future<void> unmuteChat(
    int showId,
    _isc.UuidValue userId,
  ) => caller.callServerEndpoint<void>(
    'live',
    'unmuteChat',
    {
      'showId': showId,
      'userId': userId,
    },
  );

  /// Fuera de este vivo. Host o moderador.
  _ida.Future<void> kick(
    int showId,
    _isc.UuidValue userId,
  ) => caller.callServerEndpoint<void>(
    'live',
    'kick',
    {
      'showId': showId,
      'userId': userId,
    },
  );

  /// Fuera de todos los vivos del host. Sólo el host.
  _ida.Future<void> ban(
    int showId,
    _isc.UuidValue userId,
  ) => caller.callServerEndpoint<void>(
    'live',
    'ban',
    {
      'showId': showId,
      'userId': userId,
    },
  );

  /// Levanta un baneo de los vivos propios.
  _ida.Future<void> unban(_isc.UuidValue userId) =>
      caller.callServerEndpoint<void>(
        'live',
        'unban',
        {'userId': userId},
      );

  /// Devuelve un mensaje oculto. Uno borrado no vuelve.
  _ida.Future<void> unhideChat(int messageId) =>
      caller.callServerEndpoint<void>(
        'live',
        'unhideChat',
        {'messageId': messageId},
      );

  /// Borra un mensaje para todos y del replay; la fila queda para la
  /// auditoría. Host o moderador.
  _ida.Future<void> deleteChat(int messageId) =>
      caller.callServerEndpoint<void>(
        'live',
        'deleteChat',
        {'messageId': messageId},
      );

  /// Fija un mensaje arriba del chat, o lo despega con null.
  _ida.Future<void> pinChat(
    int showId,
    int? messageId,
  ) => caller.callServerEndpoint<void>(
    'live',
    'pinChat',
    {
      'showId': showId,
      'messageId': messageId,
    },
  );

  /// Destaca una pregunta del chat, o la quita con null. Host, moderador o
  /// invitado.
  _ida.Future<void> highlightQuestion(
    int showId,
    int? messageId,
  ) => caller.callServerEndpoint<void>(
    'live',
    'highlightQuestion',
    {
      'showId': showId,
      'messageId': messageId,
    },
  );

  /// Lo que pasa en un show, en tiempo real. El primer evento es
  /// `snapshot`; después llegan `status`, `viewers`, `chat`, `chatHidden`,
  /// `stage`, `roleChanged`, `sanction`, `chatDeleted`, `chatRestored`,
  /// `pinned` y `highlighted`. Un expulsado o baneado recibe `forbidden`.
  /// Mientras la conexión está abierta, cuenta como espectador.
  _ida.Stream<_ihybkmik.LiveEvent> watch(int showId) =>
      caller.callStreamingServerEndpoint<
        _ida.Stream<_ihybkmik.LiveEvent>,
        _ihybkmik.LiveEvent
      >(
        'live',
        'watch',
        {'showId': showId},
        {},
      );

  /// Cada cambio de estado de cualquier show: para que la lista de "en vivo"
  /// se actualice sola en todos los dispositivos.
  _ida.Stream<_igcmn4rt.LiveShowView> watchIndex() =>
      caller.callStreamingServerEndpoint<
        _ida.Stream<_igcmn4rt.LiveShowView>,
        _igcmn4rt.LiveShowView
      >(
        'live',
        'watchIndex',
        {},
        {},
      );
}

/// Mensajes directos 1 a 1 (SDD 0010). Desde Flutter: `client.messages`.
/// Todo exige sesión.
/// {@category Endpoint}
class EndpointMessages extends _isc.EndpointRef {
  EndpointMessages(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'messages';

  /// La bandeja: la conversación con actividad más reciente primero. No
  /// lista las conversaciones sin mensajes.
  _ida.Future<_inyp06xy.ConversationPage> conversations({
    _ir35iwx2.PageCursor? after,
    int? limit,
  }) => caller.callServerEndpoint<_inyp06xy.ConversationPage>(
    'messages',
    'conversations',
    {
      'after': after,
      'limit': limit,
    },
  );

  /// La conversación con [userId], creándola si no existía.
  _ida.Future<_ij19srvj.ConversationView> open(_isc.UuidValue userId) =>
      caller.callServerEndpoint<_ij19srvj.ConversationView>(
        'messages',
        'open',
        {'userId': userId},
      );

  /// Una conversación de la sesión, con el otro miembro y los no leídos.
  _ida.Future<_ij19srvj.ConversationView> conversation(int conversationId) =>
      caller.callServerEndpoint<_ij19srvj.ConversationView>(
        'messages',
        'conversation',
        {'conversationId': conversationId},
      );

  /// Mensajes anteriores a [beforeId] (o los últimos), del más viejo al más
  /// nuevo.
  _ida.Future<_iqf2mvpx.DirectMessagePage> history(
    int conversationId, {
    int? beforeId,
    int? limit,
  }) => caller.callServerEndpoint<_iqf2mvpx.DirectMessagePage>(
    'messages',
    'history',
    {
      'conversationId': conversationId,
      'beforeId': beforeId,
      'limit': limit,
    },
  );

  _ida.Future<_ijlq9btc.DirectMessageView> send(
    int conversationId,
    String body,
  ) => caller.callServerEndpoint<_ijlq9btc.DirectMessageView>(
    'messages',
    'send',
    {
      'conversationId': conversationId,
      'body': body,
    },
  );

  /// Marca leída la conversación. Devuelve las que quedan sin leer.
  _ida.Future<int> markRead(int conversationId) =>
      caller.callServerEndpoint<int>(
        'messages',
        'markRead',
        {'conversationId': conversationId},
      );

  /// Conversaciones con algo sin leer: el número del badge.
  _ida.Future<int> unreadCount() => caller.callServerEndpoint<int>(
    'messages',
    'unreadCount',
    {},
  );

  /// Mensajes nuevos y lecturas de las conversaciones de la sesión, en el
  /// momento.
  _ida.Stream<_i5xhp5ut.DirectMessageEvent> watch() =>
      caller.callStreamingServerEndpoint<
        _ida.Stream<_i5xhp5ut.DirectMessageEvent>,
        _i5xhp5ut.DirectMessageEvent
      >(
        'messages',
        'watch',
        {},
        {},
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

/// Los avisos de la cuenta de la sesión. Desde Flutter:
/// `client.notifications`. Todo exige sesión.
/// {@category Endpoint}
class EndpointNotifications extends _isc.EndpointRef {
  EndpointNotifications(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'notifications';

  /// De la más nueva a la más vieja.
  _ida.Future<_iu8vyvf0.NotificationPage> list({
    _ir35iwx2.PageCursor? after,
    int? limit,
  }) => caller.callServerEndpoint<_iu8vyvf0.NotificationPage>(
    'notifications',
    'list',
    {
      'after': after,
      'limit': limit,
    },
  );

  _ida.Future<int> unreadCount() => caller.callServerEndpoint<int>(
    'notifications',
    'unreadCount',
    {},
  );

  /// Marca [ids] como leídos (sólo los propios). Devuelve los que quedan.
  _ida.Future<int> markRead(List<int> ids) => caller.callServerEndpoint<int>(
    'notifications',
    'markRead',
    {'ids': ids},
  );

  /// Marca todos como leídos. Devuelve 0.
  _ida.Future<int> markAllRead() => caller.callServerEndpoint<int>(
    'notifications',
    'markAllRead',
    {},
  );

  /// Cada aviso nuevo, en el momento: el badge de Actividad cambia sin
  /// recargar.
  _ida.Stream<_iloot1zz.NotificationView> watch() =>
      caller.callStreamingServerEndpoint<
        _ida.Stream<_iloot1zz.NotificationView>,
        _iloot1zz.NotificationView
      >(
        'notifications',
        'watch',
        {},
        {},
      );
}

/// El buscador de Explorar. Desde Flutter: `client.search`.
/// {@category Endpoint}
class EndpointSearch extends _isc.EndpointRef {
  EndpointSearch(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'search';

  /// Cuentas, publicaciones, vivos y etiquetas que coinciden con [text].
  /// Público: un invitado también busca, y ve sólo lo que vería en el feed.
  /// Con menos de dos letras devuelve todo vacío. [limit] es por sección
  /// (10 por defecto, 20 como máximo).
  _ida.Future<_iu557ba1.SearchResults> query(
    String text, {
    int? limit,
  }) => caller.callServerEndpoint<_iu557ba1.SearchResults>(
    'search',
    'query',
    {
      'text': text,
      'limit': limit,
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

/// Seguir cuentas. Desde Flutter: `client.follows`.
///
/// Seguir y dejar de seguir exigen sesión y son idempotentes. Las listas y
/// las sugerencias son públicas.
/// {@category Endpoint}
class EndpointFollows extends _isc.EndpointRef {
  EndpointFollows(_isc.EndpointCaller caller) : super(caller);

  @override
  String get name => 'follows';

  /// Sigue a [userId]. No se puede seguir a uno mismo; la cuenta tiene que
  /// estar activa.
  _ida.Future<_iecu8iqi.FollowState> follow(_isc.UuidValue userId) =>
      caller.callServerEndpoint<_iecu8iqi.FollowState>(
        'follows',
        'follow',
        {'userId': userId},
      );

  /// Deja de seguir a [userId]. Sin efecto si no lo seguía.
  _ida.Future<_iecu8iqi.FollowState> unfollow(_isc.UuidValue userId) =>
      caller.callServerEndpoint<_iecu8iqi.FollowState>(
        'follows',
        'unfollow',
        {'userId': userId},
      );

  /// Quién sigue a [userId], del más reciente al más viejo.
  _ida.Future<_ie4jjjxk.FollowPage> followers(
    _isc.UuidValue userId, {
    _ir35iwx2.PageCursor? after,
    int? limit,
  }) => caller.callServerEndpoint<_ie4jjjxk.FollowPage>(
    'follows',
    'followers',
    {
      'userId': userId,
      'after': after,
      'limit': limit,
    },
  );

  /// A quién sigue [userId], del más reciente al más viejo.
  _ida.Future<_ie4jjjxk.FollowPage> following(
    _isc.UuidValue userId, {
    _ir35iwx2.PageCursor? after,
    int? limit,
  }) => caller.callServerEndpoint<_ie4jjjxk.FollowPage>(
    'follows',
    'following',
    {
      'userId': userId,
      'after': after,
      'limit': limit,
    },
  );

  /// Creadores verificados que la sesión todavía no sigue, por seguidores
  /// (hasta 20; 10 por defecto). Sin sesión, los más seguidos.
  _ida.Future<List<_iaqpe3js.ProfileView>> suggestions({int? limit}) =>
      caller.callServerEndpoint<List<_iaqpe3js.ProfileView>>(
        'follows',
        'suggestions',
        {'limit': limit},
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
    feed = EndpointFeed(this);
    profiles = EndpointProfiles(this);
    live = EndpointLive(this);
    messages = EndpointMessages(this);
    moderation = EndpointModeration(this);
    notifications = EndpointNotifications(this);
    search = EndpointSearch(this);
    comments = EndpointComments(this);
    follows = EndpointFollows(this);
    likes = EndpointLikes(this);
    health = EndpointHealth(this);
    modules = Modules(this);
  }

  late final EndpointEmailIdp emailIdp;

  late final EndpointJwtRefresh jwtRefresh;

  late final EndpointPosts posts;

  late final EndpointFeed feed;

  late final EndpointProfiles profiles;

  late final EndpointLive live;

  late final EndpointMessages messages;

  late final EndpointModeration moderation;

  late final EndpointNotifications notifications;

  late final EndpointSearch search;

  late final EndpointComments comments;

  late final EndpointFollows follows;

  late final EndpointLikes likes;

  late final EndpointHealth health;

  late final Modules modules;

  @override
  Map<String, _isc.EndpointRef> get endpointRefLookup => {
    'emailIdp': emailIdp,
    'jwtRefresh': jwtRefresh,
    'posts': posts,
    'feed': feed,
    'profiles': profiles,
    'live': live,
    'messages': messages,
    'moderation': moderation,
    'notifications': notifications,
    'search': search,
    'comments': comments,
    'follows': follows,
    'likes': likes,
    'health': health,
  };

  @override
  Map<String, _isc.ModuleEndpointCaller> get moduleLookup => {
    'serverpod_auth_idp': modules.serverpod_auth_idp,
    'serverpod_auth_core': modules.serverpod_auth_core,
  };
}
