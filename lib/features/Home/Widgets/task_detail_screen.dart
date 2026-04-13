
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'task_card.dart';
import '../Services/address_marker_screen.dart';
import '../Services/requirements_screen.dart';
import '../Services/attachments_screen.dart';
import '../Services/comments_screen.dart';
import '../Services/guest_screen.dart';
import '../Services/issues_screen.dart';
import '../Services/property_elements_screen.dart';
import '../Services/costs_screen.dart';
import '../Services/supplies_screen.dart';
import '../Services/task_details.dart';
import '../Services/summary_screen.dart';

class TaskDetailScreen extends StatefulWidget {
  final TaskItem task;
  const TaskDetailScreen({super.key, required this.task});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  static const Color _accent = Color(0xFF29B6F6);
  static const Color _textPri = Color(0xFF1A1A1A);
  static const Color _textSec = Color(0xFF8A8A8A);
  static const Color _divider = Color(0xFFF0F0F0);
  static const Color _orange = Color(0xFFF57C00);

  // Static detail data
  static const _currentGuest = 'Guest • Occupied Apr 1 – Apr 10';
  static const _nextGuest = 'Next: Guest • Apr 11';
  static const _dueLabel = 'Today';
  static const _element = 'Address Marker';
  static const int _reqTotal = 36;
  static const int _reqDone = 0;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Scrollable Content
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildMapHeader(context)),
              SliverToBoxAdapter(child: _buildOccupancyStrip()),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 120),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTaskHeader(),
                      const SizedBox(height: 20),
                      _buildDueOn(),
                      const SizedBox(height: 20),
                      _buildElement(),
                      const SizedBox(height: 24),
                      _buildActionTiles(),
                      const SizedBox(height: 32),

                      _buildSectionHeader('Reservation'),
                      const SizedBox(height: 14),

                     // Current Guest
                      _buildReservationRow(
                        icon: Icons.person_outline_rounded,
                        label: _currentGuest,
                        bookmarks: 1,
                        guests: 1,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const GuestScreen(guestName: 'Afo')),
                        ),
                      ),

                      const Divider(height: 28, thickness: 1, color: _divider),

                      // Next Guest
                      _buildReservationRow(
                        icon: Icons.calendar_month_outlined,
                        label: _nextGuest,
                        bookmarks: 1,
                        guests: 3,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const GuestScreen(
                            guestName: 'Eileen',
                            isCurrentGuest: false,
                          )),
                        ),
                      ),
                      const SizedBox(height: 32),
                      _buildSectionHeader('Property'),
                      const SizedBox(height: 14),
                      _buildNavRow(
                        icon: Icons.wine_bar_outlined,
                        label: 'Issues',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const IssuesScreen()),
                        ),
                      ),
                      const Divider(height: 1, thickness: 1, color: _divider),
                     _buildNavRow(
                          icon: Icons.dashboard_customize_outlined,
                          label: 'Property elements',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const PropertyElementsScreen()),
                          ),
                        ),

                      const SizedBox(height: 32),
                      _buildSectionHeader('Task'),
                      const SizedBox(height: 14),
                      _buildNavRow(
                        icon: Icons.attach_money_rounded,
                        label: 'Costs',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const CostsScreen()),
                        ),
                      ),
                      const Divider(height: 1, thickness: 1, color: _divider),
                     _buildNavRow(
                        icon: Icons.inventory_2_outlined,
                        label: 'Supplies',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const SuppliesScreen()),
                        ),
                      ),
                      const Divider(height: 1, thickness: 1, color: _divider),
                      _buildNavRow(icon: Icons.check_box_outlined, label: 'Task details',
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const TaskDetails()),
                        ),),
                      const Divider(height: 1, thickness: 1, color: _divider),
                      _buildNavRow(
                        icon: Icons.label_outline_rounded,
                        label: 'Task tags',
                        trailing: const _Chip(label: 'Approval Needed'),
                        showArrow: false, // This hides the chevron for this row only
                      ),
                      const Divider(height: 1, thickness: 1, color: _divider),
                      _buildNavRow(icon: Icons.list_alt_rounded, label: 'Summary',
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const SummaryScreen()),
                        ),),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // Floating Back & Direction Buttons
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 14,
            right: 14,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _CircleBtn(
                  icon: Icons.arrow_back_rounded,
                  onTap: () => Navigator.pop(context),
                ),
                _CircleBtn(
                  icon: Icons.assistant_direction_rounded,
                  onTap: () {},
                ),
              ],
            ),
          ),

          // Start Task Button
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildStartTaskBar(context),
          ),
        ],
      ),
    );
  }

  // ==================== Reservation Row ====================
  Widget _buildReservationRow({
    required IconData icon,
    required String label,
    required int bookmarks,
    required int guests,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: _textSec),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: _textPri,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _CountChip(icon: Icons.bookmark_border_rounded, count: bookmarks),
                      const SizedBox(width: 8),
                      _CountChip(icon: Icons.person_outline_rounded, count: guests),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, size: 20, color: _textSec),
          ],
        ),
      ),
    );
  }

  // ==================== Other Widgets (unchanged) ====================
  Widget _buildMapHeader(BuildContext context) {
    return SizedBox(
      height: 260,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            color: const Color(0xFFE8F0D8),
            child: CustomPaint(painter: _MapPlaceholderPainter()),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 110,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0xCC1A1A1A)],
                ),
              ),
            ),
          ),
          const Center(
            child: Icon(Icons.location_on_rounded, size: 48, color: Color(0xFFE53935)),
          ),
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.task.propertyName.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.3,
                    height: 1.3,
                    shadows: [Shadow(blurRadius: 6, color: Colors.black54)],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.task.address,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.88),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


