import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/media/media_picker.dart';
import '../../../feed/domain/entities/post.dart';
import '../../../feed/domain/entities/post_extras.dart';
import '../../domain/entities/profile_changes.dart';
import '../../domain/repositories/account_repository.dart';
import '../../domain/repositories/profile_repository.dart';

enum EditProfileStatus { loading, editing, saving, saved, loadFailed }

/// Por qué no se pudo guardar. La View elige la copy.
enum EditProfileIssue {
  usernameTaken,
  rejected,
  network,
  suspended,
  avatarTooLarge,
  avatarType,
  other,
}

class EditProfileState extends Equatable {
  const EditProfileState({
    this.status = EditProfileStatus.loading,
    this.initialUsername = '',
    this.initialName = '',
    this.initialBio = '',
    this.username = '',
    this.name = '',
    this.bio = '',
    this.avatarUrl,
    this.pickedAvatar,
    this.removeAvatar = false,
    this.isCreator = false,
    this.becomingCreator = false,
    this.issue,
    this.issueSerial = 0,
  });

  final EditProfileStatus status;
  final String initialUsername;
  final String initialName;
  final String initialBio;
  final String username;
  final String name;
  final String bio;

  /// La foto que ya tiene la cuenta.
  final String? avatarUrl;

  /// La foto nueva elegida y todavía no subida.
  final MediaAttachment? pickedAvatar;
  final bool removeAvatar;

  final bool isCreator;
  final bool becomingCreator;

  final EditProfileIssue? issue;
  final int issueSerial;

  ProfileFieldIssue? get usernameIssue => ProfileRules.usernameIssue(username);
  ProfileFieldIssue? get nameIssue => ProfileRules.nameIssue(name);
  ProfileFieldIssue? get bioIssue => ProfileRules.bioIssue(bio);

  bool get hasAvatar =>
      pickedAvatar != null || (!removeAvatar && avatarUrl != null);

  ProfileChanges get changes => ProfileChanges(
    username:
        ProfileRules.normalizeUsername(username) ==
            ProfileRules.normalizeUsername(initialUsername)
        ? null
        : ProfileRules.normalizeUsername(username),
    displayName: name.trim() == initialName.trim() ? null : name.trim(),
    bio: bio.trim() == initialBio.trim() ? null : bio.trim(),
  );

  bool get hasChanges =>
      !changes.isEmpty || pickedAvatar != null || removeAvatar;

  /// La regla de "se puede guardar" vive acá y no en el `builder`: dos
  /// copias de una regla se separan.
  bool get canSave =>
      status == EditProfileStatus.editing &&
      hasChanges &&
      usernameIssue == null &&
      nameIssue == null &&
      bioIssue == null;

  EditProfileState copyWith({
    EditProfileStatus? status,
    String? initialUsername,
    String? initialName,
    String? initialBio,
    String? username,
    String? name,
    String? bio,
    String? Function()? avatarUrl,
    MediaAttachment? Function()? pickedAvatar,
    bool? removeAvatar,
    bool? isCreator,
    bool? becomingCreator,
    EditProfileIssue? issue,
    int? issueSerial,
  }) => EditProfileState(
    status: status ?? this.status,
    initialUsername: initialUsername ?? this.initialUsername,
    initialName: initialName ?? this.initialName,
    initialBio: initialBio ?? this.initialBio,
    username: username ?? this.username,
    name: name ?? this.name,
    bio: bio ?? this.bio,
    avatarUrl: avatarUrl == null ? this.avatarUrl : avatarUrl(),
    pickedAvatar: pickedAvatar == null ? this.pickedAvatar : pickedAvatar(),
    removeAvatar: removeAvatar ?? this.removeAvatar,
    isCreator: isCreator ?? this.isCreator,
    becomingCreator: becomingCreator ?? this.becomingCreator,
    issue: issue ?? this.issue,
    issueSerial: issueSerial ?? this.issueSerial,
  );

  @override
  List<Object?> get props => [
    status,
    initialUsername,
    initialName,
    initialBio,
    username,
    name,
    bio,
    avatarUrl,
    pickedAvatar,
    removeAvatar,
    isCreator,
    becomingCreator,
    issue,
    issueSerial,
  ];
}

