import 'package:flutter/material.dart';

enum SortOption { urgent, high, pending, inProgress }

extension SortOptionLabel on SortOption {
  String get label {
    switch (this) {
      case SortOption.urgent:      return 'Urgent';
      case SortOption.high:        return 'High';
      case SortOption.pending:     return 'Pending';
      case SortOption.inProgress:  return 'In Progress';
    }
  }
}

class SortBottomSheet extends StatefulWidget {
  final SortOption currentSort;

  const SortBottomSheet({super.key, required this.currentSort});

  @override
  State<SortBottomSheet> createState() => _SortBottomSheetState();
}

class _SortBottomSheetState extends State<SortBottomSheet> {
  // ── Dark theme palette (consistent with login & home) ──
  static const Color _bg         = Color(0xFF0A0A0F);
  static const Color _surface    = Color(0xFF111118);
  static const Color _surfaceAlt = Color(0xFF16161F);
  static const Color _orange     = Color(0xFFFF7300);
  static const Color _textPri    = Color(0xFFFFFFFF);
  static const Color _textSec    = Color(0xFF8A8A9A);
  static const Color _border     = Color(0xFF1E1E2E);
  static const Color _borderHi   = Color(0xFF2A2A3A);

  late SortOption _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.currentSort;
  }

  @override
  Widget build(BuildContext context) {
    final options = SortOption.values;

    return Container(
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: _border, width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Handle bar ──
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 38,
            height: 4,
            decoration: BoxDecoration(
              color: _borderHi,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // ── Header ──
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Row(
              children: [
                // Close button
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _surfaceAlt,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _border, width: 1),
                    ),
                    child: const Icon(Icons.close_rounded, size: 20, color: _textPri),
                  ),
                ),
                const Expanded(
                  child: Text(
                    'SORT BY',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _textSec,
                      letterSpacing: 1.6,
                    ),
                  ),
                ),
                const SizedBox(width: 36), // balance close button
              ],
            ),
          ),

          const Divider(height: 1, thickness: 1, color: _border),

          // ── Options list ──
          ...options.map((option) {
            final isActive = _selected == option;
            return _SortOptionTile(
              label: option.label,
              isActive: isActive,
              onTap: () {
                setState(() => _selected = option);
                Future.delayed(const Duration(milliseconds: 180), () {
                  Navigator.pop(context, option);
                });
              },
            );
          }),

          // bottom safe area
          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }
}

class _SortOptionTile extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _SortOptionTile({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Material(
          color: isActive ? const Color(0x28FF7300) : Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                        color: isActive ? const Color(0xFFFF7300) : const Color(0xFFFFFFFF),
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  if (isActive)
                    Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF7300),
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        Divider(height: 1, thickness: 1, color: const Color(0xFF1E1E2E)),
      ],
    );
  }
}