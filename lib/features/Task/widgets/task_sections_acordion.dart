import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import '../../Api/api_controller.dart';

class TaskSectionsAccordion extends StatefulWidget {
  final int taskId;
  final bool readOnly;
  final ValueChanged<List<Map<String, dynamic>>>? onProgressChanged;

  const TaskSectionsAccordion({
    super.key,
    required this.taskId,
    this.readOnly = false,
    this.onProgressChanged,
  });

  @override
  State<TaskSectionsAccordion> createState() => TaskSectionsAccordionState();
}

class TaskSectionsAccordionState extends State<TaskSectionsAccordion> {
  static const Color _orange = Color(0xFFFF7300);
  static const Color _green = Color(0xFF43A047);
  static const Color _textSec = Color(0xFF8A8A9A);
  static const Color _surface = Color(0xFF16161F);
  static const Color _border = Color(0xFF1E1E2E);

  List<Map<String, dynamic>> _sections = [];
  bool _sectionsLoading = true;
  String? _sectionsError;

  final Set<int> _expandedSectionIds = {};
  final Map<int, List<Map<String, dynamic>>> _itemsBySection = {};
  final Map<int, Map<String, dynamic>> _metaBySection = {};
  final Map<int, bool> _itemsLoadingBySection = {};

  // item id (string) -> saved answer data, as returned by /responses
  final Map<String, dynamic> _answers = {};
  final Set<String> _answeredItemIds = {};

  ScrollPosition? _scrollPosition;

  // ── Pending save tracking (for "wait before submit" flow) ──
  int _pendingSaveCount = 0;
  bool get hasPendingSaves => _pendingSaveCount > 0;

  // GlobalKey per item, used to scroll a specific item into view.
  final Map<String, GlobalKey> _itemKeys = {};

  @override
  void initState() {
    super.initState();
    _loadSections();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final position = Scrollable.maybeOf(context)?.position;
    if (position != _scrollPosition) {
      _scrollPosition?.removeListener(_onScroll);
      _scrollPosition = position;
      _scrollPosition?.addListener(_onScroll);
    }
  }

  @override
  void dispose() {
    _scrollPosition?.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    final position = _scrollPosition;
    if (position == null) return;
    if (position.pixels >= position.maxScrollExtent - 400) {
      for (final sectionId in _expandedSectionIds) {
        final meta = _metaBySection[sectionId];
        final loading = _itemsLoadingBySection[sectionId] ?? false;
        if (meta != null && meta['has_more'] == true && !loading) {
          final nextPage = ((meta['current_page'] as num?)?.toInt() ?? 1) + 1;
          _loadItemsPage(sectionId, nextPage);
        }
      }
    }
  }

Future<void> _loadSections() async {
  setState(() {
    _sectionsLoading = true;
    _sectionsError = null;
  });
  final result = await ApiController.getTaskSections(widget.taskId);
  if (!mounted) return;
  if (result['success'] == true) {
    final data = List<Map<String, dynamic>>.from(
        (result['data'] as List).map((e) => Map<String, dynamic>.from(e)))
      // hide sections that have no items/requirements
      ..removeWhere((s) => ((s['item_count'] as num?)?.toInt() ?? 0) == 0)
      ..sort((a, b) => ((a['display_order'] as num?)?.toInt() ?? 0)
          .compareTo((b['display_order'] as num?)?.toInt() ?? 0));

    setState(() {
      _sections = data;
      _sectionsLoading = false;
    });
    widget.onProgressChanged?.call(_sections);

    // auto-open the first section
    if (_sections.isNotEmpty && _expandedSectionIds.isEmpty) {
      final firstId = (_sections.first['id'] as num).toInt();
      await _toggleSection(firstId);
    }
  } else {
    setState(() {
      _sectionsError = result['message'];
      _sectionsLoading = false;
    });
  }
}
  
  Future<void> _toggleSection(int sectionId) async {
    setState(() {
      if (_expandedSectionIds.contains(sectionId)) {
        _expandedSectionIds.remove(sectionId);
      } else {
        _expandedSectionIds.add(sectionId);
      }
    });
    if (_expandedSectionIds.contains(sectionId) && !_itemsBySection.containsKey(sectionId)) {
      await _loadItemsPage(sectionId, 1);
    }
  }

