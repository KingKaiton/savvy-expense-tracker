import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // Show spending limit notification
  void showSpendingLimitAlert(
    BuildContext context, {
    required String title,
    required String message,
    required bool isExceeded,
    VoidCallback? onDismissed,
  }) {
    // Haptic feedback for exceeded limits
    if (isExceeded) {
      HapticFeedback.heavyImpact();
    } else {
      HapticFeedback.mediumImpact();
    }

    final color = isExceeded ? Colors.red : Colors.orange;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                isExceeded ? Icons.warning : Icons.info_outline,
                color: color,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message,
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: color.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Icon(
                      isExceeded ? Icons.block : Icons.lightbulb_outline,
                      color: color,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isExceeded
                            ? 'Consider reviewing your spending habits or adjusting your budget.'
                            : 'Keep track of your remaining budget to avoid overspending.',
                        style: TextStyle(
                          fontSize: 14,
                          color: color.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onDismissed?.call();
              },
              child: const Text('Got it'),
            ),
            if (isExceeded)
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _showBudgetTips(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Budget Tips'),
              ),
          ],
        );
      },
    );
  }

  // Show budget tips dialog
  void _showBudgetTips(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.lightbulb, color: Colors.amber),
              SizedBox(width: 12),
              Text('Budget Tips'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTip('Track every expense', 'Record all purchases, no matter how small'),
                _buildTip('Use the 50/30/20 rule', '50% needs, 30% wants, 20% savings'),
                _buildTip('Review weekly', 'Check your spending patterns regularly'),
                _buildTip('Set realistic limits', 'Adjust your budget based on actual needs'),
                _buildTip('Plan for emergencies', 'Keep some buffer for unexpected expenses'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTip(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 6, right: 12),
            decoration: const BoxDecoration(
              color: Colors.amber,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Show spending limit snackbar
  void showSpendingLimitSnackBar(
    BuildContext context, {
    required String message,
    required bool isExceeded,
  }) {
    final color = isExceeded ? Colors.red : Colors.orange;
    
    if (isExceeded) {
      HapticFeedback.heavyImpact();
    } else {
      HapticFeedback.lightImpact();
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isExceeded ? Icons.warning : Icons.info_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        duration: Duration(seconds: isExceeded ? 6 : 4),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        action: SnackBarAction(
          label: 'View',
          textColor: Colors.white,
          onPressed: () {
            // Could navigate to budget settings or analytics
          },
        ),
      ),
    );
  }

  // Show achievement notification for staying within budget
  void showBudgetAchievement(BuildContext context, String message) {
    HapticFeedback.selectionClick();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(
              Icons.celebration,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}
