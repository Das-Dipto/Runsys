import 'package:flutter/material.dart';
import 'element_detail_screen.dart';

class PropertyElementsScreen extends StatefulWidget {
  const PropertyElementsScreen({super.key});

  @override
  State<PropertyElementsScreen> createState() => _PropertyElementsScreenState();
}

class _PropertyElementsScreenState extends State<PropertyElementsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  final List<Map<String, String>> elements = [
    {'name': '1 Qt Saucepan with Lid', 'location': 'Bedroom 1'},
    {'name': 'Address Marker', 'location': ''},
    {'name': 'Bathroom 1', 'location': ''},
    {'name': 'Bed', 'location': 'Bedroom 1'},
    {'name': 'Bedroom 1', 'location': ''},
    {'name': 'Boiler', 'location': ''},
    {'name': 'Chemicals & Toxic Cleaning Supplies', 'location': ''},
    {'name': 'Closet', 'location': 'Bedroom 1'},
    {'name': 'Couch', 'location': 'Living Room'},
  ];

  @override
  Widget build(BuildContext context) {
    final filteredList = elements.where((item) {
      return item['name']!.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Property Elements', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700)),
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Search',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                filled: true,
                fillColor: Colors.grey.shade100,
              ),
            ),
          ),

          Expanded(
            child: ListView.builder(
              itemCount: filteredList.length,
              itemBuilder: (context, index) {
                final item = filteredList[index];
                return ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.info_outline, color: Colors.grey),
                  ),
                  title: Text(item['name']!, style: const TextStyle(fontWeight: FontWeight.w500)),
                  subtitle: item['location']!.isNotEmpty ? Text(item['location']!) : null,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ElementDetailScreen(title: item['name']!),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}