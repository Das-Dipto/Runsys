import 'package:flutter/material.dart';

class IssueDetailScreen extends StatelessWidget {
  final String title;
  final String reported;
  final String scheduled;

  const IssueDetailScreen({
    super.key,
    required this.title,
    required this.reported,
    required this.scheduled,
  });

  static const Color _textPri = Color(0xFF1A1A1A);
  static const Color _textSec = Color(0xFF8A8A8A);
  static const Color _divider = Color(0xFFF0F0F0);
  static const Color _red     = Color(0xFFD32F2F);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, size: 22, color: _textPri),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Open Maintenance Issue',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: _textPri,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: true,
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: Color(0xFFEEEEEE)),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Title + URGENT pill ──
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: _textPri,
                      height: 1.25,
                      letterSpacing: -0.4,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: _red,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.double_arrow_rounded,
                          color: Colors.white, size: 14),
                      SizedBox(width: 5),
                      Text(
                        'URGENT',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            // ── Reported + Department ──
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _InfoBlock(
                    label: 'Reported',
                    icon: Icons.flag_outlined,
                    value: reported,
                  ),
                ),
                Expanded(
                  child: _InfoBlock(
                    label: 'Department',
                    icon: Icons.build_outlined,
                    value: 'Maintenance',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 22),
            const Divider(height: 1, thickness: 1, color: _divider),
            const SizedBox(height: 22),

            // ── Scheduled ──
            _InfoBlock(
              label: 'Scheduled',
              icon: Icons.calendar_today_outlined,
              value: scheduled,
            ),

            const SizedBox(height: 22),
            const Divider(height: 1, thickness: 1, color: _divider),
            const SizedBox(height: 22),

            // ── Details ──
            const Text(
              'Details',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: _textPri,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Sunny Bhai will check all the flats after guests check out and cleaners cleaning accordingly.',
              style: TextStyle(
                fontSize: 15,
                color: _textSec,
                height: 1.55,
              ),
            ),

            const SizedBox(height: 28),

            // ── Attachments + Comments tiles ──
            Row(
              children: [
                _ActionTile(
                  icon: Icons.attach_file_rounded,
                  label: 'Attachments',
                  onTap: () {},
                ),
                const SizedBox(width: 12),
                _ActionTile(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: 'Comments',
                  onTap: () {},
                ),
                // spacer so tiles don't stretch full width
                const Expanded(child: SizedBox()),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Info block (label + icon + value) ─────────────────────────────────────────

class _InfoBlock extends StatelessWidget {
  final String label;
  final IconData icon;
  final String value;
  const _InfoBlock({
    required this.label,
    required this.icon,
    required this.value,
  });

  static const Color _textPri = Color(0xFF1A1A1A);
  static const Color _textSec = Color(0xFF8A8A8A);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: _textPri,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Icon(icon, size: 17, color: _textSec),
            const SizedBox(width: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: _textSec,
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Square action tile ────────────────────────────────────────────────────────

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  static const Color _textSec = Color(0xFF8A8A8A);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFE0E0E0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 24, color: _textSec),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: _textSec,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}