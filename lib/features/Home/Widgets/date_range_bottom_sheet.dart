import 'package:flutter/material.dart';

class DateRangeBottomSheet extends StatefulWidget {
  final DateTime? initialStart;
  final DateTime? initialEnd;

  const DateRangeBottomSheet({
    super.key,
    this.initialStart,
    this.initialEnd,
  });

  @override
  State<DateRangeBottomSheet> createState() => _DateRangeBottomSheetState();
}

class _DateRangeBottomSheetState extends State<DateRangeBottomSheet> {
  static const Color _accent   = Color(0xFF29B6F6);
  static const Color _textPri  = Color(0xFF1A1A1A);
  static const Color _textSec  = Color(0xFF9E9E9E);
  static const Color _headerBg = Color(0xFFF5F5F5);
  static const Color _divider  = Color(0xFFF0F0F0);
  static const Color _rangeBg  = Color(0xFFE3F6FD);

  late DateTime _focusedMonth;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _startDate   = widget.initialStart;
    _endDate     = widget.initialEnd;
    _focusedMonth = DateTime(
      (widget.initialStart ?? DateTime.now()).year,
      (widget.initialStart ?? DateTime.now()).month,
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  String _monthLabel(DateTime d) {
    const months = [
      'January','February','March','April','May','June',
      'July','August','September','October','November','December',
    ];
    return '${months[d.month - 1]} ${d.year}';
  }

  void _prevMonth() => setState(() {
    _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1);
  });

  void _nextMonth() => setState(() {
    _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1);
  });

  void _onDayTap(DateTime tapped) {
    setState(() {
      if (_startDate == null || (_startDate != null && _endDate != null)) {
        // fresh selection
        _startDate = tapped;
        _endDate   = null;
      } else {
        // second tap
        if (tapped.isBefore(_startDate!)) {
          _endDate   = _startDate;
          _startDate = tapped;
        } else {
          _endDate = tapped;
        }
      }
    });
  }

  bool _isStart(DateTime d)    => _startDate != null && _isSameDay(d, _startDate!);
  bool _isEnd(DateTime d)      => _endDate   != null && _isSameDay(d, _endDate!);
  bool _isToday(DateTime d)    => _isSameDay(d, DateTime.now());
  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _inRange(DateTime d) {
    if (_startDate == null || _endDate == null) return false;
    return d.isAfter(_startDate!) && d.isBefore(_endDate!);
  }

  bool get _canConfirm => _startDate != null;

  void _clear() => setState(() { _startDate = null; _endDate = null; });

  void _confirm() {
    if (!_canConfirm) return;
    Navigator.pop(context, {'start': _startDate, 'end': _endDate});
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 10),
            width: 36, height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFDDDDDD),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Container(
            margin: const EdgeInsets.only(top: 10),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: const BoxDecoration(
              color: _headerBg,
              border: Border(bottom: BorderSide(color: _divider, width: 1)),
            ),
            child: Row(
              children: [
                // Close
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 6, offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.close_rounded, size: 18, color: _textPri),
                  ),
                ),
                const Expanded(
                  child: Text(
                    'DATE RANGE',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700,
                      color: _textSec, letterSpacing: 1.4,
                    ),
                  ),
                ),
                // Clear
                GestureDetector(
                  onTap: _clear,
                  child: const SizedBox(
                    width: 40,
                    child: Text(
                      'Clear',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 14, color: _textSec,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Month navigation
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _NavArrow(icon: Icons.chevron_left, onTap: _prevMonth),
                Text(
                  _monthLabel(_focusedMonth),
                  style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700, color: _textPri,
                  ),
                ),
                _NavArrow(icon: Icons.chevron_right, onTap: _nextMonth),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Day-of-week headers
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: const ['Sun','Mon','Tue','Wed','Thu','Fri','Sat']
                  .map((d) => Expanded(
                        child: Center(
                          child: Text(
                            d,
                            style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600,
                              color: _textSec,
                            ),
                          ),
                        ),
                      ))
                  .toList(),
            ),
          ),

          const SizedBox(height: 8),

          // Calendar grid
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: _buildGrid(),
          ),

          const SizedBox(height: 24),

          // Select dates button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                onPressed: _canConfirm ? _confirm : null,
                style: OutlinedButton.styleFrom(
                  foregroundColor: _canConfirm ? _accent : _textSec,
                  side: BorderSide(
                    color: _canConfirm ? _accent : const Color(0xFFDDDDDD),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: _canConfirm
                      ? _accent.withOpacity(0.06)
                      : Colors.transparent,
                ),
                child: Text(
                  'Select dates',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: _canConfirm ? _accent : _textSec,
                  ),
                ),
              ),
            ),
          ),

          SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
        ],
      ),
    );
  }

  Widget _buildGrid() {
    final firstDay = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final daysInMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0).day;
    final startWeekday = firstDay.weekday % 7; // Sun=0

    final List<DateTime?> cells = [
      ...List.filled(startWeekday, null),
      ...List.generate(daysInMonth, (i) => DateTime(_focusedMonth.year, _focusedMonth.month, i + 1)),
    ];

    // Pad to complete last row
    while (cells.length % 7 != 0) cells.add(null);

    final rows = <Widget>[];
    for (int r = 0; r < cells.length ~/ 7; r++) {
      final rowDays = cells.sublist(r * 7, r * 7 + 7);
      rows.add(
        Row(
          children: rowDays.map((day) {
            if (day == null) return const Expanded(child: SizedBox(height: 48));
            return Expanded(child: _DayCell(
              day: day,
              isStart: _isStart(day),
              isEnd: _isEnd(day),
              isToday: _isToday(day),
              inRange: _inRange(day),
              accent: _accent,
              rangeBg: _rangeBg,
              textSec: _textSec,
              onTap: () => _onDayTap(day),
            ));
          }).toList(),
        ),
      );
    }

    return Column(children: rows);
  }
}

// ── Nav arrow button ─────────────────────────────────────────────────────────

class _NavArrow extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _NavArrow({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34, height: 34,
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 20, color: const Color(0xFF444444)),
      ),
    );
  }
}

// ── Single day cell ───────────────────────────────────────────────────────────

class _DayCell extends StatelessWidget {
  final DateTime day;
  final bool isStart;
  final bool isEnd;
  final bool isToday;
  final bool inRange;
  final Color accent;
  final Color rangeBg;
  final Color textSec;
  final VoidCallback onTap;

  const _DayCell({
    required this.day,
    required this.isStart,
    required this.isEnd,
    required this.isToday,
    required this.inRange,
    required this.accent,
    required this.rangeBg,
    required this.textSec,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = isStart || isEnd;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        // range background spans full width for in-between days
        decoration: BoxDecoration(
          color: inRange ? rangeBg : Colors.transparent,
          // clip left cap on start, right cap on end
          borderRadius: isStart
              ? const BorderRadius.horizontal(left: Radius.circular(24))
              : isEnd
                  ? const BorderRadius.horizontal(right: Radius.circular(24))
                  : null,
        ),
        child: Center(
          child: Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? accent : Colors.transparent,
              border: isToday && !isSelected
                  ? Border.all(color: accent, width: 1.5)
                  : null,
            ),
            child: Center(
              child: Text(
                '${day.day}',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: isSelected || isToday
                      ? FontWeight.w700
                      : FontWeight.w400,
                  color: isSelected
                      ? Colors.white
                      : inRange
                          ? accent
                          : isToday
                              ? accent
                              : textSec,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}