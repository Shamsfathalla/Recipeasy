import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final primaryColor = Color.fromRGBO(110, 59, 226, 1);
    return MaterialApp(
      theme: ThemeData(
        primaryColor: primaryColor,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          titleTextStyle: TextStyle(color: Colors.black),
          iconTheme: IconThemeData(color: Colors.black),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
        ),
      ),
      darkTheme: ThemeData(
        primaryColor: primaryColor,
        scaffoldBackgroundColor: Colors.grey[900],
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.grey[900],
          titleTextStyle: TextStyle(color: Colors.white),
          iconTheme: IconThemeData(color: Colors.white),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
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
  final primaryColor = Color.fromRGBO(110, 59, 226, 1);

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
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: AppBar(
          backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
          bottom: TabBar(
            controller: _tabController,
            isScrollable: false,
            indicatorColor: primaryColor,
            labelColor: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : primaryColor,
            unselectedLabelColor: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey[400]
                : Colors.grey[700],
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
        child: Icon(Icons.add, color: Colors.white),
        backgroundColor: primaryColor,
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
          // Show error message if the ingredient already exists and it's a manual addition
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Ingredient "$ingredient" already exists in your shopping list.'),
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          // Increment the quantity if the ingredient already exists and it's not a manual addition
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
        // Add a new document if the ingredient does not exist
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
  Stream<QuerySnapshot> _shoppingListStream = FirebaseFirestore.instance.collection('users/${FirebaseAuth.instance.currentUser!.uid}/shopping_list').snapshots();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _shoppingListStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        final List<QueryDocumentSnapshot> documents = snapshot.data!.docs;
        if (documents.isEmpty) {
          return Center(
            child: Text('Your shopping list is empty.'),
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
              child: ListTile(
                title: Text(name),
                subtitle: Text('Quantity: $quantity'),
                leading: Checkbox(
                  value: data['bought'] ?? false,
                  onChanged: (bool? value) async {
                    await FirebaseFirestore.instance.collection('users/${FirebaseAuth.instance.currentUser!.uid}/shopping_list').doc(doc.id).update({
                      'bought': value,
                    });
                    if (value == true) {
                      await FirebaseFirestore.instance.collection('users/${FirebaseAuth.instance.currentUser!.uid}/history').add({
                        'name': name,
                        'quantity': quantity,
                        'addedAt': FieldValue.serverTimestamp(),
                      });
                      await FirebaseFirestore.instance.collection('users/${FirebaseAuth.instance.currentUser!.uid}/shopping_list').doc(doc.id).delete();
                    }
                    setState(() {}); // Refresh the list
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
                      icon: Icon(Icons.remove),
                      onPressed: () async {
                        if (quantity > 1) {
                          await FirebaseFirestore.instance.collection('users/${FirebaseAuth.instance.currentUser!.uid}/shopping_list').doc(doc.id).update({
                            'quantity': FieldValue.increment(-1),
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Decremented "$name" quantity in your shopping list.'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        } else {
                          await FirebaseFirestore.instance.collection('users/${FirebaseAuth.instance.currentUser!.uid}/shopping_list').doc(doc.id).delete();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Removed "$name" from your shopping list.'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        }
                        setState(() {}); // Refresh the list
                      },
                    ),
                    IconButton(
                      icon: Icon(Icons.add),
                      onPressed: () async {
                        await FirebaseFirestore.instance.collection('users/${FirebaseAuth.instance.currentUser!.uid}/shopping_list').doc(doc.id).update({
                          'quantity': FieldValue.increment(1),
                        });
                        setState(() {}); // Refresh the list
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
      : _historyStream = FirebaseFirestore.instance.collection('users/${FirebaseAuth.instance.currentUser!.uid}/history').snapshots();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: _historyStream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }
        final List<QueryDocumentSnapshot> documents = snapshot.data!.docs;
        if (documents.isEmpty) {
          return Center(
            child: Text('Your history is empty.'),
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
              child: ListTile(
                title: Text(name),
                subtitle: Text('Quantity: $quantity'),
                leading: Icon(Icons.history, color: Theme.of(context).iconTheme.color),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.add),
                      onPressed: () async {
                        final user = FirebaseAuth.instance.currentUser;
                        if (user == null) return;
                        final collectionRef = FirebaseFirestore.instance.collection('users/${user.uid}/shopping_list');
                        final querySnapshot = await collectionRef.where('name', isEqualTo: name).get();
                        if (querySnapshot.docs.isNotEmpty) {
                          // Increment the quantity if the ingredient already exists
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
                          // Add a new document if the ingredient does not exist
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
                      icon: Icon(Icons.delete),
                      onPressed: () async {
                        await FirebaseFirestore.instance.collection('users/${FirebaseAuth.instance.currentUser!.uid}/history').doc(doc.id).delete();
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