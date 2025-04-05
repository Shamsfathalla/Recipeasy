import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Color constants
final Color lightPurple = Color.fromARGB(255, 234, 221, 255); // Light purple shade
final Color purpleIconColor = Color.fromARGB(255, 79, 55, 139); // Purple for icons
final Color primaryPurple = Color.fromARGB(255, 110, 59, 226); // Primary purple color

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        primaryColor: primaryPurple,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          titleTextStyle: TextStyle(color: Colors.black),
          iconTheme: IconThemeData(color: Colors.black),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: primaryPurple,
          foregroundColor: Colors.white,
        ),
        checkboxTheme: CheckboxThemeData(
          fillColor: MaterialStateProperty.resolveWith<Color>((states) {
            if (states.contains(MaterialState.selected)) {
              return primaryPurple;
            }
            return Colors.grey;
          }),
        ),
      ),
      darkTheme: ThemeData(
        primaryColor: primaryPurple,
        scaffoldBackgroundColor: Colors.grey[900],
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.grey[900],
          titleTextStyle: TextStyle(color: Colors.white),
          iconTheme: IconThemeData(color: Colors.white),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: primaryPurple,
          foregroundColor: Colors.white,
        ),
        checkboxTheme: CheckboxThemeData(
          fillColor: MaterialStateProperty.resolveWith<Color>((states) {
            if (states.contains(MaterialState.selected)) {
              return primaryPurple;
            }
            return Colors.grey;
          }),
        ),
      ),
      home: ShopListPage(),
    );
  }
}

class ShopListPage extends StatefulWidget {
  @override
  _ShopListPageState createState() => _ShopListPageState();
}

