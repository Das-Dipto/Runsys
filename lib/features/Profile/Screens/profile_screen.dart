import 'package:flutter/material.dart';
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
  // ── Dark theme palette ──
  static const Color _bg         = Color(0xFF0A0A0F);
  static const Color _surface    = Color(0xFF111118);
  static const Color _surfaceAlt = Color(0xFF16161F);
  static const Color _orange     = Color(0xFFFF7300);
  static const Color _textPri    = Color(0xFFFFFFFF);
  static const Color _textSec    = Color(0xFF8A8A9A);
  static const Color _border     = Color(0xFF1E1E2E);
  static const Color _red        = Color(0xFFFF6B6B);

  Map<String, dynamic>? _profile;
  bool _isLoading = true;
  String? _error;

  final _formKey = GlobalKey<FormState>();
  late TextEditingController _fullNameController;
  late TextEditingController _mobileController;
  late TextEditingController _officePhoneController;
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() { _isLoading = true; _error = null; });
    final result = await ApiController.getProfile();
    if (!mounted) return;
    if (result['success'] == true) {
      setState(() { 
        _profile = result['data']; 
        _isLoading = false; 
      });

      final p = _profile!;
      _fullNameController = TextEditingController(text: p['full_name'] ?? '');
      _mobileController = TextEditingController(text: p['mobile_no'] ?? '');
      _officePhoneController = TextEditingController(text: p['office_phone'] ?? '');
      _notesController = TextEditingController(text: p['notes'] ?? '');
    } else {
      setState(() { _error = result['message']; _isLoading = false; });
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _mobileController.dispose();
    _officePhoneController.dispose();
    _notesController.dispose();
    super.dispose();
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

void _showEditProfileDialog() {
  bool _isSaving = false;

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        backgroundColor: _surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Edit Profile',
            style: TextStyle(color: _textPri, fontWeight: FontWeight.w700)),
        content: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTextField(_fullNameController, 'Full Name', Icons.person_outline_rounded),
                const SizedBox(height: 12),
                _buildTextField(_mobileController, 'Mobile Number', Icons.phone_rounded),
                const SizedBox(height: 12),
                _buildTextField(_officePhoneController, 'Office Phone', Icons.business_rounded),
                const SizedBox(height: 12),
                _buildTextField(_notesController, 'Notes', Icons.note_alt_rounded, maxLines: 3),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : () => Navigator.pop(dialogContext),
            child: const Text('Cancel', style: TextStyle(color: _textSec)),
          ),
          ElevatedButton(
            onPressed: _isSaving
                ? null
                : () async {
                    if (!_formKey.currentState!.validate()) return;
                    setDialogState(() => _isSaving = true);

                    final result = await ApiController.updateProfile(
                      fullName: _fullNameController.text.trim(),
                      mobileNo: _mobileController.text.trim(),
                      officePhone: _officePhoneController.text.trim(),
                      notes: _notesController.text.trim(),
                    );

                    if (!mounted) return;
                    setDialogState(() => _isSaving = false);

                    final messenger = ScaffoldMessenger.of(context);
                    Navigator.pop(dialogContext);

                    if (result['success'] == true) {
                      await _loadProfile();
                      messenger.showSnackBar(
                        SnackBar(
                          content: const Text('Profile updated successfully!',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                          backgroundColor: const Color(0xFF43A047),
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      );
                    } else {
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(result['message'] ?? 'Failed to update profile',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                          backgroundColor: _red,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      );
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: _orange,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                  )
                : const Text('Save', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    ),
  );
}
  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: _textPri),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: _textSec),
        prefixIcon: Icon(icon, color: _textSec),
        filled: true,
        fillColor: _surfaceAlt,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _orange, width: 1.5),
        ),
      ),
    );
  }
