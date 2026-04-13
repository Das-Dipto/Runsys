import 'package:flutter/material.dart';
import 'add_supply_detail_screen.dart';

class AddSupplySearchScreen extends StatefulWidget {
  const AddSupplySearchScreen({super.key});

  @override
  State<AddSupplySearchScreen> createState() => _AddSupplySearchScreenState();
}

class _AddSupplySearchScreenState extends State<AddSupplySearchScreen> {
  final List<Map<String, dynamic>> _supplyList = [
    {
      'name': 'soap',
      'description': 'House keeping soap',
      'size': '100gm',
      'unitCost': 3.45,
    },
    {
      'name': 'Toilet Paper Roll',
      'description': '',
      'size': 'Unit',
      'unitCost': 0.36,
    },
    // Add more items as needed
  ];

  List<Map<String, dynamic>> filteredList = [];

  @override
  void initState() {
    super.initState();
    filteredList = _supplyList;
  }

  void _filter(String query) {
    setState(() {
      filteredList = _supplyList
          .where((item) =>
              item['name'].toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Search'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: _filter,
              decoration: InputDecoration(
                hintText: 'Search supplies...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: filteredList.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = filteredList[index];
                return ListTile(
                  title: Text(item['name'], style: const TextStyle(fontWeight: FontWeight.w500)),
                  subtitle: Text('Size: ${item['size']}'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('£${item['unitCost'].toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      const Icon(Icons.chevron_right, color: Colors.grey),
                    ],
                  ),
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddSupplyDetailScreen(supply: item),
                      ),
                    );
                    if (result != null) {
                      Navigator.pop(context, result); // Return to SuppliesScreen
                    }
                  },
                );
              },
            ),
          ),
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text('End of list.', style: TextStyle(color: Colors.grey)),
          ),
        ],
      ),
    );
  }
}