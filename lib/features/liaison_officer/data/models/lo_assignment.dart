import '../../../../core/storage/sqlite/app_sqlite_db.dart';

class LoDelegateAssignment {
  final String delegateName;
  final String assignedLoEmail;
  final DateTime createdAt;

  const LoDelegateAssignment({
    required this.delegateName,
    required this.assignedLoEmail,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'delegateName': delegateName,
        'assignedLoEmail': assignedLoEmail,
        'createdAt': createdAt.toIso8601String(),
      };

  factory LoDelegateAssignment.fromMap(Map<String, dynamic> map) {
    return LoDelegateAssignment(
      delegateName: map['delegateName']?.toString() ?? '',
      assignedLoEmail: map['assignedLoEmail']?.toString() ?? '',
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  static Future<List<LoDelegateAssignment>> getAll() async {
    final rows = await AppSqliteDb.getJsonList('lo_delegate_assignments');
    if (rows == null) return const [];
    return rows
        .whereType<Map>()
        .map((value) =>
            LoDelegateAssignment.fromMap(Map<String, dynamic>.from(value)))
        .toList();
  }

  static Future<void> saveAll(List<LoDelegateAssignment> assignments) async {
    await AppSqliteDb.saveJsonList(
      'lo_delegate_assignments',
      assignments.map((e) => e.toMap()).toList(),
    );
  }

  /// Seeds demo assignments for the LO portal if none exist.
  static Future<void> ensureDemoSeed(String loEmail) async {
    final existing = await getAll();
    if (existing.isNotEmpty) return;
    await saveAll([
      LoDelegateAssignment(
        delegateName: 'Sharan',
        assignedLoEmail: loEmail,
        createdAt: DateTime.now(),
      ),
      LoDelegateAssignment(
        delegateName: 'Dr. Michael Thompson',
        assignedLoEmail: loEmail,
        createdAt: DateTime.now(),
      ),
    ]);
  }
}

class LoTaskAssignment {
  final String taskTitle;
  final String delegateName;
  final String assignedLoEmail;
  final String taskSource;
  final String description;
  final DateTime scheduledDate;
  final String location;
  final String status;

  const LoTaskAssignment({
    required this.taskTitle,
    required this.delegateName,
    required this.assignedLoEmail,
    required this.taskSource,
    required this.description,
    required this.scheduledDate,
    this.location = '',
    this.status = 'Pending',
  });

  LoTaskAssignment copyWith({
    String? taskTitle,
    String? delegateName,
    String? assignedLoEmail,
    String? taskSource,
    String? description,
    DateTime? scheduledDate,
    String? location,
    String? status,
  }) {
    return LoTaskAssignment(
      taskTitle: taskTitle ?? this.taskTitle,
      delegateName: delegateName ?? this.delegateName,
      assignedLoEmail: assignedLoEmail ?? this.assignedLoEmail,
      taskSource: taskSource ?? this.taskSource,
      description: description ?? this.description,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      location: location ?? this.location,
      status: status ?? this.status,
    );
  }

  String get id =>
      '${assignedLoEmail}|$delegateName|$taskTitle|${scheduledDate.toIso8601String()}';

  Map<String, dynamic> toMap() => {
        'taskTitle': taskTitle,
        'delegateName': delegateName,
        'assignedLoEmail': assignedLoEmail,
        'taskSource': taskSource,
        'description': description,
        'scheduledDate': scheduledDate.toIso8601String(),
        'location': location,
        'status': status,
      };

  factory LoTaskAssignment.fromMap(Map<String, dynamic> map) {
    return LoTaskAssignment(
      taskTitle: map['taskTitle']?.toString() ?? '',
      delegateName: map['delegateName']?.toString() ?? '',
      assignedLoEmail: map['assignedLoEmail']?.toString() ?? '',
      taskSource: map['taskSource']?.toString() ?? 'Custom',
      description: map['description']?.toString() ?? '',
      scheduledDate: map['scheduledDate'] != null
          ? DateTime.tryParse(map['scheduledDate'].toString()) ?? DateTime.now()
          : DateTime.now(),
      location: map['location']?.toString() ?? '',
      status: map['status']?.toString() ?? 'Pending',
    );
  }

  static Future<List<LoTaskAssignment>> getAll() async {
    final rows = await AppSqliteDb.getJsonList('lo_task_assignments');
    if (rows == null) return const [];
    return rows
        .whereType<Map>()
        .map((value) =>
            LoTaskAssignment.fromMap(Map<String, dynamic>.from(value)))
        .toList();
  }

  static Future<List<LoTaskAssignment>> forLo(String email) async {
    final all = await getAll();
    final normalized = email.trim().toLowerCase();
    return all
        .where((t) => t.assignedLoEmail.trim().toLowerCase() == normalized)
        .toList();
  }

  static Future<void> saveAll(List<LoTaskAssignment> assignments) async {
    await AppSqliteDb.saveJsonList(
      'lo_task_assignments',
      assignments.map((e) => e.toMap()).toList(),
    );
  }

  static Future<void> updateStatus({
    required String delegateName,
    required String assignedLoEmail,
    required String taskTitle,
    required String status,
  }) async {
    final existing = await getAll();
    final updated = existing.map((task) {
      if (task.delegateName == delegateName &&
          task.assignedLoEmail == assignedLoEmail &&
          task.taskTitle == taskTitle) {
        return task.copyWith(status: status);
      }
      return task;
    }).toList();

    await saveAll(updated);
  }

  /// Seeds demo tasks for the LO portal if none exist for this LO.
  static Future<void> ensureDemoSeed(String loEmail) async {
    final existing = await forLo(loEmail);
    if (existing.isNotEmpty) return;

    final now = DateTime.now();
    final current = await getAll();
    await saveAll([
      ...current,
      LoTaskAssignment(
        taskTitle: 'Airport Pickup',
        delegateName: 'Dr. Michael Thompson',
        assignedLoEmail: loEmail,
        taskSource: 'Protocol',
        description: 'Receive delegate at T2 arrivals and escort to hotel.',
        scheduledDate: now.add(const Duration(hours: 2)),
        location: 'Kempegowda International Airport — T2',
        status: 'Pending',
      ),
      LoTaskAssignment(
        taskTitle: 'Hotel Check-in Assist',
        delegateName: 'Dr. Michael Thompson',
        assignedLoEmail: loEmail,
        taskSource: 'Accommodation',
        description: 'Coordinate presidential suite check-in and room briefing.',
        scheduledDate: now.add(const Duration(hours: 4)),
        location: 'The Leela Palace',
        status: 'Pending',
      ),
      LoTaskAssignment(
        taskTitle: 'Welcome Dinner Escort',
        delegateName: 'Sharan',
        assignedLoEmail: loEmail,
        taskSource: 'Protocol',
        description: 'Escort delegate to Welcome Dinner and confirm seating.',
        scheduledDate: now.add(const Duration(hours: 6)),
        location: 'Taj West End — Banquet Hall',
        status: 'In Progress',
      ),
      LoTaskAssignment(
        taskTitle: 'Inaugural Function Support',
        delegateName: 'Dr. Michael Thompson',
        assignedLoEmail: loEmail,
        taskSource: 'Events',
        description: 'Protocol support during Inaugural Function.',
        scheduledDate: now.add(const Duration(days: 1, hours: 2)),
        location: 'Main Convention Centre',
        status: 'Pending',
      ),
    ]);
  }
}
