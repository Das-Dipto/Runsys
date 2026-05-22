// lib/Admin/Screens/assigned_tasks_screen.dart
import 'package:flutter/material.dart';
import '../../Dashboard/Widgets/admin_drawer.dart';
import '../Widgets/assigned_tasks_table.dart';

class AssignedTasksScreen extends StatefulWidget {
  const AssignedTasksScreen({super.key});

  @override
  State<AssignedTasksScreen> createState() => _AssignedTasksScreenState();
}

class _AssignedTasksScreenState extends State<AssignedTasksScreen> {
  static const Color _bg      = Color(0xFF0A0A0F);
  static const Color _surface = Color(0xFF111118);
  static const Color _border  = Color(0xFF1E1E2E);
  static const Color _textPri = Color(0xFFFFFFFF);
  static const Color _textSec = Color(0xFF8A8A9A);
  static const Color _orange  = Color(0xFFFF7300);

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String _selectedDateFilter = 'All Tasks';

  // Summary counts (dummy — replace with real data)
  final int _totalTasks   = 20;
  final int _pendingTasks = 14;
  final int _completedTasks = 0;

  Future<void> _showDateFilterDialog() async {
    final options = ['Today', 'This Week', 'This Month', 'Last Month', 'All Tasks'];
    final result = await showDialog<String>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.65),
      builder: (ctx) => _DateQuickFilterDialog(
        selected: _selectedDateFilter,
        options: options,
      ),
    );
    if (result != null) setState(() => _selectedDateFilter = result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: _bg,
      drawer: const AdminDrawer(activeMenu: 'Assigned Tasks'),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(),
            _buildSummaryRow(),
            _buildSubBar(),
            const Expanded(child: AssignedTaskTable()),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: _surface,
        border: Border(bottom: BorderSide(color: _border, width: 1)),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.menu_rounded, color: _textPri, size: 22),
            onPressed: () => _scaffoldKey.currentState?.openDrawer(),
          ),
          const SizedBox(width: 12),
          const Text(
            'Assigned Tasks',
            style: TextStyle(color: _textPri, fontWeight: FontWeight.w600, fontSize: 15),
          ),
        ],
      ),
    );
  }

Widget _buildSummaryRow() {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    decoration: BoxDecoration(
      color: _surface,
      border: Border(bottom: BorderSide(color: _border, width: 1)),
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        _SummaryCard(label: 'Total Tasks', value: '$_totalTasks',     icon: Icons.task_alt_rounded,             iconColor: Colors.blue),
        const SizedBox(width: 12),
        _SummaryCard(label: 'Pending',     value: '$_pendingTasks',   icon: Icons.hourglass_empty_rounded,      iconColor: _orange),
        const SizedBox(width: 12),
        _SummaryCard(label: 'Completed',   value: '$_completedTasks', icon: Icons.check_circle_outline_rounded, iconColor: Colors.green),
      ],
    ),
  );
}

  Widget _buildSubBar() {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: _bg,
        border: Border(bottom: BorderSide(color: _border, width: 1)),
      ),
      child: Row(
        children: [
          // Date filter chip
          GestureDetector(
            onTap: _showDateFilterDialog,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0x18FF7300),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _orange.withOpacity(0.35)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.calendar_today_outlined, color: _orange, size: 15),
                  const SizedBox(width: 6),
                  Text(
                    _selectedDateFilter,
                    style: const TextStyle(color: _orange, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.keyboard_arrow_down_rounded, color: _orange, size: 16),
                ],
              ),
            ),
          ),

          const SizedBox(width: 10),

          // Filter icon
          IconButton(
            icon: const Icon(Icons.filter_alt_outlined, color: _textSec, size: 20),
            onPressed: () {},
            tooltip: 'Filter',
          ),
        ],
      ),
    );
  }
}

// ── Summary Card ──────────────────────────────────────────────────────────────
class _SummaryCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF16161F),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1E1E2E)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 18),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(value,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12)),
              Text(label,
                  style: const TextStyle(color: Color(0xFF8A8A9A), fontSize: 8)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Date Quick Filter Dialog ──────────────────────────────────────────────────
class _DateQuickFilterDialog extends StatelessWidget {
  final String selected;
  final List<String> options;

  const _DateQuickFilterDialog({required this.selected, required this.options});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF111118),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFF1E1E2E)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: options.map((opt) {
            final isActive = opt == selected;
            return ListTile(
              dense: true,
              onTap: () => Navigator.pop(context, opt),
              leading: Icon(
                isActive ? Icons.radio_button_checked : Icons.radio_button_off,
                color: isActive ? const Color(0xFFFF7300) : const Color(0xFF8A8A9A),
                size: 18,
              ),
              title: Text(
                opt,
                style: TextStyle(
                  color: isActive ? Colors.white : const Color(0xFF8A8A9A),
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  fontSize: 14,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}