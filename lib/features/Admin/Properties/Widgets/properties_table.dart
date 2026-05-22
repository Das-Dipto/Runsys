// lib/Admin/Widgets/properties_table.dart
import 'package:flutter/material.dart';
import '../../../Api/api_controller.dart';
import 'create_task_dialog.dart';

class PropertyRow {
  final int id;
  final String name;
  final String unitId;
  final String address;
  final String addressSub;
  final List<String> tags;
  final String status;
  final bool hasIssues;
  final String lastClean;
  final String lastInspection;

  const PropertyRow({
    required this.id,
    required this.name,
    required this.unitId,
    required this.address,
    required this.addressSub,
    required this.tags,
    required this.status,
    required this.hasIssues,
    required this.lastClean,
    required this.lastInspection,
  });
}

// ── Column config ─────────────────────────────────────────────────────────────
const List<double> _colWidths = [
  170, // PROPERTY
  190, // ADDRESS
  120, // TAGS
  100, // STATUS
  110, // ISSUES
  110, // LAST CLEAN
  130, // LAST INSPECTION
  70,  // ACTIONS
];

const List<String> _headers = [
  'PROPERTY',
  'ADDRESS',
  'TAGS',
  'STATUS',
  'ISSUES',
  'LAST CLEAN',
  'LAST INSPECTION',
  'ACTIONS',
];

double get _tableWidth =>
    _colWidths.fold(0.0, (double a, double b) => a + b) + 32.0;

class PropertiesTable extends StatefulWidget {
  const PropertiesTable({super.key});

  @override
  State<PropertiesTable> createState() => _PropertiesTableState();
}

class _PropertiesTableState extends State<PropertiesTable> {
  final ScrollController _hScroll = ScrollController();

  bool _isLoading = true;
  String? _errorMessage;
  List<PropertyRow> _properties = [];

  @override
  void initState() {
    super.initState();
    _fetchProperties();
  }

  Future<void> _fetchProperties() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await ApiController.getActiveProperties();

    if (result['success'] == true) {
      final List<dynamic> apiData = result['data'];

      final List<PropertyRow> mapped = apiData.map((item) {
        return PropertyRow(
          id: item['id'] ?? 0,
          name: item['name'] ?? 'Untitled Property',
          unitId: item['building'] != null ? '#${item['building']}' : '',
          address: item['address'] ?? '',
          addressSub: item['city'] != null ? '${item['city']}, ${item['state'] ?? ''}' : '',
          tags: item['tags'] != null && item['tags'] is List
              ? List<String>.from(item['tags'])
              : [],
          status: item['is_active'] == 'Y' ? 'Active' : 'Inactive',
          hasIssues: (item['open_issues_count'] ?? 0) > 0,
          lastClean: 'Never',
          lastInspection: 'Never',
        );
      }).toList();

      setState(() {
        _properties = mapped;
        _isLoading = false;
      });
    } else {
      setState(() {
        _errorMessage = result['message'] ?? 'Failed to load properties';
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _hScroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _fetchProperties, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (_properties.isEmpty) {
      return const Center(child: Text('No properties found'));
    }

    return Scrollbar(
      controller: _hScroll,
      thumbVisibility: true,
      trackVisibility: true,
      child: SingleChildScrollView(
        controller: _hScroll,
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: _tableWidth,
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: _properties.length,
                  itemBuilder: (context, i) => _buildRow(_properties[i], i),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ───────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    const style = TextStyle(
      color: Color(0xFF8A8A9A),
      fontSize: 11,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.6,
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFF16161F),
        border: Border(
          top: BorderSide(color: Color(0xFF1E1E2E)),
          bottom: BorderSide(color: Color(0xFF1E1E2E)),
        ),
      ),
      child: Row(
        children: List.generate(
          _headers.length,
          (i) => SizedBox(width: _colWidths[i], child: Text(_headers[i], style: style)),
        ),
      ),
    );
  }

  // ── Row ───────────────────────────────────────────────────────────────────
  Widget _buildRow(PropertyRow prop, int index) {
    final isEven = index % 2 == 0;
    const grey12 = TextStyle(color: Color(0xFF8A8A9A), fontSize: 12);

    Widget cell(int i, Widget child) => SizedBox(width: _colWidths[i], child: child);

    Widget txt(String s, {TextStyle style = grey12}) => Text(
          s,
          style: style,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        );

    return GestureDetector(
      onTap: () => showDialog(
        context: context,
        builder: (_) => CreateTaskDialog(
          propertyId: prop.id,
          propertyName: prop.name,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: isEven
              ? const Color(0xFF0A0A0F)
              : const Color(0xFF16161F).withOpacity(0.6),
          border: const Border(
              bottom: BorderSide(color: Color(0xFF1E1E2E), width: 0.5)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            cell(0, _propertyCell(prop)),
            cell(1, _addressCell(prop)),
            cell(2, _tagsCell(prop.tags)),
            cell(3, _statusBadge(prop.status)),
            cell(4, _issuesBadge(prop.hasIssues)),
            cell(5, txt(prop.lastClean)),
            cell(6, txt(prop.lastInspection)),
            cell(7, const Icon(Icons.more_horiz_rounded,
                color: Color(0xFF8A8A9A), size: 20)),
          ],
        ),
      ),
    );
  }

  // ── Cells ─────────────────────────────────────────────────────────────────
  Widget _propertyCell(PropertyRow p) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.business_rounded,
                  color: Color(0xFF8A8A9A), size: 14),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  p.name,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Padding(
            padding: const EdgeInsets.only(left: 20),
            child: Text(p.unitId,
                style: const TextStyle(
                    color: Color(0xFF8A8A9A), fontSize: 11)),
          ),
        ],
      );

  Widget _addressCell(PropertyRow p) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on_outlined,
                  color: Color(0xFF8A8A9A), size: 13),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  p.address,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w400),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Padding(
            padding: const EdgeInsets.only(left: 17),
            child: Text(p.addressSub,
                style: const TextStyle(
                    color: Color(0xFF8A8A9A), fontSize: 11)),
          ),
        ],
      );

  Widget _tagsCell(List<String> tags) => Wrap(
        spacing: 4,
        runSpacing: 4,
        children: tags
            .map((tag) => Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E2E),
                    borderRadius: BorderRadius.circular(6),
                    border:
                        Border.all(color: const Color(0xFF2A2A3A)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.sell_outlined,
                          color: Color(0xFF8A8A9A), size: 11),
                      const SizedBox(width: 4),
                      Text(tag,
                          style: const TextStyle(
                              color: Color(0xFF8A8A9A),
                              fontSize: 11,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                ))
            .toList(),
      );

  Widget _statusBadge(String status) {
    final isActive = status == 'Active';
    final color = isActive ? Colors.green : Colors.grey;
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
              isActive
                  ? Icons.check_circle_outline_rounded
                  : Icons.cancel_outlined,
              color: color,
              size: 12),
          const SizedBox(width: 4),
          Text(status,
              style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _issuesBadge(bool hasIssues) {
    final color = hasIssues ? Colors.red : Colors.green;
    final label = hasIssues ? 'Has Issues' : 'No Issues';
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
              hasIssues
                  ? Icons.error_outline_rounded
                  : Icons.check_circle_outline_rounded,
              color: color,
              size: 12),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}