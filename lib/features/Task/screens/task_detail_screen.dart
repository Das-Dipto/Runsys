import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../Api/api_controller.dart';
import '../../Models/task_model.dart';
import '../widgets/task_submission_handler.dart';
import '../widgets/task_requirements_section.dart';

class TaskDetailScreen extends StatefulWidget {
  final TaskModel task;
  const TaskDetailScreen({super.key, required this.task});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  Map<String, dynamic>? _detail;
  bool _isLoading = true;
  String? _error;

  // Timer state
  bool _isTimerRunning = false;
  bool _isStartLoading = false;
  bool _isStopLoading  = false;
  int  _currentLogId   = -1;
  Duration _elapsed    = Duration.zero;
  Timer?   _ticker;

  // Last stop summary
  String? _lastTotalFormatted;
  String? _lastBillable;

  final _submission = TaskSubmissionHandler();

  bool _showRequirements = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
    _loadDetail();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _submission.dispose();
    super.dispose();
  }

  // ── Data loading ──────────────────────────────────────────────────────────
  Future<void> _loadDetail() async {
    setState(() { _isLoading = true; _error = null; });
    final result = await ApiController.getTaskDetail(widget.task.id);
    if (!mounted) return;

    if (result['success'] == true) {
      final data = result['data'];
      setState(() {
        _detail = data;
        _isLoading = false;
      });

      final isActive = data['is_timer_active'] == true;
      final activeLog = data['active_time_log'];

      if (isActive && activeLog != null) {
        final logId = (activeLog['id'] as num).toInt();
        final elapsedSeconds = (activeLog['elapsed_seconds'] as num?)?.toInt() ?? 0;

        setState(() {
          _isTimerRunning = true;
          _currentLogId = logId;
          _elapsed = Duration(seconds: elapsedSeconds);
        });
        _startTicker();
      }
    } else {
      setState(() { _error = result['message']; _isLoading = false; });
    }
  }

  Future<void> _autoCheckTimerState() async {
    final result = await ApiController.startTimeLog(widget.task.id);
    if (!mounted) return;
    if (result['success'] == true) {
      final data = result['data'];
      final logId = data['id'] as int;
      final startTime = DateTime.tryParse(data['start_time'] ?? '')?.toLocal();
      final alreadyElapsed = startTime != null
          ? DateTime.now().difference(startTime)
          : Duration.zero;
      setState(() {
        _isTimerRunning = true;
        _currentLogId   = logId;
        _elapsed        = alreadyElapsed;
      });
      _startTicker();
    } else {
      setState(() { _isTimerRunning = false; });
    }
  }

  // ── Timer helpers ─────────────────────────────────────────────────────────

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() { _elapsed += const Duration(seconds: 1); });
    });
  }

  String _formatElapsed(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  Future<void> _onStartPressed() async {
    if (_isTimerRunning) return;

    setState(() => {
      _isStartLoading = true,
      _showRequirements = false
    });

    final result = await ApiController.startTimeLog(widget.task.id);

    if (!mounted) return;

    if (result['success'] == true) {
      final data = result['data'];
      final logId = (data['id'] as num).toInt();

      final timeTracking = data['time_tracking'];
      final totalMinutes = (timeTracking?['total_time_minutes'] as num?)?.toInt() ?? 0;
      final totalSeconds = (timeTracking?['total_time_seconds'] as num?)?.toInt() ?? 0;
      final baseElapsed = Duration(minutes: totalMinutes, seconds: totalSeconds);

      setState(() {
        _isTimerRunning = true;
        _currentLogId = logId;
        _elapsed = baseElapsed;
        _isStartLoading = false;
        _lastTotalFormatted = null;
        _lastBillable = null;
      });

      _startTicker();
    } else {
      setState(() => _isStartLoading = false);
      if (mounted) {
        final message = result['message'] ?? '';
        final isActiveTaskBlock = message.toLowerCase().contains('active') ||
            message.toLowerCase().contains('already') ||
            message.toLowerCase().contains('running') ||
            message.toLowerCase().contains('stop');

        if (isActiveTaskBlock) {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              backgroundColor: const Color(0xFF111118),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Color(0xFFFF7300), size: 22),
                  SizedBox(width: 10),
                  Text('Task Already Running',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white)),
                ],
              ),
              content: SingleChildScrollView(
                child: Text(
                  message.isNotEmpty
                      ? message
                      : 'You are currently working on another task. Please stop that task first before starting a new one.',
                  style: const TextStyle(fontSize: 14.5, color: Color(0xFF8A8A9A), height: 1.5),
                ),
              ),
              actions: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF7300),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('OK', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message.isNotEmpty ? message : 'Failed to start timer')),
          );
        }
      }
    }
  }

  Future<void> _onStopPressed() async {
    if (_currentLogId == -1 || !_isTimerRunning) return;

    setState(() => {
      _isStopLoading = true,
      _showRequirements = false
    });

    final result = await ApiController.stopTimeLog(_currentLogId);

    if (!mounted) return;

    if (result['success'] == true) {
      final data = result['data'];

      _ticker?.cancel();

      setState(() {
        _isTimerRunning = false;
        _isStopLoading = false;
        _elapsed = Duration.zero;
        _currentLogId = -1;
        _lastTotalFormatted = data['total_formatted']?.toString();
        _lastBillable = data['billable']?.toString();
      });
    } else {
      setState(() => _isStopLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Failed to stop timer')),
        );
      }
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Color _priorityColor(String priority) {
    switch (priority.toUpperCase()) {
      case 'URGENT': return const Color(0xFFFF6B6B);
      case 'HIGH':   return const Color(0xFFFF7300);
      case 'MEDIUM': return const Color(0xFF1E88E5);
      default:       return const Color(0xFF8A8A9A);
    }
  }

  String _formatDate(String? iso) {
    if (iso == null) return '—';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '—';
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    const days   = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
    return '${days[dt.weekday - 1]}, ${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  String _formatTime(String? iso) {
    if (iso == null) return '—';
    final dt = DateTime.tryParse(iso)?.toLocal();
    if (dt == null) return '—';
    final h  = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m  = dt.minute.toString().padLeft(2, '0');
    final ap = dt.hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $ap';
  }

  bool get _isOverdue {
    final due = _detail?['due_date'] ?? widget.task.dueDate;
    if (due == null) return false;
    return DateTime.tryParse(due)?.isBefore(DateTime.now()) ?? false;
  }

  int _countFilledItems() {
    int count = 0;
    final sections = (_detail?['template']?['sections'] as List?) ?? [];
    for (final section in sections) {
      for (final item in (section['items'] as List? ?? [])) {
        final id = item['id'].toString();
        final type = item['type'] ?? '';
        if (type == 'YES_NO' && _submission.yesNoAnswers.containsKey(id)) {
          count++;
        } else if (type == 'REPORT' && (_submission.reportControllers[id]?.text.trim().isNotEmpty ?? false)) {
          count++;
        } else if (type == 'CHECKLIST' && (_submission.checklistAnswers[id] != null && _submission.checklistAnswers[id]!.isNotEmpty)) {
          count++;
        }
      }
    }
    return count;
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final sections = (_detail?['template']?['sections'] as List?) ?? [];
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildMapHeader(context)),
              if (_isLoading)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator(color: Color(0xFFFF7300))),
                )
              else if (_error != null)
                SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline, color: Color(0xFFFF6B6B), size: 42),
                        const SizedBox(height: 12),
                        Text(_error!, style: const TextStyle(color: Color(0xFF8A8A9A))),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: _loadDetail,
                          child: const Text('Retry', style: TextStyle(color: Color(0xFFFF7300))),
                        ),
                      ],
                    ),
                  ),
                )
              else ...[
                SliverToBoxAdapter(child: _buildStatusStrip()),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 160),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTaskHeader(),
                        const SizedBox(height: 20),
                        _buildInfoRow(Icons.calendar_today_rounded, 'Due on', _formatDate(_detail!['due_date'])),
                        const SizedBox(height: 16),
                        _buildInfoRow(Icons.business_rounded, 'Department', _detail!['department_name'] ?? '—'),
                        const SizedBox(height: 16),
                        _buildInfoRow(Icons.person_outline_rounded, 'Created by', _detail!['created_by_name'] ?? '—'),
                        if (_detail!['template_title'] != null) ...[
                          const SizedBox(height: 16),
                          _buildInfoRow(Icons.description_outlined, 'Template', _detail!['template_title']),
                        ],
                        const SizedBox(height: 20),
                        if ((_detail!['tags_details'] as List?)?.isNotEmpty == true) ...[
                          _buildTagsRow(),
                          const SizedBox(height: 20),
                        ],
                        _buildActionTiles(),
                        const SizedBox(height: 32),

                        if (_lastTotalFormatted != null || _lastBillable != null)
                          _buildSessionSummary(),

                        // ── Requirements section (now delegated to separate widget) ──
                        if (_detail!['template'] != null && _showRequirements) ...[
                          _buildSectionHeader('Requirements'),
                          const SizedBox(height: 14),
                          TaskRequirementsSection(
                            detail: _detail!,
                            submission: _submission,
                            onChanged: () => setState(() {}),
                          ),
                          const SizedBox(height: 32),
                        ],

                        if (sections.isNotEmpty && _isTimerRunning && _showRequirements) ...[
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                _submission.showConfirmAndSubmit(
                                  context: context,
                                  taskId: widget.task.id,
                                  timeLogId: _currentLogId,
                                  sections: sections,
                                  onSuccess: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: const Text(
                                          'Task submitted successfully!',
                                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                                        ),
                                        backgroundColor: const Color(0xFF43A047),
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      ),
                                    );
                                  },
                                  onStopTimer: _onStopPressed,
                                );
                              },
                              icon: const Icon(Icons.assignment_turned_in_rounded, size: 22),
                              label: const Text('Submit Requirements',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF43A047),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                        ],

                        _buildSectionHeader('Comments'),
                        const SizedBox(height: 14),
                        _buildComments(),
                        const SizedBox(height: 32),

                        if ((_detail!['time_logs'] as List?)?.isNotEmpty == true) ...[
                          _buildSectionHeader('Time Logs'),
                          const SizedBox(height: 14),
                          _buildTimeLogs(),
                          const SizedBox(height: 32),
                        ],

                        _buildSectionHeader('Task'),
                        const SizedBox(height: 14),
                        _buildNavRow(
                          icon: Icons.attach_money_rounded,
                          label: 'Rate',
                          trailing: _detail!['rate'] != null
                              ? _Chip(label: '\$${_detail!['rate']} / ${_detail!['rate_type']}')
                              : null,
                          showArrow: false,
                        ),
                        const Divider(height: 1, thickness: 1, color: Color(0xFF1E1E2E)),
                        if (_detail!['estimated_time'] != null) ...[
                          _buildNavRow(
                            icon: Icons.timer_outlined,
                            label: 'Estimated time',
                            trailing: _Chip(label: _detail!['estimated_time']),
                            showArrow: false,
                          ),
                          const Divider(height: 1, thickness: 1, color: Color(0xFF1E1E2E)),
                        ],
                        _buildNavRow(
                          icon: Icons.repeat_rounded,
                          label: 'Repeating task',
                          trailing: _Chip(label: _detail!['is_repeating'] == '1' ? 'Yes' : 'No'),
                          showArrow: false,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),

          // Floating back + direction buttons
          Positioned(
            top: MediaQuery.of(context).padding.top + 12,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _CircleBtn(icon: Icons.arrow_back_rounded, onTap: () => Navigator.pop(context)),
                _CircleBtn(icon: Icons.assistant_direction_rounded, onTap: () {}),
              ],
            ),
          ),

          // Bottom bar with timer + start/stop
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomBar(context),
          ),
        ],
      ),
    );
  }

  // ── Map header ────────────────────────────────────────────────────────────
  Widget _buildMapHeader(BuildContext context) {
    return SizedBox(
      height: 260,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            color: const Color(0xFF1E2A1A),
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
                  colors: [Colors.transparent, Color(0xCC0A0A0F)],
                ),
              ),
            ),
          ),
          const Center(
            child: Icon(Icons.location_on_rounded, size: 52, color: Color(0xFFFF6B6B)),
          ),
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.task.propertyName.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.4,
                    height: 1.3,
                    shadows: [Shadow(blurRadius: 8, color: Colors.black87)],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.task.propertyFullAddress,
                  style: const TextStyle(fontSize: 13.5, color: Color(0xFF8A8A9A)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Status strip ──────────────────────────────────────────────────────────
  Widget _buildStatusStrip() {
    final status = _detail!['my_assignment']?['assignment_status'] ?? widget.task.myAssignment.status;
    final isOverdue = _isOverdue;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        color: isOverdue ? const Color(0xFF2A1A1A) : const Color(0xFF16161F),
        border: const Border(bottom: BorderSide(color: Color(0xFF1E1E2E), width: 1)),
      ),
      child: Row(
        children: [
          Icon(
            isOverdue ? Icons.warning_amber_rounded : Icons.assignment_outlined,
            size: 19,
            color: isOverdue ? const Color(0xFFFF6B6B) : const Color(0xFF8A8A9A),
          ),
          const SizedBox(width: 10),
          Text(
            isOverdue ? 'OVERDUE · $status' : status,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: isOverdue ? const Color(0xFFFF6B6B) : Colors.white,
              letterSpacing: 0.6,
            ),
          ),
          const Spacer(),
          if (_detail!['watch_task'] == 1)
            const Icon(Icons.visibility_outlined, size: 19, color: Color(0xFF8A8A9A)),
        ],
      ),
    );
  }

  // ── Task header ───────────────────────────────────────────────────────────
  Widget _buildTaskHeader() {
    final priority = _detail!['priority'] ?? widget.task.priority;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            _detail!['title'] ?? widget.task.title,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.6,
              height: 1.1,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: _priorityColor(priority),
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 16),
              const SizedBox(width: 6),
              Text(priority,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Colors.white)),
            ],
          ),
        ),
      ],
    );
  }

  // ── Info row ──────────────────────────────────────────────────────────────
  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: const Color(0xFF8A8A9A)),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12.5, color: Color(0xFF8A8A9A))),
              const SizedBox(height: 3),
              Text(
                value,
                style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w500, color: Colors.white),
                softWrap: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Tags ──────────────────────────────────────────────────────────────────
  Widget _buildTagsRow() {
    final tags = (_detail!['tags_details'] as List?) ?? [];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: tags.map<Widget>((t) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFFF7300).withOpacity(0.12),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFFF7300).withOpacity(0.25)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.label_outline_rounded, size: 15, color: Color(0xFFFF7300)),
              const SizedBox(width: 6),
              Text(t['name'] ?? '',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFFFF7300))),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ── Action tiles ──────────────────────────────────────────────────────────
  Widget _buildActionTiles() {
    final sections = (_detail!['template']?['sections'] as List?) ?? [];
    final totalItems = sections.fold<int>(0, (sum, s) => sum + ((s['items'] as List?)?.length ?? 0));
    final commentsCount = _detail!['comments_count'] ?? 0;

    return Row(
      children: [
        _ActionTile(
          icon: Icons.rule_rounded,
          label: 'Requirements',
          badge: '${_countFilledItems()}/$totalItems',
          onTap: () {
            if (!_isTimerRunning) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Row(
                    children: [
                      Icon(Icons.info_outline_rounded, color: Colors.white, size: 18),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Please start work first to view requirements.',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                  backgroundColor: const Color(0xFF333344),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              );
              return;
            }
            setState(() => _showRequirements = !_showRequirements);
          },
        ),
        const SizedBox(width: 12),
        _ActionTile(icon: Icons.attach_file_rounded, label: 'Attachments', onTap: () {}),
        const SizedBox(width: 12),
        _ActionTile(
          icon: Icons.chat_bubble_outline_rounded,
          label: 'Comments',
          badge: '$commentsCount',
          onTap: () {},
        ),
      ],
    );
  }

  // ── Session summary ───────────────────────────────────────────────────────
  Widget _buildSessionSummary() {
    return Container(
      margin: const EdgeInsets.only(bottom: 28),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF43A047).withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF43A047).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF43A047).withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_rounded, color: Color(0xFF43A047), size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Last session completed',
                    style: TextStyle(fontSize: 13, color: Color(0xFF8A8A9A), fontWeight: FontWeight.w500)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    if (_lastTotalFormatted != null) ...[
                      const Icon(Icons.timer_outlined, size: 16, color: Color(0xFF43A047)),
                      const SizedBox(width: 6),
                      Text(_lastTotalFormatted!,
                          style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Colors.white)),
                    ],
                    if (_lastTotalFormatted != null && _lastBillable != null)
                      const SizedBox(width: 16),
                    if (_lastBillable != null) ...[
                      const Icon(Icons.attach_money_rounded, size: 16, color: Color(0xFF43A047)),
                      Text('\$$_lastBillable billable',
                          style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: Colors.white)),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Comments ──────────────────────────────────────────────────────────────
  Widget _buildComments() {
    final comments = (_detail!['comments'] as List?) ?? [];
    if (comments.isEmpty) {
      return const Text('No comments yet.', style: TextStyle(color: Color(0xFF8A8A9A), fontSize: 15));
    }
    return Column(
      children: comments.map<Widget>((c) {
        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF16161F),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF1E1E2E)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF7300).withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        (c['user_name'] ?? '?')[0].toUpperCase(),
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFFFF7300)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c['user_name'] ?? '',
                            style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600, color: Colors.white)),
                        Text(_formatTime(c['created_at']),
                            style: const TextStyle(fontSize: 12, color: Color(0xFF8A8A9A))),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(c['comment'] ?? '',
                  style: const TextStyle(fontSize: 14.5, color: Colors.white, height: 1.5)),
            ],
          ),
        );
      }).toList(),
    );
  }

  // ── Time logs ─────────────────────────────────────────────────────────────
  Widget _buildTimeLogs() {
    final logs = (_detail!['time_logs'] as List?) ?? [];
    final totalHours    = _detail!['total_time_spent_hours'] ?? '0';
    final totalBillable = _detail!['total_billable_amount'] ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...logs.map<Widget>((log) {
          final isActive = log['end_time'] == null;
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isActive ? const Color(0xFF43A047).withOpacity(0.08) : const Color(0xFF16161F),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isActive ? const Color(0xFF43A047).withOpacity(0.4) : const Color(0xFF1E1E2E),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isActive ? Icons.play_circle_outline_rounded : Icons.check_circle_outline_rounded,
                  color: isActive ? const Color(0xFF43A047) : const Color(0xFF8A8A9A),
                  size: 22,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${_formatTime(log['start_time'])} → ${isActive ? 'Active' : _formatTime(log['end_time'])}',
                        style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w600,
                          color: isActive ? const Color(0xFF43A047) : Colors.white,
                        ),
                      ),
                      if (!isActive && log['total_minutes'] != null)
                        Text('${log['total_minutes']} min · \$${log['billable_amount'] ?? '—'}',
                            style: const TextStyle(fontSize: 13, color: Color(0xFF8A8A9A))),
                    ],
                  ),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 10),
        Row(
          children: [
            _Chip(label: '$totalHours hrs total'),
            const SizedBox(width: 10),
            _Chip(label: '\$$totalBillable billable'),
          ],
        ),
      ],
    );
  }

  // ── Section header ────────────────────────────────────────────────────────
  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 21,
        fontWeight: FontWeight.w800,
        color: Colors.white,
        letterSpacing: -0.5,
      ),
    );
  }

  // ── Nav row ───────────────────────────────────────────────────────────────
  Widget _buildNavRow({
    required IconData icon,
    required String label,
    Widget? trailing,
    VoidCallback? onTap,
    bool showArrow = true,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 17),
        child: Row(
          children: [
            Icon(icon, size: 21, color: const Color(0xFF8A8A9A)),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w500, color: Colors.white),
              ),
            ),
            if (trailing != null) ...[trailing, const SizedBox(width: 8)],
            if (showArrow) const Icon(Icons.chevron_right_rounded, size: 22, color: Color(0xFF8A8A9A)),
          ],
        ),
      ),
    );
  }

  // ── Bottom bar ────────────────────────────────────────────────────────────
  Widget _buildBottomBar(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(16, 14, 16, bottomPad + 16),
      decoration: BoxDecoration(
        color: const Color(0xFF111118),
        border: const Border(top: BorderSide(color: Color(0xFF1E1E2E), width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isTimerRunning) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF43A047).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF43A047).withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.radio_button_checked, color: Color(0xFF43A047), size: 16),
                  const SizedBox(width: 10),
                  Text(
                    'Time running · ${_formatElapsed(_elapsed)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF43A047),
                      letterSpacing: 0.6,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (!_isTimerRunning)
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: !_isStartLoading ? _onStartPressed : null,
                icon: _isStartLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                      )
                    : const Icon(Icons.play_arrow_rounded, size: 24),
                label: const Text('Start', style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF7300),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFFFF7300).withOpacity(0.4),
                  disabledForegroundColor: Colors.white70,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          if (_isTimerRunning)
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: !_isStopLoading ? _onStopPressed : null,
                icon: _isStopLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                      )
                    : const Icon(Icons.stop_rounded, size: 24),
                label: const Text('Stop', style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w700)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B6B),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFFFF6B6B).withOpacity(0.35),
                  disabledForegroundColor: Colors.white70,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Local widgets ─────────────────────────────────────────────────────────────

