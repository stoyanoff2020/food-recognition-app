import 'package:flutter/material.dart';
import '../../services/ai_vision_service.dart';

class IngredientListWidget extends StatelessWidget {
  final List<Ingredient> ingredients;
  final double confidence;

  const IngredientListWidget({
    super.key,
    required this.ingredients,
    required this.confidence,
  });

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.8) {
      return Colors.green;
    } else if (confidence >= 0.6) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }

  String _getConfidenceLabel(double confidence) {
    if (confidence >= 0.8) {
      return 'High';
    } else if (confidence >= 0.6) {
      return 'Medium';
    } else {
      return 'Low';
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'protein':
        return Icons.egg_outlined;
      case 'vegetable':
        return Icons.eco;
      case 'fruit':
        return Icons.apple;
      case 'grain':
        return Icons.grain;
      case 'dairy':
        return Icons.local_drink;
      case 'spice':
      case 'herb':
        return Icons.grass;
      case 'sauce':
        return Icons.water_drop;
      default:
        return Icons.restaurant;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Overall confidence indicator
        Card(
          color: _getConfidenceColor(confidence).withValues(alpha: 0.1),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(
                  Icons.analytics_outlined,
                  color: _getConfidenceColor(confidence),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Overall Confidence: ${_getConfidenceLabel(confidence)}',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        '${(confidence * 100).toStringAsFixed(1)}% accuracy',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getConfidenceColor(confidence),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${(confidence * 100).toInt()}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Ingredients list
        Card(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.list_alt, color: Colors.blue),
                    const SizedBox(width: 8),
                    Text(
                      '${ingredients.length} ingredient${ingredients.length != 1 ? 's' : ''} detected',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              
              const Divider(height: 1),
              
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: ingredients.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final ingredient = ingredients[index];
                  final confidenceColor = _getConfidenceColor(ingredient.confidence);
                  
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: confidenceColor.withValues(alpha: 0.1),
                      child: Icon(
                        _getCategoryIcon(ingredient.category),
                        color: confidenceColor,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      ingredient.name,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    subtitle: Text(
                      ingredient.category.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: confidenceColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: confidenceColor.withValues(alpha: 0.3)),
                          ),
                          child: Text(
                            '${(ingredient.confidence * 100).toInt()}%',
                            style: TextStyle(
                              color: confidenceColor,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _getConfidenceLabel(ingredient.confidence),
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Confidence legend
        Card(
          color: Colors.grey[50],
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Confidence Levels',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildConfidenceLegendItem(
                      color: Colors.green,
                      label: 'High (80%+)',
                      description: 'Very confident',
                    ),
                    _buildConfidenceLegendItem(
                      color: Colors.orange,
                      label: 'Medium (60-79%)',
                      description: 'Moderately confident',
                    ),
                    _buildConfidenceLegendItem(
                      color: Colors.red,
                      label: 'Low (<60%)',
                      description: 'Less confident',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConfidenceLegendItem({
    required Color color,
    required String label,
    required String description,
  }) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            description,
            style: TextStyle(
              fontSize: 8,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}