Widget _buildOccupancyStrip() {
    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const GuestScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: const BoxDecoration(
          color: Color(0xFFF5F5F5),
          border: Border(
            bottom: BorderSide(color: Color(0xFFEEEEEE), width: 1),
          ),
        ),
        child: const Row(
          children: [
            Icon(Icons.person_outline_rounded, size: 18, color: Color(0xFF555555)),
            SizedBox(width: 10),
            Text(
              'GUEST OCCUPIED',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF444444),
                letterSpacing: 0.8,
              ),
            ),
            SizedBox(width: 12),
            Icon(Icons.bookmark_border_rounded, size: 18, color: Color(0xFF8A8A8A)),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskHeader() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            widget.task.taskType,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: _textPri,
              letterSpacing: -0.5,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: _orange,
            borderRadius: BorderRadius.circular(24),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 14),
              SizedBox(width: 5),
              Text('HIGH', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.white)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDueOn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Due on', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _textSec)),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.calendar_today_rounded, size: 17, color: _textPri),
            const SizedBox(width: 10),
            Text(_dueLabel, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: _textPri)),
          ],
        ),
      ],
    );
  }

  Widget _buildElement() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Element', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _textSec)),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AddressMarkerScreen())),
          child: Text(
            _element,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: _accent,
              decoration: TextDecoration.underline,
              decorationColor: _accent,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionTiles() {
    return Row(
      children: [
        _ActionTile(
          icon: Icons.rule_rounded,
          label: 'Requirements',
          badge: '$_reqDone/$_reqTotal',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RequirementsScreen(
                taskType: widget.task.taskType,
                propertyName: widget.task.propertyName,
                address: widget.task.address,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        _ActionTile(
          icon: Icons.attach_file_rounded,
          label: 'Attachments',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AttachmentsScreen(
                taskType: widget.task.taskType,
                propertyName: widget.task.propertyName,
                address: widget.task.address,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        _ActionTile(
          icon: Icons.chat_bubble_outline_rounded,
          label: 'Comments',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CommentsScreen(
                taskType: widget.task.taskType,
                propertyName: widget.task.propertyName,
                address: widget.task.address,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        color: _textPri,
        letterSpacing: -0.4,
      ),
    );
  }


  // ── Nav row (Issues, Costs, etc.) ─────────────────────────────────────────
 Widget _buildNavRow({
  required IconData icon,
  required String label,
  Widget? trailing,
  VoidCallback? onTap,
  bool showArrow = true, // Added this parameter
}) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(8),
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Icon(icon, size: 20, color: _textSec),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w400,
                color: _textPri,
              ),
            ),
          ),
          if (trailing != null) ...[trailing, const SizedBox(width: 6)],
          // Wrap the icon in a visibility check
          if (showArrow) 
            const Icon(Icons.chevron_right_rounded, size: 20, color: _textSec),
        ],
      ),
    ),
  );
}

  Widget _buildStartTaskBar(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      color: Colors.white,
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: _accent,
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: const Text(
            'Start task',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, letterSpacing: 0.2),
          ),
        ),
      ),
    );
  }
}

// ==================== Local Widgets ====================

class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.92),
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Icon(icon, size: 20, color: const Color(0xFF333333)),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? badge;
  final VoidCallback? onTap;

  const _ActionTile({required this.icon, required this.label, this.badge, this.onTap});

  static const Color _textSec = Color(0xFF8A8A8A);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap ?? () {},
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: const Color(0xFFF7F7F7),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFEEEEEE)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 22, color: _textSec),
              const SizedBox(height: 6),
              if (badge != null) ...[
                Text(badge!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _textSec)),
                const SizedBox(height: 2),
              ],
              Text(
                label,
                style: const TextStyle(fontSize: 11.5, color: _textSec, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CountChip extends StatelessWidget {
  final IconData icon;
  final int count;
  const _CountChip({required this.icon, required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: const Color(0xFF8A8A8A)),
          const SizedBox(width: 4),
          Text('$count', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF555555))),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  const _Chip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F6FD),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF29B6F6)),
      ),
    );
  }
}

class _MapPlaceholderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final roadPaint = Paint()..color = Colors.white..style = PaintingStyle.stroke..strokeWidth = 14;
    final roadOutline = Paint()..color = const Color(0xFFCFD4C0)..style = PaintingStyle.stroke..strokeWidth = 16;
    final blockPaint = Paint()..color = const Color(0xFFDADFCF);

    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), Paint()..color = const Color(0xFFE8EDD8));

    canvas.drawLine(Offset(0, h * 0.3), Offset(w, h * 0.7), roadOutline);
    canvas.drawLine(Offset(0, h * 0.3), Offset(w, h * 0.7), roadPaint);
    canvas.drawLine(Offset(w * 0.1, 0), Offset(w * 0.6, h), roadOutline);
    canvas.drawLine(Offset(w * 0.1, 0), Offset(w * 0.6, h), roadPaint);
    canvas.drawLine(Offset(0, h * 0.55), Offset(w, h * 0.55), roadOutline);
    canvas.drawLine(Offset(0, h * 0.55), Offset(w, h * 0.55), roadPaint);

    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.55, h * 0.05, w * 0.38, h * 0.38), const Radius.circular(4)), Paint()..color = const Color(0xFFC8D9A0));

    canvas.drawRect(Rect.fromLTWH(w * 0.05, h * 0.08, w * 0.22, h * 0.18), blockPaint);
    canvas.drawRect(Rect.fromLTWH(w * 0.65, h * 0.6, w * 0.28, h * 0.25), blockPaint);
    canvas.drawRect(Rect.fromLTWH(w * 0.05, h * 0.65, w * 0.18, h * 0.22), blockPaint);
  }

  @override
  bool shouldRepaint(_) => false;
}