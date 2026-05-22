// admin_date_filter_dialog.dart
import 'package:flutter/material.dart';

// ── Palette ───────────────────────────────────────────────────────────────────
const Color _bg         = Color(0xFF0A0A0F);
const Color _surface    = Color(0xFF111118);
const Color _surfaceAlt = Color(0xFF16161F);
const Color _orange     = Color(0xFFFF7300);
const Color _orangeDim  = Color(0x22FF7300);
const Color _textPri    = Color(0xFFFFFFFF);
const Color _textSec    = Color(0xFF8A8A9A);
const Color _border     = Color(0xFF1E1E2E);
const Color _borderHi   = Color(0xFF2A2A3A);

// ── Public result model ───────────────────────────────────────────────────────
class DateFilterResult {
  final DateTime from;
  final DateTime to;

  const DateFilterResult({required this.from, required this.to});

  String get fromLabel => _fmt(from);
  String get toLabel   => _fmt(to);
  String get rangeLabel => '${_fmt(from)} – ${_fmt(to)}';

  static String _fmt(DateTime d) {
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    return '${months[d.month - 1]} ${d.day}, ${d.year}';
  }
}

// ── Entry point — call this to open the dialog ────────────────────────────────
Future<DateFilterResult?> showDateFilterDialog(
  BuildContext context, {
  DateTime? initialFrom,
  DateTime? initialTo,
}) {
  return showDialog<DateFilterResult>(
    context: context,
    barrierColor: Colors.black.withOpacity(0.65),
    builder: (_) => _DateFilterDialog(
      initialFrom: initialFrom,
      initialTo: initialTo,
    ),
  );
}

// ── Dialog widget ─────────────────────────────────────────────────────────────
class _DateFilterDialog extends StatefulWidget {
  final DateTime? initialFrom;
  final DateTime? initialTo;

  const _DateFilterDialog({this.initialFrom, this.initialTo});

  @override
  State<_DateFilterDialog> createState() => _DateFilterDialogState();
}

class _DateFilterDialogState extends State<_DateFilterDialog> {
  late DateTime _from;
  late DateTime _to;

  // Which picker is active: 'from' or 'to'
  String _active = 'from';

  // The month being displayed in the calendar
  late DateTime _displayMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _from = widget.initialFrom ?? now.subtract(const Duration(days: 30));
    _to   = widget.initialTo   ?? now;
    _displayMonth = DateTime(_from.year, _from.month);
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────
  static const _months = [
    'January','February','March','April','May','June',
    'July','August','September','October','November','December'
  ];
  static const _days = ['Su','Mo','Tu','We','Th','Fr','Sa'];

  String _fmt(DateTime d) =>
      '${_months[d.month - 1].substring(0, 3)} ${d.day}, ${d.year}';

  void _prevMonth() => setState(() {
        _displayMonth =
            DateTime(_displayMonth.year, _displayMonth.month - 1);
      });

  void _nextMonth() => setState(() {
        _displayMonth =
            DateTime(_displayMonth.year, _displayMonth.month + 1);
      });

  void _onDayTap(DateTime day) {
    setState(() {
      if (_active == 'from') {
        _from = day;
        // if from > to, push to forward
        if (_from.isAfter(_to)) _to = _from;
        _active = 'to';
      } else {
        if (day.isBefore(_from)) {
          // swap
          _to   = _from;
          _from = day;
        } else {
          _to = day;
        }
        _active = 'from';
      }
    });
  }

  bool _isFrom(DateTime d) =>
      d.year == _from.year && d.month == _from.month && d.day == _from.day;

  bool _isTo(DateTime d) =>
      d.year == _to.year && d.month == _to.month && d.day == _to.day;

  bool _isInRange(DateTime d) => d.isAfter(_from) && d.isBefore(_to);

