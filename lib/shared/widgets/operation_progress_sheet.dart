import 'package:lod_board/core/theme/app_typography.dart';
import 'package:flutter/material.dart';

class _Outcome<T> {
  const _Outcome.success(this.value) : error = null, stack = null;
  const _Outcome.failure(this.error, this.stack) : value = null;
  final T? value;
  final Object? error;
  final StackTrace? stack;
}

/// Displays progress until the operation completes and returns its real result.
Future<T> showOperationProgress<T>(
  BuildContext context, {
  required String title,
  required String message,
  required String progressLabel,
  required IconData icon,
  required Widget summary,
  required Future<T> Function() operation,
}) async {
  final result = await showModalBottomSheet<_Outcome<T>>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    backgroundColor: Colors.transparent,
    builder: (_) => _OperationSheet<T>(
      title: title,
      message: message,
      progressLabel: progressLabel,
      icon: icon,
      summary: summary,
      operation: operation,
    ),
  );
  if (result == null) throw StateError('The operation was interrupted.');
  if (result.error != null) {
    Error.throwWithStackTrace(result.error!, result.stack!);
  }
  return result.value as T;
}

class _OperationSheet<T> extends StatefulWidget {
  const _OperationSheet({
    required this.title,
    required this.message,
    required this.progressLabel,
    required this.icon,
    required this.summary,
    required this.operation,
  });
  final String title, message, progressLabel;
  final IconData icon;
  final Widget summary;
  final Future<T> Function() operation;
  @override
  State<_OperationSheet<T>> createState() => _OperationSheetState<T>();
}

class _OperationSheetState<T> extends State<_OperationSheet<T>> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _run());
  }

  Future<void> _run() async {
    _Outcome<T> result;
    try {
      result = _Outcome.success(await widget.operation());
    } catch (error, stack) {
      result = _Outcome.failure(error, stack);
    }
    if (mounted) Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    child: Container(
      padding: EdgeInsets.fromLTRB(
        18,
        12,
        18,
        MediaQuery.viewPaddingOf(context).bottom + 16,
      ),
      decoration: const BoxDecoration(
        color: Color(0xfff4f7ff),
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 46,
              height: 5,
              decoration: BoxDecoration(
                color: const Color(0xffa9b8d6),
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: Color(0xffffe9df),
                shape: BoxShape.circle,
              ),
              child: Icon(
                widget.icon,
                color: const Color(0xffff6100),
                size: 39,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xff0b1735),
                fontSize: 25,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              widget.message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xff53607d),
                fontSize: AppTextStyles.bodySize,
              ),
            ),
            const SizedBox(height: 15),
            widget.summary,
            const SizedBox(height: 17),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: const LinearProgressIndicator(
                minHeight: 10,
                backgroundColor: Color(0xffdbe6fb),
                valueColor: AlwaysStoppedAnimation(Color(0xffff5a00)),
              ),
            ),
            const SizedBox(height: 7),
            Text(
              widget.progressLabel,
              style: const TextStyle(
                color: Color(0xff53607d),
                fontSize: AppTextStyles.labelSize,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 15),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              decoration: BoxDecoration(
                color: const Color(0xffdfeaff),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.info_outline, color: Color(0xff075ad8), size: 19),
                  SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      'Please keep this screen open.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xff18386a),
                        fontSize: AppTextStyles.captionSize,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
