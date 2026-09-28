// Genera un mapa navegable de la API (estilo Swagger) a partir del código que
// ya produce Serverpod: el cliente generado, los endpoints del servidor y los
// modelos `.spy.yaml`. No hay nada que mantener a mano: cada endpoint nuevo
// aparece solo al regenerar.
//
// Uso (desde services/serverpod): dart run tool/api_map.dart [salida.html]
import 'dart:convert';
import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:yaml/yaml.dart';

final root = File.fromUri(Platform.script).parent.parent.path;
const defaultOut = 'nexo_client/doc/api/map/index.html';

void main(List<String> args) {
  final endpoints = _readClientEndpoints();
  final serverInfo = _readServerEndpoints();
  final models = _readModels();
  final baseUrl = _readBaseUrl();

  for (final e in endpoints) {
    final info = serverInfo[e.name];
    e.module = info?.module ?? 'otros';
    e.requireLogin = info?.requireLogin ?? false;
    e.scopes = info?.scopes ?? const [];
  }

  final out = File('$root/${args.isNotEmpty ? args.first : defaultOut}');
  out.parent.createSync(recursive: true);
  out.writeAsStringSync(_render(endpoints, models, baseUrl));
  stdout.writeln('Mapa de la API: ${out.path}');
}

// ---------------------------------------------------------------------------
// Lectura
// ---------------------------------------------------------------------------

class Param {
  Param(this.name, this.type, this.required);
  final String name;
  final String type;
  final bool required;
}

class Method {
  Method(
    this.name,
    this.returnType,
    this.params,
    this.doc,
    this.streaming,
    this.sendsAuth,
  );
  final String name;
  final String returnType;
  final List<Param> params;
  final String doc;
  final bool streaming;
  final bool sendsAuth;
}

class Endpoint {
  Endpoint(this.name, this.className, this.doc, this.methods);
  final String name;
  final String className;
  final String doc;
  final List<Method> methods;
  String module = 'otros';
  bool requireLogin = false;
  List<String> scopes = const [];
}

class ServerInfo {
  ServerInfo(this.module, this.requireLogin, this.scopes);
  final String module;
  final bool requireLogin;
  final List<String> scopes;
}

class Field {
  Field(this.name, this.type, this.doc);
  final String name;
  final String type;
  final String doc;
}

class Model {
  Model(this.kind, this.name, this.module, this.doc, this.fields);
  final String kind; // class | exception | enum
  final String name;
  final String module;
  final String doc;
  final List<Field> fields; // en un enum, `type` va vacío
}

/// Endpoints tal como los ve la app: clases `Endpoint*` del cliente generado.
List<Endpoint> _readClientEndpoints() {
  final path = '$root/nexo_client/lib/src/protocol/client.dart';
  final unit = parseString(
    content: File(path).readAsStringSync(),
    throwIfDiagnostics: false,
  ).unit;

  final result = <Endpoint>[];
  for (final cls in unit.declarations.whereType<ClassDeclaration>()) {
    final className = cls.namePart.typeName.lexeme;
    if (!className.startsWith('Endpoint')) continue;

    String? name;
    final methods = <Method>[];
    for (final m in cls.body.members.whereType<MethodDeclaration>()) {
      if (m.isGetter) {
        final body = m.body;
        if (m.name.lexeme == 'name' &&
            body is ExpressionFunctionBody &&
            body.expression is SimpleStringLiteral) {
          name = (body.expression as SimpleStringLiteral).value;
        }
        continue;
      }
      if (m.isSetter || m.isStatic || m.name.lexeme.startsWith('_')) continue;

      final bodySrc = m.body.toSource();
      methods.add(
        Method(
          m.name.lexeme,
          _cleanType(m.returnType?.toSource() ?? 'void'),
          [
            for (final p in m.parameters?.parameters ?? <FormalParameter>[])
              Param(
                p.name?.lexeme ?? '',
                _cleanType(p.type?.toSource() ?? 'dynamic'),
                p.isRequired,
              ),
          ],
          _docText(m.documentationComment),
          bodySrc.contains('callStreamingServerEndpoint'),
          !bodySrc.contains('authenticated: false'),
        ),
      );
    }
    if (name == null) continue;
    result.add(
      Endpoint(name, className, _docText(cls.documentationComment), methods),
    );
  }
  return result;
}

