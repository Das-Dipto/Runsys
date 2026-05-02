import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../Home/Widgets/app_drawer.dart';
import '../../Task/widgets/generic_task_list.dart';   // Reuse for empty state consistency
import '../../Api/api_controller.dart';
import '../../Models/task_model.dart';
import '../../Task/screens/today_task_list.dart';   // For TaskCard

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  List<TaskModel> _completedTasks = [];
  bool _isLoading = true;
  String? _error;

  // ── Dark theme palette (same as HomeScreen) ──
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
    _loadCompletedTasks();
  }

  Future<void> _loadCompletedTasks() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await ApiController.getCompletedTasks();

    if (!mounted) return;

    if (result['success'] == true) {
      final List data = result['data'] ?? [];
      setState(() {
        _completedTasks = data.map((e) => TaskModel.fromJson(e)).toList();
        _isLoading = false;
      });
    } else {
      setState(() {
        _error = result['message'] ?? 'Failed to load history';
        _isLoading = false;
      });
    }
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
          'My history',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: _textPri,
            letterSpacing: -0.4,
          ),
        ),
        // No sort, filter, or search buttons
      ),
      body: Column(
        children: [
          // Simple header bar (no tabs, no calendar)
          Container(
            height: 58,
            decoration: BoxDecoration(
              color: _surface,
              border: Border(
                bottom: BorderSide(color: _border, width: 1),
              ),
            ),
            child: const Center(
              child: Text(
                'Completed Tasks',
                style: TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w600,
                  color: _textSec,
                  letterSpacing: 0.4,
                ),
              ),
            ),
          ),

          // Body
          Expanded(
            child: _buildBody(),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: _orange),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: const Color(0xFFFF6B6B), size: 42),
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: _textSec)),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _loadCompletedTasks,
              child: Text('Retry', style: TextStyle(color: _orange)),
            ),
          ],
        ),
      );
    }

    if (_completedTasks.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
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
                    Icons.history_rounded,
                    size: 52,
                    color: _textSec,
                  ),
                ),
              ),
              const SizedBox(height: 48),
              const Text(
                "Life's a Running System",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: _textPri,
                  height: 1.1,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              const Text(
                "No completed tasks yet. Once you finish tasks, they will appear here.",
                style: TextStyle(
                  fontSize: 15.5,
                  height: 1.45,
                  color: _textSec,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      );
    }

    // Show completed tasks using TaskCard
    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: _completedTasks.map((task) {
        return TaskCard(
          task: task,
          onRefresh: _loadCompletedTasks,   // Refresh after coming back from detail
          disableNavigation: true, 
        );
      }).toList(),
    );
  }
}