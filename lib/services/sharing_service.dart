import 'package:share_plus/share_plus.dart';
import 'ai_recipe_service.dart';

/// Exception thrown when sharing operations fail
class SharingException implements Exception {
  final String message;
  final String? code;

  const SharingException(this.message, [this.code]);

  @override
  String toString() => 'SharingException: $message${code != null ? ' (Code: $code)' : ''}';
}

/// Supported sharing platforms
enum SharingPlatform {
  social,
  email,
  messaging,
  general,
}

/// Service interface for recipe sharing functionality
abstract class SharingServiceInterface {
  /// Share a recipe to the specified platform
  /// Throws [SharingException] if sharing fails
  Future<void> shareRecipe(Recipe recipe, SharingPlatform platform);

  /// Generate shareable text content for a recipe
  String generateShareableContent(Recipe recipe);

  /// Share recipe with an image (if available)
  /// Returns the path to the shared image or null if no image
  Future<String?> shareRecipeWithImage(Recipe recipe, SharingPlatform platform);

  /// Check if sharing is available on the current platform
  bool isSharingAvailable();
}

/// Implementation of recipe sharing service
class SharingService implements SharingServiceInterface {
  static const String _appName = 'Food Recognition App';
  static const String _appTagline = 'Discover recipes from your ingredients!';

  @override
  Future<void> shareRecipe(Recipe recipe, SharingPlatform platform) async {
    try {
      final content = generateShareableContent(recipe);
      
      switch (platform) {
        case SharingPlatform.social:
          await _shareToSocial(content, recipe);
          break;
        case SharingPlatform.email:
          await _shareToEmail(content, recipe);
          break;
        case SharingPlatform.messaging:
          await _shareToMessaging(content, recipe);
          break;
        case SharingPlatform.general:
          await _shareGeneral(content, recipe);
          break;
      }
    } catch (e) {
      throw SharingException('Failed to share recipe: ${e.toString()}');
    }
  }

  @override
  String generateShareableContent(Recipe recipe) {
    final buffer = StringBuffer();
    
    // Title and app branding
    buffer.writeln('🍽️ ${recipe.title}');
    buffer.writeln('');
    buffer.writeln('Found this amazing recipe using $_appName!');
    buffer.writeln('');
    
    // Basic info
    buffer.writeln('⏱️ Cooking Time: ${recipe.cookingTime} minutes');
    buffer.writeln('👥 Servings: ${recipe.servings}');
    buffer.writeln('📊 Difficulty: ${_formatDifficulty(recipe.difficulty)}');
    buffer.writeln('');
    
    // Nutrition highlights
    buffer.writeln('🥗 Nutrition (per serving):');
    buffer.writeln('• Calories: ${recipe.nutrition.calories}');
    buffer.writeln('• Protein: ${recipe.nutrition.protein}g');
    buffer.writeln('• Carbs: ${recipe.nutrition.carbohydrates}g');
    buffer.writeln('• Fat: ${recipe.nutrition.fat}g');
    buffer.writeln('');
    
    // Ingredients
    buffer.writeln('🛒 Ingredients:');
    for (int i = 0; i < recipe.ingredients.length; i++) {
      buffer.writeln('${i + 1}. ${recipe.ingredients[i]}');
    }
    buffer.writeln('');
    
    // Instructions (abbreviated for sharing)
    buffer.writeln('👨‍🍳 Instructions:');
    final maxInstructions = recipe.instructions.length > 5 ? 5 : recipe.instructions.length;
    for (int i = 0; i < maxInstructions; i++) {
      buffer.writeln('${i + 1}. ${recipe.instructions[i]}');
    }
    
    if (recipe.instructions.length > 5) {
      buffer.writeln('... and ${recipe.instructions.length - 5} more steps!');
    }
    buffer.writeln('');
    
    // Allergen warnings if any
    if (recipe.allergens.isNotEmpty) {
      buffer.writeln('⚠️ Contains: ${recipe.allergens.map((a) => a.name).join(', ')}');
      buffer.writeln('');
    }
    
    // App promotion
    buffer.writeln('$_appTagline');
    buffer.writeln('Get the app to discover more recipes from your ingredients!');
    
    return buffer.toString();
  }

