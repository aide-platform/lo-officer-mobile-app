import '../enum/taskStatus.dart';
import '../enum/taskType.dart';

class LOTask {
  final String vipName;
  final TaskType type;
  TaskStatus status;
  final String description;
  final DateTime createdAt;
  /// Index used by [LoTaskStatusChanged] (0=pickup, 1=hotel, 2+=engagement).
  final int taskIndex;

  LOTask({
    required this.vipName,
    required this.type,
    required this.status,
    required this.description,
    required this.createdAt,
    required this.taskIndex,
  });
}