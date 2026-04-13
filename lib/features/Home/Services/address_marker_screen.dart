import 'package:flutter/material.dart';

class AddressMarkerScreen extends StatefulWidget {
  const AddressMarkerScreen({super.key});

  @override
  State<AddressMarkerScreen> createState() => _AddressMarkerScreenState();
}

class _AddressMarkerScreenState extends State<AddressMarkerScreen>
    with SingleTickerProviderStateMixin {
  static const Color _accent  = Color(0xFF29B6F6);
  static const Color _textPri = Color(0xFF1A1A1A);
  static const Color _textSec = Color(0xFF9E9E9E);
  static const Color _bgGrey  = Color(0xFFF2F4F6);

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
          icon: const Icon(Icons.arrow_back_rounded,
              size: 22, color: _textPri),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Address Marker',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: _textPri,
            letterSpacing: -0.3,
          ),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () {},
            child: const Text(
              'Edit name',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: _accent,
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: _accent,
              unselectedLabelColor: _textSec,
              labelStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
              ),
              indicatorColor: _accent,
              indicatorWeight: 2.5,
              tabs: const [
                Tab(text: 'OVERVIEW'),
                Tab(text: 'ABOUT'),
                Tab(text: 'ITEMS (0)'),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _OverviewTab(),
          _AboutTab(),
          _ItemsTab(),
        ],
      ),
    );
  }
}

// ── OVERVIEW TAB ──────────────────────────────────────────────────────────────

class _OverviewTab extends StatelessWidget {
  const _OverviewTab();

  static const Color _textPri = Color(0xFF1A1A1A);
  static const Color _textSec = Color(0xFF9E9E9E);
  static const Color _accent  = Color(0xFF29B6F6);
  static const Color _divider = Color(0xFFEEEEEE);
  static const Color _bgGrey  = Color(0xFFF2F4F6);

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.only(bottom: 100),
          children: [
            // Photos section
            _buildWhiteSection(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Photos',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _textPri,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'No photos yet.',
                    style: TextStyle(fontSize: 14, color: _textSec),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Documents',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: _textPri,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'No documents yet.',
                    style: TextStyle(fontSize: 14, color: _textSec),
                  ),
                ],
              ),
            ),

            // Maintenance issues section
            Container(
              color: _bgGrey,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: const Text(
                'NO MAINTENANCE ISSUES',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _textSec,
                  letterSpacing: 1.2,
                ),
              ),
            ),

            Container(
              color: _bgGrey,
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Column(
                children: [
                  // Balloon illustration
                  SizedBox(
                    height: 180,
                    child: CustomPaint(
                      painter: _BalloonsPainter(),
                      size: const Size(double.infinity, 180),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'There are currently no issues reported',
                    style: TextStyle(
                      fontSize: 14,
                      color: _textSec,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),

        // Report an issue button
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: EdgeInsets.fromLTRB(
                16, 12, 16,
                MediaQuery.of(context).padding.bottom + 12),
            color: Colors.white,
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: _accent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Report an issue',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWhiteSection({required Widget child}) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      margin: const EdgeInsets.only(bottom: 8),
      child: child,
    );
  }
}

// ── ABOUT TAB ─────────────────────────────────────────────────────────────────

class _AboutTab extends StatelessWidget {
  const _AboutTab();

  static const Color _textSec = Color(0xFF9E9E9E);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 64,
            color: _textSec.withOpacity(0.45),
          ),
          const SizedBox(height: 20),
          Text(
            'No about information for this element.',
            style: TextStyle(
              fontSize: 14,
              color: _textSec.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}

// ── ITEMS TAB ─────────────────────────────────────────────────────────────────

class _ItemsTab extends StatelessWidget {
  const _ItemsTab();

  static const Color _textSec = Color(0xFF9E9E9E);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.info_outline_rounded,
            size: 64,
            color: _textSec.withOpacity(0.45),
          ),
          const SizedBox(height: 20),
          Text(
            'No items for this element.',
            style: TextStyle(
              fontSize: 14,
              color: _textSec.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Balloons painter ──────────────────────────────────────────────────────────

class _BalloonsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFCCCCCC).withOpacity(0.55)
      ..style = PaintingStyle.fill;

    final cx = size.width / 2;
    final cy = size.height / 2;

    // Cloud blobs
    _drawCloud(canvas, paint, cx * 0.35, cy * 0.55, 52, 30);
    _drawCloud(canvas, paint, cx * 0.28, cy * 1.55, 68, 38);
    _drawCloud(canvas, paint, cx * 1.65, cy * 1.62, 78, 40);

    // Balloons
    _drawBalloon(canvas, paint, cx * 0.85, cy * 0.9,  28, size);
    _drawBalloon(canvas, paint, cx * 1.10, cy * 0.72, 36, size);
    _drawBalloon(canvas, paint, cx * 1.32, cy * 0.85, 30, size);
  }

  void _drawCloud(Canvas canvas, Paint paint,
      double cx, double cy, double rx, double ry) {
    canvas.drawOval(Rect.fromCenter(
        center: Offset(cx, cy), width: rx * 2, height: ry * 2), paint);
    canvas.drawOval(Rect.fromCenter(
        center: Offset(cx - rx * 0.4, cy - ry * 0.3),
        width: rx * 1.2, height: ry * 1.2), paint);
    canvas.drawOval(Rect.fromCenter(
        center: Offset(cx + rx * 0.4, cy - ry * 0.25),
        width: rx * 1.0, height: ry * 1.0), paint);
  }

  void _drawBalloon(Canvas canvas, Paint paint,
      double cx, double cy, double r, Size size) {
    // Balloon body
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(cx, cy), width: r * 2, height: r * 2.2),
      paint,
    );

    // Subtle highlight
    canvas.drawOval(
      Rect.fromCenter(
          center: Offset(cx - r * 0.25, cy - r * 0.35),
          width: r * 0.5,
          height: r * 0.35),
      Paint()
        ..color = Colors.white.withOpacity(0.35)
        ..style = PaintingStyle.fill,
    );

    // String
    final stringPaint = Paint()
      ..color = const Color(0xFFAAAAAA)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(cx, cy + r * 1.1)
      ..cubicTo(
        cx - 6, cy + r * 1.6,
        cx + 6, cy + r * 2.1,
        cx, size.height,
      );
    canvas.drawPath(path, stringPaint);
  }

  @override
  bool shouldRepaint(_) => false;
}