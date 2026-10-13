import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/repositories/theme_preference_repository.dart';

class ThemeState extends Equatable {
  const ThemeState(this.themeId);

  /// El id del catálogo (`NexoThemes`). El cubit no conoce las paletas: son
  /// presentación, y quien las resuelve es la raíz de la app.
  final String themeId;

  @override
  List<Object?> get props => [themeId];
}

/// El tema elegido. Singleton, como la sesión: la raíz lo escucha para
/// redibujar la app entera, y la pantalla de Temas lo cambia.
class ThemeCubit extends Cubit<ThemeState> {
  ThemeCubit(this._preferences, {required String defaultId})
    : super(ThemeState(_preferences.read() ?? defaultId));

  final ThemePreferenceRepository _preferences;

  void select(String themeId) {
    if (themeId == state.themeId) return;
    emit(ThemeState(themeId));
    // Si no se pudo guardar, el tema igual queda aplicado en esta sesión: no
    // hay nada que el usuario pueda hacer distinto, así que no se le avisa.
    unawaited(_preferences.write(themeId));
  }
}