/// Módulo y requisitos de acceso de cada endpoint, leídos del servidor.
Map<String, ServerInfo> _readServerEndpoints() {
  final classRe = RegExp(r'class\s+(\w+)Endpoint\s+extends');
  final scopesRe = RegExp(r'requiredScopes\s*=>\s*\{([^}]*)\}');
  final result = <String, ServerInfo>{};

  for (final file in _serverSources('.dart')) {
    final src = file.readAsStringSync();
    final requireLogin = RegExp(r'requireLogin\s*=>\s*true').hasMatch(src);
    final scopes = [
      for (final m in scopesRe.allMatches(src))
        ...m
            .group(1)!
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty),
    ];
    for (final m in classRe.allMatches(src)) {
      final base = m.group(1)!;
      final name = base[0].toLowerCase() + base.substring(1);
      result[name] = ServerInfo(_moduleOf(file.path), requireLogin, scopes);
    }
  }
  return result;
}

/// Modelos `.spy.yaml` que llegan al cliente (se omiten los `serverOnly`).
List<Model> _readModels() {
  final result = <Model>[];
  for (final file in _serverSources('.spy.yaml')) {
    final text = file.readAsStringSync();
    final yaml = loadYaml(text);
    if (yaml is! YamlMap || yaml['serverOnly'] == true) continue;

    final kind = [
      'class',
      'exception',
      'enum',
    ].firstWhere((k) => yaml.containsKey(k), orElse: () => '');
    if (kind.isEmpty) continue;

    final docs = _yamlDocs(text);
    final fields = <Field>[];
    if (kind == 'enum') {
      for (final v in (yaml['values'] as YamlList? ?? YamlList())) {
        final name = v is YamlMap ? v.keys.first.toString() : v.toString();
        fields.add(Field(name, '', docs[name] ?? ''));
      }
    } else {
      final map = yaml['fields'] as YamlMap? ?? YamlMap();
      for (final entry in map.entries) {
        final parts = _splitTopLevel(entry.value.toString());
        if (parts
            .skip(1)
            .any((p) => p.replaceAll(' ', '') == 'scope=serverOnly')) {
          continue;
        }
        final name = entry.key.toString();
        fields.add(Field(name, parts.first, docs[name] ?? ''));
      }
    }
    result.add(
      Model(
        kind,
        yaml[kind].toString(),
        _moduleOf(file.path),
        docs[''] ?? '',
        fields,
      ),
    );
  }
  result.sort((a, b) => a.name.compareTo(b.name));
  return result;
}

String _readBaseUrl() {
  try {
    final config = loadYaml(
      File('$root/nexo_server/config/development.yaml').readAsStringSync(),
    )['apiServer'];
    return '${config['publicScheme']}://${config['publicHost']}:${config['publicPort']}';
  } catch (_) {
    return 'http://localhost:8080';
  }
}

Iterable<File> _serverSources(String suffix) =>
    Directory('$root/nexo_server/lib/src')
        .listSync(recursive: true)
        .whereType<File>()
        .where(
          (f) => f.path.endsWith(suffix) && !f.path.contains('/generated/'),
        );

/// `lib/src/modules/<modulo>/...` → modulo; `lib/src/<carpeta>/...` → carpeta.
String _moduleOf(String path) {
  final parts = path.split('/lib/src/').last.split('/');
  if (parts.first == 'modules' && parts.length > 2) return parts[1];
  return parts.length > 1 ? parts.first : 'otros';
}

/// Comentarios `###` del `.spy.yaml`: los del principio documentan el modelo
/// (clave ''), los que preceden a una clave documentan ese campo o valor.
Map<String, String> _yamlDocs(String text) {
  final docs = <String, String>{};
  final pending = <String>[];
  var seenTop = false;
  for (final line in const LineSplitter().convert(text)) {
    final t = line.trim();
    if (t.startsWith('###')) {
      pending.add(t.substring(3).trim());
      continue;
    }
    final key = RegExp(r'^(?:-\s*)?(\w+)\s*:?').firstMatch(t)?.group(1);
    if (pending.isNotEmpty && key != null) {
      docs[seenTop ? key : ''] = pending.join('\n');
    }
    if (t.isNotEmpty) seenTop = true;
    pending.clear();
  }
  return docs;
}

