import 'package:flutter/material.dart';

class ErrorRetryWidget extends StatelessWidget {
  final String error;
  final VoidCallback? onRetry;
  final bool canRetry;

  const ErrorRetryWidget({
    super.key,
    required this.error,
    this.onRetry,
    this.canRetry = true,
  });

  IconData _getErrorIcon(String error) {
    final errorLower = error.toLowerCase();
    
    if (errorLower.contains('network') || 
        errorLower.contains('connection') || 
        errorLower.contains('timeout')) {
      return Icons.wifi_off;
    } else if (errorLower.contains('permission') || 
               errorLower.contains('access')) {
      return Icons.lock_outline;
    } else if (errorLower.contains('image') || 
               errorLower.contains('format') || 
               errorLower.contains('quality')) {
      return Icons.image_not_supported;
    } else if (errorLower.contains('api') || 
               errorLower.contains('key') || 
               errorLower.contains('auth')) {
      return Icons.key_off;
    } else if (errorLower.contains('rate') || 
               errorLower.contains('limit') || 
               errorLower.contains('quota')) {
      return Icons.hourglass_disabled;
    } else {
      return Icons.error_outline;
    }
  }

  Color _getErrorColor(String error) {
    final errorLower = error.toLowerCase();
    
    if (errorLower.contains('network') || 
        errorLower.contains('connection') || 
        errorLower.contains('timeout')) {
      return Colors.orange;
    } else if (errorLower.contains('rate') || 
               errorLower.contains('limit') || 
               errorLower.contains('quota')) {
      return Colors.amber;
    } else {
      return Colors.red;
    }
  }

  String _getErrorTitle(String error) {
    final errorLower = error.toLowerCase();
    
    if (errorLower.contains('rate') || 
        errorLower.contains('limit') || 
        errorLower.contains('quota')) {
      return 'Rate Limit Exceeded';
    } else if (errorLower.contains('network') || 
        errorLower.contains('connection')) {
      return 'Connection Error';
    } else if (errorLower.contains('timeout')) {
      return 'Request Timeout';
    } else if (errorLower.contains('permission') || 
               errorLower.contains('access')) {
      return 'Permission Error';
    } else if (errorLower.contains('image') || 
               errorLower.contains('format') || 
               errorLower.contains('quality')) {
      return 'Image Error';
    } else if (errorLower.contains('api') || 
               errorLower.contains('key') || 
               errorLower.contains('auth')) {
      return 'Authentication Error';
    } else {
      return 'Recognition Error';
    }
  }

  String _getErrorSuggestion(String error) {
    final errorLower = error.toLowerCase();
    
    if (errorLower.contains('network') || 
        errorLower.contains('connection')) {
      return 'Check your internet connection and try again';
    } else if (errorLower.contains('timeout')) {
      return 'The request took too long. Please try again';
    } else if (errorLower.contains('image') || 
               errorLower.contains('format') || 
               errorLower.contains('quality')) {
      return 'Try taking a clearer photo with better lighting';
    } else if (errorLower.contains('rate') || 
               errorLower.contains('limit') || 
               errorLower.contains('quota')) {
      return 'You\'ve reached your usage limit. Try again later or upgrade your plan';
    } else if (errorLower.contains('api') || 
               errorLower.contains('key') || 
               errorLower.contains('auth')) {
      return 'There\'s an issue with the service. Please try again later';
    } else {
      return 'Something went wrong. Please try again';
    }
  }

  @override
  Widget build(BuildContext context) {
    final errorColor = _getErrorColor(error);
    final errorIcon = _getErrorIcon(error);
    final errorTitle = _getErrorTitle(error);
    final errorSuggestion = _getErrorSuggestion(error);
    
    return Card(
      color: errorColor.withValues(alpha: 0.05),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Error icon
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: errorColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                errorIcon,
                size: 48,
                color: errorColor,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Error title
            Text(
              errorTitle,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: errorColor,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 8),
            
            // Error message
            Text(
              error,
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 12),
            
            // Error suggestion
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Colors.blue[700],
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      errorSuggestion,
                      style: TextStyle(
                        color: Colors.blue[700],
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (canRetry && onRetry != null) ...[
                  ElevatedButton.icon(
                    onPressed: onRetry,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Try Again'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: errorColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Take New Photo'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Additional help
            TextButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Troubleshooting Tips'),
                    content: const SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('For better results:', style: TextStyle(fontWeight: FontWeight.bold)),
                          SizedBox(height: 8),
                          Text('• Ensure good lighting'),
                          Text('• Keep the camera steady'),
                          Text('• Focus on the food items'),
                          Text('• Avoid blurry or dark images'),
                          Text('• Make sure food is clearly visible'),
                          SizedBox(height: 12),
                          Text('Network issues:', style: TextStyle(fontWeight: FontWeight.bold)),
                          SizedBox(height: 8),
                          Text('• Check your internet connection'),
                          Text('• Try switching between WiFi and mobile data'),
                          Text('• Wait a moment and try again'),
                        ],
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Got it'),
                      ),
                    ],
                  ),
                );
              },
              child: const Text('Need help?'),
            ),
          ],
        ),
      ),
    );
  }
}