void _confirmLogout() {
  showModalBottomSheet(
    context: context,
    backgroundColor: _surface,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
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
                  color: _red.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _red.withOpacity(0.3)),
                ),
                child: const Icon(Icons.logout_rounded, color: _red, size: 20),
              ),
              const SizedBox(width: 14),
              const Text('Sign out?',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w700, color: _textPri)),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'You will be signed out of your account',
            style: TextStyle(fontSize: 13, color: _textSec, height: 1.6),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(sheetContext),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _textSec,
                    side: const BorderSide(color: _border),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Cancel',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(sheetContext);
                    showDialog(
                      context: context,
                      barrierDismissible: false,
                      barrierColor: Colors.black.withOpacity(0.7),
                      builder: (_) => Dialog(
                        backgroundColor: _surfaceAlt,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(color: _red.withOpacity(0.3), width: 1),
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
                                  valueColor: AlwaysStoppedAnimation<Color>(_red),
                                ),
                              ),
                              SizedBox(width: 18),
                              Text('Signing out…',
                                  style: TextStyle(
                                      fontSize: 15,
                                      color: _textPri,
                                      fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                      ),
                    );

                    final auth = Provider.of<AuthProvider>(context, listen: false);
                    await auth.logout();

                    if (!mounted) return;
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (_) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _red,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Sign out',
                      style: TextStyle(fontWeight: FontWeight.w700)),
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
              title: const Text('Change Password', style: TextStyle(color: _textPri, fontWeight: FontWeight.w700)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: _currentPassController,
                      obscureText: _obscureCurrent,
                      style: const TextStyle(color: _textPri),
                      decoration: InputDecoration(
                        labelText: 'Current Password',
                        labelStyle: const TextStyle(color: _textSec),
                        suffixIcon: IconButton(
                          icon: Icon(_obscureCurrent ? Icons.visibility_off : Icons.visibility, color: _textSec),
                          onPressed: () => setDialogState(() => _obscureCurrent = !_obscureCurrent),
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _border)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _orange, width: 1.5)),
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextField(
                      controller: _newPassController,
                      obscureText: _obscureNew,
                      style: const TextStyle(color: _textPri),
                      onChanged: (_) => setDialogState(() {}),
                      decoration: InputDecoration(
                        labelText: 'New Password',
                        labelStyle: const TextStyle(color: _textSec),
                        suffixIcon: IconButton(
                          icon: Icon(_obscureNew ? Icons.visibility_off : Icons.visibility, color: _textSec),
                          onPressed: () => setDialogState(() => _obscureNew = !_obscureNew),
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _border)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _orange, width: 1.5)),
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextField(
                      controller: _confirmPassController,
                      obscureText: _obscureConfirm,
                      style: const TextStyle(color: _textPri),
                      onChanged: (_) => setDialogState(() {}),
                      decoration: InputDecoration(
                        labelText: 'Confirm New Password',
                        labelStyle: const TextStyle(color: _textSec),
                        suffixIcon: IconButton(
                          icon: Icon(_obscureConfirm ? Icons.visibility_off : Icons.visibility, color: _textSec),
                          onPressed: () => setDialogState(() => _obscureConfirm = !_obscureConfirm),
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _border)),
                        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _orange, width: 1.5)),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel', style: TextStyle(color: _textSec)),
                ),
                ElevatedButton(
                  onPressed: isValid && !_isLoading
                      ? () async {
                          setDialogState(() => _isLoading = true);
                          final current = _currentPassController.text.trim();
                          final newPass = _newPassController.text.trim();

                          final result = await ApiController.changePassword(current, newPass);

                          if (!mounted) return;
                          setDialogState(() => _isLoading = false);
                          Navigator.pop(dialogContext);

                          if (result['success'] == true) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Password changed successfully!'), backgroundColor: Colors.green),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(result['message'] ?? 'Failed to change password'), backgroundColor: _red),
                            );
                          }
                        }
                      : null,
                  style: ElevatedButton.styleFrom(backgroundColor: _orange, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
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
    final p = _profile;

    return Scaffold(
      backgroundColor: _bg,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: _orange))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, color: _red, size: 42),
                      const SizedBox(height: 12),
                      Text(_error!, style: const TextStyle(color: _textSec)),
                      const SizedBox(height: 16),
                      TextButton(onPressed: _loadProfile, child: const Text('Retry')),
                    ],
                  ),
                )
              : CustomScrollView(
                  slivers: [
                    // Hero Header
                    SliverToBoxAdapter(
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            height: 180,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Color(0xFF1A1F2E), Color(0xFF0A0A0F)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                          ),
                          // Back button
                          Positioned(
                            top: MediaQuery.of(context).padding.top + 10,
                            left: 14,
                            child: GestureDetector(
                              onTap: () => Navigator.pop(context),
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                              ),
                            ),
                          ),

Positioned(
  top: MediaQuery.of(context).padding.top + 10,
  right: 14,
  child: Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: _showEditProfileDialog,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Color(0xFFFF7300),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Row(
          children: const [
            Icon(Icons.edit_rounded, color: Colors.white, size: 16),
            SizedBox(width: 6),
            Text(
              'Edit',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    ),
  ),
),


// ── Avatar with old image + bottom-right edit icon (tap to open dialog) ──
Positioned(
  bottom: -55,
  left: 0,
  right: 0,
  child: Center(
    child: Stack(
      clipBehavior: Clip.none,
      children: [
        // ✅ Avatar (centered, non-clickable)
        IgnorePointer(
          child: Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: const Color(0xFFFF7300).withOpacity(0.6),
                width: 4,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/user-image.png',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: const Color(0xFF16161F),
                  child: Center(
                    child: Text(
                      _initials(_profile?['full_name'] ?? ''),
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFFF7300),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),


      
      ],
    ),
  ),
),

                        ],
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 70)),

                    // Name + Role
                    SliverToBoxAdapter(
                      child: Column(
                        children: [
                          Text(
                            p?['full_name'] ?? 'User Name',
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: _textPri),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                            decoration: BoxDecoration(
                              color: _orange.withOpacity(0.10),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              (p?['role_name'] ?? 'Role').toUpperCase(),
                              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: _orange, letterSpacing: 0.8),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(p?['email'] ?? '', style: const TextStyle(fontSize: 13, color: _textSec)),
                        ],
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 30)),

                    // Stats Row
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          decoration: BoxDecoration(
                            color: _surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: _border, width: 1),
                          ),
                          child: Row(
                            children: [
                              _StatItem(label: 'Employee ID', value: p?['employee_id'] ?? '—'),
                              _VertDivider(),
                              _StatItem(label: 'Department', value: p?['department']?['name'] ?? '—'),
                              _VertDivider(),
                              _StatItem(label: 'Group', value: p?['group']?['name'] ?? '—'),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 20)),

                    // Contact Information
                    SliverToBoxAdapter(
                      child: _Section(
                        title: 'Contact Information',
                        children: [
                          _InfoRow(icon: Icons.email_outlined, label: 'Email', value: p?['email'] ?? '—'),
                          _InfoRow(icon: Icons.phone_outlined, label: 'Mobile', value: p?['mobile_no'] ?? '—'),
                          _InfoRow(icon: Icons.phone_in_talk_outlined, label: 'Office phone', value: p?['office_phone'] ?? '—'),
                        ],
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 16)),

                    // Company
                    SliverToBoxAdapter(
                      child: _Section(
                        title: 'Company',
                        children: [
                          _InfoRow(icon: Icons.business_rounded, label: 'Company', value: p?['company']?['name'] ?? '—'),
                          _InfoRow(icon: Icons.location_on_outlined, label: 'Address', value: p?['company']?['address'] ?? '—'),
                        ],
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 16)),

                    // Account
                    SliverToBoxAdapter(
                      child: _Section(
                        title: 'Account',
                        children: [
                          _InfoRow(icon: Icons.calendar_today_outlined, label: 'Member since', value: _formatDate(p?['created_at'])),
                          _InfoRow(icon: Icons.access_time_rounded, label: 'Last login', value: _formatDate(p?['last_login_at'])),
                          _InfoRow(
                            icon: Icons.verified_user_outlined,
                            label: 'Account status',
                            value: p?['is_active'] == 'Y' ? 'Active' : 'Inactive',
                            valueColor: p?['is_active'] == 'Y' ? const Color(0xFF43A047) : _red,
                          ),
                        ],
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 16)),

                    // Security
                    SliverToBoxAdapter(
                      child: _Section(
                        title: 'Security',
                        children: [
                          _SwitchRow(
                            icon: Icons.lock_outline_rounded,
                            label: 'Two-factor authentication',
                            value: p?['security_settings']?['two_factor_enabled'] == true,
                          ),
                          _SwitchRow(
                            icon: Icons.notifications_outlined,
                            label: 'Login notifications',
                            value: p?['security_settings']?['login_notifications'] == true,
                          ),
                          _InfoRow(
                            icon: Icons.timer_outlined,
                            label: 'Session timeout',
                            value: '${p?['security_settings']?['session_timeout_minutes'] ?? 60} minutes',
                          ),
                          _InfoRow(
                            icon: Icons.password_rounded,
                            label: 'Password expiry',
                            value: '${p?['security_settings']?['password_expiry_days'] ?? 90} days',
                          ),
                          ListTile(
                            leading: Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: _orange.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.lock_reset_rounded, size: 18, color: _orange),
                            ),
                            title: const Text('Change Password', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: _textPri)),
                            trailing: const Icon(Icons.chevron_right_rounded, color: _textSec),
                            onTap: _showChangePasswordDialog,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                          ),
                        ],
                      ),
                    ),

                    const SliverToBoxAdapter(child: SizedBox(height: 16)),

                    // Sign Out
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton.icon(
                            onPressed: _confirmLogout,
                            icon: const Icon(Icons.logout_rounded, size: 18),
                            label: const Text('Sign Out', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
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
                ),
    );
  }
}

