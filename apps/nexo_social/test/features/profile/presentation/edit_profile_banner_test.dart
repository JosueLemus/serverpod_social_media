import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
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

const _ana = PublicProfile(
  id: 'uuid-ana',
  username: 'ana',
  name: 'Ana Ruiz',
  coverUrl: 'https://api.nexo.dev/covers/ana.jpg',
  website: 'https://ana.dev',
);

MediaAttachment _image({int bytes = 10, String type = 'image/jpeg'}) =>
    MediaAttachment(
      kind: PostMedia.image,
      bytes: Uint8List(bytes),
      contentType: type,
      fileName: 'banner.jpg',
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
    when(() => profiles.byUsername('ana')).thenAnswer((_) async => _ana);
    when(() => account.update(any())).thenAnswer((_) async {});
    when(() => account.setAvatar(any())).thenAnswer((_) async {});
    when(() => account.setCover(any())).thenAnswer((_) async {});
  });

  Future<EditProfileCubit> loaded() async {
    final cubit = EditProfileCubit(account, profiles, picker);
    await cubit.load('ana');
    return cubit;
  }

  test('loads the banner and the link the account already has', () async {
    final cubit = await loaded();
    expect(cubit.state.coverUrl, _ana.coverUrl);
    expect(cubit.state.hasCover, isTrue);
    expect(cubit.state.website, 'https://ana.dev');
    expect(cubit.state.canSave, isFalse);
    await cubit.close();
  });

  test('a new banner is uploaded on save, and removing it clears it', () async {
    final cubit = await loaded();
    final banner = _image(bytes: 2048);
    picker.next = banner;

    await cubit.pickCover();
    expect(cubit.state.pickedCover, banner);
    expect(cubit.state.canSave, isTrue);
    await cubit.save();
    verify(() => account.setCover(banner)).called(1);
    verifyNever(() => account.setAvatar(any()));
    await cubit.close();

    final again = await loaded();
    again.removeCover();
    expect(again.state.hasCover, isFalse);
    await again.save();
    verify(() => account.setCover(null)).called(1);
    await again.close();
  });

  test('a banner over 8 MB or in another format is refused', () async {
    final cubit = await loaded();
    picker.next = _image(bytes: 8 * 1024 * 1024 + 1);
    await cubit.pickCover();
    expect(cubit.state.issue, EditProfileIssue.coverTooLarge);
    expect(cubit.state.pickedCover, isNull);

    picker.next = _image(type: 'image/gif');
    await cubit.pickCover();
    expect(cubit.state.issue, EditProfileIssue.coverType);
    await cubit.close();
  });

  test('the link is validated before saving and sent with https', () async {
    final cubit = await loaded();

    cubit.setWebsite('no es un link');
    expect(cubit.state.websiteIssue, ProfileFieldIssue.websiteInvalid);
    expect(cubit.state.canSave, isFalse);

    cubit.setWebsite('https://ana.dev/${'a' * 200}');
    expect(cubit.state.websiteIssue, ProfileFieldIssue.websiteTooLong);

    cubit.setWebsite('ana.dev/portfolio');
    expect(cubit.state.websiteIssue, isNull);
    expect(cubit.state.changes.website, 'https://ana.dev/portfolio');
    await cubit.save();
    verify(
      () => account.update(
        const ProfileChanges(website: 'https://ana.dev/portfolio'),
      ),
    ).called(1);
    await cubit.close();
  });

  test('the same link written without scheme is not a change, and an empty '
      'one removes it', () async {
    final cubit = await loaded();
    cubit.setWebsite('ana.dev');
    // "ana.dev" se guarda como "https://ana.dev": es el mismo enlace.
    expect(cubit.state.changes.website, isNull);
    expect(cubit.state.canSave, isFalse);

    cubit.setWebsite('   ');
    expect(cubit.state.changes.website, '');
    expect(cubit.state.canSave, isTrue);
    await cubit.close();
  });
}
