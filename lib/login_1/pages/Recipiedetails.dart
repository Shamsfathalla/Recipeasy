// // In recipe_detail_page.dart
// import 'package:flutter/material.dart';
// import 'Web.dart';  // Import the WebViewPage
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
//                       // Add save functionality
//                     },
//                     child: Text('Save Recipe'),
//                   ),
//                   SizedBox(height: 20),
//                   ElevatedButton(
//                     onPressed: () {
//                       if (recipe['url'] != null) {
//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                             builder: (context) => WebViewPage(url: recipe['url']),
//                           ),
//                         );
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