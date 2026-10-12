import 'package:flutter/widgets.dart';
import 'package:share_plus/share_plus.dart';

import '../constants/environment.dart';

/// Abre la hoja de compartir del sistema (WhatsApp, Instagram, copiar…).
///
/// Es un efecto de la plataforma, como abrir un enlace: no pasa por un cubit
/// porque no cambia ningún estado de la app. En iPad la hoja necesita un
/// ancla, así que se toma la caja del botón que la abrió.
Future<void> openShareSheet(
  BuildContext context, {
  required String text,
  String? subject,
}) {
  final box = context.findRenderObject() as RenderBox?;
  return SharePlus.instance.share(
    ShareParams(
      text: text,
      subject: subject,
      sharePositionOrigin: box == null || !box.hasSize
          ? null
          : box.localToGlobal(Offset.zero) & box.size,
    ),
  );
}

/// El enlace público a [path] dentro de la app, o null sin `SHARE_BASE_URL`.
///
/// [baseUrl] es inyectable para los tests; en la app sale del entorno.
String? shareLink(String path, {String baseUrl = Environment.shareBaseUrl}) {
  final base = baseUrl.trim();
  if (base.isEmpty) return null;
  final root = base.endsWith('/') ? base.substring(0, base.length - 1) : base;
  return '$root$path';
}
