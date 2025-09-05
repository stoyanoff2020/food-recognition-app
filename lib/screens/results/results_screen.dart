import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_state_provider.dart';
import '../../providers/ai_vision_provider.dart';
import '../../services/ai_vision_service.dart';
import '../../widgets/results/ingredient_list_widget.dart';
import '../../widgets/results/custom_ingredient_manager_widget.dart';
import '../../widgets/results/error_retry_widget.dart';

class ResultsScreen extends StatefulWidget {
  final String? imagePath;
  final dynamic recognitionResult;

  const ResultsScreen({
    super.key,
    this.imagePath,
    this.recognitionResult,
  });

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {

  @override
  void initState() {
    super.initState();
    
    // If we have a recognition result passed in, use it
    if (widget.recognitionResult != null && widget.recognitionResult is FoodRecognitionResult) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final appState = context.read<AppStateProvider>();
        appState.setRecognitionResults(widget.recognitionResult as FoodRecognitionResult);
      });
    }
  }



  Future<void> _retryRecognition() async {
    if (widget.imagePath == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No image available to retry recognition'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    final aiVisionProvider = context.read<AIVisionProvider>();
    await aiVisionProvider.analyzeImage(widget.imagePath!);
    
    // Update app state with new results
    if (mounted) {
      final appState = context.read<AppStateProvider>();
      if (aiVisionProvider.hasResults) {
        appState.setRecognitionResults(aiVisionProvider.lastResult);
      } else if (aiVisionProvider.error != null) {
        appState.setRecognitionError(aiVisionProvider.error);
      }
    }
  }

  void _navigateToRecipes() {
    final appState = context.read<AppStateProvider>();
    final recognitionResults = appState.state.recognition.results;
    final customIngredients = appState.state.recipes.customIngredients;
    
    // Combine detected ingredients with custom ingredients
    final allIngredients = <String>[];
    
    if (recognitionResults != null && recognitionResults.ingredients.isNotEmpty) {
      allIngredients.addAll(recognitionResults.ingredients.map((i) => i.name));
    }
    
    allIngredients.addAll(customIngredients);
    
    if (allIngredients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add some ingredients before getting recipes'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    // Navigate to recipe suggestions (this will be implemented in a later task)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Getting recipes for ${allIngredients.length} ingredients...'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recognition Results'),
        elevation: 0,
        actions: [
          if (widget.imagePath != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _retryRecognition,
              tooltip: 'Retry Recognition',
            ),
        ],
      ),
      body: Consumer<AppStateProvider>(
        builder: (context, appState, child) {
          final recognitionState = appState.state.recognition;
          final recipeState = appState.state.recipes;
          
          return Column(
            children: [
              // Image preview section
              if (widget.imagePath != null)
                Container(
                  height: 200,
                  width: double.infinity,
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      File(widget.imagePath!),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey[200],
                          child: const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.error_outline, size: 48, color: Colors.grey),
                                SizedBox(height: 8),
                                Text('Failed to load image', style: TextStyle(color: Colors.grey)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Recognition results section
                      if (recognitionState.isProcessing)
                        const Center(
                          child: Column(
                            children: [
                              CircularProgressIndicator(),
                              SizedBox(height: 16),
                              Text('Analyzing your image...'),
                            ],
                          ),
                        )
                      else if (recognitionState.error != null)
                        ErrorRetryWidget(
                          error: recognitionState.error!,
                          onRetry: _retryRecognition,
                          canRetry: widget.imagePath != null,
                        )
                      else if (recognitionState.results != null)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Detected ingredients section
                            Text(
                              'Detected Ingredients',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            
                            if (recognitionState.results!.ingredients.isEmpty)
                              Card(
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    children: [
                                      const Icon(Icons.search_off, size: 48, color: Colors.grey),
                                      const SizedBox(height: 8),
                                      const Text(
                                        'No ingredients detected',
                                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Try taking another photo or add ingredients manually',
                                        style: TextStyle(color: Colors.grey[600]),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            else
                              IngredientListWidget(
                                ingredients: recognitionState.results!.ingredients,
                                confidence: recognitionState.results!.confidence,
                              ),
                            
                            const SizedBox(height: 24),
                            
                            // Enhanced custom ingredients section
                            CustomIngredientManagerWidget(
                              currentIngredients: recipeState.customIngredients,
                              onIngredientAdded: (ingredient) {
                                context.read<AppStateProvider>().addCustomIngredient(ingredient);
                              },
                              onIngredientRemoved: (ingredient) {
                                context.read<AppStateProvider>().removeCustomIngredient(ingredient);
                              },
                              showSuggestions: true,
                              showCategories: true,
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              
              // Bottom action bar
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SafeArea(
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _navigateToRecipes,
                      icon: const Icon(Icons.restaurant_menu),
                      label: const Text('Get Recipe Suggestions'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}