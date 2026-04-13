import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../Widgets/app_drawer.dart';
import '../Widgets/sort_bottom_sheet.dart';
import '../widgets/date_range_bottom_sheet.dart';
import '../../Task/Screens/today_task_list.dart';
import '../../Task/screens/all_task_list.dart';
import '../../Task/screens/tomorrow_task_list.dart';
import '../../Task/screens/week_task_list.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentTabIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  SortOption _currentSort = SortOption.urgent;
  DateTime? _filterStart;
  DateTime? _filterEnd;

  final List<String> _tabLabels = [
    'TODAY',
    'TOMORROW',
    'WEEK',
    'ALL',
  ];

  String get _emptyTitle {
    if (_currentTabIndex == 3) {
      return "Life's a breeze";
    }
    return "No assigned tasks for ${_tabLabels[_currentTabIndex].toLowerCase()}.";
  }

  String? get _emptySubtitle {
    if (_currentTabIndex == 3) {
      return "Your task list is empty. We'll notify you when you have new tasks.";
    }
    return "Try changing your dates to see your assigned tasks.";
  }

  Future<void> _openSortSheet() async {
    final result = await showModalBottomSheet<SortOption>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => SortBottomSheet(currentSort: _currentSort),
    );
    if (result != null) {
      setState(() => _currentSort = result);
    }
  }

  Future<void> _openDateRangeSheet() async {
    final result = await showModalBottomSheet<Map<String, DateTime?>>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => DateRangeBottomSheet(
        initialStart: _filterStart,
        initialEnd: _filterEnd,
      ),
    );
    if (result != null) {
      setState(() {
        _filterStart = result['start'];
        _filterEnd = result['end'];
      });
    }
  }

  // ── Web-consistent palette ──
  static const Color _bg         = Color(0xFF0A0A0F);
  static const Color _surface    = Color(0xFF111118);
  static const Color _surfaceAlt = Color(0xFF16161F);
  static const Color _orange     = Color(0xFFFF7300);
  static const Color _textPri    = Color(0xFFFFFFFF);
  static const Color _textSec    = Color(0xFF8A8A9A);
  static const Color _border     = Color(0xFF1E1E2E);

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
  }

  @override
  Widget build(BuildContext context) {
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
          'My tasks',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: _textPri,
            letterSpacing: -0.4,
          ),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10),
            child: TextButton(
              onPressed: _openSortSheet,
              style: TextButton.styleFrom(
                backgroundColor: _orange.withOpacity(0.12),
                foregroundColor: _orange,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                minimumSize: const Size(0, 32),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Sort by ${_currentSort.label.toLowerCase()}',
                    style: const TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.keyboard_arrow_down_rounded, size: 16),
                ],
              ),
            ),
          ),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.filter_list_rounded, size: 22),
            color: _textSec,
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.search_rounded, size: 22),
            color: _textSec,
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Tab bar ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            height: 58,
            decoration: BoxDecoration(
              color: _surface,
              border: Border(
                bottom: BorderSide(color: _border, width: 1),
              ),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _openDateRangeSheet,
                  child: Icon(
                    Icons.calendar_today_rounded,
                    size: 22,
                    color: _filterStart != null ? _orange : _textSec,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: List.generate(_tabLabels.length, (index) {
                        final isActive = _currentTabIndex == index;
                        return GestureDetector(
                          onTap: () {
                            setState(() => _currentTabIndex = index);
                          },
                          child: Padding(
                            padding: const EdgeInsets.only(right: 32),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _tabLabels[index],
                                  style: TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: isActive
                                        ? FontWeight.w700
                                        : FontWeight.w600,
                                    color: isActive ? _orange : _textSec,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                if (isActive)
                                  Container(
                                    width: 38,
                                    height: 3.5,
                                    decoration: BoxDecoration(
                                      color: _orange,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Body ──
          Expanded(
            child: _buildTabBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBody() {
    if (_currentTabIndex == 0) return const TodayTaskList();
    if (_currentTabIndex == 1) return const TomorrowTaskList();
    if (_currentTabIndex == 2) return const WeekTaskList();
    if (_currentTabIndex == 3) return const AllTaskList();

    // Empty state (design updated)
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_currentTabIndex == 3)
              Column(
                children: [
                  Text(
                    _emptyTitle,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: _textPri,
                      letterSpacing: -0.6,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Icon(
                    Icons.emoji_emotions_rounded,
                    size: 92,
                    color: _orange.withOpacity(0.85),
                  ),
                ],
              )
            else
              Container(
                width: 180,
                height: 120,
                decoration: BoxDecoration(
                  color: _surfaceAlt,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: _border, width: 1),
                ),
                child: const Center(
                  child: Icon(
                    Icons.assignment_outlined,
                    size: 48,
                    color: _textSec,
                  ),
                ),
              ),
            const SizedBox(height: 40),
            Text(
              _emptyTitle,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: _textPri,
                height: 1.1,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            if (_emptySubtitle != null)
              Text(
                _emptySubtitle!,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: _textSec,
                ),
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: 60),
          ],
        ),
      ),
    );
  }
}