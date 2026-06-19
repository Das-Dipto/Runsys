import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../Providers/auth_providers.dart';
import '../../Home/Screens/home_screen.dart';
import '../../Admin/Dashboard/Screens/admin_dashboard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  late AnimationController _glowController;
  late Animation<double> _glowAnim;

  late AnimationController _shimmerController;
  late Animation<double> _shimmerAnim;

  // ── Web-consistent palette ──
  static const Color _bg         = Color(0xFF0A0A0F);
  static const Color _surface    = Color(0xFF111118);
  static const Color _surfaceAlt = Color(0xFF16161F);
  static const Color _orange     = Color(0xFFFF7300);
  static const Color _orangeAlt  = Color(0xFFFF8C00);
  static const Color _orangeDim  = Color(0x28FF7300);
  static const Color _textPri    = Color(0xFFFFFFFF);
  static const Color _textSec    = Color(0xFF8A8A9A);
  static const Color _border     = Color(0xFF1E1E2E);
  static const Color _borderHi   = Color(0xFF2A2A3A);
  static const Color _error      = Color(0xFFFF6B6B);

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeIn),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _glowController, curve: Curves.easeInOut),
    );

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat();
    _shimmerAnim = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );

    _animController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _animController.dispose();
    _glowController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.7),
      builder: (_) => Dialog(
        backgroundColor: _surfaceAlt,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: _orange.withOpacity(0.3), width: 1),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(_orange),
                ),
              ),
              const SizedBox(width: 18),
              const Text(
                'Signing you in…',
                style: TextStyle(
                  fontSize: 15,
                  color: _textPri,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        backgroundColor: const Color(0xFF1A0F0F),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: _error, width: 1),
        ),
        content: Row(
          children: [
            const Icon(Icons.error_outline_rounded, color: _error, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                    color: _textPri, fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _showLoadingDialog();

    final remember = _rememberMe ? 'Y' : 'N';
    final result = await authProvider.login(
      _emailController.text.trim(),
      _passwordController.text.trim(),
      remember,
    );

    if (!mounted) return;
    Navigator.of(context).pop();

    if (result['success'] == true) {
      final roleName = authProvider.user?.roleName.toLowerCase().trim() ?? '';
      final isAdmin = roleName == 'admin';

      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 500),
          pageBuilder: (context, animation, secondaryAnimation) =>
              isAdmin ? const AdminDashboardScreen() : const HomeScreen(),
          transitionsBuilder: (context, anim, secondaryAnimation, child) =>
              FadeTransition(opacity: anim, child: child),
        ),
      );
    } else {
      _showError(
          result['message'] ?? 'Incorrect email or password. Please try again.');
    }
  }

  void _onForgotPassword() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _surfaceAlt,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 14, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: _borderHi,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: _orangeDim,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _orange.withOpacity(0.3)),
                  ),
                  child: const Icon(Icons.lock_reset_rounded,
                      color: _orange, size: 20),
                ),
                const SizedBox(width: 14),
                const Text(
                  'Forgot Password?',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: _textPri),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Contact your administrator or check your registered email for a password reset link.',
              style: TextStyle(fontSize: 13, color: _textSec, height: 1.7),
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _orange,
                  side: BorderSide(color: _orange.withOpacity(0.6)),
                  shape: const StadiumBorder(),
                ),
                child: const Text('Got it',
                    style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration({
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) =>
      InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: _textSec.withOpacity(0.6), fontSize: 14),
        filled: true,
        fillColor: _surface,
        prefixIcon: Icon(icon, color: _textSec, size: 18),
        suffixIcon: suffix,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _orange, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _error, width: 1.5),
        ),
        errorStyle: const TextStyle(color: _error, fontSize: 12),
      );

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          // ── Ambient radial glow — top center ──
          AnimatedBuilder(
            animation: _glowAnim,
            builder: (_, __) => Positioned(
              top: -size.height * 0.15,
              left: size.width * 0.05,
              right: size.width * 0.05,
              child: Container(
                height: size.height * 0.55,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      _orange.withOpacity(0.18 * _glowAnim.value),
                      _orangeAlt.withOpacity(0.08 * _glowAnim.value),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.4, 1.0],
                  ),
                ),
              ),
            ),
          ),

          // ── Secondary bottom glow ──
          Positioned(
            bottom: -80,
            left: -60,
            child: Container(
              width: 240,
              height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    _orange.withOpacity(0.07),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // ── Main scrollable content ──
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 56),

                        // ── Logo icon + Runsys name + tagline ──
                        Center(
                          child: Column(
                            children: [
                              Container(
                                width: 68,
                                height: 68,
                                decoration: BoxDecoration(
                                  color: _orange,
                                  borderRadius: BorderRadius.circular(18),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color.fromARGB(255, 255, 115, 0).withOpacity(0.40),
                                      blurRadius: 32,
                                      spreadRadius: 0,
                                      offset: const Offset(0, 8),
                                    ),
                                    BoxShadow(
                                      // color: const Color(0xFF9029FF).withOpacity(0.18),
                                      color: const Color.fromARGB(255, 255, 115, 0).withOpacity(0.40),
                                      blurRadius: 60,
                                      spreadRadius: 8,
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Image.asset(
                                    'assets/icons/runsys-white-icon.png',
                                    width: 38,
                                    height: 38,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),

                              RichText(
                                text: const TextSpan(
                                  children: [
                                    TextSpan(
                                      text: 'Run',
                                      style: TextStyle(
                                        fontSize: 36,
                                        fontWeight: FontWeight.w300,
                                        color: _textPri,
                                        letterSpacing: 0.5,
                                        height: 1.0,
                                      ),
                                    ),
                                    TextSpan(
                                      text: 'sys',
                                      style: TextStyle(
                                        fontSize: 36,
                                        fontWeight: FontWeight.w800,
                                        color: _orange,
                                        letterSpacing: 0.5,
                                        height: 1.0,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 10),

                              const Text(
                                'Complete property management platform',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: _textSec,
                                  fontWeight: FontWeight.w400,
                                  letterSpacing: 0.1,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 44),

                        // ── Form card ──
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: _surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: _border, width: 1),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.4),
                                blurRadius: 40,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // ── Email ──
                              const _FieldLabel(text: 'Email Address'),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                style: const TextStyle(
                                    color: _textPri, fontSize: 14),
                                decoration: _fieldDecoration(
                                  hint: 'hello@example.com',
                                  icon: Icons.alternate_email_rounded,
                                ),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return 'Email is required';
                                  }
                                  if (!v.contains('@') || !v.contains('.')) {
                                    return 'Enter a valid email address';
                                  }
                                  return null;
                                },
                              ),

                              const SizedBox(height: 20),

                              // ── Password ──
                              const _FieldLabel(text: 'Password'),
                              const SizedBox(height: 8),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                style: const TextStyle(
                                    color: _textPri, fontSize: 14),
                                decoration: _fieldDecoration(
                                  hint: '••••••••',
                                  icon: Icons.lock_outline_rounded,
                                  suffix: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      size: 18,
                                      color: _textSec,
                                    ),
                                    onPressed: () => setState(() =>
                                        _obscurePassword = !_obscurePassword),
                                  ),
                                ),
                                validator: (v) {
                                  if (v == null || v.trim().isEmpty) {
                                    return 'Password is required';
                                  }
                                  if (v.length < 6) {
                                    return 'Password must be at least 6 characters';
                                  }
                                  return null;
                                },
                              ),

                              const SizedBox(height: 16),

                              // ── Remember me | Forgot password ──
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: Checkbox(
                                          value: _rememberMe,
                                          onChanged: (v) => setState(
                                              () => _rememberMe = v ?? false),
                                          activeColor: _orange,
                                          checkColor: Colors.white,
                                          side: const BorderSide(
                                              color: _borderHi, width: 1.5),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Text(
                                        'Remember me',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: _textSec,
                                        ),
                                      ),
                                    ],
                                  ),
                                  GestureDetector(
                                    onTap: _onForgotPassword,
                                    child: const Text(
                                      'Forgot password?',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: _orange,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // ── Sign In button ──
                        AnimatedBuilder(
                          animation: _shimmerAnim,
                          builder: (_, __) => SizedBox(
                            width: double.infinity,
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                padding: EdgeInsets.zero,
                              ),
                              child: Ink(
                                decoration: BoxDecoration(
                                  color: _surface,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                      color: _border, width: 1),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _orange.withOpacity(0.22),
                                      blurRadius: 24,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Container(
                                  alignment: Alignment.center,
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      ShaderMask(
                                        shaderCallback: (bounds) =>
                                            const LinearGradient(
                                          colors: [
                                            Color(0xFFFF7300),
                                            Color(0xFFFF8C00),
                                            Color(0xFFFF7300),
                                          ],
                                        ).createShader(bounds),
                                        child: const Icon(
                                          Icons.auto_awesome_rounded,
                                          color: Colors.white,
                                          size: 18,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Stack(
                                        clipBehavior: Clip.none,
                                        children: [
                                          const Text(
                                            'Sign In',
                                            style: TextStyle(
                                              fontSize: 17,
                                              fontWeight: FontWeight.w700,
                                              color: _textPri,
                                              letterSpacing: 0.2,
                                            ),
                                          ),
                                          Positioned(
                                            bottom: -3,
                                            left: 0,
                                            right: 0,
                                            child: Container(
                                              height: 2,
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  colors: [
                                                    _orange.withOpacity(0.2),
                                                    _orange,
                                                    _orange.withOpacity(0.2),
                                                  ],
                                                  stops: [
                                                    (_shimmerAnim.value - 0.5)
                                                        .clamp(0.0, 1.0),
                                                    _shimmerAnim.value
                                                        .clamp(0.0, 1.0),
                                                    (_shimmerAnim.value + 0.5)
                                                        .clamp(0.0, 1.0),
                                                  ],
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(1),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(width: 10),
                                      const Icon(
                                        Icons.arrow_forward_rounded,
                                        color: _textPri,
                                        size: 18,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // ── Credentials notice ──
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            color: _orange.withOpacity(0.07),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: _orange.withOpacity(0.18),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.shield_outlined,
                                color: _orange.withOpacity(0.85),
                                size: 17,
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'Use your company-issued credentials to sign in. Contact your admin if you have trouble accessing your account.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _textSec,
                                    height: 1.6,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 40),
                      ],
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

// ── Field label ───────────────────────────────────────────────────────────────
class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Color(0xFFCCCCDD),
        letterSpacing: 0.1,
      ),
    );
  }
}