// lib/Admin/Widgets/create_task_dialog.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../Api/api_controller.dart';

class CreateTaskDialog extends StatefulWidget {
  final int propertyId;
  final String propertyName;

  const CreateTaskDialog({
    super.key,
    required this.propertyId,
    required this.propertyName,
  });

  @override
  State<CreateTaskDialog> createState() => _CreateTaskDialogState();
}

class _CreateTaskDialogState extends State<CreateTaskDialog> {
  static const Color _bg      = Color(0xFF0D0D17);
  static const Color _surface = Color(0xFF111118);
  static const Color _field   = Color(0xFF1A1A28);
  static const Color _border  = Color(0xFF1E1E2E);
  static const Color _orange  = Color(0xFFFF7300);
  static const Color _blue    = Color(0xFF3B82F6);
  static const Color _textPri = Color(0xFFFFFFFF);
  static const Color _textSec = Color(0xFF8A8A9A);

  // ── Loading states ──────────────────────────────────────────────────────
  bool _loadingDepts   = true;
  bool _loadingTags    = true;
  bool _loadingUsers   = false;
  bool _loadingProps   = true;
  bool _isCreating     = false;

  // ── API data ────────────────────────────────────────────────────────────
  List<dynamic> _departments   = [];
  List<dynamic> _tags          = [];
  List<dynamic> _users         = [];
  List<dynamic> _allProperties = [];

  // ── Selected values ─────────────────────────────────────────────────────
  List<Map<String, dynamic>> _selectedProperties = [];
  Map<String, dynamic>? _selectedDepartment;
  Map<String, dynamic>? _selectedTemplate;
  Map<String, dynamic>? _selectedSubdepartment;

  String _priority = 'medium';

  final _titleController   = TextEditingController();
  final _descController    = TextEditingController();
  final _rateController    = TextEditingController();
  final _estTimeController = TextEditingController();

  String _rateType = 'Hourly';

  bool _isRepeating = false;
  DateTime? _dueDate = DateTime.now();
  TimeOfDay? _dueTime;

  List<Map<String, dynamic>> _selectedAssignees = [];
  List<Map<String, dynamic>> _selectedTags      = [];

  bool _watchTask   = false;
  bool _textUpdates = false;

  Map<String, dynamic>? _requestedBy;

  // ── Helpers ─────────────────────────────────────────────────────────────
  List<dynamic> get _currentTemplates =>
      _selectedDepartment?['task_templates'] as List<dynamic>? ?? [];

  List<dynamic> get _currentSubdepts =>
      _selectedDepartment?['subdepartments'] as List<dynamic>? ?? [];

  // ── Priority config ──────────────────────────────────────────────────────
  final List<Map<String, dynamic>> _priorities = [
    {'key': 'lowest', 'label': 'Lowest', 'icon': Icons.keyboard_double_arrow_down_rounded, 'color': Color(0xFF1E3A5F), 'accent': Color(0xFF3B82F6)},
    {'key': 'low',    'label': 'Low',    'icon': Icons.keyboard_arrow_down_rounded,        'color': Color(0xFF1E3A5F), 'accent': Color(0xFF3B82F6)},
    {'key': 'medium', 'label': 'Medium', 'icon': Icons.circle_rounded,                    'color': Color(0xFF7C3500), 'accent': Color(0xFFFF7300)},
    {'key': 'high',   'label': 'High',   'icon': Icons.keyboard_arrow_up_rounded,          'color': Color(0xFF5C2800), 'accent': Color(0xFFFF5733)},
    {'key': 'urgent', 'label': 'Urgent', 'icon': Icons.notification_important_rounded,     'color': Color(0xFF4A1010), 'accent': Color(0xFFEF4444)},
  ];

  @override
  void initState() {
    super.initState();
    _selectedProperties = [
      {'id': widget.propertyId, 'name': widget.propertyName}
    ];
    _fetchAll();
  }

  Future<void> _fetchAll() async {
    await Future.wait([
      _fetchProperties(),
      _fetchDepartments(),
      _fetchTags(),
    ]);
  }

