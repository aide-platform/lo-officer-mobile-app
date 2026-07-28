import 'package:flutter/material.dart';
import 'package:liaison_officer/features/liaison_officer/data/enum/taskStatusX.dart';

import '../../../../../core/design/app_colors.dart';
import '../../../../../core/design/contrast.dart';
import '../../data/enum/taskStatus.dart';

class StatusSlider extends StatelessWidget {
  final TaskStatus status;
  final ValueChanged<TaskStatus> onChanged;

  const StatusSlider({
    super.key,
    required this.status,
    required this.onChanged,
  });

  Color _colorFor(TaskStatus s) {
    switch (s) {
      case TaskStatus.pending:
        return AppColors.warning;
      case TaskStatus.inProgress:
        return AppColors.primary;
      case TaskStatus.completed:
        return AppColors.success;
    }
  }

  @override
  Widget build(BuildContext context) {
    final active = _colorFor(status);
    final muted = Contrast.mutedLabel(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            trackHeight: 6,
            activeTrackColor: active,
            inactiveTrackColor: active.withValues(alpha: 0.18),
            thumbColor: active,
            overlayColor: active.withValues(alpha: 0.15),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
            tickMarkShape: const RoundSliderTickMarkShape(tickMarkRadius: 3),
            activeTickMarkColor: Colors.white,
            inactiveTickMarkColor: active.withValues(alpha: 0.45),
          ),
          child: Slider(
            min: 0,
            max: 2,
            divisions: 2,
            value: status.index.toDouble(),
            onChanged: (v) => onChanged(TaskStatus.values[v.round()]),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              for (final s in TaskStatus.values)
                Expanded(
                  child: Text(
                    s.label,
                    textAlign: s == TaskStatus.pending
                        ? TextAlign.left
                        : s == TaskStatus.completed
                            ? TextAlign.right
                            : TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: status == s
                          ? FontWeight.w800
                          : FontWeight.w500,
                      color: status == s ? _colorFor(s) : muted,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