class _CircleBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _CircleBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFF111118),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFF1E1E2E), width: 1),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: Icon(icon, size: 22, color: Colors.white),
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

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap ?? () {},
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: const Color(0xFF16161F),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF1E1E2E)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 24, color: const Color(0xFF8A8A9A)),
              const SizedBox(height: 8),
              if (badge != null) ...[
                Text(badge!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFFFF7300))),
                const SizedBox(height: 2),
              ],
              Text(label,
                  style: const TextStyle(fontSize: 12.5, color: Color(0xFF8A8A9A), fontWeight: FontWeight.w500),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFFF7300).withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFF7300).withOpacity(0.25)),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFFFF7300)),
      ),
    );
  }
}

class _MapPlaceholderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final roadPaint   = Paint()..color = const Color(0xFF2A3A2A)..style = PaintingStyle.stroke..strokeWidth = 14;
    final roadOutline = Paint()..color = const Color(0xFF1E2A1E)..style = PaintingStyle.stroke..strokeWidth = 16;
    final blockPaint  = Paint()..color = const Color(0xFF24301F);

    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), Paint()..color = const Color(0xFF1A251A));
    canvas.drawLine(Offset(0, h * 0.3), Offset(w, h * 0.7), roadOutline);
    canvas.drawLine(Offset(0, h * 0.3), Offset(w, h * 0.7), roadPaint);
    canvas.drawLine(Offset(w * 0.1, 0), Offset(w * 0.6, h), roadOutline);
    canvas.drawLine(Offset(w * 0.1, 0), Offset(w * 0.6, h), roadPaint);
    canvas.drawLine(Offset(0, h * 0.55), Offset(w, h * 0.55), roadOutline);
    canvas.drawLine(Offset(0, h * 0.55), Offset(w, h * 0.55), roadPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(w * 0.55, h * 0.05, w * 0.38, h * 0.38), const Radius.circular(4)), Paint()..color = const Color(0xFF2F3F28));
    canvas.drawRect(Rect.fromLTWH(w * 0.05, h * 0.08, w * 0.22, h * 0.18), blockPaint);
    canvas.drawRect(Rect.fromLTWH(w * 0.65, h * 0.6, w * 0.28, h * 0.25), blockPaint);
    canvas.drawRect(Rect.fromLTWH(w * 0.05, h * 0.65, w * 0.18, h * 0.22), blockPaint);
  }

  @override
  bool shouldRepaint(_) => false;
}