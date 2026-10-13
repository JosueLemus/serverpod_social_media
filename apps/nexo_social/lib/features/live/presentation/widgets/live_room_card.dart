import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../app/theme/app_tokens.dart';
import '../../../../core/widgets/nexo_icon.dart';
import '../../../../core/widgets/pills.dart';
import '../../../../core/widgets/user_avatar.dart';
import '../../domain/entities/live_session.dart';
import '../../domain/entities/live_stage.dart';
import '../utils/live_status_ui.dart';

/// Qué dibuja la tarjeta de "sala": el host, hasta cuatro oradores apilados a
/// su lado y el total de oyentes (SDD 0011, Etapa 5).
///
/// La lista real de oradores sólo la tiene [LiveStage]; sin ese dato la
/// tarjeta cae a los `cohostIds` de la agenda —son los que la sala va a subir
/// al escenario al salir al aire—. **Nunca** se inventan nombres.
class LiveRoomSpeakers {
  const LiveRoomSpeakers({
    required this.host,
    required this.others,
    this.extra = 0,
  });

  factory LiveRoomSpeakers.fromSession(LiveSession session) =>
      LiveRoomSpeakers(
        host: LiveRoomParticipant(
          id: session.hostId,
          name: session.hostName,
          avatarUrl: session.hostAvatarUrl,
          isHost: true,
        ),
        others: [
          for (final id in session.cohostIds.take(_cap))
            LiveRoomParticipant(id: id, name: _initialOf(id)),
        ],
        extra: math.max(0, session.cohostIds.length - _cap),
      );

  /// Un snapshot real del escenario. La tarjeta destacada lo pide una sola
  /// vez al armarse para no cotizar un dato por fila.
  factory LiveRoomSpeakers.fromStage(LiveSession session, LiveStage stage) {
    final hostSpeaker = stage.speakers
        .where((s) => s.role == LiveRole.host || s.userId == session.hostId)
        .firstOrNull;
    final others = stage.speakers
        .where((s) => s.userId != (hostSpeaker?.userId ?? session.hostId))
        .toList();
    return LiveRoomSpeakers(
      host: LiveRoomParticipant(
        id: hostSpeaker?.userId ?? session.hostId,
        name: hostSpeaker?.name ?? session.hostName,
        avatarUrl: hostSpeaker?.avatarUrl ?? session.hostAvatarUrl,
        isHost: true,
      ),
      others: [
        for (final s in others.take(_cap))
          LiveRoomParticipant(
            id: s.userId,
            name: s.name,
            avatarUrl: s.avatarUrl,
          ),
      ],
      extra: math.max(0, others.length - _cap),
    );
  }

  static const _cap = 4;

  final LiveRoomParticipant host;
  final List<LiveRoomParticipant> others;
  final int extra;

  /// Un nombre legible a partir de un id (`creator-1` → `C`). Sólo se usa
  /// cuando el id es lo único que la tarjeta sabe; en cuanto llega el
  /// escenario real, el nombre viene de ahí.
  static String _initialOf(String id) {
    final clean = id.replaceAll('-', ' ').trim();
    if (clean.isEmpty) return '?';
    final first = clean.characters.first;
    return first.toUpperCase();
  }
}

class LiveRoomParticipant {
  const LiveRoomParticipant({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.isHost = false,
  });

  final String id;
  final String name;
  final String? avatarUrl;
  final bool isHost;
}

/// La tarjeta de una sala en vivo para el home y Explorar.
///
/// Un sticker con fondo oscuro: host al aire con holo, oradores apilados a su
/// lado, línea de "N escuchando", la onda de audio como decoración y
/// "Escuchar" como CTA. Reemplaza al par `FeaturedLiveCard`/`LiveCard` cuando
/// se trata de una sala tipo podcast; una sesión programada o un replay sigue
/// yendo por `LiveCard` porque no son salas al aire.
class LiveRoomCard extends StatelessWidget {
  const LiveRoomCard({
    super.key,
    required this.session,
    required this.speakers,
    required this.onJoin,
    this.isOwn = false,
  });

  final LiveSession session;
  final LiveRoomSpeakers speakers;
  final VoidCallback onJoin;