  @override
  Future<String?> shareRecipeWithImage(Recipe recipe, SharingPlatform platform) async {
    try {
      final content = generateShareableContent(recipe);
      
      if (recipe.imageUrl != null && recipe.imageUrl!.isNotEmpty) {
        // If we have an image URL, we could download and share it
        // For now, we'll just share the text content
        await shareRecipe(recipe, platform);
        return recipe.imageUrl;
      } else {
        // No image available, share text only
        await shareRecipe(recipe, platform);
        return null;
      }
    } catch (e) {
      throw SharingException('Failed to share recipe with image: ${e.toString()}');
    }
  }

  @override
  bool isSharingAvailable() {
    // Share Plus is available on all supported platforms
    return true;
  }

  // Private helper methods for different sharing platforms
  Future<void> _shareToSocial(String content, Recipe recipe) async {
    final socialContent = _formatForSocial(content, recipe);
    await Share.share(
      socialContent,
      subject: '🍽️ ${recipe.title} - Recipe from $_appName',
    );
  }

  Future<void> _shareToEmail(String content, Recipe recipe) async {
    final emailContent = _formatForEmail(content, recipe);
    await Share.share(
      emailContent,
      subject: 'Recipe: ${recipe.title} from $_appName',
    );
  }

  Future<void> _shareToMessaging(String content, Recipe recipe) async {
    final messagingContent = _formatForMessaging(content, recipe);
    await Share.share(messagingContent);
  }

  Future<void> _shareGeneral(String content, Recipe recipe) async {
    await Share.share(
      content,
      subject: '${recipe.title} - Recipe from $_appName',
    );
  }

  // Content formatting methods for different platforms
  String _formatForSocial(String content, Recipe recipe) {
    // Shorter format for social media with hashtags
    final buffer = StringBuffer();
    buffer.writeln('🍽️ ${recipe.title}');
    buffer.writeln('');
    buffer.writeln('⏱️ ${recipe.cookingTime}min | 👥 ${recipe.servings} servings | 📊 ${_formatDifficulty(recipe.difficulty)}');
    buffer.writeln('🥗 ${recipe.nutrition.calories} cal per serving');
    buffer.writeln('');
    buffer.writeln('Found this recipe using $_appName! 📱');
    buffer.writeln('');
    buffer.writeln('#recipe #cooking #foodie #ingredients #${recipe.difficulty}recipe');
    
    return buffer.toString();
  }

  String _formatForEmail(String content, Recipe recipe) {
    // More detailed format for email
    final buffer = StringBuffer();
    buffer.writeln('Subject: Recipe: ${recipe.title}');
    buffer.writeln('');
    buffer.writeln('Hi there!');
    buffer.writeln('');
    buffer.writeln('I found this amazing recipe using $_appName and thought you might enjoy it:');
    buffer.writeln('');
    buffer.writeln(content);
    buffer.writeln('');
    buffer.writeln('Happy cooking!');
    buffer.writeln('');
    buffer.writeln('---');
    buffer.writeln('Sent from $_appName');
    
    return buffer.toString();
  }

  String _formatForMessaging(String content, Recipe recipe) {
    // Concise format for messaging apps
    final buffer = StringBuffer();
    buffer.writeln('🍽️ ${recipe.title}');
    buffer.writeln('⏱️ ${recipe.cookingTime}min | 👥 ${recipe.servings} servings');
    buffer.writeln('🥗 ${recipe.nutrition.calories} cal');
    buffer.writeln('');
    buffer.writeln('Check out this recipe I found! 👨‍🍳');
    buffer.writeln('');
    buffer.writeln('Ingredients: ${recipe.ingredients.take(3).join(', ')}${recipe.ingredients.length > 3 ? '...' : ''}');
    buffer.writeln('');
    buffer.writeln('Found using $_appName 📱');
    
    return buffer.toString();
  }

  String _formatDifficulty(String difficulty) {
    switch (difficulty.toLowerCase()) {
      case 'easy':
        return '🟢 Easy';
      case 'medium':
        return '🟡 Medium';
      case 'hard':
        return '🔴 Hard';
      default:
        return difficulty;
    }
  }
}

/// Factory for creating sharing service instances
class SharingServiceFactory {
  static SharingServiceInterface create() {
    return SharingService();
  }
}