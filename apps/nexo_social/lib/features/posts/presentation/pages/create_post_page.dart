import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/theme/app_tokens.dart';
import '../../../../core/animations/app_motion.dart';
import '../../../../core/widgets/user_avatar.dart';
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
          // devolverlo a donde salió.
          context.pop();
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
                      onChanged: cubit.setMode,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _AuthorRow(visibility: state.visibility),
                    const SizedBox(height: AppSpacing.xs),
                    _Editor(
                      controller: _controller,
                      state: state,
                      onChanged: cubit.change,
                    ),
                    if (state.attachment != null) ...[
                      const SizedBox(height: AppSpacing.sm),
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
                    const SizedBox(height: AppSpacing.sm),
                    ComposerAttachments(
                      onAttach: cubit.attach,
                      onPoll: cubit.togglePoll,
                      pollActive: state.poll != null,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const Enter(child: ComposerAiTeaser()),
                    const SizedBox(height: AppSpacing.md),
                    ComposerToggles(
                      allowComments: state.allowComments,
                      notifyVip: state.notifyVip,
                      onAllowComments: (value) =>
                          cubit.setAllowComments(value: value),
                      onNotifyVip: (value) => cubit.setNotifyVip(value: value),
                    ),
                    const SizedBox(height: AppSpacing.md),
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

  @override
  Widget build(BuildContext context) =>
      BlocBuilder<PostComposerCubit, PostComposerState>(
        builder: (context, state) {
          final draft = state is PostComposerIdle ? state : null;
          return LayoutBuilder(
            builder: (context, constraints) {
              final showStatus =
                  constraints.maxWidth.isFinite &&
                  constraints.maxWidth >= _statusMinWidth;
              return Row(
                children: [
                  SizedBox(
                    height: 36,
                    child: TextButton(
                      key: const Key('composer-close'),
                      onPressed: context.pop,
                      style: TextButton.styleFrom(
                        backgroundColor: AppColors.primarySurface,
                        minimumSize: const Size(0, 36),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                        ),
                      ),
                      child: const Text('Cancelar'),
                    ),
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
                    )
                  else
                    const Spacer(),
                  SizedBox(
                    height: 36,
                    child: FilledButton.icon(
                      key: const Key('publish-button'),
                      // Deshabilitado por estado, no por un bool local: el
                      // cubit es lo único que sabe si el borrador es
                      // publicable.
                      onPressed: draft != null && draft.canPublish
                          ? context.read<PostComposerCubit>().publish
                          : null,
                      iconAlignment: IconAlignment.end,
                      icon: draft?.isPublishing ?? false
                          ? const SizedBox.square(
                              dimension: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send_rounded, size: 15),
                      label: Text(
                        draft?.isPublishing ?? false
                            ? 'Publicando…'
                            : 'Publicar',
                      ),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 36),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                        ),
                        textStyle: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      );
}

class _AuthorRow extends StatelessWidget {
  const _AuthorRow({required this.visibility});

  final PostVisibility visibility;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      const UserAvatar(name: 'Elena Vega', size: 42),
      const SizedBox(width: AppSpacing.sm),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  'Elena Vega',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.verified_rounded,
                  size: 14,
                  color: AppColors.primary,
                ),
              ],
            ),
            const SizedBox(height: 3),
            VisibilityPicker(visibility: visibility),
          ],
        ),
      ),
    ],
  );
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

  @override
  Widget build(BuildContext context) {
    final over = state.length > PostComposerCubit.maxLength;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            filled: false,
            contentPadding: EdgeInsets.zero,
          ),
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.45),
        ),
        Row(
          children: [
            IconButton(
              tooltip: 'Añadir hashtag',
              visualDensity: VisualDensity.compact,
              onPressed: () {},
              icon: const Icon(Icons.tag_rounded, size: 19),
            ),
            IconButton(
              tooltip: 'Mencionar a alguien',
              visualDensity: VisualDensity.compact,
              onPressed: () {},
              icon: const Icon(Icons.alternate_email_rounded, size: 19),
            ),
            const Spacer(),
            Text(
              '${state.length}/${PostComposerCubit.maxLength}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: over ? AppColors.error : AppColors.textSecondary,
                fontWeight: over ? FontWeight.w700 : FontWeight.w400,
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

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const Icon(
        Icons.shield_outlined,
        size: 13,
        color: AppColors.textSecondary,
      ),
      const SizedBox(width: 5),
      Flexible(
        child: Text(
          'Publicación protegida bajo las directrices comunitarias de Nexo',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ),
    ],
  );
}

/// Selector de visibilidad. Hoja de opciones en vez de menú: en teléfono un
/// PopupMenu aparece pegado al borde y no deja lugar para la descripción de
/// cada opción, que es lo que hace entendible la diferencia entre ellas.
class VisibilityPicker extends StatelessWidget {
  const VisibilityPicker({super.key, required this.visibility});

  final PostVisibility visibility;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<PostComposerCubit>();
    return InkWell(
      key: const Key('composer-visibility'),
      borderRadius: AppRadii.pill,
      onTap: () => showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (sheetContext) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final option in PostVisibility.values)
                ListTile(
                  leading: Icon(
                    option == visibility
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: option == visibility
                        ? AppColors.primaryDeep
                        : AppColors.textSecondary,
                  ),
                  title: Text(option.label),
                  subtitle: Text(option.detail),
                  onTap: () {
                    cubit.setVisibility(option);
                    Navigator.pop(sheetContext);
                  },
                ),
            ],
          ),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: 3,
        ),
        decoration: const BoxDecoration(
          color: AppColors.primarySurface,
          borderRadius: AppRadii.pill,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.public_rounded,
              size: 13,
              color: AppColors.textOnBrandSurface,
            ),
            const SizedBox(width: 4),
            Text(
              visibility.label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textOnBrandSurface,
              ),
            ),
            const Icon(
              Icons.expand_more_rounded,
              size: 15,
              color: AppColors.textOnBrandSurface,
            ),
          ],
        ),
      ),
    );
  }
}

/// Pestañas Post / En vivo.
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
    decoration: const BoxDecoration(
      color: AppColors.primarySurface,
      borderRadius: AppRadii.pill,
    ),
    child: Row(
      children: [
        for (final option in ComposerMode.values)
          Expanded(
            child: InkWell(
              key: Key('composer-mode-${option.name}'),
              onTap: () => onChanged(option),
              borderRadius: AppRadii.pill,
              child: AnimatedContainer(
                duration: AppMotion.feedbackDuration,
                height: 38,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: option == mode
                      ? AppColors.surface
                      : Colors.transparent,
                  borderRadius: AppRadii.pill,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (option == ComposerMode.live)
                      Container(
                        width: 7,
                        height: 7,
                        margin: const EdgeInsets.only(right: 6),
                        decoration: const BoxDecoration(
                          color: AppColors.secondary,
                          shape: BoxShape.circle,
                        ),
                      )
                    else
                      const Padding(
                        padding: EdgeInsets.only(right: 5),
                        child: Icon(Icons.edit_note_rounded, size: 17),
                      ),
                    Text(
                      option.label,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: option == mode
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    ),
  );
}
