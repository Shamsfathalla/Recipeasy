import 'package:flutter/material.dart';

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
          // Add item functionality
        },
        child: Icon(Icons.add, color: Colors.white),
        backgroundColor: primaryColor,
      )
          : null,
    );
  }
}

class CurrentShopList extends StatefulWidget {
  @override
  _CurrentShopListState createState() => _CurrentShopListState();
}

class _CurrentShopListState extends State<CurrentShopList> {
  final List<Map<String, dynamic>> shopItems = [
    {'name': 'Flour', 'checked': false},
    {'name': 'Sugar', 'checked': false},
    {'name': 'Eggs', 'checked': false},
    {'name': 'Milk', 'checked': false},
    {'name': 'Butter', 'checked': false},
    {'name': 'Salt', 'checked': false},
    {'name': 'Pepper', 'checked': false},
    {'name': 'Olive Oil', 'checked': false},
    {'name': 'Tomatoes', 'checked': false},
    {'name': 'Onions', 'checked': false},
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsets.all(10.0),
      itemCount: shopItems.length,
      itemBuilder: (context, index) {
        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          elevation: 3.0,
          margin: EdgeInsets.symmetric(vertical: 6.0),
          child: ListTile(
            leading: Checkbox(
              value: shopItems[index]['checked'],
              onChanged: (bool? value) {
                setState(() {
                  shopItems[index]['checked'] = value!;
                });
              },
            ),
            title: Text(
              shopItems[index]['name'],
              style: TextStyle(
                decoration: shopItems[index]['checked']
                    ? TextDecoration.lineThrough
                    : TextDecoration.none,
              ),
            ),
            trailing: IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                setState(() {
                  shopItems.removeAt(index);
                });
              },
            ),
          ),
        );
      },
    );
  }
}

class HistoryShopList extends StatelessWidget {
  final List<String> historyItems = [
    'Flour', 'Sugar', 'Eggs', 'Milk', 'Butter',
    'Salt', 'Pepper', 'Olive Oil', 'Tomatoes', 'Onions'
  ];

  @override
  Widget build(BuildContext context) {
    final primaryColor = Color.fromRGBO(110, 59, 226, 1);

    return ListView.builder(
      padding: EdgeInsets.all(10.0),
      itemCount: historyItems.length,
      itemBuilder: (context, index) {
        return Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.0),
          ),
          elevation: 3.0,
          margin: EdgeInsets.symmetric(vertical: 6.0),
          child: ListTile(
            leading: Icon(
              Icons.history,
              color: Theme.of(context).iconTheme.color,
            ),
            title: Text(historyItems[index]),
            trailing: IconButton(
              icon: Icon(Icons.add, color: primaryColor),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Added ${historyItems[index]} to current list'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}