  /// Lets the parent screen open a specific section (e.g. jump to the
  /// first incomplete one before Submit).
  void expandSection(int sectionId) {
    if (!_expandedSectionIds.contains(sectionId)) {
      _toggleSection(sectionId);
    }
  }


    Future<void> refreshAll() async {
    // 1. Refresh section list (answered_count / is_complete / titles etc.)
    final sectionsResult = await ApiController.getTaskSections(widget.taskId);
    if (!mounted) return;
    if (sectionsResult['success'] == true) {
    final data = List<Map<String, dynamic>>.from(
        (sectionsResult['data'] as List).map((e) => Map<String, dynamic>.from(e)))
      ..removeWhere((s) => ((s['item_count'] as num?)?.toInt() ?? 0) == 0)
      ..sort((a, b) => ((a['display_order'] as num?)?.toInt() ?? 0)
          .compareTo((b['display_order'] as num?)?.toInt() ?? 0));
      setState(() => _sections = data);
      widget.onProgressChanged?.call(_sections);
    }

    // 2. Re-fetch responses for every item already loaded in any
    //    expanded section, so answers reappear even if this accordion
    //    instance was already mounted from a previous session.
    for (final entry in _itemsBySection.entries) {
      final ids = entry.value.map((it) => (it['id'] as num).toInt()).toList();
      if (ids.isNotEmpty) {
        await _loadResponsesFor(ids);
      }
    }
  }
  

   Future<void> _loadItemsPage(int sectionId, int page) async {
    setState(() => _itemsLoadingBySection[sectionId] = true);

    final result = await ApiController.getTaskItems(
      taskId: widget.taskId,
      sectionId: sectionId,
      page: page,
      limit: 20,
    );

    if (!mounted) return;

    if (result['success'] == true) {
      final newItems = List<Map<String, dynamic>>.from(
          (result['data'] as List).map((e) => Map<String, dynamic>.from(e)));

      // Fetch existing responses BEFORE showing the items, so cards are
      // built with the correct existingAnswer the first time (no flash
      // of empty state that depends on didUpdateWidget to fix itself).
      final ids = newItems.map((it) => (it['id'] as num).toInt()).toList();
      if (ids.isNotEmpty) {
        await _loadResponsesFor(ids);
        if (!mounted) return;
      }

      setState(() {
        final existing = _itemsBySection[sectionId] ?? [];
        _itemsBySection[sectionId] = [...existing, ...newItems];
        _metaBySection[sectionId] = Map<String, dynamic>.from(result['meta'] ?? {});
        _itemsLoadingBySection[sectionId] = false;
      });
    } else {
      setState(() => _itemsLoadingBySection[sectionId] = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Failed to load items')),
      );
    }
  }

  Future<void> _loadResponsesFor(List<int> itemIds) async {
    // API allows up to 100 ids per call; our page size (<=20) is always
    // under that, but chunk defensively anyway.
    for (var i = 0; i < itemIds.length; i += 100) {
      final end = (i + 100 > itemIds.length) ? itemIds.length : i + 100;
      final chunk = itemIds.sublist(i, end);
      final result = await ApiController.getItemResponses(taskId: widget.taskId, itemIds: chunk);
      if (!mounted) return;
      if (result['success'] == true) {
        final data = Map<String, dynamic>.from(result['data'] ?? {});
        setState(() {
          data.forEach((key, value) {
            _answers[key] = value;
            _answeredItemIds.add(key);
          });
        });
      }
    }
  }

