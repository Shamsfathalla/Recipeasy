import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      navigatorObservers: [
        FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance),
      ],
      home: const HomeScreen(),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Recipeasy")),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            FirebaseAnalytics analytics = FirebaseAnalytics.instance;
            await analytics.logEvent(
              name: 'test_event',
              parameters: <String, Object>{
                'string': 'test',
                'int': 42,
                'long': 12345678910,
                'double': 42.0,
              },
            );
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Event logged!')),
            );
          },
          child: const Text('Log Event'),
        ),
      ),
    );
  }
}