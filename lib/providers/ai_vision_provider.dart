import 'package:flutter/material.dart';
import '../services/ai_vision_service.dart';

class AIVisionProvider extends ChangeNotifier {
  final AIVisionServiceInterface _aiVisionService;
  
  FoodRecognitionResult? _lastResult;
  bool _isAnalyzing = false;
  String? _error;

  AIVisionProvider({required AIVisionServiceInterface aiVisionService})
      : _aiVisionService = aiVisionService;

  // Getters
  FoodRecognitionResult? get lastResult => _lastResult;
  bool get isAnalyzing => _isAnalyzing;
  String? get error => _error;
  List<Ingredient> get ingredients => _lastResult?.ingredients ?? [];
  double get confidence => _lastResult?.confidence ?? 0.0;
  bool get hasResults => _lastResult != null && _lastResult!.isSuccess;

  // Methods
  Future<void> analyzeImage(String imageUri) async {
    _isAnalyzing = true;
    _error = null;
    _lastResult = null;
    notifyListeners();

    try {
      debugPrint('Starting food recognition analysis...');
      final result = await _aiVisionService.analyzeImage(imageUri);
      
      _lastResult = result;
      
      if (!result.isSuccess) {
        _error = result.errorMessage;
        debugPrint('Food recognition failed: ${result.errorMessage}');
      } else {
        debugPrint('Food recognition successful: ${result.ingredients.length} ingredients found');
      }
    } catch (e) {
      _error = 'An unexpected error occurred: $e';
      debugPrint('Food recognition error: $e');
    } finally {
      _isAnalyzing = false;
      notifyListeners();
    }
  }

  void clearResults() {
    _lastResult = null;
    _error = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _aiVisionService.dispose();
    super.dispose();
  }
}