/// Separa por comas que no estén dentro de `<...>` (p. ej. `Map<String, int>`).
List<String> _splitTopLevel(String s) {
  final parts = <String>[];
  var depth = 0, start = 0;
  for (var i = 0; i < s.length; i++) {
    if (s[i] == '<') depth++;
    if (s[i] == '>') depth--;
    if (s[i] == ',' && depth == 0) {
      parts.add(s.substring(start, i).trim());
      start = i + 1;
    }
  }
  parts.add(s.substring(start).trim());
  return parts;
}

/// Quita los prefijos de import del código generado (`_ida.Future` → `Future`).
String _cleanType(String t) => t.replaceAll(RegExp(r'\b_\w+\.'), '');

String _docText(Comment? c) {
  if (c == null) return '';
  return c.tokens
      .map((t) => t.lexeme.replaceFirst(RegExp(r'^///\s?'), ''))
      .where((l) => !l.trim().startsWith('{@category'))
      .join('\n')
      .trim();
}

// ---------------------------------------------------------------------------
// HTML
// ---------------------------------------------------------------------------

final _esc = const HtmlEscape();

String _render(List<Endpoint> endpoints, List<Model> models, String baseUrl) {
  final modelNames = {for (final m in models) m.name};
  final modules = <String, List<Endpoint>>{};
  for (final e in endpoints) {
    modules.putIfAbsent(e.module, () => []).add(e);
  }
  final order = modules.keys.toList()..sort();

  final nav = StringBuffer();
  final main = StringBuffer();

  for (final module in order) {
    nav.writeln('<li class="nav-module">${_esc.convert(module)}<ul>');
    main.writeln(
      '<section class="module" id="mod-$module">'
      '<h2>${_esc.convert(module)}</h2>',
    );
    for (final e in modules[module]!) {
      nav.writeln('<li><a href="#ep-${e.name}">/${e.name}</a></li>');
      main.writeln(_renderEndpoint(e, modelNames, baseUrl));
    }
    nav.writeln('</ul></li>');
    main.writeln('</section>');
  }

  if (models.isNotEmpty) {
    nav.writeln('<li class="nav-module">Modelos<ul>');
    main.writeln('<section class="module" id="models"><h2>Modelos</h2>');
    for (final m in models) {
      nav.writeln('<li><a href="#model-${m.name}">${m.name}</a></li>');
      main.writeln(_renderModel(m, modelNames));
    }
    nav.writeln('</ul></li>');
    main.writeln('</section>');
  }

  final total = endpoints.fold<int>(0, (n, e) => n + e.methods.length);
  return _page
      .replaceFirst('{{nav}}', nav.toString())
      .replaceFirst('{{main}}', main.toString())
      .replaceFirst(
        '{{summary}}',
        '${endpoints.length} endpoints · $total métodos · ${models.length} modelos · '
            'base <code>${_esc.convert(baseUrl)}</code>',
      );
}

