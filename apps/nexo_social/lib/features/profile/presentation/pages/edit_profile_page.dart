import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/di/injection.dart';
import '../../../../app/theme/app_tokens.dart';
import '../../../../core/widgets/app_state_views.dart';
import '../../../../core/widgets/nexo_icon.dart';
import '../../../../core/widgets/pills.dart';
import '../../../../core/widgets/sticker.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../../auth/presentation/bloc/auth_cubit.dart';
import '../../domain/entities/profile_changes.dart';
import '../bloc/edit_profile_cubit.dart';

/// "Editar perfil": banner, foto, nombre de usuario, nombre visible, bio,
/// enlace y el paso a creador. Al guardar vuelve con `true`, y quien la abrió relee el perfil.
class EditProfilePage extends StatelessWidget {
  const EditProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthCubit>().state;
    final username = auth is AuthAuthenticated ? auth.user.username : '';
    return BlocProvider(
      create: (_) => sl<EditProfileCubit>()..load(username),
      child: const _EditProfileView(),
    );
  }
}

class _EditProfileView extends StatelessWidget {
  const _EditProfileView();

  @override
  Widget build(BuildContext context) => MultiBlocListener(
    listeners: [
      BlocListener<EditProfileCubit, EditProfileState>(
        listenWhen: (previous, current) =>
            previous.status != current.status &&
            current.status == EditProfileStatus.saved,
        listener: (context, state) {
          // La sesión cambia de nombre, de foto o de rol: la barra, el
          // perfil y la guarda tienen que verlo sin cerrar sesión.
          unawaited(context.read<AuthCubit>().reload());
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Perfil actualizado.')));
          context.pop(true);
        },
      ),
      BlocListener<EditProfileCubit, EditProfileState>(
        // Sólo el paso a creador hecho acá, no la carga de alguien que ya
        // lo era.
        listenWhen: (previous, current) =>
            previous.status == EditProfileStatus.editing &&
            !previous.isCreator &&
            current.isCreator,
        listener: (context, state) {
          unawaited(context.read<AuthCubit>().reload());
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Listo: ya eres creador.')),
          );
        },
      ),
      BlocListener<EditProfileCubit, EditProfileState>(
        listenWhen: (previous, current) =>
            current.issue != null &&
            previous.issueSerial != current.issueSerial,
        listener: (context, state) => ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(state.issue!.message))),
      ),
    ],
    child: BlocBuilder<EditProfileCubit, EditProfileState>(
      builder: (context, state) {
        final cubit = context.read<EditProfileCubit>();
        final saving = state.status == EditProfileStatus.saving;
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            leading: IconButton(
              tooltip: MaterialLocalizations.of(context).backButtonTooltip,
              onPressed: () => unawaited(Navigator.of(context).maybePop()),
              icon: const NexoIcon(NexoGlyph.back),
            ),
            title: const Text('Editar perfil'),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                // El CTA es el sticker blanco del tema.
                child: FilledButton(
                  key: const Key('edit-profile-save'),
                  onPressed: state.canSave
                      ? () => unawaited(cubit.save())
                      : null,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(88, AppSizes.buttonHeightDense),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                    ),
                  ),
                  child: saving
                      // Guardando, el botón está deshabilitado (liner): la
                      // rueda va en el color del texto, no en tinta.
                      ? SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.textPrimary,
                          ),
                        )
                      : const Text('Guardar'),
                ),
              ),
            ],
          ),
          body: switch (state.status) {
            EditProfileStatus.loading => const Center(
              child: CircularProgressIndicator(),
            ),
            EditProfileStatus.loadFailed => Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: AppErrorView(
                  onRetry: () {
                    final auth = context.read<AuthCubit>().state;
                    if (auth is AuthAuthenticated) {
                      unawaited(cubit.load(auth.user.username));
                    }
                  },
                ),
              ),
            ),
            _ => Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: _Form(state: state),
              ),
            ),
          },
        );
      },
    ),
  );
}

/// Dueño de sus controllers: construirlos en `build` los recrea en cada
/// tecla, el cursor salta al principio y los descartados no se liberan.
class _Form extends StatefulWidget {
  const _Form({required this.state});

  final EditProfileState state;

  @override
  State<_Form> createState() => _FormState();
}

class _FormState extends State<_Form> {
  late final _username = TextEditingController(text: widget.state.username);
  late final _name = TextEditingController(text: widget.state.name);
  late final _bio = TextEditingController(text: widget.state.bio);
  late final _website = TextEditingController(text: widget.state.website);

