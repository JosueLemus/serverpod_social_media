import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../app/theme/app_tokens.dart';

/// The Nexo Social brand mark, sourced from the shared SVG asset.
/// Keep this widget as the single entry point for the logo in the UI.
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
            padding: EdgeInsets.all(size * .08),
            child: SvgPicture.asset('assets/branding/nexo_mark.svg'),
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
