import 'package:flutter/material.dart';

class AddSupplyDetailScreen extends StatefulWidget {
  final Map<String, dynamic> supply;

  const AddSupplyDetailScreen({super.key, required this.supply});

  @override
  State<AddSupplyDetailScreen> createState() => _AddSupplyDetailScreenState();
}

class _AddSupplyDetailScreenState extends State<AddSupplyDetailScreen> {
  int _quantity = 1;
  bool _isBillable = true;

  @override
  Widget build(BuildContext context) {
    final unitCost = widget.supply['unitCost'] as double;
    final charge = unitCost * _quantity;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Add supply'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.supply['name'],
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            if (widget.supply['description'] != null && widget.supply['description'].toString().isNotEmpty)
              Text(widget.supply['description'], style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 32),

            // Quantity
            Row(
              children: [
                const Text('Quantity', style: TextStyle(fontSize: 16)),
                const Spacer(),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove),
                      onPressed: () => setState(() => _quantity = _quantity > 1 ? _quantity - 1 : 1),
                    ),
                    Text('$_quantity', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    IconButton(
                      icon: const Icon(Icons.add),
                      onPressed: () => setState(() => _quantity++),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 32),

            // Unit Cost
            Row(
              children: [
                const Text('Unit cost', style: TextStyle(fontSize: 16)),
                const Spacer(),
                Text('£${unitCost.toStringAsFixed(2)}'),
              ],
            ),
            const Divider(height: 32),

            // Charge
            Row(
              children: [
                const Text('Charge', style: TextStyle(fontSize: 16)),
                const Spacer(),
                Text('£${charge.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
            const Divider(height: 32),

            // Is billable
            Row(
              children: [
                const Text('Is billable', style: TextStyle(fontSize: 16)),
                const Spacer(),
                Switch(
                  value: _isBillable,
                  activeColor: const Color(0xFF29B6F6),
                  onChanged: (val) => setState(() => _isBillable = val),
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(20),
        child: ElevatedButton(
          onPressed: () {
            Navigator.pop(context, {
              'name': widget.supply['name'],
              'quantity': _quantity,
              'unitCost': unitCost,
              'charge': charge,
              'isBillable': _isBillable,
            });
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF29B6F6),
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text(
            'Add',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}