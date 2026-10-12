import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:nexo_social/core/errors/failures.dart';
import 'package:nexo_social/core/media/media_picker.dart';
import 'package:nexo_social/features/feed/domain/entities/post.dart';
import 'package:nexo_social/features/feed/domain/entities/post_extras.dart';
import 'package:nexo_social/features/profile/domain/entities/profile_changes.dart';
import 'package:nexo_social/features/profile/domain/entities/public_profile.dart';
import 'package:nexo_social/features/profile/domain/repositories/account_repository.dart';
import 'package:nexo_social/features/profile/domain/repositories/profile_repository.dart';
import 'package:nexo_social/features/profile/presentation/bloc/edit_profile_cubit.dart';

class _MockAccount extends Mock implements AccountRepository {}

class _MockProfiles extends Mock implements ProfileRepository {}

class _FakePicker implements MediaPicker {
  MediaAttachment? next;

  @override
  Future<MediaAttachment?> pick(PostMedia kind) async => next;
}

const _tomas = PublicProfile(
  id: 'uuid-tomas',
  username: 'tomas',
  name: 'Tomás Ríos',
  bio: 'Miro vivos',
);

MediaAttachment _image({int bytes = 10, String type = 'image/jpeg'}) =>
    MediaAttachment(
      kind: PostMedia.image,
      bytes: Uint8List(bytes),
      contentType: type,
      fileName: 'foto.jpg',
    );

void main() {
  late _MockAccount account;
  late _MockProfiles profiles;
  late _FakePicker picker;

  setUpAll(() {
    registerFallbackValue(const ProfileChanges());
    registerFallbackValue(_image());
  });

  setUp(() {
    account = _MockAccount();
    profiles = _MockProfiles();
    picker = _FakePicker();
    when(() => profiles.byUsername('tomas')).thenAnswer((_) async => _tomas);
    when(() => account.update(any())).thenAnswer((_) async {});
    when(() => account.setAvatar(any())).thenAnswer((_) async {});
  });

  Future<EditProfileCubit> loaded() async {
    final cubit = EditProfileCubit(account, profiles, picker);
    await cubit.load('tomas');
    return cubit;
  }

  test('starts from the account and has nothing to save', () async {
    final cubit = await loaded();

    expect(cubit.state.status, EditProfileStatus.editing);
    expect(cubit.state.username, 'tomas');
    expect(cubit.state.bio, 'Miro vivos');
    expect(cubit.state.canSave, isFalse);
    await cubit.close();
  });

  /// La regla vive en el cubit, no en el botón: un nombre de usuario que el
  /// servidor va a rechazar no habilita "Guardar".
  test('an invalid username cannot be saved', () async {
    final cubit = await loaded();

    cubit.setUsername('To Más');
    expect(cubit.state.usernameIssue, ProfileFieldIssue.usernameCharacters);
    expect(cubit.state.canSave, isFalse);

    cubit.setUsername('ad');
    expect(cubit.state.usernameIssue, ProfileFieldIssue.usernameLength);

    cubit.setUsername('admin');
    expect(cubit.state.usernameIssue, ProfileFieldIssue.usernameReserved);
    await cubit.close();
  });

  test('saves only what changed, normalized', () async {
    final cubit = await loaded();
    cubit
      ..setUsername('Tomas_R ')
      ..setBio('Miro vivos');

    await cubit.save();

    final changes =
        verify(() => account.update(captureAny())).captured.single
            as ProfileChanges;
    expect(changes.username, 'tomas_r');
    expect(changes.displayName, isNull);
    expect(changes.bio, isNull);
    expect(cubit.state.status, EditProfileStatus.saved);
    verifyNever(() => account.setAvatar(any()));
    await cubit.close();
  });

  test('a taken username says so and keeps the form', () async {
    when(
      () => account.update(any()),
    ).thenThrow(const ConflictFailure('username taken'));
    final cubit = await loaded();
    cubit.setUsername('elena_ux');

    await cubit.save();

    expect(cubit.state.status, EditProfileStatus.editing);
    expect(cubit.state.issue, EditProfileIssue.usernameTaken);
    expect(cubit.state.username, 'elena_ux');
    await cubit.close();
  });

  test('a picked photo is uploaded on save', () async {
    final photo = _image();
    picker.next = photo;
    final cubit = await loaded();

    await cubit.pickAvatar();
    expect(cubit.state.canSave, isTrue);
    await cubit.save();

    verify(() => account.setAvatar(photo)).called(1);
    await cubit.close();
  });

  test('a photo the server would refuse is refused here first', () async {
    final cubit = await loaded();

    picker.next = _image(bytes: EditProfileCubit.maxAvatarBytes + 1);
    await cubit.pickAvatar();
    expect(cubit.state.issue, EditProfileIssue.avatarTooLarge);

    picker.next = _image(type: 'image/gif');
    await cubit.pickAvatar();
    expect(cubit.state.issue, EditProfileIssue.avatarType);
    expect(cubit.state.pickedAvatar, isNull);
    await cubit.close();
  });

  test('removing the photo sends null', () async {
    when(() => profiles.byUsername('tomas')).thenAnswer(
      (_) async => const PublicProfile(
        id: 'uuid-tomas',
        username: 'tomas',
        name: 'Tomás Ríos',
        avatarUrl: 'https://cdn.example/t.webp',
      ),
    );
    final cubit = await loaded();

    cubit.removeAvatar();
    await cubit.save();

    verify(() => account.setAvatar(null)).called(1);
    await cubit.close();
  });

  test('becoming a creator flips the account', () async {
    when(() => account.becomeCreator()).thenAnswer((_) async {});
    final cubit = await loaded();

    await cubit.becomeCreator();

    expect(cubit.state.isCreator, isTrue);
    expect(cubit.state.becomingCreator, isFalse);
    await cubit.close();
  });
}
