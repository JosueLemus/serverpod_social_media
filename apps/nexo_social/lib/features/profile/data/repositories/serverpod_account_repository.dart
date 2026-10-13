import 'dart:typed_data';

import 'package:nexo_client/nexo_client.dart' as api;

import '../../../../core/errors/failures.dart';
import '../../../../core/network/serverpod_failures.dart';
import '../../../feed/domain/entities/post_extras.dart';
import '../../domain/entities/profile_changes.dart';
import '../../domain/repositories/account_repository.dart';

/// La cuenta propia sobre `client.profiles`. La foto sube igual que un
/// adjunto de post: el servidor da un permiso, el archivo va directo al
/// storage y después se confirma con la clave.
class ServerpodAccountRepository implements AccountRepository {
  ServerpodAccountRepository(this._client);

  final api.Client _client;

  @override
  Future<void> update(ProfileChanges changes) => _guard(() async {
    if (changes.isEmpty) return;
    await _client.profiles.update(
      api.ProfileEdit(
        username: changes.username,
        displayName: changes.displayName,
        bio: changes.bio,
        website: changes.website,
      ),
    );
  });

  @override
  Future<void> setAvatar(MediaAttachment? image) => _guard(() async {
    if (image == null) {
      await _client.profiles.setAvatar(null);
      return;
    }
    final ticket = await _client.profiles.requestAvatarUpload(
      contentType: image.contentType,
      sizeBytes: image.sizeBytes,
    );
    final uploaded = await api.FileUploader(
      ticket.uploadDescription,
    ).uploadByteData(ByteData.sublistView(image.bytes));
    if (!uploaded) throw const NetworkFailure('avatar upload failed');
    await _client.profiles.setAvatar(ticket.key);
  });

  @override
  Future<void> setCover(MediaAttachment? image) => _guard(() async {
    if (image == null) {
      await _client.profiles.setCover(null);
      return;
    }
    final ticket = await _client.profiles.requestCoverUpload(
      contentType: image.contentType,
      sizeBytes: image.sizeBytes,
    );
    final uploaded = await api.FileUploader(
      ticket.uploadDescription,
    ).uploadByteData(ByteData.sublistView(image.bytes));
    if (!uploaded) throw const NetworkFailure('cover upload failed');
    await _client.profiles.setCover(ticket.key);
  });

  @override
  Future<void> becomeCreator() =>
      _guard(() async => _client.profiles.becomeCreator());

  static Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on Failure {
      rethrow;
    } catch (error) {
      throw failureFromServer(error);
    }
  }
}
