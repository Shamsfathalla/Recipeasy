import 'package:flutter/material.dart';

class MyRecipesPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      initialIndex: 0, // Start with bookmarks selected
      child: Scaffold(
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(kToolbarHeight), // Reduce height to minimize gap
          child: AppBar(
            automaticallyImplyLeading: false, // Remove the back button
            backgroundColor: Colors.transparent, // Make the app bar transparent
            elevation: 0, // Remove the shadow
            bottom: TabBar(
              indicatorColor: Color.fromARGB(255, 110, 59, 226), // Selected tab color
              indicatorSize: TabBarIndicatorSize.label, // Adjust the indicator size
              tabs: [
                Tab(text: 'Bookmarks'),
                Tab(text: 'My Recipes'),
              ],
            ),
          ),
        ),
        body: TabBarView(
          children: [
            BookmarksPage(),
            MyRecipesPageContent(),
          ],
        ),
        floatingActionButton: Builder(
          builder: (context) {
            final tabController = DefaultTabController.of(context);
            return AnimatedBuilder(
              animation: tabController,
              builder: (context, child) {
                return FloatingActionButton(
                  backgroundColor: Color.fromARGB(255, 110, 59, 226),
                  onPressed: () {
                    if (tabController.index == 0) {
                      // Action for bookmarks
                    } else {
                      // Action for my recipes
                    }
                  },
                  child: IconTheme(
                    data: IconThemeData(color: Colors.white),
                    child: Icon(Icons.add),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class MyRecipesPageContent extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('My Recipes Page Content'),
    );
  }
}

class BookmarksPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text('Bookmarks Page Content'),
    );
  }
}