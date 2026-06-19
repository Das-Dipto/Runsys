import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../Widgets/board_stat_card.dart';
import '../Widgets/board_task_card.dart';
import '../Widgets/board_filter_bar.dart';
import '../../Home/Widgets/app_drawer.dart';
import '../../Api/api_controller.dart';

class BoardScreen extends StatefulWidget {
  const BoardScreen({super.key});

  @override
  State<BoardScreen> createState() => _BoardScreenState();
}

class _BoardScreenState extends State<BoardScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // ── Palette ──
  static const Color _bg      = Color(0xFF0A0A0F);
  static const Color _surface = Color(0xFF111118);
  static const Color _orange  = Color(0xFFFF7300);
  static const Color _textPri = Color(0xFFFFFFFF);
  static const Color _textSec = Color(0xFF8A8A9A);
  static const Color _border  = Color(0xFF1E1E2E);

  // ── State ──
  List<Map<String, dynamic>> _tasks = [];
  bool   _isLoading    = true;
  String _error        = '';
  String _statusFilter = 'All';
  String _boardFilter  = 'All Boards';
  String _sortOption   = 'Due Date';
  bool   _isGridView   = true;
  String _searchQuery  = '';

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
    _loadCards();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCards() async {
    setState(() { _isLoading = true; _error = ''; });

    final allTasks = <Map<String, dynamic>>[];
    int page = 1;

    while (true) {
      final result = await ApiController.getMyCards(page: page);
      if (!mounted) return;

      if (result['success'] != true) {
        setState(() {
          _error = result['message'] ?? 'Failed to load cards';
          _isLoading = false;
        });
        return;
      }

      final data = List<Map<String, dynamic>>.from(result['data'] as List);
      allTasks.addAll(data);

      final totalPages = result['totalPages'] as int? ?? 1;
      if (page >= totalPages) break;
      page++;
    }

    setState(() {
      _tasks = allTasks;
      _isLoading = false;
    });
  }

  // ── Filtering ──
  List<Map<String, dynamic>> get _filteredTasks {
    return _tasks.where((task) {
      // Status: All | IN_PROGRESS (Pending) | COMPLETED
      final status = (task['status'] as String? ?? '').toUpperCase();
      bool matchesStatus = true;
      if (_statusFilter == 'Pending')   matchesStatus = status == 'IN_PROGRESS';
      if (_statusFilter == 'Completed') matchesStatus = status == 'COMPLETED';

      final matchesBoard = _boardFilter == 'All Boards' ||
          (task['board_name'] as String? ?? '') == _boardFilter;

      final matchesSearch = _searchQuery.isEmpty ||
          (task['title'] as String? ?? '')
              .toLowerCase()
              .contains(_searchQuery.toLowerCase());

      return matchesStatus && matchesBoard && matchesSearch;
    }).toList()
      ..sort((a, b) {
        if (_sortOption == 'Due Date') {
          final da = a['due_date'] as String? ?? '';
          final db = b['due_date'] as String? ?? '';
          return da.compareTo(db);
        } else if (_sortOption == 'Priority') {
          const order = {'URGENT': 0, 'HIGH': 1, 'MEDIUM': 2, 'LOW': 3};
          final pa = (a['priority'] as String? ?? '').toUpperCase();
          final pb = (b['priority'] as String? ?? '').toUpperCase();
          return (order[pa] ?? 3).compareTo(order[pb] ?? 3);
        }
        return 0;
      });
  }

  // ── Stats ──
  int get _total     => _tasks.length;
  int get _completed => _tasks.where((t) =>
      (t['status'] as String? ?? '').toUpperCase() == 'COMPLETED').length;
  int get _pending   => _tasks.where((t) =>
      (t['status'] as String? ?? '').toUpperCase() == 'IN_PROGRESS').length;
  int get _overdue   => _tasks.where((t) => t['is_overdue'] == true).length;
  double get _progress => _total == 0 ? 0 : _completed / _total;

  List<String> get _boardOptions {
    final boards = _tasks
        .map((t) => t['board_name'] as String? ?? '')
        .where((b) => b.isNotEmpty)
        .toSet()
        .toList();
    return ['All Boards', ...boards];
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredTasks;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: _bg,
      drawer: const AppDrawer(),
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded, size: 24, color: _textPri),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        titleSpacing: 0,
        title: const Text(
          'My Assigned Task',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: _textPri,
            letterSpacing: -0.4,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 22),
            color: _textSec,
            onPressed: _loadCards,
            tooltip: 'Refresh',
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFFF7300)))
          : _error.isNotEmpty
              ? _buildError()
              : Column(
                  children: [
                    // ── Stats + Progress ──
                    Container(
                      color: _surface,
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: BoardStatCard(
                                        label: 'Total Tasks',
                                        value: '$_total',
                                        icon: Icons.assignment_outlined,
                                        iconColor: const Color(0xFF5C6BC0),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: BoardStatCard(
                                        label: 'Completed',
                                        value: '$_completed',
                                        icon: Icons.check_circle_outline_rounded,
                                        iconColor: const Color(0xFF43A047),
                                        valueColor: const Color(0xFF43A047),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: BoardStatCard(
                                        label: 'Pending',
                                        value: '$_pending',
                                        icon: Icons.schedule_rounded,
                                        iconColor: const Color(0xFFFF7300),
                                        valueColor: const Color(0xFFFF7300),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: BoardStatCard(
                                        label: 'Overdue',
                                        value: '$_overdue',
                                        icon: Icons.error_outline_rounded,
                                        iconColor: const Color(0xFFFF6B6B),
                                        valueColor: const Color(0xFFFF6B6B),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // ── Overall Progress ──
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: _bg,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: _border),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Overall Progress',
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: _textPri,
                                        ),
                                      ),
                                      Text(
                                        '${(_progress * 100).toStringAsFixed(0)}%',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: _textSec,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(6),
                                    child: LinearProgressIndicator(
                                      value: _progress,
                                      minHeight: 7,
                                      backgroundColor: const Color(0xFF1E1E2E),
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        _progress == 1.0
                                            ? const Color(0xFF43A047)
                                            : _orange,
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

                    const Divider(height: 1, thickness: 1, color: Color(0xFF1E1E2E)),

                    // ── Filter bar ──
                    BoardFilterBar(
                      searchController: _searchController,
                      statusFilter: _statusFilter,
                      boardFilter: _boardFilter,
                      sortOption: _sortOption,
                      isGridView: _isGridView,
                      boardOptions: _boardOptions,
                      onSearchChanged: (val) =>
                          setState(() => _searchQuery = val),
                      onStatusChanged: (val) =>
                          setState(() => _statusFilter = val),
                      onBoardChanged: (val) =>
                          setState(() => _boardFilter = val),
                      onSortChanged: (val) =>
                          setState(() => _sortOption = val),
                      onViewToggle: (isGrid) =>
                          setState(() => _isGridView = isGrid),
                    ),

                    const Divider(height: 1, thickness: 1, color: Color(0xFF1E1E2E)),

                    // ── Task grid / list ──
                    Expanded(
                      child: filtered.isEmpty
                          ? _buildEmpty()
                          : _isGridView
                              ? _buildGrid(filtered)
                              : _buildList(filtered),
                    ),
                  ],
                ),
    );
  }

  Widget _buildGrid(List<Map<String, dynamic>> tasks) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: tasks.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) =>
          BoardTaskCard(task: tasks[index], isGrid: true),
    );
  }

  Widget _buildList(List<Map<String, dynamic>> tasks) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: tasks.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) =>
          BoardTaskCard(task: tasks[index], isGrid: false),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: const Color(0xFFFF7300).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.calendar_month_rounded,
                size: 36, color: Color(0xFFFF7300)),
          ),
          const SizedBox(height: 16),
          const Text('No tasks found',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white)),
          const SizedBox(height: 8),
          const Text('Try adjusting your filters.',
              style: TextStyle(fontSize: 14, color: Color(0xFF8A8A9A))),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFFF6B6B), size: 42),
          const SizedBox(height: 12),
          Text(_error,
              style: const TextStyle(color: Color(0xFF8A8A9A)),
              textAlign: TextAlign.center),
          const SizedBox(height: 16),
          TextButton(
            onPressed: _loadCards,
            child: const Text('Retry',
                style: TextStyle(color: Color(0xFFFF7300))),
          ),
        ],
      ),
    );
  }
}