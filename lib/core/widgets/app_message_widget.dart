import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

enum MessageType { info, success, warning, error }

class AppMessageWidget extends StatelessWidget {
  final String message;
  final MessageType type;
  final VoidCallback? onDismiss;

  const AppMessageWidget({
    super.key,
    required this.message,
    this.type = MessageType.info,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getColor();
    final icon = _getIcon();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: color.withAlpha(230),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (onDismiss != null)
            GestureDetector(
              onTap: onDismiss,
              child: Icon(Icons.close, color: color, size: 18),
            ),
        ],
      ),
    );
  }

  Color _getColor() {
    switch (type) {
      case MessageType.success:
        return AppColors.success;
      case MessageType.warning:
        return AppColors.warning;
      case MessageType.error:
        return AppColors.error;
      case MessageType.info:
        return AppColors.info;
    }
  }

  IconData _getIcon() {
    switch (type) {
      case MessageType.success:
        return Icons.check_circle_outline;
      case MessageType.warning:
        return Icons.warning_amber_rounded;
      case MessageType.error:
        return Icons.error_outline;
      case MessageType.info:
        return Icons.info_outline;
    }
  }
}
