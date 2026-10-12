import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/media/media_picker.dart';
import '../../../feed/domain/entities/media_rules.dart';
import '../../../feed/domain/entities/post.dart';
import '../../../feed/domain/entities/post_extras.dart';
import '../../../feed/domain/repositories/post_repository.dart';

export '../../../feed/domain/entities/post.dart' show PostMedia, PostVisibility;

/// Qué se está componiendo. El diseño pone Post y En vivo en el mismo
/// compositor porque la decisión es la misma —qué quiero contar y a quién—:
/// sólo cambia si se publica o se programa.
enum ComposerMode {
  post('Post'),
  live('En vivo');

  const ComposerMode(this.label);

  final String label;
}

/// Por qué no se pudo adjuntar o publicar. La View lo traduce.
enum ComposerIssue {
  fileTooLarge,
  unsupportedFile,
  publishFailed,
  offline,
  forbidden,
}

/// Una encuesta en edición.
class DraftPoll extends Equatable {
  const DraftPoll({this.options = const ['', ''], this.durationHours = 24});

  final List<String> options;
  final int durationHours;

  static const maxOptions = 4;
  static const minOptions = 2;

  /// Publicable sólo con al menos dos opciones con texto. Una encuesta con una
  /// sola respuesta no es una pregunta.
  bool get isValid =>
      options.where((option) => option.trim().isNotEmpty).length >= minOptions;

  bool get canAddOption => options.length < maxOptions;

  DraftPoll copyWith({List<String>? options, int? durationHours}) => DraftPoll(
    options: options ?? this.options,
    durationHours: durationHours ?? this.durationHours,
  );

  @override
  List<Object?> get props => [options, durationHours];
}

sealed class PostComposerState extends Equatable {
  const PostComposerState();

  @override
  List<Object?> get props => const [];
}

class PostComposerIdle extends PostComposerState {
  const PostComposerIdle({
    this.text = '',
    this.mode = ComposerMode.post,
    this.visibility = PostVisibility.public,
    this.attachment,
    this.poll,
    this.allowComments = true,
    this.notifyVip = true,
    this.isPublishing = false,
    this.issue,
    this.issueSerial = 0,
  });

  final String text;
  final ComposerMode mode;
  final PostVisibility visibility;

  /// El archivo elegido, con sus bytes. Uno solo: el diseño muestra una
  /// pieza de media.
  final MediaAttachment? attachment;
  PostMedia? get media => attachment?.kind;
  final DraftPoll? poll;
  final bool allowComments;
  final bool notifyVip;

  /// Subiendo el archivo y publicando. Deshabilita el CTA: un doble toque no
  /// puede publicar dos veces.
  final bool isPublishing;
  final ComposerIssue? issue;
  final int issueSerial;

  int get length => text.characters.length;

  /// La única fuente de verdad de si el CTA está habilitado. La vista lo
  /// re-derivaba inline, así que la regla vivía en dos lugares y podía
  /// separarse.
  bool get canPublish {
    if (isPublishing) return false;
    if (text.trim().isEmpty || length > PostComposerCubit.maxLength) {
      return false;
    }
    // Con encuesta abierta, el texto solo no alcanza: publicar una encuesta a
    // medio escribir deja una votación que nadie puede responder.
    if (poll != null && !poll!.isValid) return false;
    return true;
  }

  PostComposerIdle copyWith({
    String? text,
    ComposerMode? mode,
    PostVisibility? visibility,
    MediaAttachment? attachment,
    DraftPoll? poll,
    bool? allowComments,
    bool? notifyVip,
    bool? isPublishing,
    ComposerIssue? issue,
    int? issueSerial,
    bool clearMedia = false,
    bool clearPoll = false,
  }) => PostComposerIdle(
    text: text ?? this.text,
    mode: mode ?? this.mode,
    visibility: visibility ?? this.visibility,
    attachment: clearMedia ? null : (attachment ?? this.attachment),
    poll: clearPoll ? null : (poll ?? this.poll),
    allowComments: allowComments ?? this.allowComments,
    notifyVip: notifyVip ?? this.notifyVip,
    isPublishing: isPublishing ?? this.isPublishing,
    issue: issue ?? this.issue,
    issueSerial: issueSerial ?? this.issueSerial,
  );