  @override
  void dispose() {
    _username.dispose();
    _name.dispose();
    _bio.dispose();
    _website.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final cubit = context.read<EditProfileCubit>();
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.xl,
      ),
      children: [
        _CoverPicker(state: state),
        const SizedBox(height: AppSpacing.lg),
        Center(
          child: Semantics(
            button: true,
            label: state.hasAvatar ? 'Cambiar foto' : 'Elegir foto',
            child: GestureDetector(
              key: const Key('edit-profile-avatar'),
              onTap: () => unawaited(cubit.pickAvatar()),
              child: _AvatarPicker(state: state),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          spacing: AppSpacing.xs,
          alignment: WrapAlignment.center,
          children: [
            TextButton.icon(
              onPressed: () => unawaited(cubit.pickAvatar()),
              icon: const NexoIcon(NexoGlyph.media, size: 18),
              label: Text(state.hasAvatar ? 'Cambiar foto' : 'Elegir foto'),
            ),
            if (state.hasAvatar)
              TextButton(
                key: const Key('edit-profile-remove-avatar'),
                onPressed: cubit.removeAvatar,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                ),
                child: const Text('Quitar'),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        TextField(
          key: const Key('edit-profile-username'),
          controller: _username,
          onChanged: cubit.setUsername,
          autocorrect: false,
          decoration: InputDecoration(
            labelText: 'Nombre de usuario',
            prefixText: '@',
            errorText: state.usernameIssue?.message,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          key: const Key('edit-profile-name'),
          controller: _name,
          onChanged: cubit.setName,
          decoration: InputDecoration(
            labelText: 'Nombre visible',
            errorText: state.nameIssue?.message,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          key: const Key('edit-profile-bio'),
          controller: _bio,
          onChanged: cubit.setBio,
          minLines: 2,
          maxLines: 4,
          decoration: InputDecoration(
            labelText: 'Bio',
            helperText:
                '${_bio.text.trim().length}/${ProfileRules.bioMax} caracteres',
            errorText: state.bioIssue?.message,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        TextField(
          key: const Key('edit-profile-website'),
          controller: _website,
          onChanged: cubit.setWebsite,
          autocorrect: false,
          keyboardType: TextInputType.url,
          decoration: InputDecoration(
            labelText: 'Enlace',
            hintText: 'tusitio.com',
            prefixIcon: const Padding(
              padding: EdgeInsets.all(12),
              child: NexoIcon(NexoGlyph.link, size: 18),
            ),
            helperText: 'Tu web, portafolio o red. Se abre desde tu perfil.',
            errorText: state.websiteIssue?.message,
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        _CreatorCard(state: state),
      ],
    );
  }
}

/// El banner del perfil, ancho como en el encabezado: la foto nueva, la que
/// ya tiene o el vinilo de la cuenta, con sus acciones debajo.
class _CoverPicker extends StatelessWidget {
  const _CoverPicker({required this.state});

  final EditProfileState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<EditProfileCubit>();
    final picked = state.pickedCover;
    final current = state.removeCover ? null : state.coverUrl;
    final Widget image = picked != null
        ? Image.memory(
            picked.bytes,
            fit: BoxFit.cover,
            // Al ancho en que se ve: una foto de galería pesa decenas de MB
            // decodificada a resolución nativa.
            cacheWidth: 1200,
          )
        : current != null
        ? Image.network(
            current,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => ColoredBox(color: AppColors.linerHigh),
          )
        : ColoredBox(
            color: vinylFor(state.username),
            child: Center(
              child: NexoIcon(
                NexoGlyph.media,
                size: 28,
                color: AppColors.ink.withValues(alpha: .5),
              ),
            ),
          );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          button: true,
          label: state.hasCover ? 'Cambiar banner' : 'Elegir banner',
          child: GestureDetector(
            key: const Key('edit-profile-cover'),
            onTap: () => unawaited(cubit.pickCover()),
            child: ClipRRect(
              borderRadius: AppRadii.medium,
              child: AspectRatio(aspectRatio: 3, child: image),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Wrap(
          spacing: AppSpacing.xs,
          alignment: WrapAlignment.center,
          children: [
            TextButton.icon(
              onPressed: () => unawaited(cubit.pickCover()),
              icon: const NexoIcon(NexoGlyph.media, size: 18),
              label: Text(state.hasCover ? 'Cambiar banner' : 'Elegir banner'),
            ),
            if (state.hasCover)
              TextButton(
                key: const Key('edit-profile-remove-cover'),
                onPressed: cubit.removeCover,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                ),
                child: const Text('Quitar banner'),
              ),
          ],
        ),
      ],
    );
  }
}

/// La foto como el sticker grande del perfil, con un sticker chico de
/// cámara pegado en el borde que dice que se puede cambiar.
class _AvatarPicker extends StatelessWidget {
  const _AvatarPicker({required this.state});

  final EditProfileState state;

  static const _size = 112.0;

  @override
  Widget build(BuildContext context) {
    final picked = state.pickedAvatar;
    final avatar = picked != null
        // El mismo troquel blanco que `UserAvatar`: la foto recién elegida
        // ya se ve como va a quedar en el perfil.
        ? Container(
            width: _size,
            height: _size,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.sticker,
              shape: BoxShape.circle,
            ),
            child: ClipOval(
              child: Image.memory(
                picked.bytes,
                fit: BoxFit.cover,
                // Se decodifica al tamaño en que se ve: una foto de la
                // galería a resolución nativa pesa decenas de MB.
                cacheWidth: 336,
              ),
            ),
          )
        : UserAvatar(
            name: state.name.isEmpty ? '?' : state.name,
            imageUrl: state.removeAvatar ? null : state.avatarUrl,
            size: _size,
          );
    return Stack(
      clipBehavior: Clip.none,
      children: [
        avatar,
        Positioned(
          right: -2,
          bottom: -2,
          child: Container(
            width: 40,
            height: 40,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.sticker,
              shape: BoxShape.circle,
              // Un aro del liner lo separa del troquel del avatar: pegado,
              // se leería como parte del mismo borde.
              border: Border.all(color: AppColors.background, width: 3),
            ),
            child: NexoIcon(
              NexoGlyph.media,
              filled: true,
              size: 18,
              color: AppColors.ink,
            ),
          ),
        ),
      ],
    );
  }
}

/// Ser creador es autoservicio; verificar es del operador. La tarjeta lo
/// dice para que nadie espere poder transmitir apenas toca el botón.
class _CreatorCard extends StatelessWidget {
  const _CreatorCard({required this.state});

  final EditProfileState state;

  @override
  Widget build(BuildContext context) {
    if (state.isCreator) {
      final textTheme = Theme.of(context).textTheme;
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text('Eres creador', style: textTheme.titleLarge),
                  ),
                  StatusBadge(
                    label: 'Creador',
                    color: AppColors.vinylLime,
                    foreground: AppColors.ink,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Ya puedes programar shows. Para transmitir en vivo, el '
                'equipo de Nexo tiene que verificar tu cuenta.',
                style: textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }
    // Volverse creador es el objeto de la pantalla que invita a algo: el
    // sticker del logo, con el CTA en tinta.
    return StickerCard(
      child: Builder(
        // El tema se lee adentro de la tarjeta, que lo invierte a tinta.
        builder: (context) {
          final textTheme = Theme.of(context).textTheme;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Hazte creador', style: textTheme.titleLarge),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Publica como creador y programa shows. Para transmitir en '
                'vivo, el equipo de Nexo verifica tu cuenta.',
                style: textTheme.bodyMedium,
              ),
              const SizedBox(height: AppSpacing.md),
              FilledButton(
                key: const Key('edit-profile-become-creator'),
                onPressed: state.becomingCreator
                    ? null
                    : () => unawaited(
                        context.read<EditProfileCubit>().becomeCreator(),
                      ),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, AppSizes.buttonHeightDense),
                ),
                child: const Text('Ser creador'),
              ),
            ],
          );
        },
      ),
    );
  }
}

