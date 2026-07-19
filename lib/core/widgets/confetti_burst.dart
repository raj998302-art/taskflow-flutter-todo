import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A lightweight overlay that fires a confetti burst when [trigger] flips to
/// true. Place it near the top of a Stack so the confetti rains down over the
/// UI. Used when a task is marked complete.
class ConfettiBurst extends ConsumerStatefulWidget {
  const ConfettiBurst({
    super.key,
    required this.trigger,
    this.maxBlast = 18,
  });

  /// When this flips from false → true, a single confetti burst fires.
  final bool trigger;
  final int maxBlast;

  @override
  ConsumerState<ConfettiBurst> createState() => _ConfettiBurstState();
}

class _ConfettiBurstState extends ConsumerState<ConfettiBurst> {
  late final ConfettiController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ConfettiController(duration: const Duration(seconds: 2));
  }

  @override
  void didUpdateWidget(covariant ConfettiBurst oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger && !oldWidget.trigger) {
      _controller.play();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Align(
        alignment: Alignment.topCenter,
        child: ConfettiWidget(
          confettiController: _controller,
          blastDirectionality: BlastDirectionality.explosive,
          maxBlastForce: widget.maxBlast.toDouble(),
          minBlastForce: 8,
          emissionFrequency: 0.06,
          numberOfParticles: 20,
          gravity: 0.15,
          shouldLoop: false,
          colors: const [
            Color(0xFF7C5CFC),
            Color(0xFF22D3EE),
            Color(0xFFFF6B9D),
            Color(0xFF10B981),
            Color(0xFFF59E0B),
          ],
        ),
      ),
    );
  }
}

/// Provider-backed flag that the UI flips to `true` for ~2.5s whenever a task
/// is completed, so any mounted [ConfettiBurst] fires.
final celebrateProvider = StateProvider<bool>((ref) => false);

/// Call this from anywhere to fire a one-shot confetti celebration.
void celebrate(WidgetRef ref) {
  ref.read(celebrateProvider.notifier).state = true;
  Future<void>.delayed(const Duration(milliseconds: 2500), () {
    ref.read(celebrateProvider.notifier).state = false;
  });
}
