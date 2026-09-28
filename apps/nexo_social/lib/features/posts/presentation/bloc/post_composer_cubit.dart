import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/storage/mock_social_store.dart';
import '../../../feed/domain/entities/post.dart';

/// Qué se está componiendo. El diseño pone Post y En vivo en el mismo
/// compositor porque la decisión es la misma —qué quiero contar y a quién—:
/// sólo cambia si se publica o se programa.
enum ComposerMode {
  post('Post'),
  live('En vivo');

  const ComposerMode(this.label);

  final String label;
}

/// Quién puede verlo. Es una decisión del dominio, no un adorno: el backend
/// filtra el feed por esto, y "todos" nunca puede ser un default accidental.
enum PostVisibility {
  public('Público', 'Todos'),
  followers('Seguidores', 'Solo quien te sigue'),
  members('Miembros', 'Solo suscriptores Pro');

  const PostVisibility(this.label, this.detail);

  final String label;
  final String detail;
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
    this.media,
    this.poll,
    this.allowComments = true,
    this.notifyVip = true,
  });

  final String text;
  final ComposerMode mode;
  final PostVisibility visibility;
  final PostMedia? media;
  final DraftPoll? poll;
  final bool allowComments;
  final bool notifyVip;

  int get length => text.characters.length;

  /// La única fuente de verdad de si el CTA está habilitado. La vista lo
  /// re-derivaba inline, así que la regla vivía en dos lugares y podía
  /// separarse.
  bool get canPublish {
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
    PostMedia? media,
    DraftPoll? poll,
    bool? allowComments,
    bool? notifyVip,
    bool clearMedia = false,
    bool clearPoll = false,
  }) => PostComposerIdle(
    text: text ?? this.text,
    mode: mode ?? this.mode,
    visibility: visibility ?? this.visibility,
    media: clearMedia ? null : (media ?? this.media),
    poll: clearPoll ? null : (poll ?? this.poll),
    allowComments: allowComments ?? this.allowComments,
    notifyVip: notifyVip ?? this.notifyVip,
  );

  @override
  List<Object?> get props => [
    text,
    mode,
    visibility,
    media,
    poll,
    allowComments,
    notifyVip,
  ];
}

class PostComposerPublished extends PostComposerState {
  const PostComposerPublished();
}

class PostComposerCubit extends Cubit<PostComposerState> {
  PostComposerCubit(this._store) : super(const PostComposerIdle());

  final MockSocialStore _store;

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

  void attach(PostMedia media) {
    if (state is! PostComposerIdle) return;
    // Adjuntar reemplaza: el diseño muestra una sola pieza de media, y una
    // lista de adjuntos sin UI para reordenarlos es una lista que no se puede
    // corregir.
    emit(_draft.copyWith(media: media));
  }

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

    final posts = _store.readPosts();
    posts.insert(
      0,
      Post(
        // Temporal y no `draft-${length + 1}`: ese esquema repite un id apenas
        // se borra algo, y dos posts con la misma key hacen que la lista
        // reutilice el elemento equivocado.
        id: 'draft-${DateTime.now().microsecondsSinceEpoch}',
        author: 'elena_ux',
        name: 'Elena Vega',
        body: current.text.trim(),
        tags: const ['Nuevo'],
        likes: 0,
        comments: 0,
        createdAt: DateTime.now(),
        media: current.media,
        isFollowed: true,
        authorIsVerified: true,
      ),
    );
    await _store.savePosts(posts);
    emit(const PostComposerPublished());
  }
}
