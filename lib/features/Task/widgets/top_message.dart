import 'package:flutter/material.dart';

enum TopMessageType { success, error, warning }

class TopMessage {
  static OverlayEntry? _current;

  static void show(
    BuildContext context,
    String message, {
    TopMessageType type = TopMessageType.success,
    Duration duration = const Duration(seconds: 2),
  }) {
    // Remove any message that is still showing
    if (_current != null && _current!.mounted) _current!.remove();
    _current = null;

    final overlay = Overlay.of(context, rootOverlay: true);
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _TopMessageWidget(
        message: message,
        type: type,
        duration: duration,
        onDone: () {
          if (entry.mounted) entry.remove();
          if (_current == entry) _current = null;
        },
      ),
    );
    _current = entry;
    overlay.insert(entry);
  }

  static void success(BuildContext c, String m) => show(c, m, type: TopMessageType.success);
  static void error(BuildContext c, String m) => show(c, m, type: TopMessageType.error);
  static void warning(BuildContext c, String m) => show(c, m, type: TopMessageType.warning);
}

class _TopMessageWidget extends StatefulWidget {
  final String message;
  final TopMessageType type;
  final Duration duration;
  final VoidCallback onDone;

  const _TopMessageWidget({
    required this.message,
    required this.type,
    required this.duration,
    required this.onDone,
  });

  @override
  State<_TopMessageWidget> createState() => _TopMessageWidgetState();
}

class _TopMessageWidgetState extends State<_TopMessageWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 300),
  );
  late final Animation<Offset> _slide = Tween<Offset>(
    begin: const Offset(0, -1.5),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    await _ctrl.forward();
    await Future.delayed(widget.duration); // stays visible for 2 seconds
    if (!mounted) return;
    await _ctrl.reverse();
    widget.onDone();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Color get _color {
    switch (widget.type) {
      case TopMessageType.success:
        return const Color(0xFF43A047);
      case TopMessageType.error:
        return const Color(0xFFFF4D4D);
      case TopMessageType.warning:
        return const Color(0xFFFF7300);
    }
  }

  IconData get _icon {
    switch (widget.type) {
      case TopMessageType.success:
        return Icons.check_circle_rounded;
      case TopMessageType.error:
        return Icons.error_rounded;
      case TopMessageType.warning:
        return Icons.warning_amber_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slide,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: _color,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: _color.withOpacity(0.45),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Icon(_icon, color: Colors.white, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.message,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}