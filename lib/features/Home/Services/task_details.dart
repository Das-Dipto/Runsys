import 'package:flutter/material.dart';

class TaskDetails extends StatelessWidget {
  const TaskDetails({super.key});

  static const Color _textPri = Color(0xFF1A1A1A);
  static const Color _textSec = Color(0xFF9E9E9E);
  static const Color _bgGrey  = Color(0xFFF2F4F6);
  static const Color _orange  = Color(0xFFF57C00);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgGrey,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, size: 22, color: _textSec),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Details',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: _textPri,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          // ── TASK section ──
          _buildCard(
            children: [
              _SectionLabel(
                icon: Icons.check_box_outlined,
                label: 'TASK',
              ),
              const SizedBox(height: 20),
              _DetailField(label: 'Last updated', value: 'Apr 04, 2026 at 1:57 PM'),
              const SizedBox(height: 20),
              _DetailField(
                label: 'Assignees',
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFFCCCCCC),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Text(
                          'DD',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF555555),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Dipto Das',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        color: _textPri,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _DetailField(label: 'Due date', value: 'Apr 04, 2026'),
              const SizedBox(height: 20),
              _DetailField(
                label: 'Priority',
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE0E0E0)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.arrow_upward_rounded,
                          size: 14, color: _orange),
                      const SizedBox(width: 5),
                      Text(
                        'HIGH',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _orange,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _DetailField(
                label: 'Status',
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE0E0E0)),
                  ),
                  child: const Text(
                    'NEW',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: _textPri,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // ── SOURCE section ──
          _buildCard(
            children: [
              _SectionLabel(
                icon: Icons.info_outline_rounded,
                label: 'SOURCE',
              ),
              const SizedBox(height: 20),
              _DetailField(
                label: 'Company',
                value: 'Guest House — Your Perfect Escape',
              ),
              const SizedBox(height: 20),
              _DetailField(label: 'Task ID', value: '141064323'),
              const SizedBox(height: 20),
              _DetailField(
                label: 'Created date',
                value: 'Apr 04, 2026 at 1:57 PM',
              ),
              const SizedBox(height: 20),
              _DetailField(label: 'Created by', value: 'Md Saydujiaman'),
              const SizedBox(height: 8),
            ],
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildCard({required List<Widget> children}) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

// ── Section label ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SectionLabel({required this.icon, required this.label});

  static const Color _textSec = Color(0xFF9E9E9E);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: _textSec),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: _textSec,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }
}

// ── Detail field ──────────────────────────────────────────────────────────────

class _DetailField extends StatelessWidget {
  final String label;
  final String? value;
  final Widget? child;
  const _DetailField({required this.label, this.value, this.child});

  static const Color _textPri = Color(0xFF1A1A1A);
  static const Color _textSec = Color(0xFF9E9E9E);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: _textSec,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 6),
        if (child != null)
          child!
        else
          Text(
            value ?? '',
            style: const TextStyle(
              fontSize: 15,
              color: _textPri,
              fontWeight: FontWeight.w500,
            ),
          ),
      ],
    );
  }
}