  Future<void> _fetchProperties() async {
    final res = await ApiController.getActiveProperties();
    if (res['success'] == true) {
      setState(() {
        _allProperties = res['data'];
        _loadingProps = false;
      });
    } else {
      setState(() => _loadingProps = false);
    }
  }

  Future<void> _fetchDepartments() async {
    final res = await ApiController.getTaskDepartments();
    if (res['success'] == true) {
      setState(() {
        _departments = res['data'];
        _loadingDepts = false;
      });
    } else {
      setState(() => _loadingDepts = false);
    }
  }

  Future<void> _fetchTags() async {
    final res = await ApiController.getTaskTags();
    if (res['success'] == true) {
      setState(() {
        _tags = res['data'];
        _loadingTags = false;
      });
    } else {
      setState(() => _loadingTags = false);
    }
  }

  Future<void> _fetchUsers(int departmentId) async {
    setState(() => _loadingUsers = true);
    final res =
        await ApiController.getAssignableUsers(departmentId: departmentId);
    if (res['success'] == true) {
      setState(() {
        _users = res['data'];
        _loadingUsers = false;
      });
    } else {
      setState(() => _loadingUsers = false);
    }
  }

  void _onDepartmentSelected(Map<String, dynamic> dept) {
    setState(() {
      _selectedDepartment    = dept;
      _selectedTemplate      = null;
      _selectedSubdepartment = null;
      _titleController.clear();
      _descController.clear();
      _rateController.clear();
      _estTimeController.clear();
      _dueDate           = DateTime.now();
      _dueTime           = null;
      _priority          = 'medium';
      _selectedAssignees = [];
    });
    _fetchUsers(dept['id'] as int);
  }

  void _onTemplateSelected(Map<String, dynamic> tpl) {
    setState(() {
      _selectedTemplate      = tpl;
      _selectedSubdepartment = null;
      _titleController.text  = tpl['title'] ?? '';
      _descController.text   = tpl['description'] ?? '';
      _priority              = tpl['priority'] ?? 'medium';

      if (tpl['due_time'] != null) {
        _estTimeController.text = _formatDueTime(tpl['due_time'] as String);
        _dueTime = _parseTime(tpl['due_time'] as String);
      }
      if (tpl['due_days'] != null) {
        final days = (tpl['due_days'] as num).toInt();
        _dueDate = DateTime.now().add(Duration(days: days));
      }
    });
  }

  String _formatDueTime(String raw) {
    final parts = raw.split(':');
    if (parts.length >= 2) return '${parts[0]}:${parts[1]}';
    return raw;
  }

  TimeOfDay? _parseTime(String raw) {
    final parts = raw.split(':');
    if (parts.length >= 2) {
      return TimeOfDay(
          hour: int.tryParse(parts[0]) ?? 0,
          minute: int.tryParse(parts[1]) ?? 0);
    }
    return null;
  }

