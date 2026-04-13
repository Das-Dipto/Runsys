import 'package:flutter/material.dart';

class RequirementsScreen extends StatefulWidget {
  final String taskType;
  final String propertyName;
  final String address;
  const RequirementsScreen({
    super.key,
    required this.taskType,
    required this.propertyName,
    required this.address,
  });

  @override
  State<RequirementsScreen> createState() => _RequirementsScreenState();
}

class _RequirementsScreenState extends State<RequirementsScreen>
    with SingleTickerProviderStateMixin {
  static const Color _accent  = Color(0xFF29B6F6);
  static const Color _textPri = Color(0xFF1A1A1A);
  static const Color _textSec = Color(0xFF9E9E9E);
  static const Color _orange  = Color(0xFFF57C00);
  static const Color _bgGrey  = Color(0xFFEEF0F3);

  late TabController _tabController;

  static const int _totalReq = 36;
  static const int _doneReq  = 0;

  // ── Static requirement data ───────────────────────────────────────────────

  final List<_ReqSection> _firstTasksSections = [
    _ReqSection(
      text:
          'গেস্ট ফ্ল্যাটকে কান কন্ডিশনে রেখে গিয়েছেন তার রেটিং দাও (৫ এ কত?)',
      type: _SectionType.starRating,
    ),
    _ReqSection(
      text:
          '- রেটিং যদি ১ বা ২ হয় তবে তার প্রমণস্বরূপ ছবি আপলোড কর',
      type: _SectionType.checklist,
    ),
    _ReqSection(
      text:
          '- গেস্ট যদি থালা-বাসন নোংরা অবস্থায় রেখে যায় তবে দ্রতই ডিশওয়াশার মেশিনটি চালু কর\n- ছেড়া বিছানার চাদর, বা চাদরে কোন অস্বস্তিকর দাগ থাকলে তা চেক কর এবং কোম্পানির পলিসি অনুযায়ী তা দ্রত পরিষ্কার করার পদক্ষেপ নাও',
      type: _SectionType.checklist,
    ),
  ];

  final List<_ReqSection> _interiorSections = [
    _ReqSection(
      text:
          '- মেঝের যে যে স্থানে প্রয়োজন সেখানে, ঝাড়ু দাও, মপ দিয়ে মুছে ফেল এবং প্রয়োজনে ভ্যাকুয়াম ক্লিনার বা হভার ব্যাবহার কর\n'
          '- ফ্ল্যাটের সকল লাইট চেক কর যে তা সঠিকভাবে জ্বলছে কিনা, যদি কোন লাইটে সমস্যা পাও তবে তা সানি ভাইকে দ্রত জানাও\n'
          '- Clean and sanitize all guest contact items (remotes, door knobs/handles, window locks, curtain/blind rods, etc)\n'
          '- Clean all mirrors, windows and glass surfaces with glass cleaner without leaving streaks\n'
          '- Check ceiling edges/corners for cobwebs, removing them\n'
          '- Report any property issues/problems requiring maintenance immediately',
      type: _SectionType.checklist,
    ),
  ];

  final List<_ReqSection> _exteriorSections = [
    _ReqSection(
      text:
          '- Sweep debris off exterior access points, balcony, patio and/or deck (as applicable)\n'
          '- Ensure there are no trip hazards\n'
          '- Turn off the front entrance light if guests are not arriving today\n'
          '- Walk the full exterior premises and remove any trash',
      type: _SectionType.checklist,
    ),
  ];

  final List<_ReqSection> _finishingTouchesSections = [
    _ReqSection(
      text:
          '-\n'
          '- Ensure all interior lights and fans are off\n'
          '- Set drapes, curtains and blinds to company standards\n'
          '- Ensure interior odor is clean and fresh upon completion\n'
          '- Lock all doors and windows\n'
          '- All areas smell fresh\n'
          '- No visible dust or stains\n'
          '- All items placed properly\n'
          '- Property ready for guest use\n'
          '- Turn off all the heating system before leaving',
      type: _SectionType.checklist,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgGrey,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, size: 22, color: _textPri),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Requirements',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: _textPri,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // ── Start button + property info ──
          Container(
            color: _bgGrey,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Column(
              children: [
                // Start button
                SizedBox(
                  width: 160,
                  height: 44,
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.play_arrow_rounded, size: 18),
                    label: const Text(
                      'Start',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Property card
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.taskType,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: _textPri,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${widget.propertyName} | ${widget.address}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: _textSec,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Map thumbnail
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: 64,
                        height: 56,
                        child: CustomPaint(
                          painter: _MiniMapPainter(),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),

          // ── Requirements header + count ──
          Container(
            color: _bgGrey,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: Row(
              children: [
                const Text(
                  'Requirements',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: _textPri,
                  ),
                ),
                const Spacer(),
                Text(
                  '$_doneReq of $_totalReq',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _orange,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ── Tab bar ──
          Container(
            color: _bgGrey,
            child: TabBar(
              controller: _tabController,
              labelColor: _accent,
              unselectedLabelColor: _textSec,
              labelStyle: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
              ),
              indicatorColor: _accent,
              indicatorWeight: 2.5,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              tabs: const [
                Tab(text: 'First Tasks'),
                Tab(text: 'Interior'),
                Tab(text: 'Exterior'),
                Tab(text: 'Finishing Touches'),
              ],
            ),
          ),

          // ── Tab content ──
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _SectionList(sections: _firstTasksSections),
                _SectionList(sections: _interiorSections),
                _SectionList(sections: _exteriorSections),
                _SectionList(sections: _finishingTouchesSections),
              ],
            ),
          ),

          // ── Bottom action bar ──
          _buildBottomBar(context),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          0, 12, 0, MediaQuery.of(context).padding.bottom + 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _BottomBarBtn(
            icon: Icons.build_outlined,
            label: 'Issues',
            color: _accent,
            onTap: () {},
          ),
          _BottomBarBtn(
            icon: Icons.compress_rounded,
            label: 'Collapse',
            color: _accent,
            onTap: () {},
          ),
          _BottomBarBtn(
            icon: Icons.check_box_outlined,
            label: 'Hide completed',
            color: _accent,
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

// ── Section list ──────────────────────────────────────────────────────────────

enum _SectionType { starRating, checklist }

class _ReqSection {
  final String text;
  final _SectionType type;
  const _ReqSection({required this.text, required this.type});
}

class _SectionList extends StatelessWidget {
  final List<_ReqSection> sections;
  const _SectionList({required this.sections});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: sections.length,
      separatorBuilder: (_, __) =>
          const Divider(height: 1, thickness: 1, color: Color(0xFFDDDDDD)),
      itemBuilder: (_, i) => _SectionTile(section: sections[i]),
    );
  }
}

class _SectionTile extends StatefulWidget {
  final _ReqSection section;
  const _SectionTile({super.key, required this.section});

  @override
  State<_SectionTile> createState() => _SectionTileState();
}

class _SectionTileState extends State<_SectionTile> {
  static const Color _textPri = Color(0xFF2A2A2A);
  static const Color _textSec = Color(0xFFAAAAAA);

  int _starRating = 0;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFEEF0F3),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Text
          Text(
            widget.section.text,
            style: const TextStyle(
              fontSize: 14.5,
              color: _textPri,
              height: 1.55,
            ),
          ),

          const SizedBox(height: 16),

          // Star rating (only for star type)
          if (widget.section.type == _SectionType.starRating) ...[
            Row(
              children: [
                ...List.generate(5, (i) {
                  return GestureDetector(
                    onTap: () => setState(() => _starRating = i + 1),
                    child: Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: Icon(
                        i < _starRating ? Icons.star_rounded : Icons.star_border_rounded,
                        size: 32,
                        color: i < _starRating
                            ? const Color(0xFFF57C00)
                            : _textSec,
                      ),
                    ),
                  );
                }),
                const Spacer(),
                Icon(Icons.camera_alt_outlined, size: 24, color: _textSec),
                const SizedBox(width: 16),
                Icon(Icons.edit_outlined, size: 22, color: _textSec),
              ],
            ),
          ],

          // Checklist button
          if (widget.section.type == _SectionType.checklist) ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _textSec,
                      side: const BorderSide(color: Color(0xFFCCCCCC)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      backgroundColor: Colors.white.withOpacity(0.5),
                    ),
                    icon: Icon(Icons.check_rounded, size: 18, color: _textSec),
                    label: Text(
                      'Checklist',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: _textSec,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Icon(Icons.camera_alt_outlined, size: 24, color: _textSec),
                const SizedBox(width: 16),
                Icon(Icons.edit_outlined, size: 22, color: _textSec),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ── Bottom bar button ─────────────────────────────────────────────────────────

class _BottomBarBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _BottomBarBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Mini map painter ──────────────────────────────────────────────────────────

class _MiniMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFFE8EDD8),
    );
    final road = Paint()
      ..color = Colors.white
      ..strokeWidth = 5
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
        Offset(0, size.height * 0.5), Offset(size.width, size.height * 0.5), road);
    canvas.drawLine(
        Offset(size.width * 0.5, 0), Offset(size.width * 0.5, size.height), road);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.55, size.height * 0.05,
            size.width * 0.38, size.height * 0.38),
        const Radius.circular(2),
      ),
      Paint()..color = const Color(0xFFC8D9A0),
    );
    canvas.drawCircle(
      Offset(size.width * 0.35, size.height * 0.38),
      6,
      Paint()..color = const Color(0xFFE53935),
    );
  }

  @override
  bool shouldRepaint(_) => false;
}