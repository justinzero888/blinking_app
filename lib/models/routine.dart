/// Routine frequency enum
enum RoutineFrequency {
  daily,
  weekly,
  custom,
}

/// Routine model - for daily habits tracking
class Routine {
  final String id;
  final String name;
  final String nameEn;
  final String? icon;
  final String? description;
  final String? descriptionEn;
  final RoutineFrequency frequency;
  final String? reminderTime; // HH:mm format
  final bool isActive;
  final int? targetCount; // For countable routines (e.g., steps)
  final int currentCount;
  final bool isCounter; // true = count up to target, false = simple checkbox
  final String? unit; // e.g., '步', 'ml', '次'
  final List<RoutineCompletion> completionLog;
  final DateTime createdAt;
  final DateTime updatedAt;

  Routine({
    required this.id,
    required this.name,
    required this.nameEn,
    this.icon,
    this.description,
    this.descriptionEn,
    required this.frequency,
    this.reminderTime,
    this.isActive = true,
    this.targetCount,
    this.currentCount = 0,
    this.isCounter = false,
    this.unit,
    this.completionLog = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  Routine copyWith({
    String? id,
    String? name,
    String? nameEn,
    String? icon,
    String? description,
    String? descriptionEn,
    RoutineFrequency? frequency,
    String? reminderTime,
    bool? isActive,
    int? targetCount,
    int? currentCount,
    bool? isCounter,
    String? unit,
    List<RoutineCompletion>? completionLog,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Routine(
      id: id ?? this.id,
      name: name ?? this.name,
      nameEn: nameEn ?? this.nameEn,
      icon: icon ?? this.icon,
      description: description ?? this.description,
      descriptionEn: descriptionEn ?? this.descriptionEn,
      frequency: frequency ?? this.frequency,
      reminderTime: reminderTime ?? this.reminderTime,
      isActive: isActive ?? this.isActive,
      targetCount: targetCount ?? this.targetCount,
      currentCount: currentCount ?? this.currentCount,
      isCounter: isCounter ?? this.isCounter,
      unit: unit ?? this.unit,
      completionLog: completionLog ?? this.completionLog,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Calculate streak (consecutive days)
  int get streak {
    if (completionLog.isEmpty) return 0;
    
    final sortedLogs = List<RoutineCompletion>.from(completionLog)
      ..sort((a, b) => b.completedAt.compareTo(a.completedAt));
    
    int count = 0;
    DateTime? lastDate;
    
    for (final log in sortedLogs) {
      final logDate = DateTime(
        log.completedAt.year,
        log.completedAt.month,
        log.completedAt.day,
      );
      
      if (lastDate == null) {
        // Check if completed today or yesterday
        final today = DateTime.now();
        final todayDate = DateTime(today.year, today.month, today.day);
        final yesterday = todayDate.subtract(const Duration(days: 1));
        
        if (logDate == todayDate || logDate == yesterday) {
          count = 1;
          lastDate = logDate;
        } else {
          break;
        }
      } else {
        final expectedDate = lastDate.subtract(const Duration(days: 1));
        if (logDate == expectedDate) {
          count++;
          lastDate = logDate;
        } else if (logDate == lastDate) {
          // Same day, skip
          continue;
        } else {
          break;
        }
      }
    }
    
    return count;
  }

  /// Check if completed on a specific date
  bool isCompletedOn(DateTime date) {
    return completionLog.any((log) =>
        log.completedAt.year == date.year &&
        log.completedAt.month == date.month &&
        log.completedAt.day == date.day);
  }

  /// Get completion record for a specific date
  RoutineCompletion? getCompletionOn(DateTime date) {
    try {
      return completionLog.firstWhere((log) =>
          log.completedAt.year == date.year &&
          log.completedAt.month == date.month &&
          log.completedAt.day == date.day);
    } catch (_) {
      return null;
    }
  }

  /// Check if completed today
  bool get isCompletedToday => isCompletedOn(DateTime.now());

  /// Get today's completion if exists
  RoutineCompletion? get todayCompletion => getCompletionOn(DateTime.now());

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'nameEn': nameEn,
      'icon': icon,
      'description': description,
      'descriptionEn': descriptionEn,
      'frequency': frequency.name,
      'reminderTime': reminderTime,
      'isActive': isActive,
      'targetCount': targetCount,
      'currentCount': currentCount,
      'isCounter': isCounter,
      'unit': unit,
      'completionLog': completionLog.map((e) => e.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Routine.fromJson(Map<String, dynamic> json) {
    return Routine(
      id: json['id'] as String,
      name: json['name'] as String,
      nameEn: json['nameEn'] as String,
      icon: json['icon'] as String?,
      description: json['description'] as String?,
      descriptionEn: json['descriptionEn'] as String?,
      frequency: RoutineFrequency.values.firstWhere(
        (e) => e.name == json['frequency'],
        orElse: () => RoutineFrequency.daily,
      ),
      reminderTime: json['reminderTime'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      targetCount: json['targetCount'] as int?,
      currentCount: json['currentCount'] as int? ?? 0,
      isCounter: json['isCounter'] as bool? ?? false,
      unit: json['unit'] as String?,
      completionLog: (json['completionLog'] as List<dynamic>?)
              ?.map((e) => RoutineCompletion.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}

/// Routine completion record
class RoutineCompletion {
  final String id;
  final String routineId;
  final DateTime completedAt;
  final int? count; // For countable routines
  final String? notes;

  RoutineCompletion({
    required this.id,
    required this.routineId,
    required this.completedAt,
    this.count,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'routineId': routineId,
      'completedAt': completedAt.toIso8601String(),
      'count': count,
      'notes': notes,
    };
  }

  factory RoutineCompletion.fromJson(Map<String, dynamic> json) {
    return RoutineCompletion(
      id: json['id'] as String,
      routineId: json['routineId'] as String,
      completedAt: DateTime.parse(json['completedAt'] as String),
      count: json['count'] as int?,
      notes: json['notes'] as String?,
    );
  }
}
