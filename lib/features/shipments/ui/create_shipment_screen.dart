import 'package:lod_board/core/theme/app_typography.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import 'post_load_sections.dart';

/// Shell for the post-load form and its step navigation.
class CreateShipmentScreen extends StatefulWidget {
  const CreateShipmentScreen({super.key, this.resumeDraft = false});

  final bool resumeDraft;

  @override
  State<CreateShipmentScreen> createState() => _CreateShipmentScreenState();
}

enum _PostStep { route, cargo, trucks, review }

enum _PostType { normal, contract }

class _CreateShipmentScreenState extends State<CreateShipmentScreen> {
  final _sectionsKey = GlobalKey<PostLoadSectionsState>();
  _PostStep _step = _PostStep.route;
  _PostType _postType = _PostType.normal;
  bool _allowPop = false;
  void _closeConfirmed() {
    setState(() => _allowPop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _allowPop,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _sectionsKey.currentState?.closeForm();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF1F3FA),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),
                _PostHeader(
                  onBack: () => _sectionsKey.currentState?.closeForm(),
                  onSave: () => _sectionsKey.currentState?.saveDraft(),
                ),
                const SizedBox(height: 26),
                _StepIndicator(
                  selected: _step,
                  onSelected: (step) => setState(() => _step = step),
                ),
                const SizedBox(height: 25),
                _PostTypeSelector(
                  selected: _postType,
                  onSelected: (type) => setState(() => _postType = type),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: PostLoadSections(
                    key: _sectionsKey,
                    resumeDraft: widget.resumeDraft,
                    onCloseConfirmed: _closeConfirmed,
                    isContract: _postType == _PostType.contract,
                    onTypeRestored: (isContract) => setState(
                      () => _postType = isContract
                          ? _PostType.contract
                          : _PostType.normal,
                    ),
                    step: _step.index,
                    onStepChanged: (index) =>
                        setState(() => _step = _PostStep.values[index]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PostHeader extends StatelessWidget {
  const _PostHeader({required this.onBack, required this.onSave});

  final VoidCallback onBack;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          onPressed: onBack,
          tooltip: 'Back',
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.navy),
        ),
        const SizedBox(width: 4),
        const Expanded(
          child: Text(
            'Post a load',
            style: TextStyle(
              color: AppColors.navy,
              fontSize: 23,
              fontWeight: FontWeight.w800,
              letterSpacing: -.4,
            ),
          ),
        ),
        OutlinedButton.icon(
          onPressed: onSave,
          icon: const Icon(Icons.description_outlined, size: 19),
          label: const Text('Save draft'),
          style: OutlinedButton.styleFrom(
            disabledForegroundColor: AppColors.navy.withValues(alpha: .5),
            side: const BorderSide(color: Color(0xFFC9CEDA)),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            minimumSize: const Size(0, 44),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            textStyle: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

class _StepIndicator extends StatelessWidget {
  const _StepIndicator({required this.selected, required this.onSelected});

  final _PostStep selected;
  final ValueChanged<_PostStep> onSelected;

  @override
  Widget build(BuildContext context) {
    const labels = ['Route', 'Cargo', 'Trucks', 'Review'];
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = constraints.maxWidth / labels.length;
        return SizedBox(
          height: 56,
          child: Stack(
            children: [
              Positioned(
                left: itemWidth / 2,
                right: itemWidth / 2,
                top: 9,
                child: Container(height: 2, color: const Color(0xFFBDC1CC)),
              ),
              Row(
                children: [
                  for (final step in _PostStep.values)
                    Expanded(
                      child: Semantics(
                        button: true,
                        selected: step == selected,
                        label: '${labels[step.index]} step',
                        child: InkWell(
                          onTap: () => onSelected(step),
                          borderRadius: BorderRadius.circular(8),
                          child: Column(
                            children: [
                              Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F3FA),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: step == selected
                                        ? AppColors.orange
                                        : const Color(0xFFADB2C0),
                                    width: step == selected ? 5 : 2,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 7),
                              Text(
                                labels[step.index],
                                style: TextStyle(
                                  color: step == selected
                                      ? AppColors.orange
                                      : const Color(0xFF5C6171),
                                  fontSize: AppTextStyles.labelSize,
                                  fontWeight: step == selected
                                      ? FontWeight.w800
                                      : FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PostTypeSelector extends StatelessWidget {
  const _PostTypeSelector({required this.selected, required this.onSelected});

  final _PostType selected;
  final ValueChanged<_PostType> onSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .35),
        border: Border.all(color: const Color(0xFFD3D7E1)),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final type in _PostType.values)
            Expanded(
              child: Semantics(
                button: true,
                selected: selected == type,
                child: Material(
                  color: selected == type
                      ? AppColors.orange
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    onTap: () => onSelected(type),
                    borderRadius: BorderRadius.circular(10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          type == _PostType.normal
                              ? Icons.inventory_2_outlined
                              : Icons.calendar_today_outlined,
                          size: 20,
                          color: selected == type
                              ? Colors.white
                              : AppColors.navy,
                        ),
                        const SizedBox(width: 9),
                        Text(
                          type == _PostType.normal ? 'Normal' : 'Contract',
                          style: TextStyle(
                            color: selected == type
                                ? Colors.white
                                : AppColors.navy,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ],
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
