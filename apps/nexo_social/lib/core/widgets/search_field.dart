import 'package:flutter/material.dart';

import '../../app/theme/app_tokens.dart';

/// El buscador del design system: pill, lupa a la izquierda, sin marco.
///
/// El `inputDecorationTheme` ya pone la forma y el relleno; esto agrega la
/// lupa, el alto denso y —cuando no es interactivo— el gesto de toda la caja.
class SearchField extends StatelessWidget {
  const SearchField({
    super.key,
    required this.hint,
    this.controller,
    this.onChanged,
    this.onTap,
    this.readOnly = false,
    this.trailing,
  });

  final String hint;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;

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
      onChanged: onChanged,
      onTap: onTap,
      readOnly: readOnly,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: hint,
        isDense: true,
        prefixIcon: const Icon(
          Icons.search_rounded,
          size: 20,
          color: AppColors.textSecondary,
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 42),
        suffixIcon: trailing,
        contentPadding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      ),
    ),
  );
}
