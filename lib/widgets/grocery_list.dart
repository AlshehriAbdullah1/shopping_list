import 'dart:convert';
import 'package:shopping_list/data/categories.dart';
import 'package:flutter/material.dart';
import 'package:shopping_list/models/grocery_item.dart';
import 'package:shopping_list/widgets/new_item.dart';
import 'package:http/http.dart' as http;

class GroceryList extends StatefulWidget {
  const GroceryList({super.key});

  @override
  State<GroceryList> createState() => _GroceryListState();
}

class _GroceryListState extends State<GroceryList> {
  List<GroceryItem> _groceryItems = [];
  late Future<List<GroceryItem>> _loadedItems;
  String? _error;
  @override
  void initState() {
    super.initState();
    _loadedItems = _loadItems();
  }

  Future<List<GroceryItem>> _loadItems() async {
    final url = Uri.https(
        'flutter-prep-7df2e-default-rtdb.europe-west1.firebasedatabase.app',
        'shopping-list.json');

    final response = await http.get(url);
    if (response.statusCode >= 400) {
      throw Exception('Failed to check , please try again later! ');
    }
    if (response.body == 'null') {
      return [];
    }
    final Map<String, dynamic> listData = json.decode(response.body);
    final List<GroceryItem> loadedItems = [];
    for (final item in listData.entries) {
      final category = categories.entries
          .firstWhere(
              (element) => item.value['category'] == element.value.title)
          .value;
      loadedItems.add(GroceryItem(
          id: item.key,
          name: item.value['name'].toString(),
          quantity: item.value['quantity'],
          category: category));
    }
    return loadedItems;
  }

  void _addItem() async {
    final newItem = await Navigator.of(context).push<GroceryItem>(
      MaterialPageRoute(
        builder: (ctx) {
          return const NewItem();
        },
      ),
    );
    if (newItem == null) {
      return;
    } else {
      setState(() {
        _groceryItems.add(newItem);
      });
    }
  }

  void _removeItem(GroceryItem item) async {
    final index = _groceryItems.indexOf(item);
    setState(() {
      _groceryItems.remove(item);
    });
    final url = Uri.https(
        'flutter-prep-7df2e-default-rtdb.europe-west1.firebasedatabase.app',
        'shopping-list/${item.id}.json');
    final response = await http.delete(url);
    if (response.statusCode >= 400) {
      setState(() {
        _groceryItems.insert(index, item);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Groceries'),
        actions: [IconButton(onPressed: _addItem, icon: const Icon(Icons.add))],
      ),
      body: FutureBuilder(
        future: _loadedItems,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          if (snapshot.hasError) {
            return Center(
                child: Text(
              snapshot.error.toString(),
              style: const TextStyle(fontSize: 30),
            ));
          }
          if (snapshot.data!.isEmpty) {
            return const Center(
                child: Text(
              'No Items here!',
              style: TextStyle(fontSize: 30),
            ));
          }

          return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                return Dismissible(
                  key: ValueKey(snapshot.data![index].id),
                  onDismissed: (direction) {
                    _removeItem(snapshot.data![index]);
                  },
                  child: ListTile(
                    title: Text(snapshot.data![index].name),
                    leading: Container(
                      width: 24,
                      height: 24,
                      color: snapshot.data![index].category.color,
                    ),
                    trailing: Text('${snapshot.data![index].quantity}'),
                  ),
                );
              });
        },
      ),
    );
  }
}
