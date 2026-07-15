import 'package:flutter/material.dart';
import '../../Api/api_controller.dart';


import '../../Task/widgets/task_requirements_section.dart';
import '../../Task/widgets/task_submission_handler.dart';

/// Requirements screen — fetches the task's requirement template, then
/// renders it through [TaskRequirementsSection]. Progress ("x of y saved")
/// is driven by onItemSaved/onItemEdited callbacks coming up from each
/// individual item card, NOT from a single global submit anymore.
class RequirementsScreen extends StatefulWidget {
  final int taskId;
  final String taskType;
  final String propertyName;
  final String address;

  const RequirementsScreen({
    super.key,
    required this.taskId,
    required this.taskType,
    required this.propertyName,
    required this.address,
  });

  @override
  State<RequirementsScreen> createState() => _RequirementsScreenState();
}

class _RequirementsScreenState extends State<RequirementsScreen>
    with SingleTickerProviderStateMixin {
  static const Color _accent = Color(0xFF29B6F6);
  static const Color _textPri = Color(0xFF1A1A1A);
  static const Color _textSec = Color(0xFF9E9E9E);
  static const Color _orange = Color(0xFFF57C00);
  static const Color _bgGrey = Color(0xFFEEF0F3);

  TabController? _tabController;

  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _detail;
  late final TaskSubmissionHandler _submission;

  // Tracks which item ids have been saved via the API, for the progress counter.
  final Set<String> _savedItemIds = {};

  List<Map<String, dynamic>> get _sections {
    final sections = _detail?['template']?['sections'] as List?;
    return (sections ?? []).cast<Map<String, dynamic>>();
  }

  int get _totalReq =>
      _sections.fold<int>(0, (sum, s) => sum + ((s['items'] as List?)?.length ?? 0));
  int get _doneReq => _savedItemIds.length;

  Map<String, dynamic> get _existingAnswers =>
      (_detail?['existing_responses']?['answers'] as Map?)?.cast<String, dynamic>() ?? {};

  @override
  void initState() {
    super.initState();
    _submission = TaskSubmissionHandler();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await ApiController.getTaskDetail(widget.taskId);

    if (!mounted) return;

    if (result['success'] == true) {
      final detail = result['data'] as Map<String, dynamic>;
      final sections = ((detail['template']?['sections'] as List?) ?? [])
          .cast<Map<String, dynamic>>();

      _tabController?.dispose();
      _tabController = TabController(
        length: sections.isEmpty ? 1 : sections.length,
        vsync: this,
      );

      // Pre-fill progress counter with items that already have a saved
      // answer from a previous session (existing_responses.answers).
      final existingAnswers =
          (detail['existing_responses']?['answers'] as Map?)?.cast<String, dynamic>() ?? {};

      setState(() {
        _detail = detail;
        _isLoading = false;
        _savedItemIds
          ..clear()
          ..addAll(existingAnswers.keys);
      });
    } else {
      setState(() {
        _errorMessage = result['message'] ?? 'Failed to load requirements';
        _isLoading = false;
      });
    }
  }

  void _onItemSaved(String itemId) {
    setState(() => _savedItemIds.add(itemId));
  }

  void _onItemEdited(String itemId) {
    setState(() => _savedItemIds.remove(itemId));
  }

  @override
  void dispose() {
    _tabController?.dispose();
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
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _textPri, letterSpacing: -0.3),
        ),
        centerTitle: true,
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, size: 40, color: Color(0xFFFF6B6B)),
              const SizedBox(height: 12),
              Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: _textSec)),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _loadDetail, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    final sections = _sections;

    return Column(
      children: [
        Container(
          color: _bgGrey,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(
            children: [
              SizedBox(
                width: 160,
                height: 44,
                child: ElevatedButton.icon(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.play_arrow_rounded, size: 18),
                  label: const Text('Start', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.taskType,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _textPri)),
                        const SizedBox(height: 4),
                        Text('${widget.propertyName} | ${widget.address}',
                            style: const TextStyle(fontSize: 12, color: _textSec, height: 1.4)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
        Container(
          color: _bgGrey,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
          child: Row(
            children: [
              const Text('Requirements', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _textPri)),
              const Spacer(),
              Text('$_doneReq of $_totalReq',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _orange)),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (sections.length > 1)
          Container(
            color: _bgGrey,
            child: TabBar(
              controller: _tabController,
              labelColor: _accent,
              unselectedLabelColor: _textSec,
              labelStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
              unselectedLabelStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500),
              indicatorColor: _accent,
              indicatorWeight: 2.5,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              tabs: sections
                  .map((s) => Tab(text: (s['title'] ?? '').toString()))
                  .toList(),
            ),
          ),
        Expanded(
          child: sections.isEmpty
              ? const Center(
                  child: Text('No requirements for this task', style: TextStyle(color: _textSec)),
                )
              : TabBarView(
                  controller: _tabController,
                  children: sections.map((section) {
                    // Wrap a single section so it can be shown as its own tab,
                    // while reusing the same TaskRequirementsSection widget.
                    final singleSectionDetail = {
                      'template': {
                        'sections': [section],
                      },
                    };
                    return SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                      child: TaskRequirementsSection(
                        detail: singleSectionDetail,
                        submission: _submission,
                        taskId: widget.taskId,
                        existingAnswers: _existingAnswers,
                        onChanged: () {}, // no whole-task submit here anymore
                        onItemSaved: _onItemSaved,
                        onItemEdited: _onItemEdited,
                      ),
                    );
                  }).toList(),
                ),
        ),
        _buildBottomBar(context),
      ],
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(0, 12, 0, MediaQuery.of(context).padding.bottom + 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _BottomBarBtn(icon: Icons.build_outlined, label: 'Issues', color: _accent, onTap: () {}),
          _BottomBarBtn(icon: Icons.compress_rounded, label: 'Collapse', color: _accent, onTap: () {}),
          _BottomBarBtn(icon: Icons.check_box_outlined, label: 'Hide completed', color: _accent, onTap: () {}),
        ],
      ),
    );
  }
}

class _BottomBarBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _BottomBarBtn({required this.icon, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}