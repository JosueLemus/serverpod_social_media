import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/di/injection.dart';
import '../../../../app/theme/app_tokens.dart';
import '../bloc/post_composer_cubit.dart';

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
  final controller = TextEditingController();
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      BlocListener<PostComposerCubit, PostComposerState>(
        listener: (context, state) {
          if (state is PostComposerPublished) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Publicación creada en esta sesión'),
              ),
            );
            context.go('/');
          }
        },
        child: ListView(
          children: [
            Text(
              'Crear publicación',
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(height: AppSpacing.md),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  children: [
                    TextField(
                      key: const Key('create-post-field'),
                      controller: controller,
                      onChanged: context.read<PostComposerCubit>().change,
                      maxLength: 500,
                      maxLines: 6,
                      decoration: const InputDecoration(
                        hintText: '¿Qué quieres compartir con tu comunidad?',
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    BlocBuilder<PostComposerCubit, PostComposerState>(
                      builder: (context, state) {
                        final ready =
                            state is PostComposerIdle &&
                            state.text.trim().isNotEmpty;
                        return Align(
                          alignment: Alignment.centerRight,
                          child: FilledButton(
                            key: const Key('publish-button'),
                            onPressed: ready
                                ? context.read<PostComposerCubit>().publish
                                : null,
                            child: const Text('Publicar'),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
}
