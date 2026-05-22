// create_task_dialog.dart
import 'package:flutter/material.dart';

class CreateTaskDialog extends StatefulWidget {
  const CreateTaskDialog({super.key});

  @override
  State<CreateTaskDialog> createState() => _CreateTaskDialogState();
}

class _CreateTaskDialogState extends State<CreateTaskDialog> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _rateController = TextEditingController(text: '0.00');

  String _selectedProperty = '';
  String _selectedDepartment = '';
  String _selectedPriority = 'Medium';
  String _selectedTemplate = 'Select template';
  String _selectedSubdepartment = 'None';
  bool _isRepeating = false;
  DateTime _dueDate = DateTime.now();
  TimeOfDay _dueTime = TimeOfDay.now();
  bool _watchTask = true;
  bool _textUpdates = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _rateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF111118),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: SizedBox(
        width: double.infinity,
        height: MediaQuery.of(context).size.height * 0.85,
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
              child: Row(
                children: [
                  const Icon(Icons.add_task_rounded, color: Color(0xFFFF7300), size: 28),
                  const SizedBox(width: 12),
                  const Text(
                    'Create New Task',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const Spacer(),
                  IconButton(icon: const Icon(Icons.close, color: Colors.grey), onPressed: () => Navigator.pop(context)),
                ],
              ),
            ),

            const Divider(color: Color(0xFF1E1E2E), height: 1),

            // Scrollable Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Properties
                      _buildLabel('Properties *'),
                      _buildDropdown('Select properties', _selectedProperty, (v) => setState(() => _selectedProperty = v ?? '')),

                      const SizedBox(height: 16),

                      // Department
                      _buildLabel('Department *'),
                      _buildDropdown('Select department', _selectedDepartment, (v) => setState(() => _selectedDepartment = v ?? '')),

                      const SizedBox(height: 24),

                      // Priority
                      _buildLabel('Priority Level'),
                      _buildPrioritySelector(),

                      const SizedBox(height: 20),

                      // Task Title
                      _buildLabel('Task Title *'),
                      TextFormField(
                        controller: _titleController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Enter a descriptive title...',
                          hintStyle: const TextStyle(color: Color(0xFF8A8A9A)),
                          filled: true,
                          fillColor: const Color(0xFF1E1E2E),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Description
                      _buildLabel('Description'),
                      TextFormField(
                        controller: _descriptionController,
                        maxLines: 4,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Add detailed description, instructions, or notes...',
                          hintStyle: const TextStyle(color: Color(0xFF8A8A9A)),
                          filled: true,
                          fillColor: const Color(0xFF1E1E2E),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Rate & Est. Time
                      Row(
                        children: [
                          Expanded(child: _buildRateField()),
                          const SizedBox(width: 12),
                          Expanded(child: _buildEstTimeField()),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Schedule Section (Simplified)
                      _buildLabel('Schedule'),
                      SwitchListTile(
                        title: const Text('Make this a repeating task', style: TextStyle(color: Colors.white)),
                        value: _isRepeating,
                        onChanged: (v) => setState(() => _isRepeating = v),
                        activeColor: const Color(0xFFFF7300),
                      ),

                      const SizedBox(height: 16),

                      // Assignees, Tags, etc. (Simplified for now)
                      _buildLabel('Assignees'),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: const Color(0xFF1E1E2E), borderRadius: BorderRadius.circular(10)),
                        child: const Text('+ Add assignee', style: TextStyle(color: Color(0xFF8A8A9A))),
                      ),

                      const SizedBox(height: 24),

                      // Tags
                      _buildLabel('Tags'),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: const Color(0xFF1E1E2E), borderRadius: BorderRadius.circular(10)),
                        child: const Text('Add tags...', style: TextStyle(color: Color(0xFF8A8A9A))),
                      ),

                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom Buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey,
                        side: const BorderSide(color: Color(0xFF1E1E2E)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // TODO: Save task logic
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Task created successfully!')));
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF7300),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Create Task', style: TextStyle(fontWeight: FontWeight.w700)),
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

  Widget _buildLabel(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      );

  Widget _buildDropdown(String hint, String value, Function(String?) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: const Color(0xFF1E1E2E), borderRadius: BorderRadius.circular(10)),
      child: DropdownButton<String>(
        value: value.isEmpty ? null : value,
        hint: Text(hint, style: const TextStyle(color: Color(0xFF8A8A9A))),
        isExpanded: true,
        underline: const SizedBox(),
        dropdownColor: const Color(0xFF1E1E2E),
        style: const TextStyle(color: Colors.white),
        items: const [DropdownMenuItem(value: 'Option 1', child: Text('Option 1'))], // Add real options later
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildPrioritySelector() {
    final priorities = ['Lowest', 'Low', 'Medium', 'High', 'Urgent'];
    final colors = [Colors.blue[900], Colors.blue, Colors.orange, Colors.deepOrange, Colors.red];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: List.generate(priorities.length, (i) {
        final isSelected = _selectedPriority == priorities[i];
        return GestureDetector(
          onTap: () => setState(() => _selectedPriority = priorities[i]),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? colors[i] : const Color(0xFF1E1E2E),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(priorities[i], style: TextStyle(color: isSelected ? Colors.white : Colors.grey[400], fontWeight: FontWeight.w500)),
          ),
        );
      }),
    );
  }

  Widget _buildRateField() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel('Rate'),
          TextField(
            controller: _rateController,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              prefixText: '\$ ',
              filled: true,
              fillColor: const Color(0xFF1E1E2E),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            ),
          ),
        ],
      );

  Widget _buildEstTimeField() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel('Est. Time'),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(color: const Color(0xFF1E1E2E), borderRadius: BorderRadius.circular(10)),
            child: const Text('HH:MM', style: TextStyle(color: Color(0xFF8A8A9A))),
          ),
        ],
      );
}