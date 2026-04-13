import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../Api/api_controller.dart';
import '../../Authentication/Providers/auth_providers.dart';
import '../../Authentication/Screens/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const Color _accent    = Color(0xFF29B6F6);
  static const Color _bg        = Color(0xFFF5F7FA);
  static const Color _surface   = Colors.white;
  static const Color _textPri   = Color(0xFF1A1A1A);
  static const Color _textSec   = Color(0xFF8A8A8A);
  static const Color _divider   = Color(0xFFF0F0F0);
  static const Color _red       = Color(0xFFE53935);

  Map<String, dynamic>? _profile;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() { _isLoading = true; _error = null; });
    final result = await ApiController.getProfile();
    if (!mounted) return;
    if (result['success'] == true) {
      setState(() { _profile = result['data']; _isLoading = false; });
    } else {
      setState(() { _error = result['message']; _isLoading = false; });
    }
  }

  String _initials(String name) {
    final parts = name.trim().split(' ').where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  String _formatDate(String? iso) {
    if (iso == null) return '—';
    final dt = DateTime.tryParse(iso)?.toLocal();
    if (dt == null) return '—';
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  void _confirmLogout() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFDDDDDD),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 22),
            const Text('Sign out?',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _textPri)),
            const SizedBox(height: 8),
            const Text('You will be signed out of your account and returned to the login screen.',
                style: TextStyle(fontSize: 13, color: _textSec, height: 1.6)),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _textSec,
                      side: const BorderSide(color: Color(0xFFDDDDDD)),
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
                      Navigator.pop(context);
                      final auth = Provider.of<AuthProvider>(context, listen: false);
                      await auth.logout();
                      if (!mounted) return;
                      Navigator.pushAndRemoveUntil(
                        context,
                        PageRouteBuilder(
                          transitionDuration: const Duration(milliseconds: 500),
                          pageBuilder: (_, __, ___) => const LoginScreen(),
                          transitionsBuilder: (_, anim, __, child) =>
                              FadeTransition(opacity: anim, child: child),
                        ),
                        (_) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _red,
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


    void _showChangePasswordDialog() {
    final _currentPassController = TextEditingController();
    final _newPassController = TextEditingController();
    final _confirmPassController = TextEditingController();

    bool _obscureCurrent = true;
    bool _obscureNew = true;
    bool _obscureConfirm = true;
    bool _isLoading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final bool isValid = _currentPassController.text.trim().isNotEmpty &&
                _newPassController.text.trim().isNotEmpty &&
                _confirmPassController.text.trim().isNotEmpty &&
                _newPassController.text == _confirmPassController.text &&
                _newPassController.text.length >= 6;

            return AlertDialog(
              backgroundColor: _surface,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text(
                'Change Password',
                style: TextStyle(color: _textPri, fontWeight: FontWeight.w700),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Current Password
                    TextField(
                      controller: _currentPassController,
                      obscureText: _obscureCurrent,
                      style: TextStyle(color: _textPri),
                      decoration: InputDecoration(
                        labelText: 'Current Password',
                        labelStyle: TextStyle(color: _textSec),
                        suffixIcon: IconButton(
                          icon: Icon(_obscureCurrent ? Icons.visibility_off : Icons.visibility, color: _textSec),
                          onPressed: () => setDialogState(() => _obscureCurrent = !_obscureCurrent),
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: _divider),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: _accent, width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // New Password
                    TextField(
                      controller: _newPassController,
                      obscureText: _obscureNew,
                      style: TextStyle(color: _textPri),
                      onChanged: (_) => setDialogState(() {}),
                      decoration: InputDecoration(
                        labelText: 'New Password',
                        labelStyle: TextStyle(color: _textSec),
                        suffixIcon: IconButton(
                          icon: Icon(_obscureNew ? Icons.visibility_off : Icons.visibility, color: _textSec),
                          onPressed: () => setDialogState(() => _obscureNew = !_obscureNew),
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: _divider),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: _accent, width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Confirm New Password
                    TextField(
                      controller: _confirmPassController,
                      obscureText: _obscureConfirm,
                      style: TextStyle(color: _textPri),
                      onChanged: (_) => setDialogState(() {}),
                      decoration: InputDecoration(
                        labelText: 'Confirm New Password',
                        labelStyle: TextStyle(color: _textSec),
                        suffixIcon: IconButton(
                          icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility, color: _textSec),
                          onPressed: () => setDialogState(() => _obscureConfirm = !_obscureConfirm),
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: _divider),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: _accent, width: 1.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: Text('Cancel', style: TextStyle(color: _textSec)),
                ),
                ElevatedButton(
                  onPressed: isValid && !_isLoading
                      ? () async {
                          setDialogState(() => _isLoading = true);

                          final current = _currentPassController.text.trim();
                          final newPass = _newPassController.text.trim();

                          final authProvider = Provider.of<AuthProvider>(context, listen: false);
                          final result = await ApiController.changePassword(current, newPass);

                          if (!mounted) return;
                          setDialogState(() => _isLoading = false);
                          Navigator.pop(dialogContext);

                          if (result['success'] == true) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Password changed successfully!'),
                                backgroundColor: Colors.green,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(result['message'] ?? 'Failed to change password'),
                                backgroundColor: _red,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                      : const Text('Change Password'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _accent))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red, size: 40),
                      const SizedBox(height: 12),
                      Text(_error!, style: const TextStyle(color: Colors.grey)),
                      const SizedBox(height: 16),
                      TextButton(onPressed: _loadProfile, child: const Text('Retry')),
                    ],
                  ),
                )
              : _buildBody(),
    );
  }

  Widget _buildBody() {
    final p = _profile!;
    final name        = p['full_name'] ?? '';
    final email       = p['email'] ?? '';
    final mobile      = p['mobile_no'] ?? '—';
    final officePhone = p['office_phone'] ?? '—';
    final employeeId  = p['employee_id'] ?? '—';
    final roleName    = p['role_name'] ?? '—';
    final department  = p['department']?['name'] ?? '—';
    final group       = p['group']?['name'] ?? '—';
    final company     = p['company']?['name'] ?? '—';
    final companyAddr = p['company']?['address'] ?? '—';
    final lastLogin   = _formatDate(p['last_login_at']);
    final memberSince = _formatDate(p['created_at']);
    final security    = p['security_settings'] as Map<String, dynamic>? ?? {};

    return CustomScrollView(
      slivers: [
        // ── Hero header ──
        SliverToBoxAdapter(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Banner
              Container(
                height: 180,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1A1F2E), Color(0xFF29B6F6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -30, top: -30,
                      child: Container(
                        width: 180, height: 180,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.05),
                        ),
                      ),
                    ),
                    Positioned(
                      left: -20, bottom: -20,
                      child: Container(
                        width: 120, height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.05),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Back button
              Positioned(
                top: MediaQuery.of(context).padding.top + 10,
                left: 14,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                  ),
                ),
              ),

              // Avatar + name block
              Positioned(
                bottom: -60, left: 0, right: 0,
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Container(
                          width: 100, height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3.5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.12),
                                blurRadius: 16, offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/user-image.png',
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: _accent.withOpacity(0.15),
                                child: Center(
                                  child: Text(
                                    _initials(name),
                                    style: const TextStyle(
                                      fontSize: 32, fontWeight: FontWeight.w800, color: _accent,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        Container(
                          width: 28, height: 28,
                          decoration: const BoxDecoration(color: _accent, shape: BoxShape.circle),
                          child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 14),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Spacer for avatar overlap
        const SliverToBoxAdapter(child: SizedBox(height: 76)),

        // ── Name + role chip ──
        SliverToBoxAdapter(
          child: Column(
            children: [
              Text(name,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800,
                      color: _textPri, letterSpacing: -0.5)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  color: _accent.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(roleName.toUpperCase(),
                    style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700,
                        color: _accent, letterSpacing: 0.8)),
              ),
              const SizedBox(height: 6),
              Text(email,
                  style: const TextStyle(fontSize: 13, color: _textSec)),
            ],
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 24)),

        // ── Stats row ──
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                color: _surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.05),
                      blurRadius: 12, offset: const Offset(0, 4)),
                ],
              ),
              child: Row(
                children: [
                  _StatItem(label: 'Employee ID', value: employeeId),
                  _VertDivider(),
                  _StatItem(label: 'Department', value: department),
                  _VertDivider(),
                  _StatItem(label: 'Group', value: group),
                ],
              ),
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 20)),

        // ── Contact info ──
        SliverToBoxAdapter(
          child: _Section(
            title: 'Contact Information',
            children: [
              _InfoRow(icon: Icons.email_outlined, label: 'Email', value: email),
              _InfoRow(icon: Icons.phone_outlined, label: 'Mobile', value: mobile),
              _InfoRow(icon: Icons.phone_in_talk_outlined, label: 'Office phone', value: officePhone),
            ],
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 16)),

        // ── Company info ──
        SliverToBoxAdapter(
          child: _Section(
            title: 'Company',
            children: [
              _InfoRow(icon: Icons.business_rounded, label: 'Company', value: company),
              _InfoRow(icon: Icons.location_on_outlined, label: 'Address', value: companyAddr),
            ],
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 16)),

        // ── Account info ──
        SliverToBoxAdapter(
          child: _Section(
            title: 'Account',
            children: [
              _InfoRow(icon: Icons.calendar_today_outlined, label: 'Member since', value: memberSince),
              _InfoRow(icon: Icons.access_time_rounded, label: 'Last login', value: lastLogin),
              _InfoRow(
                icon: Icons.verified_user_outlined,
                label: 'Account status',
                value: p['is_active'] == 'Y' ? 'Active' : 'Inactive',
                valueColor: p['is_active'] == 'Y' ? const Color(0xFF43A047) : _red,
              ),
            ],
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 16)),

        // ── Security ──
        SliverToBoxAdapter(
          child: _Section(
            title: 'Security',
            children: [
              _SwitchRow(
                icon: Icons.lock_outline_rounded,
                label: 'Two-factor authentication',
                value: security['two_factor_enabled'] == true,
              ),
              _SwitchRow(
                icon: Icons.notifications_outlined,
                label: 'Login notifications',
                value: security['login_notifications'] == true,
              ),
              _InfoRow(
                icon: Icons.timer_outlined,
                label: 'Session timeout',
                value: '${security['session_timeout_minutes'] ?? 60} minutes',
              ),
              _InfoRow(
                icon: Icons.password_rounded,
                label: 'Password expiry',
                value: '${security['password_expiry_days'] ?? 90} days',
              ),
              ListTile(
                leading: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: _accent.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.lock_reset_rounded, size: 18, color: _accent),
                ),
                title: const Text(
                  'Change Password',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: _textPri),
                ),
                trailing: const Icon(Icons.chevron_right_rounded, color: _textSec),
                onTap: _showChangePasswordDialog,
                contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
              ),
            ],
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 16)),

        // ── Sign out ──
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _confirmLogout,
                icon: const Icon(Icons.logout_rounded, size: 18),
                label: const Text('Sign Out',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _red,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 40)),
      ],
    );
  }
}