  /// Called by an item card the moment the user changes an answer.
  /// Updates local progress counters immediately (optimistic) — the save
  /// request itself fires in the background and the UI never waits on it.
  void _onItemAnswered(int sectionId, String itemId, Map<String, dynamic> payload) {
    final firstTimeAnswered = !_answeredItemIds.contains(itemId);
    _answeredItemIds.add(itemId);

    // NEW: cache the answer locally in the same shape /responses uses,
    // so re-expanding a collapsed section (which rebuilds _ItemCard from
    // scratch) can prefill correctly without waiting on a server refetch.
    _answers[itemId] = _normalizePayloadToAnswer(payload);

    if (firstTimeAnswered) {
      final idx = _sections.indexWhere((s) => (s['id'] as num).toInt() == sectionId);
      if (idx != -1) {
        final section = Map<String, dynamic>.from(_sections[idx]);
        final answered = ((section['answered_count'] as num?)?.toInt() ?? 0) + 1;
        final total = (section['item_count'] as num?)?.toInt() ?? 0;
        section['answered_count'] = answered;
        section['is_complete'] = answered >= total;
        setState(() => _sections[idx] = section);
        widget.onProgressChanged?.call(_sections);
      }
    }

    _pendingSaveCount++;
    ApiController.saveTaskItem(taskId: widget.taskId, payload: payload).then((result) {
      _pendingSaveCount = _pendingSaveCount > 0 ? _pendingSaveCount - 1 : 0;
      if (!mounted) return;
      if (result['success'] != true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to save answer'),
            backgroundColor: const Color(0xFFFF6B6B),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
  }

    /// Converts a /save-item request payload into the same shape /responses
  /// returns, so we can cache it locally the moment the user answers —
  /// without waiting for (or re-fetching from) the server.
Map<String, dynamic> _normalizePayloadToAnswer(Map<String, dynamic> payload) {
  final files = payload['files'] ?? [];

  if (payload.containsKey('answer_yes_no')) {
    return {'answer_text': payload['answer_yes_no'], 'files': files};
  }
  if (payload.containsKey('rating_value')) {
    return {'answer_text': payload['rating_value'].toString(), 'files': files};
  }
  if (payload.containsKey('count_value')) {
    return {'answer_text': payload['count_value'].toString(), 'files': files};
  }
  if (payload.containsKey('checklist_responses')) {
    final options = <String, dynamic>{};
    for (final opt in (payload['checklist_responses'] as List)) {
      options[opt['option_id'].toString()] = {
        'checked': opt['checked'] == true,
        'files': opt['files'] ?? [],
      };
    }
    return {'options': options, 'files': files};
  }
  return {
    if (payload.containsKey('answer_text')) 'answer_text': payload['answer_text'],
    if (payload.containsKey('files')) 'files': payload['files'],
  };
}

    /// Waits until all in-flight /save-item calls resolve (success or
  /// failure), so Submit never races an unsent answer. Times out as a
  /// safety net rather than hanging forever if something never resolves.
  Future<void> waitForPendingSaves({Duration timeout = const Duration(seconds: 8)}) async {
    final deadline = DateTime.now().add(timeout);
    while (hasPendingSaves && DateTime.now().isBefore(deadline)) {
      await Future.delayed(const Duration(milliseconds: 150));
    }
  }

  /// Finds the next incomplete section (in display order), makes sure its
  /// items are loaded far enough to find an unanswered one (paginating if
  /// needed), expands it, and scrolls that item into view. Returns true
  /// if it found and scrolled to something, false if everything is
  /// actually complete (shouldn't normally happen if is_complete flags
  /// are accurate).
  ///
  /// Calling this repeatedly (e.g. once per Submit press) naturally walks
  /// through incomplete items one at a time, because each item is
  /// removed from consideration the moment the user answers it.
  Future<bool> goToNextIncomplete() async {
    final orderedSections = [..._sections]
      ..sort((a, b) => ((a['display_order'] as num?)?.toInt() ?? 0)
          .compareTo((b['display_order'] as num?)?.toInt() ?? 0));

    for (final section in orderedSections) {
      final sectionId = (section['id'] as num).toInt();
      if (section['is_complete'] == true) continue;

      if (!_expandedSectionIds.contains(sectionId)) {
        await _toggleSection(sectionId); // expands + loads page 1
        await Future.delayed(const Duration(milliseconds: 250)); // let it build
      }

      Map<String, dynamic>? target;
      while (true) {
        final items = _itemsBySection[sectionId] ?? [];
        for (final it in items) {
          if (!_answeredItemIds.contains(it['id'].toString())) {
            target = it;
            break;
          }
        }
        if (target != null) break;

        final meta = _metaBySection[sectionId];
        final hasMore = meta?['has_more'] == true;
        if (!hasMore) break;
        final nextPage = ((meta?['current_page'] as num?)?.toInt() ?? 1) + 1;
        await _loadItemsPage(sectionId, nextPage);
      }

      if (target != null) {
        final itemId = target['id'].toString();
        await Future.delayed(const Duration(milliseconds: 150));
        final key = _itemKeys[itemId];
        final ctx = key?.currentContext;
        if (ctx != null) {
          await Scrollable.ensureVisible(
            ctx,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
            alignment: 0.25,
          );
        }
        return true;
      }
    }
    return false;
  }


  @override
  Widget build(BuildContext context) {
    if (_sectionsLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40),
        child: Center(child: CircularProgressIndicator(color: _orange)),
      );
    }
    if (_sectionsError != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: [
            Text(_sectionsError!, style: const TextStyle(color: _textSec)),
            const SizedBox(height: 12),
            TextButton(onPressed: _loadSections, child: const Text('Retry', style: TextStyle(color: _orange))),
          ],
        ),
      );
    }
    if (_sections.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Text('No requirements found for this task, Kindly contact your admin.', style: TextStyle(color: _textSec)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _sections.map((section) {
        final sectionId = (section['id'] as num).toInt();
        final isExpanded = _expandedSectionIds.contains(sectionId);
        final isComplete = section['is_complete'] == true;
        final answered = section['answered_count'] ?? 0;
        final total = section['item_count'] ?? 0;

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () => _toggleSection(sectionId),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Icon(
                        isComplete ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                        size: 20,
                        color: isComplete ? _green : _textSec,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          section['title'] ?? '',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
                        ),
                      ),
                      Text(
                        '$answered / $total',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isComplete ? _green : _textSec,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(isExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded, color: _textSec),
                    ],
                  ),
                ),
              ),
              if (isExpanded) ...[
                const Divider(height: 1, color: _border),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                  child: _buildSectionItems(sectionId),
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSectionItems(int sectionId) {
    final items = _itemsBySection[sectionId];
    final loading = _itemsLoadingBySection[sectionId] ?? false;
    final meta = _metaBySection[sectionId];
    final hasMore = meta?['has_more'] == true;

    if (items == null && loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(child: CircularProgressIndicator(color: _orange)),
      );
    }
    if (items == null || items.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Text('No items in this section.', style: TextStyle(color: _textSec)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
         ...items.map((item) {
          final itemId = item['id'].toString();
          final positionKey = _itemKeys.putIfAbsent(itemId, () => GlobalKey());
          return Container(
            key: positionKey,
            child: _ItemCard(
              key: ValueKey(itemId),
              item: item,
              existingAnswer: _answers[itemId] as Map?,
              readOnly: widget.readOnly,
              onAnswered: (payload) => _onItemAnswered(sectionId, itemId, payload),
            ),
          );
        }),
        if (hasMore) ...[
          const SizedBox(height: 8),
          Center(
            child: loading
                ? const Padding(
                    padding: EdgeInsets.all(8),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: _orange),
                    ),
                  )
                : TextButton(
                    onPressed: () {
                      final nextPage = ((meta?['current_page'] as num?)?.toInt() ?? 1) + 1;
                      _loadItemsPage(sectionId, nextPage);
                    },
                    child: const Text('Load more', style: TextStyle(color: _orange)),
                  ),
          ),
        ],
      ],
    );
  }
}

