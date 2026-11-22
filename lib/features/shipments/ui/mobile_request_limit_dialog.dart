import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

Future<void> showMobileRequestLimitDialog(BuildContext context) {
  return showDialog<void>(
    context: context,
    barrierColor: const Color(0xA5101728),
    builder: (context) => const _MobileRequestLimitDialog(),
  );
}

class _MobileRequestLimitDialog extends StatelessWidget {
  const _MobileRequestLimitDialog();

  @override
  Widget build(BuildContext context) {
    final availableHeight = MediaQuery.sizeOf(context).height;
    final compact = availableHeight < 650;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 26, vertical: 24),
      backgroundColor: const Color(0xFFFBFBFD),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 390),
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(22, compact ? 12 : 16, 22, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: IconButton.filledTonal(
                  tooltip: 'Close',
                  onPressed: () => Navigator.of(context).pop(),
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFFEDEEF3),
                    foregroundColor: const Color(0xFF444B5C),
                  ),
                  icon: const Icon(Icons.close_rounded),
                ),
              ),
              _LimitIllustration(height: compact ? 118 : 150),
              SizedBox(height: compact ? 14 : 20),
              Text(
                'Mobile Request Limit Reached',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: AppColors.navy,
                  fontWeight: FontWeight.w800,
                  fontSize: 21,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'You have reached the mobile request limit of 3. Please use the '
                'LODBOD web platform to create additional requests.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF555C6D),
                  fontSize: 15,
                  height: 1.5,
                ),
              ),
              SizedBox(height: compact ? 18 : 24),
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      onPressed: () {
                        final messenger = ScaffoldMessenger.of(context);
                        Navigator.of(context).pop();
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text(
                              'The web platform link is not configured yet.',
                            ),
                          ),
                        );
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFFF4B0D),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 54),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: const Icon(Icons.language, size: 19),
                      label: const FittedBox(child: Text('Open Web Platform')),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF353C4B),
                        minimumSize: const Size(0, 54),
                        side: const BorderSide(color: Color(0xFFDCDDE5)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text('Close'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LimitIllustration extends StatelessWidget {
  const _LimitIllustration({required this.height});
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 240,
      height: height,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 215,
            height: height * .75,
            decoration: const BoxDecoration(
              color: Color(0xFFFFE8E1),
              shape: BoxShape.circle,
            ),
          ),
          Transform.rotate(
            angle: -math.pi / 18,
            child: Container(
              width: 78,
              height: height * .92,
              decoration: BoxDecoration(
                color: const Color(0xFFFAFAFF),
                border: Border.all(color: const Color(0xFF393960), width: 5),
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x22393960),
                    blurRadius: 12,
                    offset: Offset(0, 7),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Container(
                    width: 23,
                    height: 5,
                    decoration: BoxDecoration(
                      color: const Color(0xFF393960),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const Icon(
                    Icons.local_shipping_rounded,
                    color: Color(0xFFFF7046),
                    size: 27,
                  ),
                  for (final width in [48.0, 51.0, 34.0])
                    Container(
                      width: width,
                      height: 5,
                      decoration: BoxDecoration(
                        color: const Color(0xFFD7D7F4),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  const SizedBox(height: 3),
                ],
              ),
            ),
          ),
          Positioned(
            right: 6,
            bottom: height * .17,
            child: Transform.rotate(
              angle: -math.pi / 20,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF4EF),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: const Color(0xFFFFC7B6), width: 2),
                  boxShadow: const [
                    BoxShadow(color: Color(0x22EA5C2D), blurRadius: 10),
                  ],
                ),
                child: const Text(
                  '3 / 3',
                  style: TextStyle(
                    color: Color(0xFFE53D0B),
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