/// "Editar perfil": nombre de usuario, nombre visible, bio y foto, y el paso
/// a creador. El servidor valida todo otra vez; acá sólo se avisa antes.
class EditProfileCubit extends Cubit<EditProfileState> {
  /// El selector de fotos es el del dispositivo salvo en los tests, igual
  /// que en el compositor.
  EditProfileCubit(this._account, this._profiles, [MediaPicker? picker])
    : _picker = picker ?? DeviceMediaPicker(),
      super(const EditProfileState());

  final AccountRepository _account;
  final ProfileRepository _profiles;
  final MediaPicker _picker;

  /// Lo que acepta el servidor para una foto de perfil.
  static const maxAvatarBytes = 5 * 1024 * 1024;
  static const avatarTypes = {'image/jpeg', 'image/png', 'image/webp'};

  Future<void> load(String username) async {
    emit(state.copyWith(status: EditProfileStatus.loading));
    try {
      final profile = await _profiles.byUsername(username);
      if (isClosed) return;
      final bio = profile.bio ?? '';
      emit(
        EditProfileState(
          status: EditProfileStatus.editing,
          initialUsername: profile.username,
          initialName: profile.name,
          initialBio: bio,
          username: profile.username,
          name: profile.name,
          bio: bio,
          avatarUrl: profile.avatarUrl,
          isCreator: profile.isCreator,
        ),
      );
    } on Failure {
      if (!isClosed) emit(state.copyWith(status: EditProfileStatus.loadFailed));
    }
  }

  void setUsername(String value) => emit(state.copyWith(username: value));
  void setName(String value) => emit(state.copyWith(name: value));
  void setBio(String value) => emit(state.copyWith(bio: value));

  Future<void> pickAvatar() async {
    final picked = await _picker.pick(PostMedia.image);
    if (picked == null || isClosed) return;
    if (!avatarTypes.contains(picked.contentType)) {
      return _fail(EditProfileIssue.avatarType);
    }
    if (picked.sizeBytes > maxAvatarBytes) {
      return _fail(EditProfileIssue.avatarTooLarge);
    }
    emit(state.copyWith(pickedAvatar: () => picked, removeAvatar: false));
  }

  void removeAvatar() =>
      emit(state.copyWith(pickedAvatar: () => null, removeAvatar: true));

  Future<void> save() async {
    if (!state.canSave) return;
    final snapshot = state;
    emit(state.copyWith(status: EditProfileStatus.saving));
    try {
      await _account.update(snapshot.changes);
      if (snapshot.pickedAvatar case final image?) {
        await _account.setAvatar(image);
      } else if (snapshot.removeAvatar) {
        await _account.setAvatar(null);
      }
      if (!isClosed) emit(state.copyWith(status: EditProfileStatus.saved));
    } on Failure catch (failure) {
      if (isClosed) return;
      emit(state.copyWith(status: EditProfileStatus.editing));
      _fail(switch (failure) {
        ConflictFailure() => EditProfileIssue.usernameTaken,
        AccountSuspendedFailure() => EditProfileIssue.suspended,
        NetworkFailure() => EditProfileIssue.network,
        ServerFailure() => EditProfileIssue.rejected,
        _ => EditProfileIssue.other,
      });
    }
  }

  /// El servidor decide; verificar después es del operador.
  Future<void> becomeCreator() async {
    if (state.isCreator || state.becomingCreator) return;
    emit(state.copyWith(becomingCreator: true));
    try {
      await _account.becomeCreator();
      if (!isClosed) {
        emit(state.copyWith(isCreator: true, becomingCreator: false));
      }
    } on Failure catch (failure) {
      if (isClosed) return;
      emit(state.copyWith(becomingCreator: false));
      _fail(
        failure is NetworkFailure
            ? EditProfileIssue.network
            : EditProfileIssue.other,
      );
    }
  }

  void _fail(EditProfileIssue issue) =>
      emit(state.copyWith(issue: issue, issueSerial: state.issueSerial + 1));
}
