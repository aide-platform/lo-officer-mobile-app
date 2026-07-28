import 'package:liaison_officer/features/liaison_officer/data/enum/taskStatus.dart';
import 'package:flutter/material.dart';
import '../../../../core/design/app_colors.dart';


extension TaskStatusX on TaskStatus {
  String get label {
    switch (this) {
      case TaskStatus.pending:
        return 'Pending';
      case TaskStatus.inProgress:
        return 'In Progress';
      case TaskStatus.completed:
        return 'Completed';
    }
  }

  Color get color {
    switch (this) {
      case TaskStatus.pending:
        return AppColors.warning;
      case TaskStatus.inProgress:
        return AppColors.primary;
      case TaskStatus.completed:
        return AppColors.success;
    }
  }
}