  @override
  List<Object?> get props => [
    text,
    mode,
    visibility,
    attachment,
    poll,
    allowComments,
    notifyVip,
    isPublishing,
    issue,
    issueSerial,
  ];
}

class PostComposerPublished extends PostComposerState {
  const PostComposerPublished();
}

class PostComposerCubit extends Cubit<PostComposerState> {
  PostComposerCubit(this._posts, [MediaPicker? picker])
    : _picker = picker ?? DeviceMediaPicker(),
      super(const PostComposerIdle());

  final PostRepository _posts;
  final MediaPicker _picker;

  static const maxLength = 500;

  PostComposerIdle get _draft => state as PostComposerIdle;

  void change(String text) {
    if (state is! PostComposerIdle) return;
    emit(_draft.copyWith(text: text));
  }

  void setMode(ComposerMode mode) {
    if (state is! PostComposerIdle) return;
    emit(_draft.copyWith(mode: mode));
  }

  void setVisibility(PostVisibility visibility) {
    if (state is! PostComposerIdle) return;
    emit(_draft.copyWith(visibility: visibility));
  }

  /// Abre el selector del dispositivo. Adjuntar reemplaza: el diseño muestra
  /// una sola pieza de media, y una lista de adjuntos sin UI para
  /// reordenarlos es una lista que no se puede corregir.
  Future<void> attach(PostMedia kind) async {
    if (state is! PostComposerIdle) return;
    final picked = await _picker.pick(kind);
    if (picked == null || isClosed || state is! PostComposerIdle) return;
    if (!MediaRules.accepts(kind, picked.contentType)) {
      _flag(ComposerIssue.unsupportedFile);
      return;
    }
    if (picked.sizeBytes > MediaRules.maxBytes(kind)) {
      _flag(ComposerIssue.fileTooLarge);
      return;
    }
    emit(_draft.copyWith(attachment: picked));
  }

  void _flag(ComposerIssue issue) =>
      emit(_draft.copyWith(issue: issue, issueSerial: _draft.issueSerial + 1));

  void removeMedia() {
    if (state is! PostComposerIdle) return;
    emit(_draft.copyWith(clearMedia: true));
  }

  void togglePoll() {
    if (state is! PostComposerIdle) return;
    emit(
      _draft.poll == null
          ? _draft.copyWith(poll: const DraftPoll())
          : _draft.copyWith(clearPoll: true),
    );
  }

  void setPollOption(int index, String value) {
    if (state is! PostComposerIdle) return;
    final poll = _draft.poll;
    if (poll == null || index < 0 || index >= poll.options.length) return;
    final options = List.of(poll.options)..[index] = value;
    emit(_draft.copyWith(poll: poll.copyWith(options: options)));
  }

  void addPollOption() {
    if (state is! PostComposerIdle) return;
    final poll = _draft.poll;
    if (poll == null || !poll.canAddOption) return;
    emit(_draft.copyWith(poll: poll.copyWith(options: [...poll.options, ''])));
  }

  void setAllowComments({required bool value}) {
    if (state is! PostComposerIdle) return;
    emit(_draft.copyWith(allowComments: value));
  }

  void setNotifyVip({required bool value}) {
    if (state is! PostComposerIdle) return;
    emit(_draft.copyWith(notifyVip: value));
  }

  Future<void> publish() async {
    final current = state;
    if (current is! PostComposerIdle || !current.canPublish) return;

    emit(current.copyWith(isPublishing: true));
    final body = current.text.trim();
    try {
      // Las encuestas todavía no existen en el servidor: se componen pero no
      // viajan. El texto sí, y las etiquetas salen de sus #hashtags.
      await _posts.create(
        PostDraftInput(
          body: body,
          tags: MediaRules.tagsIn(body),
          visibility: current.visibility,
          allowComments: current.allowComments,
          attachment: current.attachment,
        ),
      );
      if (!isClosed) emit(const PostComposerPublished());
    } on Failure catch (failure) {
      if (isClosed) return;
      emit(
        _draft.copyWith(
          isPublishing: false,
          issue: switch (failure) {
            NetworkFailure() => ComposerIssue.offline,
            ForbiddenFailure() => ComposerIssue.forbidden,
            _ => ComposerIssue.publishFailed,
          },
          issueSerial: _draft.issueSerial + 1,
        ),
      );
    }
  }
}
