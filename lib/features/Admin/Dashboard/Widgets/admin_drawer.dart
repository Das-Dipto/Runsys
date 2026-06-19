import 'package:Runsys/features/Admin/Dashboard/Screens/admin_dashboard.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../Authentication/Providers/auth_providers.dart';
import '../../../Authentication/Screens/login_screen.dart';
import '../../Assigned_Tasks/Screens/assigned_tasks_screen.dart';
import '../../Properties/Screens/properties_screen.dart';
import '../../Settings/Screens/settings_screen.dart';

class AdminDrawer extends StatelessWidget {
  final String activeMenu;

  const AdminDrawer({super.key, this.activeMenu = 'Properties'});

  static const Color _bg        = Color(0xFF0D0D14);
  static const Color _orange    = Color(0xFFFF7300);
  static const Color _orangeDim = Color(0x22FF7300);
  static const Color _textPri   = Color(0xFFFFFFFF);
  static const Color _textSec   = Color(0xFF8A8A9A);
  static const Color _border    = Color(0xFF1E1E2E);

  void _showLogoutSheet(BuildContext rootContext) {
    showModalBottomSheet(
      context: rootContext,
      backgroundColor: const Color(0xFF111118),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A3A),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6B6B).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFFF6B6B).withOpacity(0.3)),
                  ),
                  child: const Icon(Icons.logout_rounded, color: Color(0xFFFF6B6B), size: 20),
                ),
                const SizedBox(width: 14),
                const Text('Sign out?',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              'You will be signed out of your account',
              style: TextStyle(fontSize: 13, color: Color(0xFF8A8A9A), height: 1.6),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(sheetContext),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF8A8A9A),
                      side: const BorderSide(color: Color(0xFF1E1E2E)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      Navigator.pop(sheetContext);

                      showDialog(
                        context: rootContext,
                        barrierDismissible: false,
                        barrierColor: Colors.black.withOpacity(0.7),
                        builder: (_) => Dialog(
                          backgroundColor: const Color(0xFF16161F),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                            side: BorderSide(color: const Color(0xFFFF6B6B).withOpacity(0.3), width: 1),
                          ),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 32, vertical: 28),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFF6B6B)),
                                  ),
                                ),
                                SizedBox(width: 18),
                                Text('Signing out…',
                                    style: TextStyle(fontSize: 15, color: Colors.white, fontWeight: FontWeight.w500)),
                              ],
                            ),
                          ),
                        ),
                      );

                      final auth = Provider.of<AuthProvider>(rootContext, listen: false);
                      await auth.logout();

                      if (!rootContext.mounted) return;
                      Navigator.of(rootContext).pop(); // pop loading dialog
                      Navigator.pushAndRemoveUntil(
                        rootContext,
                        PageRouteBuilder(
                          transitionDuration: const Duration(milliseconds: 500),
                          pageBuilder: (_, __, ___) => const LoginScreen(),
                          transitionsBuilder: (_, anim, __, child) =>
                              FadeTransition(opacity: anim, child: child),
                        ),
                        (route) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6B6B),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Sign out', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final rootContext = Navigator.of(context).context;

    return Drawer(
      backgroundColor: _bg,
      width: 270,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
            Container(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: _border, width: 1)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RichText(
                    text: const TextSpan(
                      children: [
                        TextSpan(
                          text: 'Run',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w300,
                            color: _textPri,
                            letterSpacing: 0.5,
                          ),
                        ),
                        TextSpan(
                          text: 'sys',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: _orange,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _orangeDim,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _orange.withOpacity(0.35), width: 1),
                        ),
                        child: Center(
                          child: Text(
                            user?.fullName.isNotEmpty == true
                                ? user!.fullName[0].toUpperCase()
                                : 'A',
                            style: const TextStyle(
                              color: _orange,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user?.fullName ?? 'Admin',
                              style: const TextStyle(
                                color: _textPri,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: _orangeDim,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: _orange.withOpacity(0.3), width: 1),
                              ),
                              child: const Text(
                                'Admin',
                                style: TextStyle(
                                  color: _orange,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                'MENU',
                style: TextStyle(
                  fontSize: 10,
                  color: _textSec.withOpacity(0.6),
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.8,
                ),
              ),
            ),

            _DrawerMenuItem(
              icon: Icons.domain_rounded,
              label: 'Properties',
              isActive: activeMenu == 'Properties',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PropertiesScreen()),
                );
              },
            ),

            _DrawerMenuItem(
              icon: Icons.task_alt_rounded,
              label: 'Tasks',
              isActive: activeMenu == 'Tasks',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AdminDashboardScreen()),
                );
              },
            ),

            _DrawerMenuItem(
              icon: Icons.date_range_rounded,
              label: 'Assigned Tasks',
              isActive: activeMenu == 'Assigned Tasks',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AssignedTasksScreen()),
                );
              },
            ),

            const Spacer(),

            // ── Logout ──
            Container(
              margin: const EdgeInsets.fromLTRB(12, 0, 12, 16),
              child: _DrawerMenuItem(
                icon: Icons.logout_rounded,
                label: 'Sign Out',
                isActive: false,
                isLogout: true,
                onTap: () {
                  Navigator.pop(context); // close drawer
                  _showLogoutSheet(rootContext);
                },
              ),
            ),

            Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Center(
                child: Text(
                  'v 1.0.0',
                  style: TextStyle(
                    fontSize: 11,
                    color: _textSec.withOpacity(0.4),
                    letterSpacing: 1.4,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Drawer menu item ──────────────────────────────────────────────────────────
class _DrawerMenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final bool isLogout;
  final VoidCallback onTap;

  const _DrawerMenuItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
    this.isLogout = false,
  });

  static const Color _orange    = Color(0xFFFF7300);
  static const Color _orangeDim = Color(0x22FF7300);
  static const Color _textPri   = Color(0xFFFFFFFF);
  static const Color _textSec   = Color(0xFF8A8A9A);

  @override
  Widget build(BuildContext context) {
    final color = isLogout
        ? const Color(0xFFFF6B6B)
        : isActive
            ? _orange
            : _textSec;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          splashColor: _orange.withOpacity(0.08),
          highlightColor: _orange.withOpacity(0.05),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              color: isActive ? _orangeDim : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isActive ? _orange.withOpacity(0.25) : Colors.transparent,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 18),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    color: isActive ? _textPri : color,
                    fontSize: 14,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
                if (isActive) ...[
                  const Spacer(),
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: _orange,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}