// ── Single item card ─────────────────────────────────────────────────────
class _ItemCard extends StatefulWidget {
  final Map<String, dynamic> item;
  final Map? existingAnswer;
  final bool readOnly;
  final ValueChanged<Map<String, dynamic>> onAnswered;

  const _ItemCard({
    super.key,
    required this.item,
    required this.onAnswered,
    this.existingAnswer,
    this.readOnly = false,
  });

  @override
  State<_ItemCard> createState() => _ItemCardState();
}

class _ItemCardState extends State<_ItemCard> {
  static const Color _orange = Color(0xFFFF7300);
  static const Color _green = Color(0xFF43A047);
  static const Color _red = Color(0xFFFF6B6B);
  static const Color _textSec = Color(0xFF8A8A9A);

  final _picker = ImagePicker();
  final _textController = TextEditingController();
  Timer? _debounce;

  String? _yesNo;
  final Map<int, bool> _checkedOptions = {};
  List<Map<String, dynamic>> _files = [];
  bool _isUploadingImage = false;
  bool _isSaved = false;

  int get _id => (widget.item['id'] as num).toInt();
  String get _type => widget.item['type'] ?? '';
  bool get _imageMandatory => widget.item['image_mandatory'] == true;
  bool get _readOnly => widget.readOnly;

