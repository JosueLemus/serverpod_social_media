import 'package:flutter/material.dart';

import '../../app/theme/app_tokens.dart';

/// Reusable vector mark based on the Nexo Social Stitch identity.
/// It is drawn with Flutter primitives so it stays sharp on mobile, web and desktop.
class NexoLogo extends StatelessWidget {
  const NexoLogo({super.key, this.size = 92, this.showBadge = true});

  final double size;
  final bool showBadge;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        DecoratedBox(
          decoration: const BoxDecoration(
            color: AppColors.surface,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Color(0x1A172033),
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(size * .11),
            child: const DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.primarySurface,
                shape: BoxShape.circle,
              ),
              child: CustomPaint(painter: _NexoMarkPainter()),
            ),
          ),
        ),
        if (showBadge)
          Positioned(
            right: -size * .04,
            bottom: -size * .02,
            child: Container(
              width: size * .31,
              height: size * .31,
              decoration: const BoxDecoration(
                color: AppColors.primaryDark,
                shape: BoxShape.circle,
                border: Border.fromBorderSide(
                  BorderSide(color: AppColors.surface, width: 2),
                ),
              ),
              child: Icon(
                Icons.check_rounded,
                color: Colors.white,
                size: size * .21,
              ),
            ),
          ),
      ],
    ),
  );
}

class _NexoMarkPainter extends CustomPainter {
  const _NexoMarkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final blue = Paint()
      ..color = AppColors.primaryDark
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * .19
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final mark = Path()
      ..moveTo(size.width * .25, size.height * .74)
      ..lineTo(size.width * .25, size.height * .34)
      ..quadraticBezierTo(
        size.width * .25,
        size.height * .21,
        size.width * .39,
        size.height * .21,
      )
      ..quadraticBezierTo(
        size.width * .51,
        size.height * .21,
        size.width * .51,
        size.height * .36,
      )
      ..lineTo(size.width * .51, size.height * .65)
      ..quadraticBezierTo(
        size.width * .51,
        size.height * .78,
        size.width * .64,
        size.height * .78,
      )
      ..quadraticBezierTo(
        size.width * .77,
        size.height * .78,
        size.width * .77,
        size.height * .64,
      )
      ..lineTo(size.width * .77, size.height * .34)
      ..quadraticBezierTo(
        size.width * .77,
        size.height * .21,
        size.width * .64,
        size.height * .21,
      );
    canvas.drawPath(mark, blue);

    final white = Paint()
      ..color = Colors.white
      ..strokeWidth = size.width * .055
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(size.width * .25, size.height * .33),
      Offset(size.width * .25, size.height * .58),
      white,
    );
    canvas.drawLine(
      Offset(size.width * .77, size.height * .46),
      Offset(size.width * .77, size.height * .67),
      white,
    );
    canvas.drawCircle(
      Offset(size.width * .25, size.height * .31),
      size.width * .08,
      Paint()..color = Colors.white,
    );
    canvas.drawCircle(
      Offset(size.width * .77, size.height * .7),
      size.width * .08,
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(covariant _NexoMarkPainter oldDelegate) => false;
}
