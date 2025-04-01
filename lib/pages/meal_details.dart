import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '/theme_provider.dart';
import '/services/firestore_services.dart';

class MealDetailsPage extends StatefulWidget {
  final Map<String, dynamic> initialPreferences;
  final Function(Map<String, dynamic>) onSave;
  final String userId;

  const MealDetailsPage({
    Key? key,
    required this.initialPreferences,
    required this.onSave,
    required this.userId,
  }) : super(key: key);

  @override
  _MealDetailsPageState createState() => _MealDetailsPageState();
}

class _MealDetailsPageState extends State<MealDetailsPage> {
  late String _timeFrame;
  late String _diet;
  late int _targetCalories;
  late int _minProtein;
  late int _minCarbs;
  late int _minFat;
  final TextEditingController _includeController = TextEditingController();
  final TextEditingController _excludeController = TextEditingController();
  bool _isSaving = false;
  bool _isLoading = true;

  final List<String> _dietOptions = [
    'None',
    'Vegetarian',
    'Vegan',
    'Gluten Free',
    'Ketogenic',
    'Mediterranean',
    'Paleo',
    'Pescetarian',
  ];

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      if (widget.userId.isNotEmpty) {
        final prefs = await FirestoreServices().getMealPreferences(widget.userId);
        if (prefs.isNotEmpty) {
          setState(() {
            _timeFrame = prefs['timeFrame'] ?? 'day';
            _diet = prefs['diet'] ?? 'None';
            _targetCalories = prefs['targetCalories'] ?? 2000;
            _minProtein = prefs['minProtein'] ?? 50;
            _minCarbs = prefs['minCarbs'] ?? 130;
            _minFat = prefs['minFat'] ?? 30;
            _includeController.text = prefs['include'] ?? '';
            _excludeController.text = prefs['exclude'] ?? '';
          });
        } else {
          _initializeWithDefaultValues();
        }
      }
    } catch (e) {
      debugPrint('Error loading preferences: $e');
      _initializeWithDefaultValues();
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _initializeWithDefaultValues() {
    setState(() {
      _timeFrame = widget.initialPreferences['timeFrame'] ?? 'day';
      _diet = widget.initialPreferences['diet'] ?? 'None';
      _targetCalories = widget.initialPreferences['targetCalories'] ?? 2000;
      _minProtein = widget.initialPreferences['minProtein'] ?? 50;
      _minCarbs = widget.initialPreferences['minCarbs'] ?? 130;
      _minFat = widget.initialPreferences['minFat'] ?? 30;
      _includeController.text = widget.initialPreferences['include'] ?? '';
      _excludeController.text = widget.initialPreferences['exclude'] ?? '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final colorScheme = Theme.of(context).colorScheme;

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Loading Preferences...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Meal Plan Preferences'),
        actions: [
          _isSaving
              ? const Padding(
            padding: EdgeInsets.all(16.0),
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          )
              : IconButton(
            icon: const Icon(Icons.save),
            onPressed: _savePreferences,
            tooltip: 'Save Preferences',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTimeFrameSection(isDarkMode, colorScheme),
            const SizedBox(height: 20),
            _buildDietSection(isDarkMode, colorScheme),
            const SizedBox(height: 20),
            _buildCalorieSection(isDarkMode, colorScheme),
            const SizedBox(height: 20),
            _buildMacroSection(isDarkMode, colorScheme),
            const SizedBox(height: 20),
            _buildIngredientSection(isDarkMode, colorScheme),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeFrameSection(bool isDarkMode, ColorScheme colorScheme) {
    return Card(
      elevation: 3,
      color: isDarkMode ? colorScheme.surface : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Plan Duration',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? colorScheme.onSurface : Colors.black,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8.0,
              children: [
                _buildTimeFrameChip('Daily', 'day', isDarkMode, colorScheme),
                _buildTimeFrameChip('Weekly', 'week', isDarkMode, colorScheme),
                _buildTimeFrameChip('Monthly', 'month', isDarkMode, colorScheme),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeFrameChip(String label, String value, bool isDarkMode, ColorScheme colorScheme) {
    return ChoiceChip(
      label: Text(label),
      selected: _timeFrame == value,
      onSelected: (selected) {
        setState(() {
          _timeFrame = value;
        });
      },
      selectedColor: colorScheme.primary,
      backgroundColor: isDarkMode ? colorScheme.surfaceVariant : Colors.grey[200],
      labelStyle: TextStyle(
        color: _timeFrame == value ? Colors.white : colorScheme.onSurface,
      ),
    );
  }

  Widget _buildDietSection(bool isDarkMode, ColorScheme colorScheme) {
    return Card(
      elevation: 3,
      color: isDarkMode ? colorScheme.surface : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dietary Preferences',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? colorScheme.onSurface : Colors.black,
              ),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _diet,
              isExpanded: true,
              dropdownColor: isDarkMode ? colorScheme.surface : Colors.white,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                filled: true,
                fillColor: isDarkMode ? colorScheme.surfaceVariant : Colors.grey[100],
              ),
              style: TextStyle(
                color: isDarkMode ? colorScheme.onSurface : Colors.black,
              ),
              items: _dietOptions.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(
                    value,
                    style: TextStyle(
                      color: isDarkMode ? colorScheme.onSurface : Colors.black,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _diet = value!;
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalorieSection(bool isDarkMode, ColorScheme colorScheme) {
    return Card(
      elevation: 3,
      color: isDarkMode ? colorScheme.surface : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Calorie Target',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? colorScheme.onSurface : Colors.black,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: colorScheme.primary,
                      inactiveTrackColor: isDarkMode ? colorScheme.surfaceVariant : Colors.grey[300],
                      thumbColor: colorScheme.primary,
                      valueIndicatorColor: colorScheme.primary,
                      activeTickMarkColor: Colors.transparent,
                      inactiveTickMarkColor: Colors.transparent,
                    ),
                    child: Slider(
                      value: _targetCalories.toDouble(),
                      min: 1200,
                      max: 4000,
                      divisions: 28,
                      label: '$_targetCalories kcal',
                      onChanged: (value) {
                        setState(() {
                          _targetCalories = value.round();
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '$_targetCalories kcal',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isDarkMode ? colorScheme.onSurface : Colors.black,
                  ),
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '1200 kcal',
                  style: TextStyle(
                    color: isDarkMode ? colorScheme.onSurface.withOpacity(0.7) : Colors.grey[700],
                  ),
                ),
                Text(
                  '4000 kcal',
                  style: TextStyle(
                    color: isDarkMode ? colorScheme.onSurface.withOpacity(0.7) : Colors.grey[700],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMacroSection(bool isDarkMode, ColorScheme colorScheme) {
    return Card(
      elevation: 3,
      color: isDarkMode ? colorScheme.surface : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Macronutrient Targets',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? colorScheme.onSurface : Colors.black,
              ),
            ),
            const SizedBox(height: 15),
            _buildMacroSlider('Protein (g)', _minProtein, 0, 200, isDarkMode, colorScheme),
            const SizedBox(height: 15),
            _buildMacroSlider('Carbs (g)', _minCarbs, 0, 300, isDarkMode, colorScheme),
            const SizedBox(height: 15),
            _buildMacroSlider('Fat (g)', _minFat, 0, 150, isDarkMode, colorScheme),
          ],
        ),
      ),
    );
  }

  Widget _buildMacroSlider(
      String label,
      int value,
      int min,
      int max,
      bool isDarkMode,
      ColorScheme colorScheme,
      ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            color: isDarkMode ? colorScheme.onSurface : Colors.black,
          ),
        ),
        const SizedBox(height: 5),
        Row(
          children: [
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: colorScheme.primary,
                  inactiveTrackColor: isDarkMode ? colorScheme.surfaceVariant : Colors.grey[300],
                  thumbColor: colorScheme.primary,
                  valueIndicatorColor: colorScheme.primary,
                  activeTickMarkColor: Colors.transparent,
                  inactiveTickMarkColor: Colors.transparent,
                ),
                child: Slider(
                  value: value.toDouble(),
                  min: min.toDouble(),
                  max: max.toDouble(),
                  divisions: max ~/ 10,
                  label: '$value g',
                  onChanged: (value) {
                    setState(() {
                      if (label.contains('Protein')) _minProtein = value.round();
                      if (label.contains('Carbs')) _minCarbs = value.round();
                      if (label.contains('Fat')) _minFat = value.round();
                    });
                  },
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              '$value g',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isDarkMode ? colorScheme.onSurface : Colors.black,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildIngredientSection(bool isDarkMode, ColorScheme colorScheme) {
    return Card(
      elevation: 3,
      color: isDarkMode ? colorScheme.surface : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ingredient Preferences',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? colorScheme.onSurface : Colors.black,
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _includeController,
              style: TextStyle(
                color: isDarkMode ? colorScheme.onSurface : Colors.black,
              ),
              decoration: InputDecoration(
                labelText: 'Must Include Ingredients',
                labelStyle: TextStyle(
                  color: isDarkMode ? colorScheme.onSurface.withOpacity(0.7) : Colors.grey[700],
                ),
                hintText: 'e.g., chicken, broccoli, quinoa',
                hintStyle: TextStyle(
                  color: isDarkMode ? colorScheme.onSurface.withOpacity(0.5) : Colors.grey[500],
                ),
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: isDarkMode ? colorScheme.surfaceVariant : Colors.grey[100],
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _excludeController,
              style: TextStyle(
                color: isDarkMode ? colorScheme.onSurface : Colors.black,
              ),
              decoration: InputDecoration(
                labelText: 'Exclude Ingredients',
                labelStyle: TextStyle(
                  color: isDarkMode ? colorScheme.onSurface.withOpacity(0.7) : Colors.grey[700],
                ),
                hintText: 'e.g., nuts, shellfish, dairy',
                hintStyle: TextStyle(
                  color: isDarkMode ? colorScheme.onSurface.withOpacity(0.5) : Colors.grey[500],
                ),
                border: const OutlineInputBorder(),
                filled: true,
                fillColor: isDarkMode ? colorScheme.surfaceVariant : Colors.grey[100],
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 8),
            Text(
              'Separate ingredients with commas',
              style: TextStyle(
                fontSize: 12,
                color: isDarkMode ? colorScheme.onSurface.withOpacity(0.5) : Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _savePreferences() async {
    if (widget.userId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not authenticated')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final preferences = {
      'timeFrame': _timeFrame,
      'diet': _diet,
      'targetCalories': _targetCalories,
      'minProtein': _minProtein,
      'minCarbs': _minCarbs,
      'minFat': _minFat,
      'include': _includeController.text.trim(),
      'exclude': _excludeController.text.trim(),
      'lastUpdated': DateTime.now(),
    };

    try {
      await FirestoreServices().saveMealPreferences(
        userId: widget.userId,
        preferences: preferences,
      );

      widget.onSave(preferences);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preferences saved successfully!'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      debugPrint('Error saving preferences: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save: ${e.toString()}'),
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _includeController.dispose();
    _excludeController.dispose();
    super.dispose();
  }
}