extension on ProfileFieldIssue {
  String get message => switch (this) {
    ProfileFieldIssue.usernameLength =>
      'Entre ${ProfileRules.usernameMin} y ${ProfileRules.usernameMax} '
          'caracteres.',
    ProfileFieldIssue.usernameCharacters =>
      'Solo minúsculas, números y guion bajo.',
    ProfileFieldIssue.usernameReserved =>
      'Ese nombre de usuario está reservado.',
    ProfileFieldIssue.nameMissing => 'Escribe cómo quieres que te vean.',
    ProfileFieldIssue.nameTooLong =>
      'Hasta ${ProfileRules.nameMax} caracteres.',
    ProfileFieldIssue.bioTooLong => 'Hasta ${ProfileRules.bioMax} caracteres.',
    ProfileFieldIssue.websiteTooLong =>
      'Hasta ${ProfileRules.websiteMax} caracteres.',
    ProfileFieldIssue.websiteInvalid =>
      'Escribe un enlace válido, como tusitio.com.',
  };
}

extension on EditProfileIssue {
  String get message => switch (this) {
    EditProfileIssue.usernameTaken => 'Ese nombre de usuario ya está en uso.',
    EditProfileIssue.rejected =>
      'No pudimos guardar los cambios. Revisa los datos e inténtalo de nuevo.',
    EditProfileIssue.network =>
      'Sin conexión. Tus cambios no se guardaron todavía.',
    EditProfileIssue.suspended =>
      'Tu cuenta está suspendida: no puede editar el perfil.',
    EditProfileIssue.avatarTooLarge => 'La foto supera los 5 MB.',
    EditProfileIssue.avatarType => 'Usa una foto JPG, PNG o WebP.',
    EditProfileIssue.coverTooLarge => 'El banner supera los 8 MB.',
    EditProfileIssue.coverType => 'Usa un banner JPG, PNG o WebP.',
    EditProfileIssue.other =>
      'No pudimos completar la acción. Inténtalo de nuevo.',
  };
}