class _ShopListPageState extends State<ShopListPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _showFab = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    setState(() {
      _showFab = _tabController.index == 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: AppBar(
          backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
          bottom: TabBar(
            controller: _tabController,
            isScrollable: false,
            indicatorColor: primaryPurple,
            labelColor: isDarkMode ? Colors.white : primaryPurple,
            unselectedLabelColor: isDarkMode ? Colors.grey[400] : Colors.grey[700],
            tabs: [
              Tab(text: 'Current List'),
              Tab(text: 'History'),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          CurrentShopList(),
          HistoryShopList(),
        ],
      ),
      floatingActionButton: _showFab
          ? FloatingActionButton(
        onPressed: () {
          _showAddIngredientDialog();
        },
        child: Icon(
          Icons.add,
          color: isDarkMode ? Colors.white : purpleIconColor,
        ),
        backgroundColor: isDarkMode ? primaryPurple : lightPurple,
      )
          : null,
    );
  }

  void _showAddIngredientDialog() {
    final TextEditingController _ingredientController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Add Ingredient'),
          content: TextField(
            controller: _ingredientController,
            decoration: InputDecoration(labelText: 'Ingredient Name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final ingredient = _ingredientController.text.trim();
                if (ingredient.isNotEmpty) {
                  await _addIngredientToShoppingList(ingredient, manual: true);
                  Navigator.pop(context);
                }
              },
              child: Text('Add'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addIngredientToShoppingList(String ingredient, {required bool manual}) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;
      final collectionRef = FirebaseFirestore.instance.collection('users/${user.uid}/shopping_list');
      final querySnapshot = await collectionRef.where('name', isEqualTo: ingredient).get();
      if (querySnapshot.docs.isNotEmpty) {
        if (manual) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ingredient "$ingredient" already exists in your shopping list.'),
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          final doc = querySnapshot.docs.first;
          await collectionRef.doc(doc.id).update({
            'quantity': FieldValue.increment(1),
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Incremented "$ingredient" quantity in your shopping list.'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        await collectionRef.add({
          'name': ingredient,
          'quantity': 1,
          'addedAt': FieldValue.serverTimestamp(),
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added "$ingredient" to shopping list'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error adding ingredient to shopping list: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add "$ingredient" to shopping list'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}

class CurrentShopList extends StatefulWidget {
  @override
  _CurrentShopListState createState() => _CurrentShopListState();
}

class _CurrentShopListState extends State<CurrentShopList> {
  Stream<QuerySnapshot> _shoppingListStream = FirebaseFirestore.instance
      .collection('users/${FirebaseAuth.instance.currentUser!.uid}/shopping_list')
      .snapshots();

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return StreamBuilder<QuerySnapshot>(
      stream: _shoppingListStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: primaryPurple));
        }
        final List<QueryDocumentSnapshot> documents = snapshot.data!.docs;
        if (documents.isEmpty) {
          return Center(
            child: Text(
              'Your shopping list is empty.',
              style: TextStyle(color: isDarkMode ? Colors.grey[400] : Colors.grey[700]),
            ),
          );
        }
        return ListView.builder(
          padding: EdgeInsets.all(10.0),
          itemCount: documents.length,
          itemBuilder: (context, index) {
            final doc = documents[index];
            final data = doc.data() as Map<String, dynamic>;
            final name = data['name'];
            final quantity = data['quantity'] ?? 1;
            return Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              elevation: 3.0,
              margin: EdgeInsets.symmetric(vertical: 6.0),
              color: isDarkMode ? Colors.grey[800] : Colors.white,
              child: ListTile(
                title: Text(
                  name,
                  style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                ),
                subtitle: Text(
                  'Quantity: $quantity',
                  style: TextStyle(color: isDarkMode ? Colors.grey[400] : Colors.grey[700]),
                ),
                leading: Checkbox(
                  value: data['bought'] ?? false,
                  onChanged: (bool? value) async {
                    await FirebaseFirestore.instance
                        .collection('users/${FirebaseAuth.instance.currentUser!.uid}/shopping_list')
                        .doc(doc.id)
                        .update({'bought': value});
                    if (value == true) {
                      await FirebaseFirestore.instance
                          .collection('users/${FirebaseAuth.instance.currentUser!.uid}/history')
                          .add({
                        'name': name,
                        'quantity': quantity,
                        'addedAt': FieldValue.serverTimestamp(),
                      });
                      await FirebaseFirestore.instance
                          .collection('users/${FirebaseAuth.instance.currentUser!.uid}/shopping_list')
                          .doc(doc.id)
                          .delete();
                    }
                    setState(() {});
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(value! ? 'Marked "$name" as bought' : 'Unmarked "$name" as bought'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.remove, color: isDarkMode ? Colors.white : purpleIconColor),
                      onPressed: () async {
                        if (quantity > 1) {
                          await FirebaseFirestore.instance
                              .collection('users/${FirebaseAuth.instance.currentUser!.uid}/shopping_list')
                              .doc(doc.id)
                              .update({'quantity': FieldValue.increment(-1)});
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Decremented "$name" quantity in your shopping list.'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        } else {
                          await FirebaseFirestore.instance
                              .collection('users/${FirebaseAuth.instance.currentUser!.uid}/shopping_list')
                              .doc(doc.id)
                              .delete();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Removed "$name" from your shopping list.'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                        setState(() {});
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.add, color: isDarkMode ? Colors.white : purpleIconColor),
                      onPressed: () async {
                        await FirebaseFirestore.instance
                            .collection('users/${FirebaseAuth.instance.currentUser!.uid}/shopping_list')
                            .doc(doc.id)
                            .update({'quantity': FieldValue.increment(1)});
                        setState(() {});
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Incremented "$name" quantity in your shopping list.'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class HistoryShopList extends StatelessWidget {
  final Stream<QuerySnapshot> _historyStream;

  HistoryShopList()
      : _historyStream = FirebaseFirestore.instance
      .collection('users/${FirebaseAuth.instance.currentUser!.uid}/history')
      .snapshots();

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return StreamBuilder<QuerySnapshot>(
      stream: _historyStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: primaryPurple));
        }
        final List<QueryDocumentSnapshot> documents = snapshot.data!.docs;
        if (documents.isEmpty) {
          return Center(
            child: Text(
              'Your history is empty.',
              style: TextStyle(color: isDarkMode ? Colors.grey[400] : Colors.grey[700]),
            ),
          );
        }
        return ListView.builder(
          padding: EdgeInsets.all(10.0),
          itemCount: documents.length,
          itemBuilder: (context, index) {
            final doc = documents[index];
            final data = doc.data() as Map<String, dynamic>;
            final name = data['name'];
            final quantity = data['quantity'] ?? 1;
            return Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              elevation: 3.0,
              margin: EdgeInsets.symmetric(vertical: 6.0),
              color: isDarkMode ? Colors.grey[800] : Colors.white,
              child: ListTile(
                title: Text(
                  name,
                  style: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
                ),
                subtitle: Text(
                  'Quantity: $quantity',
                  style: TextStyle(color: isDarkMode ? Colors.grey[400] : Colors.grey[700]),
                ),
                leading: Icon(
                  Icons.history,
                  color: isDarkMode ? Colors.white : purpleIconColor,
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.add, color: isDarkMode ? Colors.white : purpleIconColor),
                      onPressed: () async {
                        final user = FirebaseAuth.instance.currentUser;
                        if (user == null) return;
                        final collectionRef = FirebaseFirestore.instance
                            .collection('users/${user.uid}/shopping_list');
                        final querySnapshot = await collectionRef.where('name', isEqualTo: name).get();
                        if (querySnapshot.docs.isNotEmpty) {
                          final doc = querySnapshot.docs.first;
                          await collectionRef.doc(doc.id).update({
                            'quantity': FieldValue.increment(1),
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Incremented "$name" quantity in your shopping list.'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        } else {
                          await collectionRef.add({
                            'name': name,
                            'quantity': quantity,
                            'addedAt': FieldValue.serverTimestamp(),
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Added "$name" to shopping list'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () async {
                        await FirebaseFirestore.instance
                            .collection('users/${FirebaseAuth.instance.currentUser!.uid}/history')
                            .doc(doc.id)
                            .delete();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Removed "$name" from your history.'),
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}