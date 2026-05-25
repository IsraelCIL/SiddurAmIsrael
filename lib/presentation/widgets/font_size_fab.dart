import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/prayer_providers.dart';

/// Bottom-corner mini-FAB cluster for adjusting the prayer text size
/// while davening one-handed. Fades to ~25% opacity after [_idleFadeDelay]
/// of inactivity and wakes back to full opacity on tap or scroll.
///
/// Position is `Positioned(left: 16, bottom: 16)` so in the RTL siddur
/// layout it sits under the user's right thumb (the device's
/// bottom-left = visual bottom-left regardless of text direction).
class FontSizeFab extends ConsumerStatefulWidget {
  const FontSizeFab({super.key, this.scrollController});

  /// Optional scroll controller — when supplied, the FABs wake up on
  /// every scroll event. Without it, only direct taps wake them.
  final ScrollController? scrollController;

  @override
  ConsumerState<FontSizeFab> createState() => _FontSizeFabState();
}

class _FontSizeFabState extends ConsumerState<FontSizeFab>
    with SingleTickerProviderStateMixin {
  static const Duration _idleFadeDelay = Duration(seconds: 3);
  static const Duration _fadeDuration = Duration(milliseconds: 400);
  static const double _activeOpacity = 0.85;
  static const double _idleOpacity = 0.25;

  late final AnimationController _opacityCtrl;
  Timer? _idleTimer;

  @override
  void initState() {
    super.initState();
    _opacityCtrl = AnimationController(
      vsync: this,
      duration: _fadeDuration,
      value: _activeOpacity,
      lowerBound: _idleOpacity,
      upperBound: _activeOpacity,
    );
    widget.scrollController?.addListener(_onScroll);
    _scheduleFade();
  }

  @override
  void dispose() {
    widget.scrollController?.removeListener(_onScroll);
    _idleTimer?.cancel();
    _opacityCtrl.dispose();
    super.dispose();
  }

  void _onScroll() => _wake();

  void _wake() {
    _opacityCtrl.animateTo(_activeOpacity, duration: _fadeDuration);
    _scheduleFade();
  }

  void _scheduleFade() {
    _idleTimer?.cancel();
    _idleTimer = Timer(_idleFadeDelay, () {
      if (mounted) {
        _opacityCtrl.animateTo(_idleOpacity, duration: _fadeDuration);
      }
    });
  }

  void _bumpFont(double delta) {
    final notifier = ref.read(fontSizeFactorProvider.notifier);
    final current = ref.read(fontSizeFactorProvider);
    final next = (current + delta).clamp(0.6, 1.6);
    notifier.set(next);
    _wake();
  }

  @override
  Widget build(BuildContext context) {
    final factor = ref.watch(fontSizeFactorProvider);
    return Positioned(
      left: 16,
      bottom: 16,
      child: AnimatedBuilder(
        animation: _opacityCtrl,
        builder: (context, child) => Opacity(
          opacity: _opacityCtrl.value,
          child: child,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _MiniFab(
              icon: Icons.text_increase,
              tooltip: 'הגדל גופן',
              onTap: factor < 1.6 ? () => _bumpFont(0.1) : null,
            ),
            const SizedBox(height: 8),
            _MiniFab(
              icon: Icons.text_decrease,
              tooltip: 'הקטן גופן',
              onTap: factor > 0.6 ? () => _bumpFont(-0.1) : null,
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniFab extends StatelessWidget {
  const _MiniFab({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Tooltip(
      message: tooltip,
      child: Material(
        color: const Color(0xFFFDF8F0).withValues(alpha: 0.92),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Color(0xFF8B1A1A), width: 1.2),
        ),
        elevation: 2,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(
              icon,
              size: 22,
              color: enabled
                  ? const Color(0xFF8B1A1A)
                  : const Color(0xFF8B1A1A).withValues(alpha: 0.35),
            ),
          ),
        ),
      ),
    );
  }
}
