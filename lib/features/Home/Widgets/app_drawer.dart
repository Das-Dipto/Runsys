import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../Authentication/Providers/auth_providers.dart';
import '../../Profile/Screens/profile_screen.dart';
import '../../Home/Screens/home_screen.dart';
import '../../History/Screens/history_screen.dart';
import '../../Board/Screens/board_screen.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});



  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  static int _activeIndex = 1;

  // ── Dark theme palette (consistent with rest of app) ──
  static const Color _bg         = Color(0xFF0A0A0F);
  static const Color _surface    = Color(0xFF111118);
  static const Color _surfaceAlt = Color(0xFF16161F);
  static const Color _orange     = Color(0xFFFF7300);
  static const Color _textPri    = Color(0xFFFFFFFF);
  static const Color _textSec    = Color(0xFF8A8A9A);
  static const Color _border     = Color(0xFF1E1E2E);
  static const Color _borderHi   = Color(0xFF2A2A3A);

  final List<Map<String, dynamic>> _menuItems = const [
    {'icon': Icons.notifications_none_rounded, 'label': 'Notifications'},
    {'icon': Icons.playlist_add_check_rounded, 'label': 'My tasks'},
    {'icon': Icons.history_rounded,            'label': 'My history'},
    {'icon': Icons.calendar_today,             'label': 'Board'},
  ];

  String _initials(String fullName) {
    final parts = fullName.trim().split(' ').where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context, listen: false).user;

    return Drawer(
      backgroundColor: _surface,
      elevation: 0,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── App branding header ──
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: _orange.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: _orange.withOpacity(0.3), width: 1),
                        ),
                        child: Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CustomPaint(
                              painter: _BHouseLogoPainter(
                                color: _orange,
                                cutoutColor: _surface,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      RichText(
                        text: const TextSpan(
                          children: [
                            TextSpan(
                              text: 'Run',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w300,
                                color: _textPri,
                                letterSpacing: -0.6,
                              ),
                            ),
                            TextSpan(
                              text: 'sys',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: _orange,
                                letterSpacing: -0.6,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Padding(
                    padding: EdgeInsets.only(left: 54),
                    child: Text(
                      'operations',
                      style: TextStyle(
                        fontSize: 13,
                        color: _textSec,
                        letterSpacing: 0.3,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Divider(height: 1, thickness: 1, color: _border),

            const SizedBox(height: 12),

            // ── Menu items ──
            ...List.generate(_menuItems.length, (index) {
              return _DrawerItem(
                icon: _menuItems[index]['icon'] as IconData,
                label: _menuItems[index]['label'] as String,
                isActive: _activeIndex == index,
onTap: () {
  setState(() => _activeIndex = index);

  Future.delayed(const Duration(milliseconds: 150), () {
    Navigator.pop(context);

    if (index == 1) {
      // My tasks → HomeScreen
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else if (index == 2) {
      // My history → HistoryScreen
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const HistoryScreen()),
      );
    }else if (index == 3) {
      // Board → BoardScreen (to be created)
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const BoardScreen()),
      );
    }
  });
}

              );
            }),

            const Divider(height: 1, thickness: 1, color: _border),

            const Spacer(),

            // ── User profile footer ──
            Divider(height: 1, thickness: 1, color: _border),

            GestureDetector(
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
              },
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: _surfaceAlt,
                        shape: BoxShape.circle,
                        border: Border.all(color: _border, width: 1),
                      ),
                      child: Center(
                        child: Text(
                          _initials(user?.fullName ?? ''),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: _textPri,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.fullName ?? 'Unknown',
                            style: const TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w600,
                              color: _textPri,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            user?.department?.name ?? '',
                            style: TextStyle(fontSize: 13, color: _textSec),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.more_vert_rounded, color: _textSec, size: 22),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Single drawer menu item ──
class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: Material(
        color: isActive ? const Color(0x28FF7300) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 23,
                  color: isActive ? const Color(0xFFFF7300) : const Color(0xFF8A8A9A),
                ),
                const SizedBox(width: 18),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                    color: isActive ? const Color(0xFFFF7300) : const Color(0xFFFFFFFF),
                    letterSpacing: 0.1,
                  ),
                ),
                if (isActive) ...[
                  const Spacer(),
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF7300),
                      shape: BoxShape.circle,
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

// ── Logo painter (updated for orange accent) ──
class _BHouseLogoPainter extends CustomPainter {
  final Color color;
  final Color cutoutColor;

  const _BHouseLogoPainter({required this.color, required this.cutoutColor});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..style = PaintingStyle.fill;
    final w = size.width;
    final h = size.height;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.05, h * 0.04, w * 0.20, h * 0.72),
        const Radius.circular(3),
      ),
      paint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.22, h * 0.96)..lineTo(w * 0.82, h * 0.96)
        ..lineTo(w * 0.82, h * 0.52)..lineTo(w * 0.50, h * 0.18)
        ..lineTo(w * 0.22, h * 0.52)..close(),
      paint,
    );
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.30, h * 0.89)..lineTo(w * 0.74, h * 0.89)
        ..lineTo(w * 0.74, h * 0.56)..lineTo(w * 0.50, h * 0.35)
        ..lineTo(w * 0.30, h * 0.56)..close(),
      Paint()..color = cutoutColor..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(_) => false;
}