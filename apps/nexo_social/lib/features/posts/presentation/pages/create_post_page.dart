import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/router/app_routes.dart';
import '../../../../app/theme/app_tokens.dart';
import '../../../../core/animations/app_motion.dart';
import '../../../../core/widgets/nexo_icon.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../auth/presentation/bloc/auth_cubit.dart';
import '../bloc/post_composer_cubit.dart';
import '../widgets/composer_widgets.dart';

/// Compositor a pantalla completa, empujado sobre el shell.
class CreatePostPage extends StatelessWidget {
  const CreatePostPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => sl<PostComposerCubit>(),
    child: const _ComposerView(),
  );
}

/// Sale del compositor. Abierto desde un enlace o recargando la pestaña no
/// hay nada debajo: `pop` sobre la pila vacía revienta, así que se va al feed.
void _leave(BuildContext context) =>
    context.canPop() ? context.pop() : context.go(AppRoutes.feed);

class _ComposerView extends StatefulWidget {
  const _ComposerView();

  @override
  State<_ComposerView> createState() => _ComposerViewState();
}

class _ComposerViewState extends State<_ComposerView> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MultiBlocListener(
    listeners: [
      // Un archivo rechazado o una publicación que falló se avisa una vez,
      // en el momento. El borrador queda como estaba para reintentar.
      BlocListener<PostComposerCubit, PostComposerState>(
        listenWhen: (previous, current) =>
            current is PostComposerIdle &&
            current.issue != null &&
            (previous is! PostComposerIdle ||
                previous.issueSerial != current.issueSerial),
        listener: (context, state) =>
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text((state as PostComposerIdle).issue!.message),
              ),
            ),
      ),
      BlocListener<PostComposerCubit, PostComposerState>(
        listenWhen: (previous, current) => current is PostComposerPublished,
        listener: (context, state) {
          // El messenger se resuelve antes del pop, con este context todavía
          // montado. Leerlo después buscaría un Element desactivado y
          // reventaría — y en release ese fallo es un null check dentro del
          // framework, sin mensaje legible.
          final messenger = ScaffoldMessenger.of(context);
          // Pop y no `go('/')`: el compositor se empujó sobre la pestaña en la
          // que estaba el usuario, y `go` lo dejaría en el feed en vez de
          // devolverlo a donde salió. Abierto por URL no hay nada debajo, y
          // ahí sí se va al feed, donde se ve lo publicado.
          _leave(context);
          messenger.showSnackBar(
            const SnackBar(content: Text('Publicación creada')),
          );
        },
      ),
    ],
    child: Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        titleSpacing: AppSpacing.md,
        // El tema centra los títulos, y centrar le da al `title`
        // restricciones sueltas: esta barra ocupa el ancho completo, así
        // que centrada se mide por su contenido y desborda en un teléfono
        // angosto.
        centerTitle: false,
        title: const _ComposerBar(),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: BlocBuilder<PostComposerCubit, PostComposerState>(
              builder: (context, state) {
                if (state is! PostComposerIdle) {
                  return const SizedBox.shrink();
                }
                final cubit = context.read<PostComposerCubit>();
                return ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.xs,
                    AppSpacing.md,
                    AppSpacing.xl,
                  ),
                  children: [
                    ComposerModeTabs(
                      mode: state.mode,
                      // "En vivo" publicaba un post común con otro
                      // placeholder. Un vivo se programa: la pestaña lleva
                      // ahí, reemplazando al compositor para que volver no
                      // caiga en un borrador a medias.
                      onChanged: (mode) {
                        if (mode == ComposerMode.live) {
                          context.pushReplacement(AppRoutes.scheduleShow);
                        } else {
                          cubit.setMode(mode);
                        }
                      },
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _AuthorRow(visibility: state.visibility),
                    const SizedBox(height: AppSpacing.sm),
                    _Editor(
                      controller: _controller,
                      state: state,
                      onChanged: cubit.change,
                    ),
                    if (state.attachment != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      ComposerMediaPreview(
                        attachment: state.attachment!,
                        onRemove: cubit.removeMedia,
                      ),
                    ],
                    if (state.poll != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      ComposerPollEditor(
                        poll: state.poll!,
                        onChanged: cubit.setPollOption,
                        onAddOption: cubit.addPollOption,
                        onRemove: cubit.togglePoll,
                      ),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    ComposerAttachments(
                      onAttach: cubit.attach,
                      onPoll: cubit.togglePoll,
                      pollActive: state.poll != null,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    ComposerToggles(
                      allowComments: state.allowComments,
                      notifyVip: state.notifyVip,
                      onAllowComments: (value) =>
                          cubit.setAllowComments(value: value),
                      onNotifyVip: (value) => cubit.setNotifyVip(value: value),
                    ),
                    // Lo que todavía no existe va después de lo que sí: el
                    // asistente no se gana el espacio de los ajustes reales.
                    const SizedBox(height: AppSpacing.md),
                    const Enter(child: ComposerAiTeaser()),
                    const SizedBox(height: AppSpacing.lg),
                    const _CommunityNote(),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    ),
  );
}

/// Cancelar · estado del borrador · Publicar, en la barra superior.
///
/// El estado del borrador se muestra sólo si sobra ancho. En un teléfono
/// angosto los dos botones ya ocupan la barra, y con el texto en el medio la
/// fila desbordaba — recortando justo el botón de publicar, que es lo único
/// que esta barra existe para ofrecer.
class _ComposerBar extends StatelessWidget {
  const _ComposerBar();

  /// Debajo de esto sólo entran los dos botones.
  static const _statusMinWidth = 320.0;

  static const _height = 40.0;

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<PostComposerCubit, PostComposerState>(
        builder: (context, state) {
          final draft = state is PostComposerIdle ? state : null;
          final publishing = draft?.isPublishing ?? false;
          final label = Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800);
          return LayoutBuilder(
            builder: (context, constraints) {
              final showStatus =
                  constraints.maxWidth.isFinite &&
                  constraints.maxWidth >= _statusMinWidth;
              final publish = FilledButton.icon(
                key: const Key('publish-button'),
                // Deshabilitado por estado, no por un bool local: el cubit es
                // lo único que sabe si el borrador es publicable.
                onPressed: draft != null && draft.canPublish
                    ? context.read<PostComposerCubit>().publish
                    : null,
                iconAlignment: IconAlignment.end,
                icon: publishing
                    ? SizedBox.square(
                        dimension: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.textSecondary,
                        ),
                      )
                    : const NexoIcon(NexoGlyph.send, size: 16),
                label: Text(
                  publishing ? 'Publicando…' : 'Publicar',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, _height),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                  ),
                  textStyle: label,
                ),
              );
              return Row(
                // Sin el estado en el medio, los dos botones se separan solos
                // y el CTA puede encogerse: "Publicando…" es más largo que
                // "Publicar", y a 320 no debe empujar la fila fuera de la
                // pantalla.
                mainAxisAlignment: showStatus
                    ? MainAxisAlignment.start
                    : MainAxisAlignment.spaceBetween,
                children: [
                  // Sticker en reposo: se puede tocar, pero no compite con
                  // el blanco de publicar.
                  TextButton(
                    key: const Key('composer-close'),
                    onPressed: () => _leave(context),
                    style: TextButton.styleFrom(
                      backgroundColor: AppColors.linerHigh,
                      foregroundColor: AppColors.textPrimary,
                      minimumSize: const Size(0, _height),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                      ),
                      textStyle: label,
                    ),
                    child: const Text('Cancelar'),
                  ),
                  if (showStatus)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xs,
                        ),
                        child: Text(
                          // Honesto: no hay autoguardado todavía, así que no
                          // dice "Borrador guardado" cuando no se guardó nada.
                          draft != null && draft.text.isNotEmpty
                              ? 'Sin guardar'
                              : 'Nuevo borrador',
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ),
                  // El CTA es el sticker blanco del tema: deshabilitado vuelve
                  // a la plancha solo, sin estilos a mano.
                  if (showStatus) publish else Flexible(child: publish),
                ],
              );
            },
          );
        },
      );
}

