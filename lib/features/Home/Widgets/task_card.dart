import 'package:flutter/material.dart';
import 'task_detail_screen.dart'; // ✅ import detail screen

// ── Data model ────────────────────────────────────────────────────────────────

enum TaskStatus { overdue, newTask, inProgress }
enum TaskPriority { high, medium, low }
enum OccupancyType { occupied, checkInOut, vacant }

class TaskItem {
  final String time;
  final TaskStatus status;
  final TaskPriority priority;
  final String propertyName;
  final String address;
  final String taskType;
  final OccupancyType occupancy;
  final String? checkOut;
  final String? checkIn;

  const TaskItem({
    required this.time,
    required this.status,
    required this.priority,
    required this.propertyName,
    required this.address,
    required this.taskType,
    required this.occupancy,
    this.checkOut,
    this.checkIn,
  });
}

// ── Dummy data ────────────────────────────────────────────────────────────────

final List<TaskItem> todayTasks = [
  const TaskItem(
    time: '10:00 AM',
    status: TaskStatus.newTask,
    priority: TaskPriority.high,
    propertyName: '2 Chelsea · #2 One Apartment CMK, W...',
    address: '599 Witan Gate',
    taskType: 'Check-Out Cleaning',
    occupancy: OccupancyType.occupied,
  ),
  const TaskItem(
    time: '1:00 PM',
    status: TaskStatus.newTask,
    priority: TaskPriority.high,
    propertyName: '32 Silbury · #132 Central MK two mins...',
    address: '897 Silbury Boulevard',
    taskType: 'Check-Out Cleaning',
    occupancy: OccupancyType.checkInOut,
    checkOut: '10:00 AM',
    checkIn: '4:00 PM',
  ),
  const TaskItem(
    time: '4:00 PM',
    status: TaskStatus.newTask,
    priority: TaskPriority.high,
    propertyName: '2 Chelsea · #2 One Apartment CMK, W...',
    address: '599 Witan Gate',
    taskType: 'Departure Clean',
    occupancy: OccupancyType.occupied,
  ),
];

// ── Task list widget ──────────────────────────────────────────────────────────

class TodayTaskList extends StatelessWidget {
  const TodayTaskList({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        const _PriorityGroupHeader(label: 'HIGH'),
        ...todayTasks.map((task) => TaskCard(task: task)),
      ],
    );
  }
}



// ── Priority group header ─────────────────────────────────────────────────────

class _PriorityGroupHeader extends StatelessWidget {
  final String label;
  const _PriorityGroupHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 9),
      color: const Color(0xFFEEEEEE),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: Color(0xFF555555),
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

// ── Single task card ──────────────────────────────────────────────────────────

class TaskCard extends StatelessWidget {
  final TaskItem task;
  const TaskCard({super.key, required this.task});

  static const Color _accent     = Color(0xFF29B6F6);
  static const Color _overdueBg  = Color(0xFFFFF0F0);
  static const Color _overdueRed = Color(0xFFE53935);
  static const Color _newBg      = Color(0xFFF7F7F7);
  static const Color _newText    = Color(0xFF1A1A1A);
  static const Color _textSec    = Color(0xFF8A8A8A);
  static const Color _green      = Color(0xFF43A047);
  static const Color _orange     = Color(0xFFF57C00);

  Color get _headerBg =>
      task.status == TaskStatus.overdue ? _overdueBg : _newBg;

  Color get _headerTextColor =>
      task.status == TaskStatus.overdue ? _overdueRed : _textSec;

  void _openDetail(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TaskDetailScreen(task: task)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openDetail(context),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: task.status == TaskStatus.overdue
                ? _overdueRed.withOpacity(0.25)
                : const Color(0xFFE8E8E8),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.055),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.propertyName,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        color: _newText,
                        letterSpacing: -0.3,
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      task.address,
                      style: const TextStyle(
                        fontSize: 13,
                        color: _textSec,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      task.taskType,
                      style: const TextStyle(
                        fontSize: 15,
                        color: _newText,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 14),
                  ],
                ),
              ),
              _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final bool isOverdue = task.status == TaskStatus.overdue;
    final bool isNew = task.status == TaskStatus.newTask;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      color: _headerBg,
      child: Row(
        children: [
          if (isOverdue) ...[
            Icon(Icons.warning_amber_rounded, size: 16, color: _overdueRed),
            const SizedBox(width: 6),
          ],
          Text(
            task.time,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: _headerTextColor,
            ),
          ),
          const Spacer(),
          if (isOverdue)
            Text(
              'OVERDUE',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: _overdueRed,
                letterSpacing: 0.8,
              ),
            )
          else if (isNew)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: _accent.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.calendar_today_rounded, size: 11, color: _accent),
                  const SizedBox(width: 5),
                  Text(
                    'Due on ${_todayLabel()}',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: _accent,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
                color: _orange, shape: BoxShape.circle),
            child: const Icon(Icons.arrow_upward_rounded,
                color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          _OccupancyChip(task: task),
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Icon(Icons.bookmark_border_rounded,
                size: 18, color: _textSec),
          ),
          const Spacer(),
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: _green.withOpacity(0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check_rounded, color: _green, size: 20),
          ),
          const SizedBox(width: 10),
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: _textSec.withOpacity(0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.chat_bubble_outline_rounded,
                color: _textSec, size: 18),
          ),
        ],
      ),
    );
  }




  String _todayLabel() {
    final now = DateTime.now();
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    const days = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
    return '${days[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}';
  }
}

// ── Occupancy chip ────────────────────────────────────────────────────────────

class _OccupancyChip extends StatelessWidget {
  final TaskItem task;
  const _OccupancyChip({required this.task});

  static const Color _textSec = Color(0xFF8A8A8A);

  @override
  Widget build(BuildContext context) {
    if (task.occupancy == OccupancyType.checkInOut &&
        task.checkOut != null &&
        task.checkIn != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFFF0F0F0),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.compare_arrows_rounded, size: 14, color: _textSec),
            const SizedBox(width: 5),
            Text(
              'OUT ${task.checkOut!} / IN ${task.checkIn!}',
              style: const TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w600,
                color: _textSec,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.person_outline_rounded, size: 14, color: _textSec),
          const SizedBox(width: 5),
          const Text(
            'OCCUPIED',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: _textSec,
            ),
          ),
        ],
      ),
    );
  }
}