// ── Section wrapper ───────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section({required this.title, required this.children});

  static const Color _textPri = Color(0xFF1A1A1A);
  static const Color _textSec = Color(0xFF8A8A8A);
  static const Color _divider = Color(0xFFF0F0F0);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 10),
            child: Text(title,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                    color: _textSec, letterSpacing: 0.5)),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.05),
                    blurRadius: 12, offset: const Offset(0, 4)),
              ],
            ),
            child: Column(
              children: List.generate(children.length, (i) => Column(
                children: [
                  children[i],
                  if (i < children.length - 1)
                    const Divider(height: 1, thickness: 1, color: _divider, indent: 52),
                ],
              )),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Info row ──────────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  const _InfoRow({required this.icon, required this.label, required this.value, this.valueColor});

  static const Color _accent  = Color(0xFF29B6F6);
  static const Color _textPri = Color(0xFF1A1A1A);
  static const Color _textSec = Color(0xFF8A8A8A);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              color: _accent.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 17, color: _accent),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(fontSize: 11.5, color: _textSec, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(value,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500,
                        color: valueColor ?? _textPri)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Switch row (display only) ─────────────────────────────────────────────────

class _SwitchRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  const _SwitchRow({required this.icon, required this.label, required this.value});

  static const Color _accent  = Color(0xFF29B6F6);
  static const Color _textPri = Color(0xFF1A1A1A);
  static const Color _textSec = Color(0xFF8A8A8A);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              color: _accent.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 17, color: _accent),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(label,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: _textPri)),
          ),
          Switch(
            value: value,
            onChanged: null,
            activeColor: _accent,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }
}

// ── Stat item ─────────────────────────────────────────────────────────────────

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  const _StatItem({required this.label, required this.value});

  static const Color _textPri = Color(0xFF1A1A1A);
  static const Color _textSec = Color(0xFF8A8A8A);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value,
              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: _textPri),
              textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 3),
          Text(label,
              style: const TextStyle(fontSize: 11, color: _textSec),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

// ── Vertical divider ──────────────────────────────────────────────────────────

class _VertDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 36, color: const Color(0xFFF0F0F0));
  }
}