/// Quién publica: la cuenta en sesión. Decía "Elena Vega" verificada para
/// cualquiera, así que se podía publicar creyendo que se hacía como otra
/// persona.
class _AuthorRow extends StatelessWidget {
  const _AuthorRow({required this.visibility});

  final PostVisibility visibility;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthCubit>().state;
    final user = auth is AuthAuthenticated ? auth.user : null;
    final name = user?.name ?? '';
    return Row(
      children: [
        UserAvatar(name: name, size: 44),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  if (user?.isVerified ?? false) ...[
                    const SizedBox(width: 4),
                    NexoIcon(
                      NexoGlyph.verified,
                      size: 15,
                      color: AppColors.primary,
                      semanticLabel: 'Verificado',
                    ),
                  ],
                ],
              ),
              const SizedBox(height: AppSpacing.xxs),
              VisibilityPicker(visibility: visibility),
            ],
          ),
        ),
      ],
    );
  }
}

class _Editor extends StatelessWidget {
  const _Editor({
    required this.controller,
    required this.state,
    required this.onChanged,
  });

  final TextEditingController controller;
  final PostComposerIdle state;
  final ValueChanged<String> onChanged;

  /// Escribe [token] donde está el cursor, separado de la palabra anterior.
  /// Los dos botones eran `() {}`: el # importa porque las etiquetas del post
  /// salen de los hashtags del texto.
  void _insert(String token) {
    final text = controller.text;
    final selection = controller.selection;
    final start = selection.isValid ? selection.start : text.length;
    final end = selection.isValid ? selection.end : text.length;
    final needsSpace = start > 0 && text[start - 1].trim().isNotEmpty;
    final inserted = '${needsSpace ? ' ' : ''}$token';
    controller.value = TextEditingValue(
      text: text.replaceRange(start, end, inserted),
      selection: TextSelection.collapsed(offset: start + inserted.length),
    );
    onChanged(controller.text);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final over = state.length > PostComposerCubit.maxLength;
    final body = text.bodyLarge?.copyWith(height: 1.45);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // El texto va directo sobre la plancha, sin campo relleno: es lo que
        // se está escribiendo, no un formulario.
        TextField(
          key: const Key('create-post-field'),
          controller: controller,
          autofocus: true,
          onChanged: onChanged,
          maxLines: 8,
          minLines: 4,
          // Sin `maxLength`: cortar en seco lo que alguien está escribiendo
          // borra texto sin avisar. El contador pasa a rojo y el CTA se apaga,
          // que deja la corrección en manos de quien escribe.
          decoration: InputDecoration(
            hintText: state.mode == ComposerMode.live
                ? '¿De qué vas a hablar en tu directo?'
                : 'Comparte algo con tu comunidad…',
            hintStyle: body?.copyWith(color: AppColors.textSecondary),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            filled: false,
            contentPadding: EdgeInsets.zero,
          ),
          style: body,
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            IconButton(
              key: const Key('composer-insert-hashtag'),
              tooltip: 'Añadir hashtag',
              visualDensity: VisualDensity.compact,
              color: AppColors.textSecondary,
              onPressed: () => _insert('#'),
              icon: const NexoIcon(NexoGlyph.hashtag, size: 20),
            ),
            IconButton(
              key: const Key('composer-insert-mention'),
              tooltip: 'Mencionar a alguien',
              visualDensity: VisualDensity.compact,
              color: AppColors.textSecondary,
              onPressed: () => _insert('@'),
              icon: const NexoIcon(NexoGlyph.mention, size: 20),
            ),
            const Spacer(),
            Text(
              '${state.length}/${PostComposerCubit.maxLength}',
              style: text.labelSmall?.copyWith(
                color: over ? AppColors.error : AppColors.textSecondary,
                fontWeight: over ? FontWeight.w900 : FontWeight.w700,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        const Divider(),
      ],
    );
  }
}

class _CommunityNote extends StatelessWidget {
  const _CommunityNote();

