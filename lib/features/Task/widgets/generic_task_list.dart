// lib/Task/Widgets/generic_task_list.dart

import 'package:flutter/material.dart';
import '../../Api/api_controller.dart';
import '../../Models/task_model.dart';

// Import SortOption from the bottom sheet file
import '../../Home/Widgets/sort_bottom_sheet.dart';   // ← This is the important import
import '../../Home/Widgets/filter_bottom_sheet.dart';   // ← This is the important import

// Import TaskCard from where it is defined
import '../Screens/today_task_list.dart';

class GenericTaskList extends StatefulWidget {
  final String dateRange;
  final String emptyTitle;
  final String? emptySubtitle;
  final SortOption? sortOption;
  final FilterOption? filterOption;     

  const GenericTaskList({
    super.key,
    required this.dateRange,
    required this.emptyTitle,
    this.emptySubtitle,
    this.sortOption,
    this.filterOption,                    // ← Add this line
  });

  @override
  State<GenericTaskList> createState() => _GenericTaskListState();
}

class _GenericTaskListState extends State<GenericTaskList> {
  List<dynamic> _tasks = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

  @override
  void didUpdateWidget(covariant GenericTaskList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.dateRange != widget.dateRange || 
        oldWidget.sortOption != widget.sortOption) {
      _loadTasks();
    }
  }
  Future<void> _loadTasks() async {
    print("🔄 Loading → date: ${widget.dateRange} | Sort: ${widget.sortOption?.label ?? 'none'} | Filter: ${widget.filterOption?.label ?? 'none'}");

    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await ApiController.getFilteredTasks(
      dateRange: widget.dateRange == "all" ? null : widget.dateRange,
      sortOption: widget.sortOption,
      filterOption: widget.filterOption,     // ← Add this line
    );

    if (!mounted) return;

    if (result['success'] == true) {
      setState(() {
        _tasks = result['data'] ?? [];
        _isLoading = false;
      });
    } else {
      setState(() {
        _error = result['message'];
        _isLoading = false;
      });
    }
  }
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: const Color(0xFFFF7300)),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Color(0xFFFF6B6B), size: 42),
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Color(0xFF8A8A9A))),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _loadTasks,
              child: const Text('Retry', style: TextStyle(color: Color(0xFFFF7300))),
            ),
          ],
        ),
      );
    }

    if (_tasks.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.dateRange == "all")
                Column(
                  children: [
                    Text(
                      widget.emptyTitle,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.6,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    Icon(
                      Icons.emoji_emotions_rounded,
                      size: 92,
                      color: const Color(0xFFFF7300).withOpacity(0.85),
                    ),
                  ],
                )
              else
                Container(
                  width: 180,
                  height: 120,
                  decoration: BoxDecoration(
                    color: const Color(0xFF16161F),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF1E1E2E), width: 1),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.assignment_outlined,
                      size: 48,
                      color: Color(0xFF8A8A9A),
                    ),
                  ),
                ),
              const SizedBox(height: 40),
              Text(
                widget.emptyTitle,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1.1,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              if (widget.emptySubtitle != null)
                Text(
                  widget.emptySubtitle!,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.5,
                    color: Color(0xFF8A8A9A),
                  ),
                  textAlign: TextAlign.center,
                ),
              const SizedBox(height: 60),
            ],
          ),
        ),
      );
    }

    // Render TaskCard
    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: _tasks.map((json) {
        final task = TaskModel.fromJson(json);
        return TaskCard(task: task, onRefresh: _loadTasks);
      }).toList(),
    );
  }
}