String _renderEndpoint(Endpoint e, Set<String> models, String baseUrl) {
  final b = StringBuffer()
    ..writeln('<article class="endpoint" id="ep-${e.name}">')
    ..writeln(
      '<header><h3>/${e.name}</h3>'
      '<a class="ref" href="../nexo_client/${e.className}-class.html">'
      'client.${e.name} · ${e.className}</a></header>',
    );
  if (e.requireLogin || e.scopes.isNotEmpty) {
    b.write('<p class="access">');
    if (e.requireLogin) b.write('<span class="tag auth">requiere login</span>');
    for (final s in e.scopes) {
      b.write('<span class="tag scope">${_esc.convert(s)}</span>');
    }
    b.writeln('</p>');
  }
  if (e.doc.isNotEmpty) b.writeln('<div class="doc">${_md(e.doc)}</div>');

  for (final m in e.methods) {
    final verb = m.streaming ? 'WS' : 'POST';
    final path = '/${e.name}/${m.name}';
    final summary = m.doc.split(RegExp(r'\n\s*\n|(?<=\.)\s')).first;
    final returns = _unwrap(m.returnType);
    b
      ..writeln(
        '<details class="op" data-search="${_esc.convert('$path ${e.module} ${m.doc}'.toLowerCase())}">',
      )
      ..writeln(
        '<summary><span class="verb ${verb.toLowerCase()}">$verb</span>'
        '<code class="path">$path</code>'
        '${m.sendsAuth ? '' : '<span class="tag public">sin token</span>'}'
        '<span class="sum">${_esc.convert(summary)}</span></summary>',
      )
      ..writeln('<div class="op-body">');
    if (m.doc.isNotEmpty) b.writeln('<div class="doc">${_md(m.doc)}</div>');

    b.writeln('<h4>Parámetros</h4>');
    if (m.params.isEmpty) {
      b.writeln('<p class="muted">Ninguno.</p>');
    } else {
      b.writeln('<table><tr><th>Nombre</th><th>Tipo</th><th></th></tr>');
      for (final p in m.params) {
        b.writeln(
          '<tr><td><code>${p.name}</code></td>'
          '<td>${_typeHtml(p.type, models)}</td>'
          '<td>${p.required ? '<span class="req">requerido</span>' : 'opcional'}</td></tr>',
        );
      }
      b.writeln('</table>');
    }

    b
      ..writeln('<h4>Respuesta</h4>')
      ..writeln(
        '<p>${m.streaming ? 'Stream de ' : ''}${_typeHtml(returns, models)}</p>',
      )
      ..writeln('<h4>Dart</h4>')
      ..writeln('<pre>${_esc.convert(_dartCall(e.name, m))}</pre>');
    if (!m.streaming) {
      b
        ..writeln('<h4>HTTP</h4>')
        ..writeln('<pre>${_esc.convert(_curl(baseUrl, path, m))}</pre>');
    }
    b
      ..writeln(
        '<a class="ref" href="../nexo_client/${e.className}/${m.name}.html">Ver en la referencia Dart</a>',
      )
      ..writeln('</div></details>');
  }
  b.writeln('</article>');
  return b.toString();
}

String _renderModel(Model m, Set<String> models) {
  final page = m.kind == 'enum' ? '${m.name}.html' : '${m.name}-class.html';
  final b = StringBuffer()
    ..writeln('<article class="model" id="model-${m.name}">')
    ..writeln(
      '<header><h3>${m.name} <span class="kind">${m.kind}</span></h3>'
      '<a class="ref" href="../nexo_client/$page">${_esc.convert(m.module)}</a></header>',
    );
  if (m.doc.isNotEmpty) b.writeln('<div class="doc">${_md(m.doc)}</div>');
  b.writeln('<table>');
  for (final f in m.fields) {
    b.writeln(
      '<tr><td><code>${f.name}</code></td>'
      '${m.kind == 'enum' ? '' : '<td>${_typeHtml(f.type, models)}</td>'}'
      '<td class="muted">${_esc.convert(f.doc)}</td></tr>',
    );
  }
  b.writeln('</table></article>');
  return b.toString();
}

/// `Future<X>` / `Stream<X>` → `X`.
String _unwrap(String t) {
  final m = RegExp(r'^(?:Future|Stream)<(.*)>$').firstMatch(t);
  return m?.group(1) ?? t;
}

/// Tipo con enlaces a los modelos propios.
String _typeHtml(String type, Set<String> models) {
  final escaped = _esc.convert(type);
  return '<code>${escaped.replaceAllMapped(RegExp(r'\b[A-Z]\w*\b'), (m) {
    final name = m.group(0)!;
    return models.contains(name) ? '<a href="#model-$name">$name</a>' : name;
  })}</code>';
}

String _dartCall(String endpoint, Method m) {
  final named = m.params.map(
    (p) => '${p.name}: ${_sample(p.type, dart: true)}',
  );
  final args = named.isEmpty ? '' : '\n  ${named.join(',\n  ')},\n';
  final ret = _unwrap(m.returnType);
  final call = 'client.$endpoint.${m.name}($args)';
  if (m.streaming) return '$call.listen((event) { ... });';
  return ret == 'void' ? 'await $call;' : 'final result = await $call;';
}

String _curl(String baseUrl, String path, Method m) {
  final body = {for (final p in m.params) p.name: _sample(p.type)};
  final auth = m.sendsAuth ? "  -H 'Authorization: Bearer <token>' \\\n" : '';
  return "curl -X POST $baseUrl$path \\\n"
      "  -H 'Content-Type: application/json' \\\n"
      "$auth  -d '${jsonEncode(body)}'";
}

