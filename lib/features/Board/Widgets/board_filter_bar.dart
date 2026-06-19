import 'package:flutter/material.dart';

class BoardFilterBar extends StatelessWidget {
  final TextEditingController searchController;
  final String statusFilter;
  final String boardFilter;
  final String sortOption;
  final bool isGridView;
  final List<String> boardOptions;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String> onStatusChanged;
  final ValueChanged<String> onBoardChanged;
  final ValueChanged<String> onSortChanged;
  final ValueChanged<bool> onViewToggle;

  static const Color _bg      = Color(0xFF0A0A0F);
  static const Color _surface = Color(0xFF111118);
  static const Color _orange  = Color(0xFFFF7300);
  static const Color _textSec = Color(0xFF8A8A9A);
  static const Color _border  = Color(0xFF1E1E2E);

  const BoardFilterBar({
    super.key,
    required this.searchController,
    required this.statusFilter,
    required this.boardFilter,
    required this.sortOption,
    required this.isGridView,
    required this.boardOptions,
    required this.onSearchChanged,
    required this.onStatusChanged,
    required this.onBoardChanged,
    required this.onSortChanged,
    required this.onViewToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _surface,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Search ──
          Container(
            height: 40,
            decoration: BoxDecoration(
              color: _bg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _border),
            ),
            child: TextField(
              controller: searchController,
              onChanged: onSearchChanged,
              style: const TextStyle(fontSize: 14, color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Search tasks...',
                hintStyle: TextStyle(fontSize: 14, color: Color(0xFF8A8A9A)),
                prefixIcon: Icon(Icons.search_rounded, size: 18, color: Color(0xFF8A8A9A)),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 10),
                isDense: true,
              ),
            ),
          ),

          const SizedBox(height: 10),

          // ── Status filters + dropdowns + view toggle ──
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Status pills
                _StatusPill(
                  label: 'All',
                  isActive: statusFilter == 'All',
                  onTap: () => onStatusChanged('All'),
                ),
                const SizedBox(width: 8),
                _StatusPill(
                  label: 'Pending',
                  isActive: statusFilter == 'Pending',
                  onTap: () => onStatusChanged('Pending'),
                ),
                const SizedBox(width: 8),
                _StatusPill(
                  label: 'Completed',
                  isActive: statusFilter == 'Completed',
                  onTap: () => onStatusChanged('Completed'),
                ),
                const SizedBox(width: 12),

                // Board dropdown
                _DropdownChip(
                  value: boardFilter,
                  items: boardOptions,
                  onChanged: onBoardChanged,
                ),
                const SizedBox(width: 8),

                // Sort dropdown
                _DropdownChip(
                  value: 'Sort by $sortOption',
                  items: const ['Due Date', 'Priority'],
                  onChanged: onSortChanged,
                  prefix: 'Sort by ',
                ),
                const SizedBox(width: 12),

                // Grid / List toggle
                Container(
                  decoration: BoxDecoration(
                    color: _bg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _border),
                  ),
                  child: Row(
                    children: [
                      _ViewBtn(
                        icon: Icons.grid_view_rounded,
                        isActive: isGridView,
                        onTap: () => onViewToggle(true),
                      ),
                      _ViewBtn(
                        icon: Icons.view_list_rounded,
                        isActive: !isGridView,
                        onTap: () => onViewToggle(false),
                      ),
                    ],
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

// ── Status pill ──
class _StatusPill extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  static const Color _orange = Color(0xFFFF7300);

  const _StatusPill({required this.label, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: isActive ? _orange : const Color(0xFF0A0A0F),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? _orange : const Color(0xFF1E1E2E),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isActive ? Colors.white : const Color(0xFF8A8A9A),
          ),
        ),
      ),
    );
  }
}

// ── Dropdown chip ──
class _DropdownChip extends StatelessWidget {
  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;
  final String prefix;

  const _DropdownChip({
    required this.value,
    required this.items,
    required this.onChanged,
    this.prefix = '',
  });

  @override
  Widget build(BuildContext context) {
    // Resolve display value back to raw item
    final rawValue = prefix.isNotEmpty && value.startsWith(prefix)
        ? value.substring(prefix.length)
        : value;
    final resolvedValue = items.contains(rawValue) ? rawValue : items.first;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0A0F),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1E1E2E)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: resolvedValue,
          isDense: true,
          dropdownColor: const Color(0xFF16161F),
          style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w600),
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Color(0xFF8A8A9A)),
          items: items.map((item) {
            return DropdownMenuItem(
              value: item,
              child: Text('$prefix$item'),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) onChanged(val);
          },
        ),
      ),
    );
  }
}

// ── View toggle button ──
class _ViewBtn extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  static const Color _orange = Color(0xFFFF7300);

  const _ViewBtn({required this.icon, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 34,
        decoration: BoxDecoration(
          color: isActive ? _orange : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(icon, size: 18, color: isActive ? Colors.white : const Color(0xFF8A8A9A)),
      ),
    );
  }
}