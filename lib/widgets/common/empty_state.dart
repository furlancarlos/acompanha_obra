// widgets/common/empty_state.dart
// Arquivo de definição da tela de empty state.
//============================================================================//

import 'package:flutter/material.dart';

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String? actionLabel;
  final VoidCallback? onActionPressed;

  const EmptyState({
    super.key,
    required this.icon,
    required this.message,
    this.actionLabel,
    this.onActionPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Column(
          children: [
            Icon(icon, size: 40, color: Colors.grey.shade400),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            if (actionLabel != null && onActionPressed != null) ...[
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: onActionPressed,
                icon: const Icon(Icons.add, size: 16),
                label: Text(actionLabel!),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1B3A5C),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  minimumSize: const Size(0, 0),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