  /// El escudo va dentro del texto y no al lado: en una fila, al partirse la
  /// frase en dos renglones el texto se centra y el ícono queda solo contra
  /// el borde izquierdo.
  @override
  Widget build(BuildContext context) => Text.rich(
    TextSpan(
      children: [
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Padding(
            padding: EdgeInsets.only(right: 6),
            child: NexoIcon(
              NexoGlyph.moderation,
              size: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        TextSpan(
          text:
              'Publicación protegida bajo las directrices comunitarias de Nexo',
        ),
      ],
    ),
    textAlign: TextAlign.center,
    style: Theme.of(context).textTheme.bodySmall,
  );
}

/// El glifo de cada audiencia: lo descubre cualquiera, la gente que te sigue,
/// o los miembros (la corona es el vocabulario de membresías de la app).
extension _VisibilityGlyph on PostVisibility {
  NexoGlyph get glyph => switch (this) {
    PostVisibility.public => NexoGlyph.explore,
    PostVisibility.followers => NexoGlyph.community,
    PostVisibility.members => NexoGlyph.crown,
  };
}

/// Selector de visibilidad. Hoja de opciones en vez de menú: en teléfono un
/// PopupMenu aparece pegado al borde y no deja lugar para la descripción de
/// cada opción, que es lo que hace entendible la diferencia entre ellas.
class VisibilityPicker extends StatelessWidget {
  const VisibilityPicker({super.key, required this.visibility});

  final PostVisibility visibility;

  void _open(BuildContext context) {
    final cubit = context.read<PostComposerCubit>();
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (sheetContext) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xs,
              0,
              AppSpacing.xs,
              AppSpacing.sm,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.xs,
                    0,
                    AppSpacing.xs,
                    AppSpacing.sm,
                  ),
                  child: Text(
                    '¿Quién puede verlo?',
                    style: Theme.of(sheetContext).textTheme.headlineSmall,
                  ),
                ),
                for (final option in PostVisibility.values)
                  ListTile(
                    selected: option == visibility,
                    selectedTileColor: AppColors.linerHigh,
                    selectedColor: AppColors.textPrimary,
                    leading: NexoIcon(
                      option.glyph,
                      size: 22,
                      filled: option == visibility,
                      color: option == visibility
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                    title: Text(option.label),
                    subtitle: Text(option.detail),
                    trailing: _RadioMark(selected: option == visibility),
                    onTap: () {
                      cubit.setVisibility(option);
                      Navigator.pop(sheetContext);
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.linerHigh,
    shape: const StadiumBorder(),
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      key: const Key('composer-visibility'),
      onTap: () => _open(context),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 5, 8, 5),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            NexoIcon(
              visibility.glyph,
              size: 14,
              color: AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                visibility.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium,
              ),
            ),
            const SizedBox(width: 2),
            // El chevrón del set apunta hacia adelante; girado, dice "abre
            // opciones" sin traer un ícono de otra mano.
            RotatedBox(
              quarterTurns: 1,
              child: NexoIcon(
                NexoGlyph.forward,
                size: 14,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// La marca de opción elegida: un punto de tinta sobre un sticker blanco. En
/// reposo, sólo la línea de corte.
class _RadioMark extends StatelessWidget {
  const _RadioMark({required this.selected});

  final bool selected;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    duration: AppMotion.feedbackDuration,
    width: 22,
    height: 22,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: selected ? AppColors.sticker : Colors.transparent,
      border: Border.all(
        color: selected ? AppColors.sticker : AppColors.textTertiary,
        width: 2,
      ),
    ),
    child: selected
        ? Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: AppColors.ink,
              shape: BoxShape.circle,
            ),
          )
        : null,
  );
}

/// Pestañas Post / En vivo, como el par de filtros de la app: la elegida se
/// despega en blanco, la otra queda en la plancha.
class ComposerModeTabs extends StatelessWidget {
  const ComposerModeTabs({
    super.key,
    required this.mode,
    required this.onChanged,
  });

