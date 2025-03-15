import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RecipesPage extends StatefulWidget {
  const RecipesPage({Key? key}) : super(key: key);

  @override
  _RecipesPageState createState() => _RecipesPageState();
}

class _RecipesPageState extends State<RecipesPage> {
  List<dynamic> _recipes = [];
  bool _isLoading = true;
  String _searchQuery = 'chicken';
  List<String> _selectedDiets = [];
  List<String> _selectedHealthLabels = [];
  List<String> _availableDiets = ['vegetarian', 'vegan', 'gluten-free'];
  List<String> _availableHealthLabels = ['dairy-free', 'low-sugar', 'paleo'];

  @override
  void initState() {
    super.initState();
    _fetchRecipes();
  }

  Future<void> _fetchRecipes() async {
    setState(() => _isLoading = true);

    const apiKey = '60d74e82c4msh16051f0d6442077p190945jsn8852c2b4f509';
    const apiHost = 'edamam-recipe-search.p.rapidapi.com';
    const apiUrl = '/api/recipes/v2';

    final params = {
      'type': 'public',
      'q': _searchQuery,
      if (_selectedDiets.isNotEmpty) 'diet': _selectedDiets.join(','),
      if (_selectedHealthLabels.isNotEmpty) 'health': _selectedHealthLabels.join(','),
    };

    final uri = Uri.https(apiHost, apiUrl, params);

    try {
      final response = await http.get(
        uri,
        headers: {
          'X-RapidAPI-Key': apiKey,
          'X-RapidAPI-Host': apiHost,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _recipes = data['hits'];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error: $e');
    }
  }

  void _showFilterModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateModal) => Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Dietary Preferences', style: TextStyle(fontSize: 18)),
              ..._availableDiets.map((diet) => CheckboxListTile(
                title: Text(diet),
                value: _selectedDiets.contains(diet),
                onChanged: (value) {
                  setStateModal(() {
                    if (value!) {
                      _selectedDiets.add(diet);
                    } else {
                      _selectedDiets.remove(diet);
                    }
                  });
                },
              )),

              SizedBox(height: 20),
              Text('Health Labels', style: TextStyle(fontSize: 18)),
              ..._availableHealthLabels.map((label) => CheckboxListTile(
                title: Text(label),
                value: _selectedHealthLabels.contains(label),
                onChanged: (value) {
                  setStateModal(() {
                    if (value!) {
                      _selectedHealthLabels.add(label);
                    } else {
                      _selectedHealthLabels.remove(label);
                    }
                  });
                },
              )),

              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _fetchRecipes();
                },
                child: Text('Apply Filters'),
              ),
              TextButton(
                onPressed: () {
                  setStateModal(() {
                    _selectedDiets.clear();
                    _selectedHealthLabels.clear();
                  });
                  Navigator.pop(context);
                  _fetchRecipes();
                },
                child: Text('Clear Filters'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Recipe Finder'),
        actions: [
          IconButton(
            icon: Icon(Icons.filter_list),
            onPressed: _showFilterModal,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Search recipes',
                suffixIcon: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: () {
                    _fetchRecipes();
                  },
                ),
              ),
              onChanged: (value) => _searchQuery = value,
            ),
          ),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : _recipes.isEmpty
                ? Center(child: Text('No recipes found'))
                : ListView.builder(
              itemCount: _recipes.length,
              itemBuilder: (context, index) {
                final recipe = _recipes[index]['recipe'];
                return Card(
                  margin: EdgeInsets.all(8),
                  child: Column(
                    children: [
                      Image.network(
                        recipe['image'],
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              recipe['label'],
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              '${recipe['calories'].toStringAsFixed(0)} kcal',
                              style: TextStyle(
                                color: Colors.grey[600],
                              ),
                            ),
                            SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: () {
                                // Add save functionality
                              },
                              child: Text('Save Recipe'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

//
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import 'dart:convert';
//
// class RecipesPage extends StatefulWidget {
//   const RecipesPage({Key? key}) : super(key: key);
//
//   @override
//   _RecipesPageState createState() => _RecipesPageState();
// }
//
// class _RecipesPageState extends State<RecipesPage> {
//   List<dynamic> _recipes = [];
//   bool _isLoading = true;
//   String _searchQuery = 'chicken';
//   List<String> _selectedDiets = [];
//   List<String> _selectedHealthLabels = [];
//   List<String> _availableDiets = ['vegetarian', 'vegan', 'gluten-free'];
//   List<String> _availableHealthLabels = ['dairy-free', 'low-sugar', 'paleo'];
//
//   @override
//   void initState() {
//     super.initState();
//     _fetchRecipes();
//   }
//
//   Future<void> _fetchRecipes() async {
//     setState(() => _isLoading = true);
//
//     const apiKey = '60d74e82c4msh16051f0d6442077p190945jsn8852c2b4f509';
//     const apiHost = 'edamam-recipe-search.p.rapidapi.com';
//     const apiUrl = '/api/recipes/v2';
//
//     final params = {
//       'type': 'public',
//       'q': _searchQuery,
//       if (_selectedDiets.isNotEmpty) 'diet': _selectedDiets.join(','),
//       if (_selectedHealthLabels.isNotEmpty) 'health': _selectedHealthLabels.join(','),
//     };
//
//     final uri = Uri.https(apiHost, apiUrl, params);
//
//     try {
//       final response = await http.get(
//         uri,
//         headers: {
//           'X-RapidAPI-Key': apiKey,
//           'X-RapidAPI-Host': apiHost,
//         },
//       );
//
//       if (response.statusCode == 200) {
//         final data = json.decode(response.body);
//         setState(() {
//           _recipes = data['hits'];
//           _isLoading = false;
//         });
//       }
//     } catch (e) {
//       setState(() => _isLoading = false);
//       print('Error: $e');
//     }
//   }
//
//   void _showFilterModal() {
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       builder: (context) => StatefulBuilder(
//         builder: (context, setStateModal) => Padding(
//           padding: const EdgeInsets.all(16.0),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Text('Dietary Preferences', style: TextStyle(fontSize: 18)),
//               ..._availableDiets.map((diet) => CheckboxListTile(
//                 title: Text(diet),
//                 value: _selectedDiets.contains(diet),
//                 onChanged: (value) {
//                   setStateModal(() {
//                     if (value!) {
//                       _selectedDiets.add(diet);
//                     } else {
//                       _selectedDiets.remove(diet);
//                     }
//                   });
//                 },
//               )),
//
//               SizedBox(height: 20),
//               Text('Health Labels', style: TextStyle(fontSize: 18)),
//               ..._availableHealthLabels.map((label) => CheckboxListTile(
//                 title: Text(label),
//                 value: _selectedHealthLabels.contains(label),
//                 onChanged: (value) {
//                   setStateModal(() {
//                     if (value!) {
//                       _selectedHealthLabels.add(label);
//                     } else {
//                       _selectedHealthLabels.remove(label);
//                     }
//                   });
//                 },
//               )),
//
//               ElevatedButton(
//                 onPressed: () {
//                   Navigator.pop(context);
//                   _fetchRecipes();
//                 },
//                 child: Text('Apply Filters'),
//               ),
//               TextButton(
//                 onPressed: () {
//                   setStateModal(() {
//                     _selectedDiets.clear();
//                     _selectedHealthLabels.clear();
//                   });
//                   Navigator.pop(context);
//                   _fetchRecipes();
//                 },
//                 child: Text('Clear Filters'),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Text('Recipe Finder'),
//         actions: [
//           IconButton(
//             icon: Icon(Icons.filter_list),
//             onPressed: _showFilterModal,
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           Padding(
//             padding: const EdgeInsets.all(8.0),
//             child: TextField(
//               decoration: InputDecoration(
//                 labelText: 'Search recipes',
//                 suffixIcon: IconButton(
//                   icon: Icon(Icons.search),
//                   onPressed: () {
//                     _fetchRecipes();
//                   },
//                 ),
//               ),
//               onChanged: (value) => _searchQuery = value,
//             ),
//           ),
//           Expanded(
//             child: _isLoading
//                 ? Center(child: CircularProgressIndicator())
//                 : _recipes.isEmpty
//                 ? Center(child: Text('No recipes found'))
//                 : ListView.builder(
//               itemCount: _recipes.length,
//               itemBuilder: (context, index) {
//                 final recipe = _recipes[index]['recipe'];
//                 return InkWell(
//                   onTap: () {
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (context) => RecipeDetailPage(recipe: recipe),
//                       ),
//                     );
//                   },
//                   child: Card(
//                     margin: EdgeInsets.all(8),
//                     child: Column(
//                       children: [
//                         Image.network(
//                           recipe['image'],
//                           height: 200,
//                           width: double.infinity,
//                           fit: BoxFit.cover,
//                         ),
//                         Padding(
//                           padding: const EdgeInsets.all(8.0),
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             children: [
//                               Text(
//                                 recipe['label'],
//                                 style: TextStyle(
//                                   fontSize: 18,
//                                   fontWeight: FontWeight.bold,
//                                 ),
//                               ),
//                               SizedBox(height: 8),
//                               Text(
//                                 '${recipe['calories'].toStringAsFixed(0)} kcal',
//                                 style: TextStyle(
//                                   color: Colors.grey[600],
//                                 ),
//                               ),
//                               SizedBox(height: 8),
//                               ElevatedButton(
//                                 onPressed: () {
//                                   // Add save functionality
//                                 },
//                                 child: Text('Save Recipe'),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 );
//               },
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// class RecipeDetailPage extends StatelessWidget {
//   final dynamic recipe;
//
//   const RecipeDetailPage({Key? key, required this.recipe}) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text(recipe['label'])),
//       body: SingleChildScrollView(
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Image.network(
//               recipe['image'],
//               height: 300,
//               width: double.infinity,
//               fit: BoxFit.cover,
//             ),
//             Padding(
//               padding: const EdgeInsets.all(16.0),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     'Ingredients:',
//                     style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//                   ),
//                   SizedBox(height: 10),
//                   ...recipe['ingredients'].map<Widget>((ingredient) =>
//                       Padding(
//                         padding: const EdgeInsets.symmetric(vertical: 4.0),
//                         child: Row(
//                           children: [
//                             Icon(Icons.circle, size: 8, color: Colors.grey),
//                             SizedBox(width: 8),
//                             Expanded(
//                               child: Text(
//                                 '${ingredient['text']}',
//                                 style: TextStyle(fontSize: 16),
//                               ),
//                             ),
//                           ],
//                         ),
//                       )
//                   ).toList(),
//                   SizedBox(height: 20),
//                   Text(
//                     'Calories: ${recipe['calories'].toStringAsFixed(0)} kcal',
//                     style: TextStyle(fontSize: 16, color: Colors.grey),
//                   ),
//                   SizedBox(height: 20),
//                   ElevatedButton(
//                     onPressed: () {
//                       // Implement save functionality
//                     },
//                     child: Text('Save Recipe'),
//                   ),
//                   SizedBox(height: 20),
//                   ElevatedButton(
//                     onPressed: () {
//                       // Open full recipe URL
//                       if (recipe['url'] != null) {
//                         // Navigator.push(
//                         //   context,
//                         //   MaterialPageRoute(
//                         //     builder: (context) => WebViewPage(url: recipe['url']),
//                         //   ),
//                         // );
//                       }
//                     },
//                     child: Text('View Full Recipe'),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
// class WebViewPage extends StatelessWidget {
//   final String url;
//
//   const WebViewPage({Key? key, required this.url}) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: Text('Full Recipe')),
//       body: WebView(
//         initialUrl: url,
//         javascriptMode: JavascriptMode.unrestricted,
//       ),
//     );
//   }
// }