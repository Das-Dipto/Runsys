// lib/Admin/Screens/properties_screen.dart
import 'package:flutter/material.dart';
import '../../Dashboard/Widgets/admin_drawer.dart';
import '../Widgets/properties_table.dart';
import '../Widgets/add_property_dialog.dart';

class PropertiesScreen extends StatefulWidget {
  const PropertiesScreen({super.key});

  @override
  State<PropertiesScreen> createState() => _PropertiesScreenState();
}

class _PropertiesScreenState extends State<PropertiesScreen> {
  static const Color _bg      = Color(0xFF0A0A0F);
  static const Color _surface = Color(0xFF111118);
  static const Color _border  = Color(0xFF1E1E2E);
  static const Color _textPri = Color(0xFFFFFFFF);
  static const Color _orange  = Color(0xFFFF7300);

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Dummy counts — replace with real data
  final int _totalProperties    = 5;
  final int _activeProperties   = 5;
  final int _inactiveProperties = 0;
  final int _withIssues         = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: _bg,
      drawer: const AdminDrawer(activeMenu: 'Properties'),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTopBar(),
            _buildStatsSection(),
            _buildFilterBar(),
             Expanded(child: PropertiesTable()),
          ],
        ),
      ),
    );
  }

  // ── Top bar ────────────────────────────────────────────────────────────────
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
          const SizedBox(width: 8),
          const Text(
            'Properties',
            style: TextStyle(
                color: _textPri, fontWeight: FontWeight.w600, fontSize: 15),
          ),
          const Spacer(),
          // Add Property button
          GestureDetector(
            onTap: () => showDialog(
              context: context,
              builder: (_) => const AddPropertyDialog(),
            ),
            child: Container(
              height: 36,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: _orange,
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: _orange.withOpacity(0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.auto_awesome_rounded,
                      color: Colors.white, size: 14),
                  SizedBox(width: 6),
                  Text(
                    '+ Add Property',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 13),
                  ),
                  SizedBox(width: 6),
                  Icon(Icons.arrow_forward_rounded,
                      color: Colors.white, size: 13),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  // ── Stats: 2 rows × 2 cards ────────────────────────────────────────────────
  Widget _buildStatsSection() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: _surface,
        border: Border(bottom: BorderSide(color: _border, width: 1)),
      ),
      child: Column(
        children: [
          // Row 1
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Total Properties',
                  value: '$_totalProperties',
                  sub: 'All properties',
                  icon: Icons.domain_rounded,
                  iconBgColor: Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  label: 'Active Properties',
                  value: '$_activeProperties',
                  sub: '100% of total ↑',
                  subColor: Colors.green,
                  icon: Icons.check_circle_outline_rounded,
                  iconBgColor: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Row 2
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  label: 'Inactive Properties',
                  value: '$_inactiveProperties',
                  sub: '0% of total ↓',
                  subColor: Colors.red,
                  icon: Icons.cancel_outlined,
                  iconBgColor: Colors.grey,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  label: 'With Issues',
                  value: '$_withIssues',
                  sub: '0 need attention',
                  icon: Icons.error_outline_rounded,
                  iconBgColor: _orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Filter bar ─────────────────────────────────────────────────────────────
  Widget _buildFilterBar() {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: _bg,
        border: Border(bottom: BorderSide(color: _border, width: 1)),
      ),
      child: Row(
        children: [
          // Filter button with icon + text
          GestureDetector(
            onTap: () {}, // TODO: open filter panel
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0xFF16161F),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _border),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.filter_alt_outlined,
                      color: Color(0xFF8A8A9A), size: 17),
                  SizedBox(width: 6),
                  Text(
                    'Filter',
                    style: TextStyle(
                        color: Color(0xFF8A8A9A),
                        fontSize: 13,
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stat Card ──────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  final Color? subColor;
  final IconData icon;
  final Color iconBgColor;

  const _StatCard({
    required this.label,
    required this.value,
    required this.sub,
    this.subColor,
    required this.icon,
    required this.iconBgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF16161F),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF1E1E2E)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                      color: Color(0xFF8A8A9A), fontSize: 11),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  sub,
                  style: TextStyle(
                      color: subColor ?? const Color(0xFF8A8A9A),
                      fontSize: 11),
                ),
              ],
            ),
          ),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBgColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconBgColor, size: 20),
          ),
        ],
      ),
    );
  }
}