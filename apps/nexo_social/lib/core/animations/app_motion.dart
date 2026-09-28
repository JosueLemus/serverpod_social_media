import 'package:animate_do/animate_do.dart';
import 'package:flutter/widgets.dart';

/// The app's motion vocabulary. Every entrance animation goes through here so
/// the whole product moves at one tempo instead of each screen inventing its
/// own duration and offset.
///
/// Two rules are baked into these helpers, and both exist because breaking them
/// produces bugs that look like something else:
///
/// * **What moves is what you do not touch.** A translate animation leaves its
///   child offset from its final position for the length of the animation, and
///   hit testing follows the transform — so during that window taps on a button
///   land on empty space. Someone who knows the flow and reaches straight for a
///   control misses it. Content may slide ([enter]); anything tappable only
///   fades ([enterStatic]).
/// * **A list staggers, but the stagger is capped.** Multiplying the delay by
///   the raw index means item 30 waits three seconds, so a feed that is scrolled
///   quickly shows blank cards. [staggerFor] stops compounding after
///   [maxStaggerSteps].
abstract final class AppMotion {
  /// Content entrance. Long enough to read as motion, short enough that it
  /// never gates a tap.
  static const enterDuration = Duration(milliseconds: 320);

  /// Chrome and controls: opacity only, so slightly quicker.
  static const staticDuration = Duration(milliseconds: 240);

  /// Reaction feedback — a like bounce, a count ticking over.
  static const feedbackDuration = Duration(milliseconds: 220);

  /// Gap between consecutive items of a staggered list.
  static const staggerStep = Duration(milliseconds: 55);

  /// After this many items the delay stops growing. Twelve steps is ~660ms:
  /// past that the user is scrolling, not watching an entrance.
  static const maxStaggerSteps = 12;

  /// Vertical travel of a content entrance. Small on purpose — a long slide
  /// widens the window in which the child is not where it appears to be.
  static const enterOffset = 18.0;

  static Duration staggerFor(int index) =>
      staggerStep * (index.clamp(0, maxStaggerSteps));
}

/// Content that slides in. Do **not** wrap a button, a tab bar, or anything
/// else the user may tap immediately — use [EnterStatic] for those.
class Enter extends StatelessWidget {
  const Enter({super.key, required this.child, this.index = 0, this.from});

  final Widget child;

  /// Position in a list; drives the stagger. Leave at 0 for a single element.
  final int index;

  /// Overrides the travel distance. Defaults to [AppMotion.enterOffset].
  final double? from;

  @override
  Widget build(BuildContext context) => FadeInUp(
    duration: AppMotion.enterDuration,
    delay: AppMotion.staggerFor(index),
    from: from ?? AppMotion.enterOffset,
    child: child,
  );
}

/// Opacity-only entrance for anything interactive. Nothing here moves, so the
/// widget is tappable in the same frame it becomes visible.
class EnterStatic extends StatelessWidget {
  const EnterStatic({super.key, required this.child, this.index = 0});

  final Widget child;
  final int index;

  @override
  Widget build(BuildContext context) => FadeIn(
    duration: AppMotion.staticDuration,
    delay: AppMotion.staggerFor(index),
    child: child,
  );
}

/// A one-shot pop that acknowledges a reaction.
///
/// [trigger] is the reaction's own state: it pops when that flips to true and
/// stays put when it flips back, which matches the asymmetry of the gesture —
/// liking is an event, un-liking is an undo.
///
/// When [trigger] is false the child is returned untouched rather than handed
/// to `animate_do` with `animate: false`. That flag does not mean "render
/// normally without animating": the widget keeps the child at frame zero of
/// the animation, which for a scale-and-fade means invisible. Wiring it the
/// obvious way made every un-liked heart in the feed disappear, leaving a bare
/// like count with nothing to tap.
class Pop extends StatelessWidget {
  const Pop({super.key, required this.child, required this.trigger});

  final Widget child;
  final bool trigger;

  @override
  Widget build(BuildContext context) {
    if (!trigger) return child;
    return BounceIn(
      // Re-keyed on the trigger so the animation replays on each activation
      // instead of being skipped as an already-built subtree.
      key: const ValueKey('pop-on'),
      duration: AppMotion.feedbackDuration,
      child: child,
    );
  }
}
