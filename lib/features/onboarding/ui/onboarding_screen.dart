import 'package:flutter/material.dart';
import 'package:lod_board/core/theme/app_typography.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, this.onComplete});

  final VoidCallback? onComplete;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  static const _pages = [
    'assets/images/onboarding/post_load.png',
    'assets/images/onboarding/competitive_bids.png',
    'assets/images/onboarding/move_across_nepal.png',
  ];

  final PageController _pageController = PageController();
  int _currentPage = 0;

  bool get _isLastPage => _currentPage == _pages.length - 1;

  void _next() {
    if (_isLastPage) {
      widget.onComplete?.call();
      return;
    }

    _pageController.nextPage(
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  void _skip() => widget.onComplete?.call();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFF6F5FF),
      child: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemBuilder: (context, index) => Image.asset(
                  _pages[index],
                  fit: BoxFit.contain,
                  alignment: Alignment.topCenter,
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.pageHorizontal,
              AppSpacing.height(4),
              AppSpacing.pageHorizontal,
              AppSpacing.height(12),
            ),
            child: _OnboardingControls(
              currentPage: _currentPage,
              pageCount: _pages.length,
              isLastPage: _isLastPage,
              onSkip: _skip,
              onNext: _next,
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingControls extends StatelessWidget {
  const _OnboardingControls({
    required this.currentPage,
    required this.pageCount,
    required this.isLastPage,
    required this.onSkip,
    required this.onNext,
  });

  final int currentPage;
  final int pageCount;
  final bool isLastPage;
  final VoidCallback onSkip;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: onSkip,
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF354B79),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                minimumSize: const Size(44, 48),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                textStyle: TextStyle(
                  fontSize: AppTypography.size(15),
                  fontWeight: FontWeight.w500,
                ),
              ),
              child: const Text('Skip'),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(pageCount, (index) {
              final selected = index == currentPage;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 12,
                height: 12,
                margin: EdgeInsets.only(right: index == pageCount - 1 ? 0 : 8),
                decoration: BoxDecoration(
                  color: selected ? AppColors.orange : const Color(0xFFD2D2EA),
                  shape: BoxShape.circle,
                ),
              );
            }),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: _OnboardingActionButton(
              label: isLastPage ? 'Start' : 'Next',
              isLastPage: isLastPage,
              onPressed: onNext,
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingActionButton extends StatelessWidget {
  const _OnboardingActionButton({
    required this.label,
    required this.isLastPage,
    required this.onPressed,
  });

  final String label;
  final bool isLastPage;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 120),
          child: Ink(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 13),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFF6500), Color(0xFFF0440B)],
              ),
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33F0440B),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: AppTypography.size(15),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 7),
                const Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: 19,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
