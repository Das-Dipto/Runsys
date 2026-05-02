import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../Authentication/Providers/auth_providers.dart';
import '../Widgets/admin_drawer.dart';
import '../Widgets/admin_task_table.dart';
import '../../Admin/Widgets/date_ramge_dialog.dart';   // ← Make sure this path is correct

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  static const Color _bg = Color(0xFF0A0A0F);
  static const Color _surface = Color(0xFF111118);
  static const Color _orange = Color(0xFFFF7300);
  static const Color _textPri = Color(0xFFFFFFFF);
  static const Color _textSec = Color(0xFF8A8A9A);
  static const Color _border = Color(0xFF1E1E2E);

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String _selectedStatus = 'Active';
  DateFilterResult? _selectedDateFilter;   // Changed to match your dialog

  Future<void> _showDateRangeDialog() async {
    final result = await showDateFilterDialog(
      context,
      initialFrom: _selectedDateFilter?.from,
      initialTo: _selectedDateFilter?.to,
    );

    if (result != null) {
      setState(() => _selectedDateFilter = result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: _bg,
      drawer: const AdminDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(user?.fullName ?? 'Admin'),
            _buildSubBar(),
            const Expanded(child: AdminTaskTable()),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(String userName) {
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
          const Text('All Tasks',
              style: TextStyle(
                  color: _textPri,
                  fontWeight: FontWeight.w600,
                  fontSize: 15)),
          const Spacer(),
          GestureDetector(
            onTap: () {},
            child: Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: _orange,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                      color: _orange.withOpacity(0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 3))
                ],
              ),
              child: const Row(children: [
                Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 14),
                SizedBox(width: 6),
                Text('Create a task',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13)),
                SizedBox(width: 6),
                Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 13),
              ]),
            ),
          ),
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
          _StatusDropdown(
            value: _selectedStatus,
            onChanged: (v) => setState(() => _selectedStatus = v ?? 'Active'),
          ),
          const SizedBox(width: 12),

          // Date Icon
          IconButton(
            icon: const Icon(Icons.calendar_today_outlined,
                color: _textSec, size: 20),
            onPressed: _showDateRangeDialog,
            tooltip: 'Select Date Range',
          ),

          const SizedBox(width: 8),

          IconButton(
            icon: const Icon(Icons.filter_alt_outlined,
                color: _textSec, size: 20),
            onPressed: () {},
          ),

          const Spacer(),
          const Icon(Icons.chevron_left_rounded, color: _textSec, size: 20),
          const SizedBox(width: 2),
          const Icon(Icons.chevron_right_rounded, color: _textSec, size: 20),
        ],
      ),
    );
  }
}

// Status Dropdown
class _StatusDropdown extends StatelessWidget {
  final String value;
  final ValueChanged<String?> onChanged;

  const _StatusDropdown({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: const Color(0x18FF7300),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFF7300).withOpacity(0.35)),
      ),
      child: DropdownButton<String>(
        value: value,
        underline: const SizedBox(),
        icon: const Icon(Icons.keyboard_arrow_down_rounded,
            color: Colors.white, size: 18),
        dropdownColor: const Color(0xFF1E1E2E),
        style: const TextStyle(
            color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
        items: const [
          DropdownMenuItem(value: 'Active', child: Text('Active')),
          DropdownMenuItem(value: 'All Tasks', child: Text('All Tasks')),
        ],
        onChanged: onChanged,
      ),
    );
  }
}