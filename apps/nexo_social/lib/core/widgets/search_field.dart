import 'package:flutter/material.dart';

import '../../app/theme/app_tokens.dart';
import 'nexo_icon.dart';

/// El buscador: pastilla sobre el liner, lupa propia a la izquierda, sin
/// marco.
///
/// El `inputDecorationTheme` ya pone la forma y el relleno; esto agrega la
/// lupa, el alto denso y —cuando no es interactivo— el gesto de toda la caja.
class SearchField extends StatelessWidget {
  const SearchField({
    super.key,
    required this.hint,
    this.controller,
    this.focusNode,
    this.onChanged,
    this.onSubmitted,
    this.onTap,
    this.readOnly = false,
    this.trailing,
  });

  final String hint;
  final TextEditingController? controller;

  /// Lo pasa la pantalla dueña del campo: para enfocarlo desde afuera (el CTA
  /// del feed vacío lleva al buscador) y para que el foco, y el teclado, no
  /// dependa de que el `TextField` sobreviva a cada rebuild.
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;

  /// La tecla de buscar del teclado: buscar ya, sin esperar el debounce.
  final ValueChanged<String>? onSubmitted;

  /// Con [readOnly] en true el campo no abre teclado y el tap sale por acá —
  /// la forma de usarlo como acceso a una pantalla de búsqueda propia.
  final VoidCallback? onTap;
  final bool readOnly;

  final Widget? trailing;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: AppSizes.searchHeight,
    child: TextField(
      controller: controller,
      focusNode: focusNode,
      onChanged: onChanged,
      onSubmitted: onSubmitted,
      onTap: onTap,
      readOnly: readOnly,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: hint,
        isDense: true,
        prefixIcon: Center(
          widthFactor: 1,
          child: NexoIcon(
            NexoGlyph.search,
            size: 19,
            color: AppColors.textSecondary,
          ),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 42),
        suffixIcon: trailing,
        contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      ),
    ),
  );
}
