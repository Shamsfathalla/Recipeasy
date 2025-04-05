// lib/pages/create_recipe_page.dart
import 'package:flutter/material.dart';
import 'package:recipeasy/models/recipe_model.dart';
import 'package:recipeasy/services/recipe_folder_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CreateRecipePage extends StatefulWidget {
  final Recipe? recipe; // Pass a recipe if editing an existing one
  const CreateRecipePage({super.key, this.recipe});

  @override
  _CreateRecipePageState createState() => _CreateRecipePageState();
}

class _CreateRecipePageState extends State<CreateRecipePage> {
  final RecipeFolderService _folderService = RecipeFolderService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final List<TextEditingController> _ingredientsControllers = [TextEditingController()];
  final List<TextEditingController> _instructionsControllers = [TextEditingController()];

  @override
  void initState() {
    super.initState();
    if (widget.recipe != null) {
      _nameController.text = widget.recipe!.title;
      _descriptionController.text = widget.recipe!.description;
      _ingredientsControllers.clear();
      _instructionsControllers.clear();
      widget.recipe!.ingredients.forEach((ingredient) {
        _ingredientsControllers.add(TextEditingController(text: ingredient));
      });
      widget.recipe!.instructions.forEach((instruction) {
        _instructionsControllers.add(TextEditingController(text: instruction));
      });
    } else {
      _ingredientsControllers.add(TextEditingController());
      _instructionsControllers.add(TextEditingController());
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _ingredientsControllers.forEach((controller) => controller.dispose());
    _instructionsControllers.forEach((controller) => controller.dispose());
    super.dispose();
  }

  void _addIngredientLine() {
    setState(() {
      _ingredientsControllers.add(TextEditingController());
    });
  }

  void _removeIngredientLine(int index) {
    setState(() {
      _ingredientsControllers.removeAt(index);
    });
  }

  void _addInstructionLine() {
    setState(() {
      _instructionsControllers.add(TextEditingController());
    });
  }

  void _removeInstructionLine(int index) {
    setState(() {
      _instructionsControllers.removeAt(index);
    });
  }

  void _saveRecipe() async {
    if (_formKey.currentState!.validate()) {
      try {
        final user = _auth.currentUser;
        if (user == null) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Please log in to create a recipe')));
          return;
        }

        final recipe = Recipe(
          id: widget.recipe?.id ?? '',
          title: _nameController.text,
          description: _descriptionController.text,
          ingredients: _ingredientsControllers.map((controller) => controller.text.trim()).where((e) => e.isNotEmpty).toList(),
          instructions: _instructionsControllers.map((controller) => controller.text.trim()).where((e) => e.isNotEmpty).toList(),
          userId: user.uid,
        );

        if (widget.recipe != null) {
          await _folderService.updateUserRecipe(recipe);
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Recipe updated successfully')));
        } else {
          await _folderService.createUserRecipe(recipe);
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Recipe created successfully')));
        }

        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.recipe != null ? 'Edit Recipe' : 'Create Recipe'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Recipe Name'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a recipe name';
                  }
                  return null;
                },
              ),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Ingredients', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ..._ingredientsControllers.asMap().entries.map((entry) {
                    int index = entry.key;
                    TextEditingController controller = entry.value;
                    return Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: controller,
                            decoration: InputDecoration(
                              labelText: 'Ingredient ${index + 1}',
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.remove),
                          onPressed: () => _removeIngredientLine(index),
                        ),
                      ],
                    );
                  }).toList(),
                  ElevatedButton(
                    onPressed: _addIngredientLine,
                    child: Text('Add Ingredient Line'),
                  ),
                ],
              ),
              SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Instructions', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ..._instructionsControllers.asMap().entries.map((entry) {
                    int index = entry.key;
                    TextEditingController controller = entry.value;
                    return Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: controller,
                            decoration: InputDecoration(
                              labelText: 'Instruction ${index + 1}',
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.remove),
                          onPressed: () => _removeInstructionLine(index),
                        ),
                      ],
                    );
                  }).toList(),
                  ElevatedButton(
                    onPressed: _addInstructionLine,
                    child: Text('Add Instruction Line'),
                  ),
                ],
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _saveRecipe,
                child: Text(widget.recipe != null ? 'Update Recipe' : 'Create Recipe'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}