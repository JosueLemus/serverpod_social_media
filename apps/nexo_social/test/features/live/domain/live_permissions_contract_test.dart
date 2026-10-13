import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// La tabla de permisos de la app es un **espejo** de la del servidor
/// (SDD 0011, S9). Dos tablas escritas a mano se separan, y el síntoma no es
/// un error: es un botón que la app ofrece y el servidor rechaza, o una acción
/// legal que la app esconde. Este test lee los dos fuentes y compara los
/// bloques entre marcas.
const _app = 'lib/features/live/domain/entities/live_permissions.dart';
const _server =
    '../../services/serverpod/nexo_server/lib/src/modules/live/services/'
    'live_permissions.dart';

/// `acción -> {roles}` del bloque `permisos`, con el rol del contrato.
Map<String, Set<String>> _allowed(String source) {
  final block = _between(source, 'permisos');
  return {
    for (final m in RegExp(
      r'LiveAction\.(\w+):\s*\{([^}]*)\}',
    ).allMatches(block))
      m.group(1)!: {
        for (final r in RegExp(r'\.(\w+)').allMatches(m.group(2)!)) r.group(1)!,
      },
  };
}

Set<String> _targeted(String source) => {
  for (final m in RegExp(
    r'LiveAction\.(\w+)',
  ).allMatches(_between(source, 'rango')))
    m.group(1)!,
};

/// La lista del enum `LiveAction`, en orden.
List<String> _actions(String source) {
  final body = RegExp(
    r'enum LiveAction \{([^}]*)\}',
  ).firstMatch(source)!.group(1)!;
  return [
    for (final line in body.split('\n'))
      if (RegExp(r'^\s*(\w+),\s*$').firstMatch(line) case final m?) m.group(1)!,
  ];
}

String _between(String source, String marker) {
  final start = source.indexOf('// $marker:inicio');
  final end = source.indexOf('// $marker:fin');
  expect(start, isNonNegative, reason: 'falta la marca $marker:inicio');
  expect(end, greaterThan(start), reason: 'falta la marca $marker:fin');
  return source.substring(start, end);
}

void main() {
  final app = File(_app).readAsStringSync();
  final server = File(_server).readAsStringSync();

  test('las dos tablas tienen las mismas acciones', () {
    expect(_actions(app), _actions(server));
  });

  test('quién puede hacer cada acción es lo mismo en los dos lados', () {
    final a = _allowed(app), s = _allowed(server);
    // Sin esto, un parser que no encuentra nada compararía dos vacíos.
    expect(s, hasLength(_actions(server).length));
    expect(a, s);
  });

  test('las acciones sobre otra persona son las mismas', () {
    final s = _targeted(server);
    expect(s, isNotEmpty);
    expect(_targeted(app), s);
  });
}
