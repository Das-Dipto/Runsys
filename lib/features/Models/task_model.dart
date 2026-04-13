class MyAssignment {
  final String status;
  final String assignedAt;
  final String? dueDate;

  MyAssignment({
    required this.status,
    required this.assignedAt,
    this.dueDate,
  });

  factory MyAssignment.fromJson(Map<String, dynamic> json) {
    return MyAssignment(
      status: json['status'] ?? '',
      assignedAt: json['assigned_at'] ?? '',
      dueDate: json['due_date'],
    );
  }
}

class TaskModel {
  final int id;
  final String title;
  final String description;
  final String priority;
  final String? status;
  final String? dueDate;
  final String? dueTime;
  final String? estimatedTime;
  final String createdAt;
  final int propertyId;
  final String propertyName;
  final String? propertyAddress;
  final String? propertyCity;
  final String? propertyState;
  final int departmentId;
  final String departmentName;
  final String departmentColor;
  final int commentsCount;
  final MyAssignment myAssignment;

  TaskModel({
    required this.id,
    required this.title,
    required this.description,
    required this.priority,
    this.status,
    this.dueDate,
    this.dueTime,
    this.estimatedTime,
    required this.createdAt,
    required this.propertyId,
    required this.propertyName,
    this.propertyAddress,
    this.propertyCity,
    this.propertyState,
    required this.departmentId,
    required this.departmentName,
    required this.departmentColor,
    required this.commentsCount,
    required this.myAssignment,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['id'],
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      priority: json['priority'] ?? '',
      status: json['status'],
      dueDate: json['due_date'],
      dueTime: json['due_time'],
      estimatedTime: json['estimated_time'],
      createdAt: json['created_at'] ?? '',
      propertyId: json['property_id'],
      propertyName: json['property_name'] ?? '',
      propertyAddress: json['property_address'],
      propertyCity: json['property_city'],
      propertyState: json['property_state'],
      departmentId: json['department_id'],
      departmentName: json['department_name'] ?? '',
      departmentColor: json['department_color'] ?? '#3b82f6',
      commentsCount: json['comments_count'] ?? 0,
      myAssignment: MyAssignment.fromJson(json['my_assignment']),
    );
  }

  bool get isOverdue {
    if (dueDate == null) return false;
    return DateTime.tryParse(dueDate!)?.isBefore(DateTime.now()) ?? false;
  }

  String get formattedDueDate {
    if (dueDate == null) return '';
    final dt = DateTime.tryParse(dueDate!);
    if (dt == null) return '';
    const months = [
      'Jan','Feb','Mar','Apr','May','Jun',
      'Jul','Aug','Sep','Oct','Nov','Dec'
    ];
    const days = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'];
    return '${days[dt.weekday - 1]}, ${months[dt.month - 1]} ${dt.day}';
  }

  String get propertyFullAddress {
    final parts = [propertyAddress, propertyCity, propertyState]
        .where((e) => e != null && e.isNotEmpty)
        .toList();
    return parts.join(', ');
  }
}