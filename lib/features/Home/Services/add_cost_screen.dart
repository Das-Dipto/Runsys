import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AddCostScreen extends StatefulWidget {
  const AddCostScreen({super.key});

  @override
  State<AddCostScreen> createState() => _AddCostScreenState();
}

class _AddCostScreenState extends State<AddCostScreen> {
  final _descriptionController = TextEditingController();
  String _selectedType = 'Labor';
  String _costAmount = '0.00';

  final List<String> _costTypes = [
    'Labor',
    'Material',
    'Expense',
    'Tax',
    'Skilled Labor',
    'Non-skilled Labor',
    'Mileage',
    'Mark-up',
  ];

  void _showTypeBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'CHOOSE TYPE',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
              ..._costTypes.map((type) => ListTile(
                    title: Text(type),
                    trailing: _selectedType == type
                        ? const Icon(Icons.check, color: Color(0xFF29B6F6))
                        : null,
                    onTap: () {
                      setState(() => _selectedType = type);
                      Navigator.pop(context);
                    },
                  )),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Add cost'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () {
              // Return cost data to previous screen
              Navigator.pop(context, {
                'description': _descriptionController.text.isEmpty
                    ? 'No description'
                    : _descriptionController.text,
                'type': _selectedType,
                'cost': double.tryParse(_costAmount) ?? 0.0,
              });
            },
            child: const Text('Save', style: TextStyle(fontSize: 17, color: Color(0xFF29B6F6))),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Description
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Description',
                border: UnderlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),

            // Type
            InkWell(
              onTap: _showTypeBottomSheet,
              child: Row(
                children: [
                  const Text('Type', style: TextStyle(fontSize: 16)),
                  const Spacer(),
                  Text(_selectedType, style: const TextStyle(fontSize: 16)),
                  const Icon(Icons.chevron_right, color: Colors.grey),
                ],
              ),
            ),
            const Divider(height: 32),

            // Cost
            Row(
              children: [
                const Text('Cost', style: TextStyle(fontSize: 16)),
                const Spacer(),
                Text('£$_costAmount', style: const TextStyle(fontSize: 16)),
              ],
            ),
            const Divider(height: 32),
          ],
        ),
      ),
    );
  }
}