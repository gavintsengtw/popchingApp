import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class CategoryListPage extends StatefulWidget {
  const CategoryListPage({super.key});

  @override
  State<CategoryListPage> createState() => _CategoryListPageState();
}

class _CategoryListPageState extends State<CategoryListPage> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<dynamic> _dictionaryItems = [];
  String _selectedCodeId = 'MAINCLASS'; // Default selection

  // Popular codes to filter by
  final List<String> _codes = [
    'MAINCLASS',
    'MIDCLASS',
    'LOCATION',
    'FLOOR',
    'REGION',
    'USETYPE',
    'COMPANY',
    'CLASSTYPE',
  ];

  @override
  void initState() {
    super.initState();
    _fetchDictionaryItems();
  }

  Future<void> _fetchDictionaryItems() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final data = await _apiService.get('/dictionary/code/$_selectedCodeId');
      setState(() {
        _dictionaryItems = data ?? [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to load metadata: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Metadata & Categories')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Dictionary Type',
                border: OutlineInputBorder(),
              ),
              initialValue: _selectedCodeId,
              items: _codes
                  .map(
                    (code) => DropdownMenuItem(value: code, child: Text(code)),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedCodeId = value;
                  });
                  _fetchDictionaryItems();
                }
              },
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _dictionaryItems.isEmpty
                ? const Center(child: Text('No items found.'))
                : ListView.builder(
                    itemCount: _dictionaryItems.length,
                    itemBuilder: (context, index) {
                      final item = _dictionaryItems[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 8.0,
                          vertical: 4.0,
                        ),
                        child: ListTile(
                          title: Text(item['itemName'] ?? 'Unknown'),
                          subtitle: Text(
                            'ID: ${item['itemId']} | Code: ${item['codeId']}',
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Future: Open dialog to add new dictionary item
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Not implemented yet.')));
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