/// Valor de ejemplo para un tipo, para los fragmentos de Dart y HTTP.
dynamic _sample(String type, {bool dart = false}) {
  final t = type.replaceAll('?', '');
  switch (t) {
    case 'String':
      return dart ? "'...'" : '...';
    case 'int':
      return 0;
    case 'double':
      return 0.0;
    case 'bool':
      return false;
    case 'DateTime':
      return dart ? 'DateTime.now()' : '2026-01-01T00:00:00.000Z';
    case 'UuidValue':
      return dart
          ? "UuidValue.fromString('...')"
          : '00000000-0000-0000-0000-000000000000';
  }
  if (t.startsWith('List<')) return dart ? '[]' : [];
  if (t.startsWith('Map<')) return dart ? '{}' : {};
  return dart ? '$t(...)' : {};
}

/// Markdown mínimo de los comentarios `///`: párrafos, listas, `código` y [Ref].
String _md(String text) {
  String inline(String s) => _esc
      .convert(s)
      .replaceAllMapped(RegExp(r'`([^`]+)`'), (m) => '<code>${m[1]}</code>')
      .replaceAllMapped(RegExp(r'\[([\w.]+)\]'), (m) => '<code>${m[1]}</code>');

  final out = StringBuffer();
  for (final block in text.split(RegExp(r'\n\s*\n'))) {
    final lines = block.split('\n');
    final items = <String>[];
    final para = <String>[];
    for (final line in lines) {
      final t = line.trim();
      if (RegExp(r'^-\s?').hasMatch(t)) {
        items.add(t.replaceFirst(RegExp(r'^-\s?'), ''));
      } else if (items.isNotEmpty && t.isNotEmpty) {
        items[items.length - 1] += ' $t';
      } else if (t.isNotEmpty) {
        para.add(t);
      }
    }
    if (para.isNotEmpty) out.write('<p>${inline(para.join(' '))}</p>');
    if (items.isNotEmpty) {
      out.write('<ul>${items.map((i) => '<li>${inline(i)}</li>').join()}</ul>');
    }
  }
  return out.toString();
}

