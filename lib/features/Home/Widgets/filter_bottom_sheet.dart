import 'package:flutter/material.dart';

enum FilterOption { high, urgent }

extension FilterOptionLabel on FilterOption {
  String get label {
    switch (this) {
      case FilterOption.high:   return 'High';
      case FilterOption.urgent: return 'Urgent';
    }
  }
}

class FilterBottomSheet extends StatefulWidget {
  final FilterOption currentFilter;

  const FilterBottomSheet({super.key, required this.currentFilter});

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late FilterOption _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.currentFilter;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF111118),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: const Color(0xFF1E1E2E), width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 38,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A3A),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFF16161F),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF1E1E2E), width: 1),
                    ),
                    child: const Icon(Icons.close_rounded, size: 20, color: Colors.white),
                  ),
                ),
                const Expanded(
                  child: Text(
                    'FILTER BY PRIORITY',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF8A8A9A),
                      letterSpacing: 1.6,
                    ),
                  ),
                ),
                const SizedBox(width: 36),
              ],
            ),
          ),

          const Divider(height: 1, thickness: 1, color: Color(0xFF1E1E2E)),

          // Options: Only High and Urgent
          _FilterOptionTile(
            label: 'High',
            isActive: _selected == FilterOption.high,
            onTap: () {
              setState(() => _selected = FilterOption.high);
              Future.delayed(const Duration(milliseconds: 180), () {
                Navigator.pop(context, FilterOption.high);
              });
            },
          ),
          _FilterOptionTile(
            label: 'Urgent',
            isActive: _selected == FilterOption.urgent,
            onTap: () {
              setState(() => _selected = FilterOption.urgent);
              Future.delayed(const Duration(milliseconds: 180), () {
                Navigator.pop(context, FilterOption.urgent);
              });
            },
          ),

          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }
}

class _FilterOptionTile extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _FilterOptionTile({
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
                        color: isActive ? const Color(0xFFFF7300) : Colors.white,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  if (isActive)
                    Container(
                      width: 9,
                      height: 9,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF7300),
                        shape: BoxShape.circle,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        const Divider(height: 1, thickness: 1, color: const Color(0xFF1E1E2E)),
      ],
    );
  }
}