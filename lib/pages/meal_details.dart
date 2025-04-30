import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '/services/firestore_services.dart';
import '/theme_provider.dart';

class MealDetailsPage extends StatefulWidget {
  const MealDetailsPage({super.key});

  @override
  _MealDetailsPageState createState() => _MealDetailsPageState();
}

class _MealDetailsPageState extends State<MealDetailsPage> {
  final FirestoreServices _firestoreServices = FirestoreServices();
  final _formKey = GlobalKey<FormState>();

  late int _calories;
  late int _protein;
  late int _carbs;
  late int _fat;

  bool _isLoading = false;
  bool _hasPreferences = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    setState(() => _isLoading = true);

    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (doc.exists && doc.data()?['mealPlanPreferences'] != null) {
        final prefs = doc.data()?['mealPlanPreferences'] as Map<String, dynamic>;
        setState(() {
          _calories = (prefs['calories'] ?? 2000).toInt();
          _protein = (prefs['protein'] ?? 50).toInt();
          _carbs = (prefs['carbs'] ?? 130).toInt();
          _fat = (prefs['fat'] ?? 30).toInt();
          _hasPreferences = true;
        });
      } else {
        // Set default values if no preferences exist
        setState(() {
          _calories = 2000;
          _protein = 50;
          _carbs = 130;
          _fat = 30;
          _hasPreferences = false;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load preferences: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _savePreferences() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      await _firestoreServices.saveMealPlanPreferences(
        userId: userId,
        calories: _calories,
        protein: _protein,
        carbs: _carbs,
        fat: _fat,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preferences saved successfully!')),
      );

      setState(() => _hasPreferences = true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save preferences: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Meal Plan Preferences',
          style: TextStyle(
            color: Colors.white, // Force white text
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(
          color: Colors.white, // Force white back icon
        ),
        actionsIconTheme: const IconThemeData(
          color: Colors.white, // Force white action icons
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.fromRGBO(161, 63, 190, 1),
                Color.fromRGBO(120, 60, 219, 1),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading && !_hasPreferences
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Nutrition Goals',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              _buildNumberInput(
                context,
                label: 'Daily Calories (kcal)',
                value: _calories,
                min: 1000,
                max: 5000,
                step: 25,
                onChanged: (value) => setState(() => _calories = value),
              ),
              const SizedBox(height: 16),
              Text(
                'Macronutrients',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Set your minimum daily targets',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: isDarkMode
                      ? colorScheme.onSurface.withValues(alpha: (0.7))
                      : Colors.grey[600],
                ),
              ),
              const SizedBox(height: 16),
              _buildNumberInput(
                context,
                label: 'Protein (g)',
                value: _protein,
                min: 10,
                max: 300,
                step: 1,
                onChanged: (value) => setState(() => _protein = value),
              ),
              const SizedBox(height: 16),
              _buildNumberInput(
                context,
                label: 'Carbohydrates (g)',
                value: _carbs,
                min: 20,
                max: 500,
                step: 1,
                onChanged: (value) => setState(() => _carbs = value),
              ),
              const SizedBox(height: 16),
              _buildNumberInput(
                context,
                label: 'Fat (g)',
                value: _fat,
                min: 10,
                max: 200,
                step: 1,
                onChanged: (value) => setState(() => _fat = value),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    backgroundColor: const Color.fromRGBO(120, 60, 219, 1),
                  ),
                  onPressed: _savePreferences,
                  child: const Text(
                    'Save Preferences',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNumberInput(
      BuildContext context, {
        required String label,
        required int value,
        required int min,
        required int max,
        required int step,
        required Function(int) onChanged,
      }) {
    return TextFormField(
      controller: TextEditingController(text: value.toString()),
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.remove),
              onPressed: () {
                final newValue = value - step;
                if (newValue >= min) {
                  onChanged(newValue);
                  _formKey.currentState?.validate();
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                final newValue = value + step;
                if (newValue <= max) {
                  onChanged(newValue);
                  _formKey.currentState?.validate();
                }
              },
            ),
          ],
        ),
      ),
      keyboardType: TextInputType.number,
      validator: (value) {
        final intVal = int.tryParse(value ?? '');
        if (intVal == null || intVal < min || intVal > max) {
          return 'Must be between $min and $max';
        }
        return null;
      },
      onChanged: (value) {
        final intVal = int.tryParse(value);
        if (intVal != null && intVal >= min && intVal <= max) {
          onChanged(intVal);
        }
      },
    );
  }
}