const _page = r'''<!doctype html>
<html lang="es">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Nexo API Map</title>
<style>
:root {
  --bg: #f7f7f8; --panel: #fff; --text: #1d1d22; --muted: #6b6b76;
  --border: #e3e3e8; --accent: #3b5bdb; --code: #f0f0f4;
  --post: #2b8a3e; --ws: #7048e8; --warn: #c2410c;
}
@media (prefers-color-scheme: dark) {
  :root:not([data-theme="light"]) {
    --bg: #131316; --panel: #1c1c21; --text: #e8e8ee; --muted: #9a9aa6;
    --border: #2e2e36; --accent: #8ea4ff; --code: #26262d;
    --post: #51cf66; --ws: #b197fc; --warn: #fb923c;
  }
}
* { box-sizing: border-box; }
body { margin: 0; background: var(--bg); color: var(--text);
  font: 15px/1.5 system-ui, -apple-system, "Segoe UI", sans-serif; }
code, pre { font-family: ui-monospace, "SF Mono", Menlo, monospace; font-size: 13px; }
code { background: var(--code); padding: 1px 5px; border-radius: 4px; }
pre { background: var(--code); padding: 12px; border-radius: 6px; overflow-x: auto; margin: 0; }
a { color: var(--accent); text-decoration: none; }
a:hover { text-decoration: underline; }
.layout { display: grid; grid-template-columns: 240px 1fr; min-height: 100vh; }
nav { position: sticky; top: 0; height: 100vh; overflow-y: auto; padding: 20px 16px;
  border-right: 1px solid var(--border); background: var(--panel); }
nav h1 { font-size: 17px; margin: 0 0 4px; }
nav ul { list-style: none; padding: 0; margin: 0; }
.nav-module { margin-top: 16px; font-size: 12px; font-weight: 600; text-transform: uppercase;
  letter-spacing: .04em; color: var(--muted); }
.nav-module ul { margin-top: 4px; text-transform: none; letter-spacing: 0; font-weight: 400; font-size: 14px; }
.nav-module li li { padding: 2px 0; }
main { padding: 24px 32px 64px; max-width: 1000px; min-width: 0; }
.top { display: flex; flex-wrap: wrap; gap: 12px; align-items: center; justify-content: space-between; margin-bottom: 8px; }
.summary { color: var(--muted); font-size: 14px; }
#q { padding: 8px 12px; border: 1px solid var(--border); border-radius: 6px; background: var(--panel);
  color: var(--text); font: inherit; width: 260px; max-width: 100%; }
.module h2 { font-size: 22px; text-transform: capitalize; border-bottom: 1px solid var(--border);
  padding-bottom: 6px; margin-top: 36px; }
.endpoint, .model { background: var(--panel); border: 1px solid var(--border); border-radius: 8px;
  padding: 16px; margin: 16px 0; }
.endpoint header, .model header { display: flex; flex-wrap: wrap; gap: 8px; align-items: baseline; justify-content: space-between; }
h3 { margin: 0; font-size: 18px; font-family: ui-monospace, Menlo, monospace; }
h4 { margin: 16px 0 6px; font-size: 13px; text-transform: uppercase; letter-spacing: .04em; color: var(--muted); }
.ref { font-size: 13px; }
.doc p { margin: 8px 0; } .doc ul { margin: 6px 0; padding-left: 20px; }
.op { border: 1px solid var(--border); border-radius: 6px; margin-top: 10px; }
.op summary { cursor: pointer; display: flex; flex-wrap: wrap; gap: 10px; align-items: center; padding: 8px 12px; list-style: none; }
.op summary::-webkit-details-marker { display: none; }
.op[open] summary { border-bottom: 1px solid var(--border); }
.op-body { padding: 4px 14px 14px; }
.verb { font: 700 12px ui-monospace, Menlo, monospace; color: #fff; padding: 3px 8px; border-radius: 4px; min-width: 48px; text-align: center; }
.verb.post { background: var(--post); } .verb.ws { background: var(--ws); }
.path { background: none; padding: 0; font-weight: 600; font-size: 14px; }
.sum { color: var(--muted); font-size: 14px; flex: 1; min-width: 200px; }
.tag { font-size: 12px; border: 1px solid var(--border); border-radius: 10px; padding: 1px 8px; margin-right: 6px; }
.tag.auth, .req { color: var(--warn); } .tag.public { color: var(--muted); }
.kind { font: 12px system-ui; color: var(--muted); border: 1px solid var(--border); border-radius: 10px; padding: 1px 8px; vertical-align: middle; }
table { border-collapse: collapse; width: 100%; font-size: 14px; }
td, th { text-align: left; padding: 6px 8px; border-bottom: 1px solid var(--border); vertical-align: top; }
th { color: var(--muted); font-weight: 500; font-size: 13px; }
.muted { color: var(--muted); }
.hidden { display: none; }
@media (max-width: 760px) {
  .layout { grid-template-columns: 1fr; }
  nav { position: static; height: auto; border-right: 0; border-bottom: 1px solid var(--border); padding: 16px; }
  main { padding: 16px; }
}
</style>
</head>
<body>
<div class="layout">
<nav>
<h1>Nexo API</h1>
<a href="../index.html" class="ref">Referencia Dart completa</a>
<ul>{{nav}}</ul>
</nav>
<main>
<div class="top">
<div class="summary">{{summary}}</div>
<input id="q" type="search" placeholder="Filtrar métodos…" aria-label="Filtrar métodos">
</div>
<p class="muted">Serverpod es RPC: todas las llamadas son <code>POST /endpoint/metodo</code> con los argumentos en JSON. Los métodos <code>WS</code> son streams por WebSocket.</p>
{{main}}
</main>
</div>
<script>
const q = document.getElementById('q');
q.addEventListener('input', () => {
  const term = q.value.trim().toLowerCase();
  document.querySelectorAll('.op').forEach(op => {
    op.classList.toggle('hidden', term !== '' && !op.dataset.search.includes(term));
  });
  document.querySelectorAll('.endpoint').forEach(ep => {
    ep.classList.toggle('hidden', term !== '' && !ep.querySelector('.op:not(.hidden)'));
  });
});
</script>
</body>
</html>
''';
