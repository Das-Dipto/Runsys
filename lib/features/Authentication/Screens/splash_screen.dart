import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'login_screen.dart';
import '../../Home/Screens/home_screen.dart';
import '../../Admin/Screens/admin_dashboard.dart';

import 'package:provider/provider.dart';
import '../Providers/auth_providers.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _logoController;
  late Animation<double> _logoFade;
  late Animation<double> _logoScale;

  late AnimationController _taglineController;
  late Animation<double> _taglineFade;
  late Animation<Offset> _taglineSlide;

  late AnimationController _loadingController;

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeIn),
    );
    _logoScale = Tween<double>(begin: 0.72, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOutBack),
    );

    _taglineController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
    _taglineFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _taglineController, curve: Curves.easeIn),
    );
    _taglineSlide = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _taglineController, curve: Curves.easeOutCubic),
    );

    _loadingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();

    _logoController.forward().then((_) {
      if (mounted) {
        Future.delayed(const Duration(milliseconds: 200), () {
          if (mounted) _taglineController.forward();
        });
      }
    });

    Future.delayed(const Duration(milliseconds: 2800), () async {
      if (!mounted) return;
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final success = await authProvider.tryAutoLogin();
      if (!mounted) return;

      if (success) {
        // ── Role-based routing on auto login ──
        final roleName =
            authProvider.user?.roleName.toLowerCase().trim() ?? '';
        final isAdmin = roleName == 'admin';

        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 500),
            pageBuilder: (_, __, ___) =>
                isAdmin ? const AdminDashboardScreen() : const HomeScreen(),
            transitionsBuilder: (_, anim, __, child) =>
                FadeTransition(opacity: anim, child: child),
          ),
        );
      } else {
        _navigate(); // goes to LoginScreen
      }
    });
  }

  void _navigate() {
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (context, animation, secondaryAnimation) =>
            const LoginScreen(),
        transitionsBuilder: (context, anim, secondaryAnimation, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _logoController.dispose();
    _taglineController.dispose();
    _loadingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    // ── Web-consistent palette ──
    const bgColor     = Color(0xFF0A0A0F);
    const orange      = Color(0xFFFF7300);
    const orangeAlt   = Color(0xFFFF8C00);
    const surfaceCard = Color(0xFF111118);

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          // ── Ambient radial glow — top center ──
          Positioned(
            top: -size.height * 0.18,
            left: size.width * 0.05,
            right: size.width * 0.05,
            child: AnimatedBuilder(
              animation: _loadingController,
              builder: (_, __) {
                final pulse = (0.7 +
                    0.3 *
                        (0.5 -
                            0.5 *
                                (2 * 3.14159 * _loadingController.value)
                                    .cos()));
                return Container(
                  height: size.height * 0.55,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        orange.withOpacity(0.20 * pulse),
                        orangeAlt.withOpacity(0.09 * pulse),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.4, 1.0],
                    ),
                  ),
                );
              },
            ),
          ),

          // ── Secondary bottom-left glow ──
          Positioned(
            bottom: -80,
            left: -60,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    orange.withOpacity(0.07),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // ── Dot grid background ──
          CustomPaint(
            size: size,
            painter: _DotGridPainter(orange),
          ),

          // ── Centered content ──
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FadeTransition(
                  opacity: _logoFade,
                  child: ScaleTransition(
                    scale: _logoScale,
                    child: Column(
                      children: [
                        // ── Logo container ──
                        Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            color: surfaceCard,
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(
                              color: orange.withOpacity(0.30),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: orange.withOpacity(0.28),
                                blurRadius: 48,
                                spreadRadius: 0,
                                offset: const Offset(0, 8),
                              ),
                              BoxShadow(
                                color: orange.withOpacity(0.12),
                                blurRadius: 80,
                                spreadRadius: 10,
                              ),
                            ],
                          ),
                          child: Center(
                            child: SizedBox(
                              width: 58,
                              height: 58,
                              child: CustomPaint(
                                painter: _ModernLogoMark(
                                    orange, orangeAlt, surfaceCard),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 28),

                        // ── Runsys wordmark ──
                        RichText(
                          text: const TextSpan(
                            children: [
                              TextSpan(
                                text: 'Run',
                                style: TextStyle(
                                  fontSize: 42,
                                  fontWeight: FontWeight.w300,
                                  color: Colors.white,
                                  letterSpacing: 1.5,
                                  height: 1.0,
                                ),
                              ),
                              TextSpan(
                                text: 'sys',
                                style: TextStyle(
                                  fontSize: 42,
                                  fontWeight: FontWeight.w800,
                                  color: orange,
                                  letterSpacing: 1.5,
                                  height: 1.0,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 8),

                        // ── Orange ornament line ──
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 30,
                              height: 1,
                              color: orange.withOpacity(0.35),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 4,
                              height: 4,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: orange.withOpacity(0.70),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 30,
                              height: 1,
                              color: orange.withOpacity(0.35),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                // ── Tagline ──
                FadeTransition(
                  opacity: _taglineFade,
                  child: SlideTransition(
                    position: _taglineSlide,
                    child: Text(
                      'Complete property management platform',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: Colors.white.withOpacity(0.45),
                        letterSpacing: 1.4,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 80),

                // ── Shimmer bar loader ──
                _ShimmerBarLoader(
                  controller: _loadingController,
                  accentColor: orange,
                ),
              ],
            ),
          ),

          // ── Version pill ──
          Positioned(
            bottom: 36,
            left: 0,
            right: 0,
            child: FadeTransition(
              opacity: _taglineFade,
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: orange.withOpacity(0.20),
                    ),
                    borderRadius: BorderRadius.circular(20),
                    color: orange.withOpacity(0.06),
                  ),
                  child: Text(
                    'v 1.0.0',
                    style: TextStyle(
                      fontSize: 11,
                      color: orange.withOpacity(0.55),
                      letterSpacing: 1.8,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shimmer bar loader ────────────────────────────────────────────────────────
class _ShimmerBarLoader extends StatelessWidget {
  final AnimationController controller;
  final Color accentColor;

  const _ShimmerBarLoader({
    required this.controller,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        return SizedBox(
          width: 140,
          height: 3,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: 0.38,
                  child: Transform.translate(
                    offset: Offset(
                      (controller.value * 140 * (1 / 0.38)) - 140 * 0.5,
                      0,
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            accentColor.withOpacity(0.90),
                            Colors.transparent,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Dot grid background painter ───────────────────────────────────────────────
class _DotGridPainter extends CustomPainter {
  final Color orange;
  _DotGridPainter(this.orange);

  @override
  void paint(Canvas canvas, Size size) {
    final dotPaint = Paint()
      ..color = orange.withOpacity(0.06)
      ..style = PaintingStyle.fill;

    const spacing = 44.0;
    for (double x = spacing; x < size.width; x += spacing) {
      for (double y = spacing; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.2, dotPaint);
      }
    }

    final linePaint = Paint()
      ..color = orange.withOpacity(0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (int i = 0; i < 5; i++) {
      final offset = i * 22.0;
      canvas.drawLine(
        Offset(0, 60 + offset),
        Offset(60 + offset, 0),
        linePaint,
      );
    }

    for (int i = 0; i < 5; i++) {
      final offset = i * 22.0;
      canvas.drawLine(
        Offset(size.width, size.height - 60 - offset),
        Offset(size.width - 60 - offset, size.height),
        linePaint,
      );
    }

    final circlePaint = Paint()
      ..color = orange.withOpacity(0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawCircle(
        Offset(size.width * 0.82, size.height * 0.18), 120, circlePaint);
    canvas.drawCircle(
        Offset(size.width * 0.82, size.height * 0.18), 75, circlePaint);
    canvas.drawCircle(
        Offset(size.width * 0.15, size.height * 0.85), 90, circlePaint);
  }

  @override
  bool shouldRepaint(_) => false;
}

// ── Modern "R" logo mark ──────────────────────────────────────────────────────
class _ModernLogoMark extends CustomPainter {
  final Color orange;
  final Color orangeAlt;
  final Color cutout;
  _ModernLogoMark(this.orange, this.orangeAlt, this.cutout);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final solidPaint = Paint()
      ..color = orange
      ..style = PaintingStyle.fill;

    final lightPaint = Paint()
      ..color = orangeAlt
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = orange.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final barW = w * 0.14;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.08, h * 0.08, barW, h * 0.84),
        const Radius.circular(3),
      ),
      solidPaint,
    );

    final bumpPath = Path()
      ..moveTo(w * 0.08 + barW, h * 0.08)
      ..lineTo(w * 0.72, h * 0.08)
      ..quadraticBezierTo(w * 0.92, h * 0.08, w * 0.92, h * 0.30)
      ..quadraticBezierTo(w * 0.92, h * 0.50, w * 0.68, h * 0.50)
      ..lineTo(w * 0.08 + barW, h * 0.50)
      ..close();
    canvas.drawPath(bumpPath, lightPaint);

    final legPath = Path()
      ..moveTo(w * 0.22 + barW * 0.3, h * 0.50)
      ..lineTo(w * 0.92, h * 0.92)
      ..lineTo(w * 0.76, h * 0.92)
      ..lineTo(w * 0.08 + barW, h * 0.56)
      ..close();
    canvas.drawPath(legPath, solidPaint);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
            w * 0.22 + barW * 0.3, h * 0.18, w * 0.44, h * 0.22),
        const Radius.circular(3),
      ),
      Paint()
        ..color = cutout
        ..style = PaintingStyle.fill,
    );

    canvas.drawCircle(Offset(w * 0.82, h * 0.78), 4, solidPaint);
    canvas.drawCircle(Offset(w * 0.82, h * 0.78), 7, strokePaint);
  }

  @override
  bool shouldRepaint(_) => false;
}

extension on double {
  double cos() =>
      1 -
      2 *
          (this % (2 * 3.14159) / (2 * 3.14159) - 0.5).abs() *
          2;
}