  @override
  void initState() {
    super.initState();
    _prefill();
  }

  @override
  void didUpdateWidget(covariant _ItemCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Responses (GET /responses) can arrive AFTER items are already
    // rendered, since they're two separate API calls. When that
    // happens this same _ItemCardState instance is reused (same
    // ValueKey), so initState()/prefill() never runs again on its
    // own. Re-prefill here the first time an answer shows up —
    // but don't clobber anything the user already answered locally.
    final hadAnswer = oldWidget.existingAnswer != null;
    final hasAnswerNow = widget.existingAnswer != null;
    if (!hadAnswer && hasAnswerNow && !_isSaved) {
      setState(_prefill);
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _textController.dispose();
    super.dispose();
  }

void _prefill() {
  final answer = widget.existingAnswer;
  if (answer == null) return;
  _isSaved = true;

  // Files: restore for ALL types (server may return maps or plain URL strings)
  final rawFiles = (answer['files'] as List?) ?? const [];
  _files = rawFiles.map<Map<String, dynamic>>((f) {
    if (f is Map) return Map<String, dynamic>.from(f);
    return {'cdn_url': f.toString()};
  }).toList();

  switch (_type) {
    case 'YES_NO':
      final v = (answer['answer_text'] ?? '').toString().trim().toUpperCase();
      _yesNo = v == 'YES' ? 'YES' : (v == 'NO' ? 'NO' : null);
      break;
    case 'RATING':
    case 'COUNT':
    case 'TEXT':
    case 'REPORT':
    case 'CONDITION':
    case 'PHOTO':
      _textController.text = (answer['answer_text'] ?? '').toString();
      break;
    case 'CHECKLIST':
      final options = (answer['options'] as Map?) ?? {};
      options.forEach((key, value) {
        final optId = int.tryParse(key.toString());
        if (optId != null && value is Map) {
          _checkedOptions[optId] = value['checked'] == true;
          // fallback: server may store files per option
          if (_files.isEmpty && value['files'] is List) {
            for (final f in value['files']) {
              _files.add(f is Map ? Map<String, dynamic>.from(f) : {'cdn_url': f.toString()});
            }
          }
        }
      });
      break;
  }
}


Map<String, dynamic> _buildPayload() {
  switch (_type) {
    case 'YES_NO':
      return {'item_id': _id, 'answer_yes_no': _yesNo ?? 'NO', 'files': _files};
    case 'RATING':
      return {'item_id': _id, 'rating_value': int.tryParse(_textController.text) ?? 0, 'files': _files};
    case 'COUNT':
      return {'item_id': _id, 'count_value': int.tryParse(_textController.text) ?? 0, 'files': _files};
    case 'TEXT':
      return {'item_id': _id, 'answer_text': _textController.text, 'files': _files};
    case 'REPORT':
    case 'CONDITION':
      return {'item_id': _id, 'answer_text': _textController.text, 'files': _files};
    case 'PHOTO':
      return {'item_id': _id, 'files': _files};
    case 'CHECKLIST':
      final options = (widget.item['options'] as List? ?? []);
      return {
        'item_id': _id,
        'checklist_responses': options.map((opt) {
          final optId = (opt['id'] as num).toInt();
          return {'option_id': optId, 'checked': _checkedOptions[optId] ?? false};
        }).toList(),
        'files': _files,
      };
    default:
      return {'item_id': _id};
  }
}


  void _commit() {
    if (_readOnly) return;
    setState(() => _isSaved = true);
    widget.onAnswered(_buildPayload());
  }

  // Debounced commit for free-typed text fields, so we don't fire a save
  // request on every keystroke.
  void _onTextChanged() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), _commit);
  }

  Future<void> _showImageSourceDialog() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: const Color(0xFF1E1E2E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Select Image Source', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.photo_library, color: _orange),
              title: const Text('Upload from Phone', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: _orange),
              title: const Text('Take Photo', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    await _pickAndCropImage(source);
  }

  Future<void> _pickAndCropImage(ImageSource source) async {
    final picked = await _picker.pickImage(source: source, imageQuality: 85);
    if (picked == null) return;

    final croppedFile = await ImageCropper().cropImage(
      sourcePath: picked.path,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Image',
          toolbarColor: _orange,
          toolbarWidgetColor: Colors.white,
          initAspectRatio: CropAspectRatioPreset.square,
          lockAspectRatio: false,
        ),
        IOSUiSettings(minimumAspectRatio: 1.0),
      ],
    );
    if (croppedFile == null) return;

    await _uploadImage(File(croppedFile.path));
  }

  Future<void> _uploadImage(File file) async {
    setState(() => _isUploadingImage = true);
    final response = await ApiController.uploadSingleFile(file: file, folder: 'task_requirements');
    if (!mounted) return;
    setState(() => _isUploadingImage = false);

    if (response['success'] == true) {
      final data = Map<String, dynamic>.from(response['data'] ?? {});
      final fileEntry = {
        'file_key': data['file_key'] ?? data['key'] ?? '',
        'file_name': data['file_name'] ?? file.path.split('/').last,
        'file_size': data['file_size'] ?? file.lengthSync(),
        'mime_type': data['mime_type'] ?? '',
        'cdn_url': data['cdn_url'] ?? data['original_url'] ?? '',
      };
      setState(() => _files = [..._files, fileEntry]);
      _commit();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(response['message'] ?? 'Upload failed. Try again.'),
        backgroundColor: _red,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  void _removeFile(int index) {
    setState(() => _files = [..._files]..removeAt(index));
    _commit();
  }

  @override
  Widget build(BuildContext context) {
    bool showImageUploader = false;
    if (_imageMandatory) {
      showImageUploader = _type == 'YES_NO' ? _yesNo == 'YES' : true;
    }
    if (_type == 'PHOTO') showImageUploader = true;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF111118),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF1E1E2E)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(widget.item['question'] ?? '',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.white)),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: _orange.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
                child: Text(_type, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: _orange)),
              ),
            ],
          ),
          if (_type == 'YES_NO') ...[
            const SizedBox(height: 12),
            Row(
              children: [
                _YesNoBtn(
                  label: 'Yes',
                  color: _green,
                  isSelected: _yesNo == 'YES',
                  onTap: _readOnly
                      ? null
                      : () {
                          setState(() => _yesNo = 'YES');
                          _commit();
                        },
                ),
                const SizedBox(width: 10),
                _YesNoBtn(
                  label: 'No',
                  color: _red,
                  isSelected: _yesNo == 'NO',
                  onTap: _readOnly
                      ? null
                      : () {
                          setState(() {
                            _yesNo = 'NO';
                            _files = [];
                          });
                          _commit();
                        },
                ),
              ],
            ),
          ],
          if (_type == 'CHECKLIST') ...[
            const SizedBox(height: 12),
            ...(widget.item['options'] as List? ?? []).map<Widget>((opt) {
              final optId = (opt['id'] as num).toInt();
              final optText = opt['text'] ?? '';
              final isSelected = _checkedOptions[optId] ?? false;
              return GestureDetector(
                onTap: _readOnly
                    ? null
                    : () {
                        setState(() => _checkedOptions[optId] = !isSelected);
                        _commit();
                      },
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: isSelected ? _orange.withOpacity(0.15) : Colors.transparent,
                          border: Border.all(color: isSelected ? _orange : _textSec, width: isSelected ? 1.5 : 1),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: isSelected ? const Icon(Icons.check, size: 13, color: _orange) : null,
                      ),
                      const SizedBox(width: 12),
                      Text(optText, style: const TextStyle(fontSize: 14, color: Colors.white)),
                    ],
                  ),
                ),
              );
            }),
          ],
          if (_type == 'REPORT' || _type == 'TEXT' || _type == 'CONDITION') ...[
            const SizedBox(height: 12),
            TextField(
              controller: _textController,
              minLines: _type == 'TEXT' ? 2 : 3,
              maxLines: _type == 'TEXT' ? 4 : 6,
              style: const TextStyle(fontSize: 14, color: Colors.white),
              onChanged: (_) => _onTextChanged(),
              enabled: !_readOnly,
              decoration: _decoration(
                  _type == 'TEXT' ? 'Enter text…' : _type == 'CONDITION' ? 'Describe condition…' : 'Enter report…'),
            ),
          ],
          if (_type == 'COUNT') ...[
            const SizedBox(height: 12),
            TextField(
              controller: _textController,
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 14, color: Colors.white),
              onChanged: (_) => _onTextChanged(),
              enabled: !_readOnly,
              decoration: _decoration('Enter count…'),
            ),
          ],
          if (_type == 'RATING') ...[
            const SizedBox(height: 12),
            _buildStarRating(),
          ],
          if (showImageUploader) ...[
            const SizedBox(height: 12),
            _buildImageUploader(),
          ],
          if (_isSaved) ...[
            const SizedBox(height: 12),
            const Row(children: [
              Icon(Icons.check_circle_rounded, size: 16, color: _green),
              SizedBox(width: 6),
              Text('Saved', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: _green)),
            ]),
          ],
        ],
      ),
    );
  }

  Widget _buildStarRating() {
    final current = int.tryParse(_textController.text) ?? 0;
    return Row(
      children: List.generate(5, (index) {
        final star = index + 1;
        return GestureDetector(
          onTap: _readOnly
              ? null
              : () {
                  setState(() => _textController.text = star.toString());
                  _commit();
                },
          child: Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Icon(
              star <= current ? Icons.star_rounded : Icons.star_outline_rounded,
              size: 36,
              color: star <= current ? _orange : _textSec,
            ),
          ),
        );
      }),
    );
  }

  InputDecoration _decoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 14, color: _textSec),
      filled: true,
      fillColor: const Color(0xFF16161F),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1E1E2E))),
      enabledBorder:
          OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1E1E2E))),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: _orange, width: 1.5)),
    );
  }

  Widget _buildImageUploader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.camera_alt_outlined, size: 15, color: _orange),
            const SizedBox(width: 6),
            Text(
              _files.isEmpty ? 'Photo Required' : 'Photos (${_files.length} Saved)',
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: _orange),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (_files.isNotEmpty) ...[
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: List.generate(_files.length, (index) {
              final url = _files[index]['cdn_url']?.toString() ?? '';
              return Stack(
                children: [
                  Container(
                    height: 100,
                    width: 100,
                    decoration:
                        BoxDecoration(borderRadius: BorderRadius.circular(10), border: Border.all(color: _green, width: 1.5)),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: url.isEmpty
                          ? const Icon(Icons.broken_image, color: _textSec, size: 28)
                          : Image.network(url,
                              height: 100,
                              width: 100,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, color: _textSec, size: 28)),
                    ),
                  ),
                  if (!_readOnly)
                    Positioned(
                      top: 5,
                      right: 5,
                      child: GestureDetector(
                        onTap: () => _removeFile(index),
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(color: Colors.black.withOpacity(0.75), shape: BoxShape.circle),
                          child: const Icon(Icons.close, size: 14, color: _red),
                        ),
                      ),
                    ),
                ],
              );
            }),
          ),
          const SizedBox(height: 12),
        ],
        if (!_readOnly)
          GestureDetector(
            onTap: _isUploadingImage ? null : _showImageSourceDialog,
            child: Container(
              height: 80,
              width: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF111118),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _orange.withOpacity(0.4), width: 1.5),
              ),
              child: _isUploadingImage
                  ? const Center(
                      child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: _orange)))
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate_outlined, size: 26, color: _orange.withOpacity(0.8)),
                        const SizedBox(height: 4),
                        const Text('Add Photo', style: TextStyle(fontSize: 13, color: _orange, fontWeight: FontWeight.w600)),
                      ],
                    ),
            ),
          ),
      ],
    );
  }
}

class _YesNoBtn extends StatelessWidget {
  final String label;
  final Color color;
  final bool isSelected;
  final VoidCallback? onTap;

  const _YesNoBtn({required this.label, required this.color, required this.isSelected, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.18) : color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? color : color.withOpacity(0.4), width: isSelected ? 1.5 : 1),
        ),
        child: Text(label,
            style: TextStyle(fontSize: 14.5, fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600, color: color)),
      ),
    );
  }
}