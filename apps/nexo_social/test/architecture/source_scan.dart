import 'dart:io';

/// One Dart file of `lib/`, as text, for the architecture guards to inspect.
class SourceFile {
  SourceFile(this.path, this.contents);

  /// Relative to the package root, with forward slashes, e.g.
  /// `lib/features/feed/presentation/pages/feed_page.dart`.
  final String path;
  final String contents;

  bool get isDomain => _layer == 'domain';
  bool get isData => _layer == 'data';
  bool get isPresentation => _layer == 'presentation';

  late final String? _layer = () {
    String? layer;
    for (final segment in path.split('/')) {
      if (segment == 'domain' || segment == 'data' || segment == 'presentation') {
        layer = segment;
      }
    }
    return layer;
  }();

  /// Contents with `//` comments and doc comments stripped.
  ///
  /// Every guard matches against this: the comments explaining a rule
  /// inevitably quote the thing the rule forbids, and a guard that fails on
  /// its own documentation teaches people to delete the documentation.
  late final String code = contents
      .split('\n')
      .where((line) => !line.trimLeft().startsWith('//'))
      .join('\n');

  List<String> get lines => code.split('\n');
}

/// Reads `lib/` once. The guards are cheap, but the file system is not.
abstract final class SourceScan {
  static List<SourceFile>? _cache;

  static List<SourceFile> lib() => _cache ??= _read();

  static List<SourceFile> _read() {
    final root = Directory('lib');
    if (!root.existsSync()) {
      // `flutter test` runs from the package root. If that ever stops being
      // true these guards would silently scan nothing and pass — which is the
      // one failure mode a guard must not have.
      throw StateError(
        'No se encontró lib/. Los tests de arquitectura tienen que '
        'ejecutarse desde apps/nexo_social.',
      );
    }
    final files =
        root
            .listSync(recursive: true)
            .whereType<File>()
            .where((file) => file.path.endsWith('.dart'))
            .map(
              (file) => SourceFile(
                file.path.replaceAll(r'\', '/'),
                file.readAsStringSync(),
              ),
            )
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path));

    if (files.isEmpty) {
      throw StateError('lib/ no contiene archivos .dart.');
    }
    return files;
  }
}