  /// El vivo es de la cuenta en sesión: el CTA la devuelve al Studio en vez
  /// de invitarla a entrar como audiencia de sí misma.
  final bool isOwn;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      key: Key('live-room-card-${session.id}'),
      decoration: BoxDecoration(
        color: AppColors.stageDark,
        borderRadius: AppRadii.large,
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            // La onda de audio como decoración: dice "sala en vivo" de un
            // vistazo. Aislada en su RepaintBoundary para que su repintado por
            // frame no suba y vuelva a rasterizar el resto de la tarjeta.
            child: _AudioWave(active: session.status.isOnAir),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const StatusBadge(label: 'EN VIVO', pulse: true, tilt: -.06),
                    const SizedBox(width: AppSpacing.xs),
                    Flexible(
                      child: Text(
                        'Sala en vivo',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.labelMedium?.copyWith(
                          color: AppColors.onMediaSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  session.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: text.titleLarge?.copyWith(color: AppColors.onMedia),
                ),
                const SizedBox(height: AppSpacing.sm),
                _SpeakersStack(speakers: speakers),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    NexoIcon(
                      NexoGlyph.community,
                      size: 14,
                      color: AppColors.onMediaSecondary,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        '${compactCount(session.viewers)} escuchando',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.labelMedium?.copyWith(
                          color: AppColors.onMediaSecondary,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    key: Key('join-live-${session.id}'),
                    onPressed: onJoin,
                    icon: NexoIcon(
                      isOwn ? NexoGlyph.studio : NexoGlyph.live,
                      size: 18,
                    ),
                    label: Text(isOwn ? 'Volver a tu sala' : 'Escuchar'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.sticker,
                      foregroundColor: AppColors.ink,
                      minimumSize: const Size(0, AppSizes.buttonHeightDense),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Avatares apilados con solapamiento: host primero con el foil, el resto a
/// su derecha; un "+N" al final si hay más que no entran.
class _SpeakersStack extends StatelessWidget {
  const _SpeakersStack({required this.speakers});

  final LiveRoomSpeakers speakers;

  @override
  Widget build(BuildContext context) {
    const size = 36.0;
    const overlap = 10.0;
    final all = <LiveRoomParticipant>[speakers.host, ...speakers.others];
    final totalWidth = size + (all.length - 1) * (size - overlap);
    return Row(
      children: [
        SizedBox(
          height: size + 2,
          width: totalWidth,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              for (final (index, person) in all.indexed)
                Positioned(
                  left: index * (size - overlap),
                  child: UserAvatar(
                    key: Key('room-card-speaker-${person.id}'),
                    name: person.name,
                    imageUrl: person.avatarUrl,
                    size: size,
                    onAir: person.isHost,
                  ),
                ),
            ],
          ),
        ),
        if (speakers.extra > 0) ...[
          const SizedBox(width: AppSpacing.xs),
          Text(
            '+${speakers.extra}',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: AppColors.onMediaSecondary,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
        const SizedBox(width: AppSpacing.sm),
        Flexible(
          child: Text(
            _speakersLabel(speakers),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.onMediaSecondary,
            ),
          ),
        ),
      ],
    );
  }

  static String _speakersLabel(LiveRoomSpeakers speakers) {
    final host = speakers.host.name.isEmpty ? 'el host' : speakers.host.name;
    if (speakers.others.isEmpty) return host;
    final others = speakers.others.map((p) => p.name).toList();
    if (others.length == 1) return '$host y ${others.single}';
    final tail = others.sublist(0, others.length - 1).join(', ');
    final last = others.last;
    return '$host, $tail y $last';
  }
}

/// Una onda que sube y baja: 24 barras verticales con fase corrida. Como el
/// barrido del escáner QR: dice "está pasando ahora" sin invitar a tocar.
///
/// `active=false` deja las barras planas al mínimo (ni al medio ni al tope):
/// el replay no se mueve y una altura plana se lee como estado estable.
class _AudioWave extends StatefulWidget {
  const _AudioWave({required this.active});

  final bool active;

  @override
  State<_AudioWave> createState() => _AudioWaveState();
}

class _AudioWaveState extends State<_AudioWave>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (widget.active && !reduceMotion) {
      if (!_controller.isAnimating) _controller.repeat();
    } else {
      _controller
        ..stop()
        ..value = 0;
    }
  }

  @override
  void didUpdateWidget(covariant _AudioWave oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active != oldWidget.active) didChangeDependencies();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: RepaintBoundary(
      child: CustomPaint(
        painter: _WavePainter(
          progress: _controller,
          active: widget.active,
        ),
      ),
    ),
  );
}

class _WavePainter extends CustomPainter {
  _WavePainter({required this.progress, required this.active})
      : super(repaint: progress);

  final Animation<double> progress;
  final bool active;

  static const _bars = 24;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.onMedia.withValues(alpha: .08)
      ..style = PaintingStyle.fill;
    final slot = size.width / _bars;
    final barWidth = slot * .4;
    final baseline = size.height * .95;
    final maxHeight = size.height * .35;
    for (var i = 0; i < _bars; i++) {
      final phase = (progress.value + i / _bars) % 1;
      final factor = active
          ? (math.sin(phase * 2 * math.pi) * .5 + .5)
          : .25;
      final h = maxHeight * (0.3 + 0.7 * factor);
      final x = i * slot + (slot - barWidth) / 2;
      final rect = Rect.fromLTWH(x, baseline - h, barWidth, h);
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(2)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_WavePainter old) => old.active != active;
}

