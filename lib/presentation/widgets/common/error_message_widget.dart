import 'package:flutter/material.dart';
import 'package:vms_app/core/constants/constants.dart';

/// 에러 메시지를 표시하는 공통 위젯
class ErrorMessageWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ErrorMessageWidget({
    super.key,  // Key? key 대신 super.key 사용
    required this.message,
    this.onRetry,
  });
  
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red[300],
          ),
          const SizedBox(height: DesignConstants.spacing16),
          Text(
            message,
            style: TextStyle(
              fontSize: DesignConstants.fontSizeM,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          if (onRetry != null) ...[
            const SizedBox(height: DesignConstants.spacing16),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('다시 시도'),
            ),
          ],
        ],
      ),
    );
  }
}
