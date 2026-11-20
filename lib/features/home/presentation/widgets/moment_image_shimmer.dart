import 'package:flutter/material.dart';

Widget momentImageLoadingFrame(
  BuildContext context, Widget child, int? frame, bool wasSynchronouslyLoaded,
) => frame != null || wasSynchronouslyLoaded
    ? child
    : const MomentImageShimmer();

/// Fills the image's existing bounds until the first decoded image frame arrives.
class MomentImageShimmer extends StatefulWidget {
  const MomentImageShimmer({super.key});

  @override
  State<MomentImageShimmer> createState() => _MomentImageShimmerState();
}

class _MomentImageShimmerState extends State<MomentImageShimmer>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this, duration: const Duration(milliseconds: 1400),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context) || !TickerMode.valuesOf(context).enabled) {
      _controller.stop();
    } else {
      _controller.repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Loading moment image',
    child: AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final offset = -3 + 6 * _controller.value;
        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment(offset - 1, -0.3),
              end: Alignment(offset + 1, 0.3),
              colors: const [Color(0xFF191A30), Color(0xFF34344F), Color(0xFF191A30)],
              stops: const [0, 0.5, 1],
            ),
          ),
          child: const SizedBox.expand(),
        );
      },
    ),
  );
}