  // ── Create Task ──────────────────────────────────────────────────────────
  Future<void> _onCreateTask() async {
    if (_selectedProperties.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select at least one property.')),
      );
      return;
    }
    if (_selectedDepartment == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a department.')),
      );
      return;
    }
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task title is required.')),
      );
      return;
    }

    setState(() => _isCreating = true);

    final List<int> propertyIds =
        _selectedProperties.map((p) => p['id'] as int).toList();

    String? formattedDueDate;
    if (_dueDate != null) {
      formattedDueDate =
          '${_dueDate!.year}-${_dueDate!.month.toString().padLeft(2, '0')}-${_dueDate!.day.toString().padLeft(2, '0')}';
    }

    String? formattedDueTime;
    if (_dueTime != null) {
      formattedDueTime =
          '${_dueTime!.hour.toString().padLeft(2, '0')}:${_dueTime!.minute.toString().padLeft(2, '0')}:00';
    }

    final String? formattedEstimatedTime =
        _estTimeController.text.trim().isNotEmpty
            ? _estTimeController.text.trim()
            : null;

    final double? rate = _rateController.text.trim().isNotEmpty
        ? double.tryParse(_rateController.text.trim())
        : null;

    final List<String> assignees =
        _selectedAssignees.map((a) => '${a['id']}').toList();

    final List<String> tags =
        _selectedTags.map((t) => '${t['id']}').toList();

    final prefs = await SharedPreferences.getInstance();
    final companyId = prefs.getInt('company_id') ?? 8;

    final Map<String, dynamic> payload = {
      'property_ids': propertyIds,
      'property_id': '[${propertyIds.join(',')}]',
      'department_id': _selectedDepartment!['id'] as int,
      'subdepartment_id': _selectedSubdepartment != null
          ? _selectedSubdepartment!['id'] as int
          : null,
      'template_id': _selectedTemplate != null
          ? _selectedTemplate!['id'] as int
          : null,
      'title': _titleController.text.trim(),
      'description': _descController.text.trim(),
      'priority': _priority,
      'rate': rate,
      'rate_type': _rateType.toLowerCase().replaceAll(' ', '_'),
      'estimated_time': formattedEstimatedTime,
      'due_date': formattedDueDate,
      'due_time': formattedDueTime,
      'is_repeating': _isRepeating ? 'Y' : 'N',
      'assignees': assignees,
      'tags': tags,
      'watch_task': _watchTask ? 1 : 0,
      'send_text_updates': _textUpdates ? 1 : 0,
      'requested_by':
          _requestedBy != null ? _requestedBy!['id'] : null,
      'company_id': companyId,
    };

    final result = await ApiController.createTask(payload);

    if (!mounted) return;
    setState(() => _isCreating = false);

    if (result['success'] == true) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Task created successfully!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(result['message'] ?? 'Failed to create task.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _rateController.dispose();
    _estTimeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: _bg,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: SizedBox(
        width: double.infinity,
        height: MediaQuery.of(context).size.height * 0.9,
        child: Column(
          children: [
            _buildHeader(),
            const Divider(color: _border, height: 1),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // ── Properties ──────────────────────────────────────
                    _label('Properties', required: true),
                    const SizedBox(height: 8),
                    _buildMultiSelectChips(
                      selectedItems: _selectedProperties,
                      allItems: _allProperties
                          .map((p) =>
                              {'id': p['id'], 'name': p['name']})
                          .toList(),
                      labelKey: 'name',
                      icon: Icons.home_rounded,
                      hint: '+ Select properties',
                      onChanged: (list) =>
                          setState(() => _selectedProperties = list),
                      loading: _loadingProps,
                    ),
                    const SizedBox(height: 16),

                    // ── Department ──────────────────────────────────────
                    _label('Department', required: true),
                    const SizedBox(height: 8),
                    _loadingDepts
                        ? _loadingWidget()
                        : _buildDropdown(
                            value: _selectedDepartment?['name'],
                            hint: 'Select department',
                            items: _departments
                                .map((d) => d['name'] as String)
                                .toList(),
                            onChanged: (val) {
                              final dept = _departments.firstWhere(
                                  (d) => d['name'] == val,
                                  orElse: () => null);
                              if (dept != null)
                                _onDepartmentSelected(dept);
                            },
                          ),
                    const SizedBox(height: 20),

                    // ── TASK DETAILS ────────────────────────────────────
                    _sectionHeader(
                        Icons.adjust_rounded, 'TASK DETAILS', _blue),
                    const SizedBox(height: 16),

                    _label('Priority Level'),
                    const SizedBox(height: 10),
                    _buildPrioritySelector(),
                    const SizedBox(height: 16),

                    // Template + Subdepartment
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              _label('Template'),
                              const SizedBox(height: 8),
                              _selectedDepartment == null
                                  ? _buildDropdown(
                                      value: null,
                                      hint: 'Select template',
                                      items: [],
                                      onChanged: (_) {})
                                  : _buildDropdown(
                                      value: _selectedTemplate?[
                                          'title'],
                                      hint: 'Select template',
                                      items: _currentTemplates
                                          .map((t) =>
                                              t['title'] as String)
                                          .toList(),
                                      onChanged: (val) {
                                        final tpl =
                                            _currentTemplates
                                                .firstWhere(
                                                    (t) =>
                                                        t['title'] ==
                                                        val,
                                                    orElse: () =>
                                                        null);
                                        if (tpl != null)
                                          _onTemplateSelected(tpl);
                                      },
                                    ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              _label('Subdepartment'),
                              const SizedBox(height: 8),
                              _buildDropdown(
                                value:
                                    _selectedSubdepartment?['name'],
                                hint: 'None',
                                items: _currentSubdepts
                                    .map((s) => s['name'] as String)
                                    .toList(),
                                onChanged: (val) {
                                  final sub =
                                      _currentSubdepts.firstWhere(
                                          (s) => s['name'] == val,
                                          orElse: () => null);
                                  setState(() =>
                                      _selectedSubdepartment = sub);
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Task Title
                    _label('Task Title', required: true),
                    const SizedBox(height: 8),
                    _textField(_titleController,
                        'Enter a descriptive title...'),
                    const SizedBox(height: 16),

                    // Description
                    _label('Description'),
                    const SizedBox(height: 8),
                    _textField(
                        _descController,
                        'Add detailed description, instructions, or notes...',
                        maxLines: 4),
                    const SizedBox(height: 16),

                    // Rate + Rate Type + Est. Time
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              _label('Rate'),
                              const SizedBox(height: 8),
                              _buildRateField(),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              _label(''),
                              const SizedBox(height: 8),
                              _buildDropdown(
                                value: _rateType,
                                hint: '',
                                items: ['Hourly', 'Flat Rate'],
                                onChanged: (v) => setState(
                                    () => _rateType = v ?? 'Hourly'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              _label('Est. Time'),
                              const SizedBox(height: 8),
                              _textField(_estTimeController, 'HH:MM',
                                  keyboardType:
                                      TextInputType.datetime),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // ── SCHEDULE ────────────────────────────────────────
                    _sectionHeader(Icons.calendar_month_rounded,
                        'SCHEDULE', _blue),
                    const SizedBox(height: 14),

                    _buildCheckboxRow(
                      label: 'Make this a repeating task',
                      value: _isRepeating,
                      onChanged: (v) =>
                          setState(() => _isRepeating = v ?? false),
                    ),
                    const SizedBox(height: 14),

                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              _label('Due Date'),
                              const SizedBox(height: 8),
                              _buildDateField(),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              _label('Time'),
                              const SizedBox(height: 8),
                              _buildTimeField(),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // ── ASSIGNEES ───────────────────────────────────────
                    _sectionHeader(
                        Icons.people_alt_rounded, 'ASSIGNEES', _blue),
                    const SizedBox(height: 14),
                    _loadingUsers
                        ? _loadingWidget()
                        : _buildMultiSelectChips(
                            selectedItems: _selectedAssignees,
                            allItems: _users
                                .map((u) => {
                                      'id': u['id'],
                                      'name': u['full_name']
                                    })
                                .toList(),
                            labelKey: 'name',
                            icon: Icons.person_add_rounded,
                            hint: '+ Add assignee',
                            onChanged: (list) => setState(
                                () => _selectedAssignees = list),
                            loading: false,
                          ),
                    const SizedBox(height: 20),

                    // ── ATTACHMENTS ─────────────────────────────────────
                    // _sectionHeader(Icons.attach_file_rounded,
                    //     'ATTACHMENTS', _blue),
                    // const SizedBox(height: 14),
                    // Row(
                    //   children: [
                    //     Expanded(
                    //         child: _outlineButton(
                    //             Icons.upload_rounded, 'Upload', () {})),
                    //     const SizedBox(width: 12),
                    //     Expanded(
                    //         child: _outlineButton(
                    //             Icons.link_rounded, 'Link', () {})),
                    //   ],
                    // ),
                    const SizedBox(height: 20),

                    // ── TAGS ────────────────────────────────────────────
                    _sectionHeader(
                        Icons.label_rounded, 'TAGS', _blue),
                    const SizedBox(height: 14),
                    _loadingTags
                        ? _loadingWidget()
                        : _buildMultiSelectChips(
                            selectedItems: _selectedTags,
                            allItems: _tags
                                .map((t) => {
                                      'id': t['id'],
                                      'name': t['name']
                                    })
                                .toList(),
                            labelKey: 'name',
                            icon: Icons.add_rounded,
                            hint: 'Add tags...',
                            onChanged: (list) =>
                                setState(() => _selectedTags = list),
                            loading: false,
                          ),
                    const SizedBox(height: 20),

                    // Watch Task + Text Updates
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF16161F),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _border),
                      ),
                      child: Column(
                        children: [
                          _buildToggleRow(
                            icon: Icons.visibility_rounded,
                            title: 'Watch Task',
                            subtitle: 'Get notified about updates',
                            value: _watchTask,
                            onChanged: (v) =>
                                setState(() => _watchTask = v),
                            showDivider: true,
                          ),
                          _buildToggleRow(
                            icon: Icons.message_rounded,
                            title: 'Text Updates',
                            subtitle: 'Send SMS notifications',
                            value: _textUpdates,
                            onChanged: (v) =>
                                setState(() => _textUpdates = v),
                            showDivider: false,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Requested By ────────────────────────────────────
                    _label('Requested By'),
                    const SizedBox(height: 8),
                    _buildDropdown(
                      value: _requestedBy?['full_name'],
                      hint: 'Select requester',
                      items: _users
                          .map((u) => u['full_name'] as String)
                          .toList(),
                      onChanged: (val) {
                        final u = _users.firstWhere(
                            (u) => u['full_name'] == val,
                            orElse: () => null);
                        setState(() => _requestedBy = u);
                      },
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),

            // ── Bottom buttons ──────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: _border)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isCreating
                          ? null
                          : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _textSec,
                        side: const BorderSide(color: _border),
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isCreating ? null : _onCreateTask,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _orange,
                        foregroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: _isCreating
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Create Task',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader() => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 12, 16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _blue.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.task_alt_rounded,
                  color: _blue, size: 22),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Create New Task',
                    style: TextStyle(
                        color: _textPri,
                        fontSize: 17,
                        fontWeight: FontWeight.w700)),
                Text('Fill in the details to create a new task',
                    style: TextStyle(color: _textSec, fontSize: 10)),
              ],
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.close, color: _textSec),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      );

  // ── Section header ────────────────────────────────────────────────────────
  Widget _sectionHeader(IconData icon, String title, Color color) =>
      Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Text(title,
              style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8)),
        ],
      );

  // ── Priority selector ─────────────────────────────────────────────────────
  Widget _buildPrioritySelector() => Row(
        children: _priorities.map((p) {
          final isSelected = _priority == p['key'];
          final accent = p['accent'] as Color;
          final bg = p['color'] as Color;
          return Expanded(
            child: GestureDetector(
              onTap: () =>
                  setState(() => _priority = p['key'] as String),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(right: 6),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color:
                      isSelected ? bg : const Color(0xFF16161F),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected
                        ? accent.withOpacity(0.6)
                        : _border,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(p['icon'] as IconData,
                        color: isSelected ? accent : _textSec,
                        size: 18),
                    const SizedBox(height: 4),
                    Text(p['label'] as String,
                        style: TextStyle(
                            color: isSelected ? accent : _textSec,
                            fontSize: 11,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500)),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      );

  // ── Multi-select chips ────────────────────────────────────────────────────
  Widget _buildMultiSelectChips({
    required List<Map<String, dynamic>> selectedItems,
    required List<Map<String, dynamic>> allItems,
    required String labelKey,
    required IconData icon,
    required String hint,
    required ValueChanged<List<Map<String, dynamic>>> onChanged,
    required bool loading,
  }) {
    return GestureDetector(
      onTap: loading
          ? null
          : () => _showMultiSelectSheet(
                selectedItems: selectedItems,
                allItems: allItems,
                labelKey: labelKey,
                onChanged: onChanged,
              ),
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: _field,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (selectedItems.isNotEmpty) ...[
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: selectedItems
                    .map((item) =>
                        _chip(item[labelKey] as String, () {
                          final updated =
                              List<Map<String, dynamic>>.from(
                                  selectedItems)
                                ..removeWhere(
                                    (i) => i['id'] == item['id']);
                          onChanged(updated);
                        }))
                    .toList(),
              ),
              const SizedBox(height: 8),
            ],
            Row(
              children: [
                Icon(icon, color: _textSec, size: 16),
                const SizedBox(width: 8),
                Text(hint,
                    style: const TextStyle(
                        color: _textSec, fontSize: 13)),
                const Spacer(),
                const Icon(Icons.keyboard_arrow_down_rounded,
                    color: _textSec, size: 18),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, VoidCallback onRemove) => Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: _blue.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _blue.withOpacity(0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label,
                style: const TextStyle(
                    color: _textPri,
                    fontSize: 12,
                    fontWeight: FontWeight.w500)),
            const SizedBox(width: 6),
            GestureDetector(
              onTap: onRemove,
              child: const Icon(Icons.close,
                  color: _textSec, size: 14),
            ),
          ],
        ),
      );

  void _showMultiSelectSheet({
    required List<Map<String, dynamic>> selectedItems,
    required List<Map<String, dynamic>> allItems,
    required String labelKey,
    required ValueChanged<List<Map<String, dynamic>>> onChanged,
  }) {
    final tempSelected =
        List<Map<String, dynamic>>.from(selectedItems);
    showModalBottomSheet(
      context: context,
      backgroundColor: _surface,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheetState) => Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                  color: _border,
                  borderRadius: BorderRadius.circular(2)),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: allItems.map((item) {
                  final isSelected = tempSelected
                      .any((s) => s['id'] == item['id']);
                  return ListTile(
                    dense: true,
                    title: Text(item[labelKey] as String,
                        style: const TextStyle(
                            color: _textPri, fontSize: 14)),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle_rounded,
                            color: _blue, size: 20)
                        : const Icon(
                            Icons.radio_button_unchecked_rounded,
                            color: _textSec,
                            size: 20),
                    onTap: () {
                      setSheetState(() {
                        if (isSelected) {
                          tempSelected.removeWhere(
                              (s) => s['id'] == item['id']);
                        } else {
                          tempSelected.add({
                            'id': item['id'],
                            labelKey: item[labelKey],
                            'name': item[labelKey],
                          });
                        }
                      });
                    },
                  );
                }).toList(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    onChanged(tempSelected);
                    Navigator.pop(ctx);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _orange,
                    padding:
                        const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Done',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Dropdown ──────────────────────────────────────────────────────────────
  Widget _buildDropdown({
    required String? value,
    required String hint,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: _field,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _border),
        ),
        child: DropdownButton<String>(
          value: items.contains(value) ? value : null,
          hint: Text(hint,
              style: const TextStyle(
                  color: _textSec, fontSize: 13)),
          isExpanded: true,
          underline: const SizedBox(),
          dropdownColor: const Color(0xFF1E1E2E),
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: _textSec, size: 20),
          style: const TextStyle(color: _textPri, fontSize: 13),
          items: items
              .map((e) =>
                  DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
          onChanged: onChanged,
        ),
      );

  // ── Rate field ────────────────────────────────────────────────────────────
  Widget _buildRateField() => Container(
        decoration: BoxDecoration(
          color: _field,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _border),
        ),
        child: Row(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text('\$',
                  style: TextStyle(color: _textSec, fontSize: 14)),
            ),
            Expanded(
              child: TextField(
                controller: _rateController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                style:
                    const TextStyle(color: _textPri, fontSize: 14),
                decoration: const InputDecoration(
                  hintText: '0.00',
                  hintStyle: TextStyle(color: _textSec),
                  border: InputBorder.none,
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      );

  // ── Date field ────────────────────────────────────────────────────────────
  Widget _buildDateField() => GestureDetector(
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: _dueDate ?? DateTime.now(),
            firstDate: DateTime(2020),
            lastDate: DateTime(2030),
            builder: (ctx, child) =>
                Theme(data: ThemeData.dark(), child: child!),
          );
          if (picked != null) setState(() => _dueDate = picked);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: _field,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _border),
          ),
          child: Row(
            children: [
              const Icon(Icons.calendar_today_rounded,
                  color: _textSec, size: 16),
              const SizedBox(width: 8),
              Text(
                _dueDate != null
                    ? '${_dueDate!.month.toString().padLeft(2, '0')}/${_dueDate!.day.toString().padLeft(2, '0')}/${_dueDate!.year}'
                    : 'MM/DD/YYYY',
                style: TextStyle(
                    color: _dueDate != null ? _textPri : _textSec,
                    fontSize: 13),
              ),
            ],
          ),
        ),
      );

  // ── Time field ────────────────────────────────────────────────────────────
  Widget _buildTimeField() => GestureDetector(
        onTap: () async {
          final picked = await showTimePicker(
            context: context,
            initialTime: _dueTime ?? TimeOfDay.now(),
            builder: (ctx, child) =>
                Theme(data: ThemeData.dark(), child: child!),
          );
          if (picked != null) setState(() => _dueTime = picked);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: _field,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _border),
          ),
          child: Row(
            children: [
              const Icon(Icons.access_time_rounded,
                  color: _textSec, size: 16),
              const SizedBox(width: 8),
              Text(
                _dueTime != null
                    ? _dueTime!.format(context)
                    : '--:-- --',
                style: TextStyle(
                    color:
                        _dueTime != null ? _textPri : _textSec,
                    fontSize: 13),
              ),
            ],
          ),
        ),
      );

  // ── Checkbox row ──────────────────────────────────────────────────────────
  Widget _buildCheckboxRow({
    required String label,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) =>
      GestureDetector(
        onTap: () => onChanged(!value),
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: _field,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _border),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: Checkbox(
                  value: value,
                  onChanged: onChanged,
                  activeColor: _blue,
                  side: const BorderSide(color: _textSec),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4)),
                ),
              ),
              const SizedBox(width: 10),
              Text(label,
                  style: const TextStyle(
                      color: _textPri, fontSize: 13)),
            ],
          ),
        ),
      );

  // ── Toggle row ────────────────────────────────────────────────────────────
  Widget _buildToggleRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required bool showDivider,
  }) =>
      Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Icon(icon, color: _textSec, size: 18),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              color: _textPri,
                              fontSize: 13,
                              fontWeight: FontWeight.w500)),
                      Text(subtitle,
                          style: const TextStyle(
                              color: _textSec, fontSize: 11)),
                    ],
                  ),
                ),
                Switch(
                  value: value,
                  onChanged: onChanged,
                  activeColor: _blue,
                  trackColor: WidgetStateProperty.resolveWith(
                      (s) => s.contains(WidgetState.selected)
                          ? _blue.withOpacity(0.3)
                          : _border),
                ),
              ],
            ),
          ),
          if (showDivider)
            const Divider(color: _border, height: 1),
        ],
      );

  // ── Text field ────────────────────────────────────────────────────────────
  Widget _textField(
    TextEditingController ctrl,
    String hint, {
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) =>
      TextField(
        controller: ctrl,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: const TextStyle(color: _textPri, fontSize: 13),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle:
              const TextStyle(color: _textSec, fontSize: 13),
          filled: true,
          fillColor: _field,
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                const BorderSide(color: _blue, width: 1.5),
          ),
        ),
      );

  // ── Outline button ────────────────────────────────────────────────────────
  Widget _outlineButton(
          IconData icon, String label, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: _field,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _border),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: _textSec, size: 16),
              const SizedBox(width: 8),
              Text(label,
                  style: const TextStyle(
                      color: _textSec, fontSize: 13)),
            ],
          ),
        ),
      );

  // ── Label ─────────────────────────────────────────────────────────────────
  Widget _label(String text, {bool required = false}) => Row(
        children: [
          Text(text,
              style: const TextStyle(
                  color: _textPri,
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
          if (required)
            const Text(' *',
                style:
                    TextStyle(color: Colors.red, fontSize: 13)),
        ],
      );

  Widget _loadingWidget() => const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
}