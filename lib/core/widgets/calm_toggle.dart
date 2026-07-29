import 'package:flutter/material.dart';
import '../theme/micro_interactions.dart';

class CalmToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;

  const CalmToggle({super.key, required this.value, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged?.call(!value),
      child: AnimatedContainer(
        duration: MicroInteractions.toggleDuration,
        curve: Curves.easeOutQuart,
        width: 50,
        height: 28,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: value
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.surfaceContainerHighest,
        ),
        child: AnimatedAlign(
          duration: MicroInteractions.toggleDuration,
          curve: Curves.easeOutQuart,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Padding(
            padding: const EdgeInsets.all(3),
            child: Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).colorScheme.surface,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