  final ComposerMode mode;
  final ValueChanged<ComposerMode> onChanged;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(4),
    decoration: BoxDecoration(
      color: AppColors.linerHigh,
      borderRadius: AppRadii.pill,
    ),
    // La tinta del toque se pinta en este Material y no en el del Scaffold,
    // que queda debajo del riel y la escondería.
    child: Material(
      type: MaterialType.transparency,
      child: Row(
        children: [
          for (final option in ComposerMode.values)
            Expanded(
              child: Semantics(
                selected: option == mode,
                child: InkWell(
                  key: Key('composer-mode-${option.name}'),
                  onTap: () => onChanged(option),
                  borderRadius: AppRadii.pill,
                  child: AnimatedContainer(
                    duration: AppMotion.feedbackDuration,
                    curve: Curves.easeOutCubic,
                    height: AppSizes.chipHeight,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: option == mode
                          ? AppColors.sticker
                          : Colors.transparent,
                      borderRadius: AppRadii.pill,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // El punto rojo es la marca de en vivo de toda la
                        // app; "Post" no necesita ícono para distinguirse.
                        if (option == ComposerMode.live)
                          Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.only(right: 7),
                            decoration: BoxDecoration(
                              color: AppColors.secondary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        Text(
                          option.label,
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: option == mode
                                    ? AppColors.ink
                                    : AppColors.textSecondary,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    ),
  );
}