// ── Section wrapper ───────────────────────────────────────────────────────────
class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 10),
            child: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: const Color(0xFF8A8A9A), letterSpacing: 0.5)),
          ),
          Container(
            decoration: BoxDecoration(
              color: Color(0xFF111118),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Color(0xFF1E1E2E), width: 1),
            ),
            child: Column(
              children: List.generate(children.length, (i) => Column(
                children: [
                  children[i],
                  if (i < children.length - 1)
                    const Divider(height: 1, thickness: 1, color: Color(0xFF1E1E2E), indent: 52),
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

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Color(0xFFFF7300).withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 17, color: Color(0xFFFF7300)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 11.5, color: Color(0xFF8A8A9A), fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: valueColor ?? Color(0xFF8A8A9A))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Switch row ────────────────────────────────────────────────────────────────
class _SwitchRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;

  const _SwitchRow({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Color(0xFFFF7300).withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 17, color: Color(0xFFFF7300)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFFFFFFFF))),
          ),
          Switch(
            value: value,
            onChanged: null,
            activeColor: Color(0xFFFF7300),
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

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: Color(0xFF8A8A9A)), textAlign: TextAlign.center),
          const SizedBox(height: 3),
          Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF8A8A9A)), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

// ── Vertical divider ─────────────────────────────────────────────────────────
class _VertDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 36, color: Color(0xFF1E1E2E));
  }
}