  // ── Build ─────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: _surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: _border, width: 1),
      ),
      child: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSelectedDatesHeader(),
            const Divider(color: _border, height: 1),
            _buildCalendar(),
            const Divider(color: _border, height: 1),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  // ── Top section: shows selected From / To ─────────────────────────────────
  Widget _buildSelectedDatesHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Date Range',
            style: TextStyle(
              color: _textPri,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _DateChip(
                  label: 'From',
                  value: _fmt(_from),
                  isActive: _active == 'from',
                  onTap: () => setState(() {
                    _active = 'from';
                    _displayMonth = DateTime(_from.year, _from.month);
                  }),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Icon(Icons.arrow_forward_rounded,
                    color: _textSec, size: 16),
              ),
              Expanded(
                child: _DateChip(
                  label: 'To',
                  value: _fmt(_to),
                  isActive: _active == 'to',
                  onTap: () => setState(() {
                    _active = 'to';
                    _displayMonth = DateTime(_to.year, _to.month);
                  }),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Calendar ──────────────────────────────────────────────────────────────────
  Widget _buildCalendar() {
    final firstDay =
        DateTime(_displayMonth.year, _displayMonth.month, 1);
    final startOffset = firstDay.weekday % 7; // Sun=0
    final daysInMonth =
        DateTime(_displayMonth.year, _displayMonth.month + 1, 0).day;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        children: [
          // Month nav
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _NavBtn(icon: Icons.chevron_left_rounded, onTap: _prevMonth),
              Text(
                '${_months[_displayMonth.month - 1]} ${_displayMonth.year}',
                style: const TextStyle(
                  color: _textPri,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              _NavBtn(icon: Icons.chevron_right_rounded, onTap: _nextMonth),
            ],
          ),

          const SizedBox(height: 12),

          // Day-of-week labels
          Row(
            children: _days
                .map((d) => Expanded(
                      child: Center(
                        child: Text(
                          d,
                          style: const TextStyle(
                            color: _textSec,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),

          const SizedBox(height: 8),

          // Days grid
          _buildDaysGrid(startOffset, daysInMonth),
        ],
      ),
    );
  }

  Widget _buildDaysGrid(int startOffset, int daysInMonth) {
    final cells = <Widget>[];

    // Empty cells before first day
    for (int i = 0; i < startOffset; i++) {
      cells.add(const SizedBox());
    }

    for (int day = 1; day <= daysInMonth; day++) {
      final date =
          DateTime(_displayMonth.year, _displayMonth.month, day);
      final isFrom   = _isFrom(date);
      final isTo     = _isTo(date);
      final inRange  = _isInRange(date);
      final isEnd    = isFrom || isTo;
      final isToday  = _isSameDay(date, DateTime.now());

      cells.add(
        GestureDetector(
          onTap: () => _onDayTap(date),
          child: Container(
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: isEnd
                  ? _orange
                  : inRange
                      ? _orangeDim
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: isToday && !isEnd
                  ? Border.all(color: _orange.withOpacity(0.5), width: 1)
                  : null,
            ),
            child: Center(
              child: Text(
                '$day',
                style: TextStyle(
                  color: isEnd
                      ? Colors.white
                      : inRange
                          ? _orange
                          : isToday
                              ? _orange
                              : _textPri,
                  fontSize: 13,
                  fontWeight:
                      isEnd ? FontWeight.w700 : FontWeight.w400,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return GridView.count(
      crossAxisCount: 7,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.1,
      children: cells,
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  // ── Footer: quick presets + Apply ─────────────────────────────────────────
  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        children: [
          // Quick presets
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _PresetChip(
                  label: 'Last 7 days',
                  onTap: () => _applyPreset(7)),
              _PresetChip(
                  label: 'Last 30 days',
                  onTap: () => _applyPreset(30)),
              _PresetChip(
                  label: 'Last 90 days',
                  onTap: () => _applyPreset(90)),
              _PresetChip(
                  label: 'This month',
                  onTap: _applyThisMonth),
            ],
          ),

          const SizedBox(height: 14),

          // Buttons row
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _textSec,
                    side: const BorderSide(color: _border),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(
                    context,
                    DateFilterResult(from: _from, to: _to),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _orange,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Text(
                    'Apply',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _applyPreset(int days) {
    final now = DateTime.now();
    setState(() {
      _to   = now;
      _from = now.subtract(Duration(days: days));
      _displayMonth = DateTime(_from.year, _from.month);
    });
  }

  void _applyThisMonth() {
    final now = DateTime.now();
    setState(() {
      _from = DateTime(now.year, now.month, 1);
      _to   = now;
      _displayMonth = DateTime(now.year, now.month);
    });
  }
}

// ── Subwidgets ────────────────────────────────────────────────────────────────

class _DateChip extends StatelessWidget {
  final String label;
  final String value;
  final bool isActive;
  final VoidCallback onTap;

  const _DateChip({
    required this.label,
    required this.value,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? _orangeDim : _surfaceAlt,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive ? _orange.withOpacity(0.6) : _border,
            width: isActive ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isActive ? _orange : _textSec,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                color: _textPri,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _NavBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: _surfaceAlt,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _border),
        ),
        child: Icon(icon, color: _textSec, size: 18),
      ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _PresetChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: _surfaceAlt,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _borderHi),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: _textSec,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}