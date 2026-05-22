// lib/Admin/Screens/settings_screen.dart
import 'package:flutter/material.dart';
import '../../../Admin/Dashboard/Widgets/admin_drawer.dart';
import 'manage_users_screen.dart';
import 'company_info_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static const Color _bg      = Color(0xFF0A0A0F);
  static const Color _surface = Color(0xFF111118);
  static const Color _border  = Color(0xFF1E1E2E);
  static const Color _textPri = Color(0xFFFFFFFF);
  static const Color _textSec = Color(0xFF8A8A9A);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
     drawer: const AdminDrawer(activeMenu: 'Settings'),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top bar
            Container(
              height: 56,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: const BoxDecoration(
                color: _surface,
                border: Border(bottom: BorderSide(color: _border, width: 1)),
              ),
              child: Row(
                children: [
                  Builder(
                    builder: (ctx) => IconButton(
                      icon: const Icon(Icons.menu_rounded, color: _textPri, size: 22),
                      onPressed: () => Scaffold.of(ctx).openDrawer(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.settings_rounded, color: _textPri, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Settings',
                    style: TextStyle(
                        color: _textPri,
                        fontWeight: FontWeight.w600,
                        fontSize: 15),
                  ),
                ],
              ),
            ),

            // Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Team Management ──
                    _sectionLabel('Team Management', Icons.people_alt_outlined, Colors.blue),
                    const SizedBox(height: 14),
                    _SettingsCard(
                      icon: Icons.manage_accounts_rounded,
                      iconBgColor: Colors.indigo,
                      title: 'Manage Users',
                      subtitle: 'Add, edit, or remove team members',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const ManageUsersScreen()),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // ── Workspace ──
                    _sectionLabel('Workspace', Icons.grid_view_rounded, Colors.green),
                    const SizedBox(height: 14),
                    _SettingsCard(
                      icon: Icons.business_rounded,
                      iconBgColor: Colors.teal,
                      title: 'Company Info',
                      subtitle: 'Manage organization details',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CompanyInfoScreen()),
                      ),
                    ),

                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
              color: Color(0xFFFFFFFF),
              fontSize: 15,
              fontWeight: FontWeight.w700),
        ),
        const SizedBox(width: 12),
        const Expanded(child: Divider(color: Color(0xFF1E1E2E))),
      ],
    );
  }
}

// ── Settings Card ─────────────────────────────────────────────────────────────
class _SettingsCard extends StatelessWidget {
  final IconData icon;
  final Color iconBgColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SettingsCard({
    required this.icon,
    required this.iconBgColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF111118),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF1E1E2E)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconBgColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconBgColor, size: 22),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: const TextStyle(color: Color(0xFF8A8A9A), fontSize: 13),
            ),
            const SizedBox(height: 16),
            const Text(
              'Configure →',
              style: TextStyle(
                  color: Color(0xFF8A8A9A),
                  fontSize: 13,
                  fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }
}