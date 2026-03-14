import 'package:flutter/foundation.dart';
import '../models/routine.dart';
import '../models/schedule.dart';
import '../repositories/routine_repository.dart';
import '../core/services/notification_service.dart';

/// Provider for managing routines (daily habits)
/// Uses RoutineRepository for data access
class RoutineProvider extends ChangeNotifier {
  final RoutineRepository _repository;
  final NotificationService _notificationService = NotificationService();
  
  List<Routine> _routines = [];
  bool _isLoading = false;
  String? _error;

  RoutineProvider(this._repository);

  // Getters
  List<Routine> get routines => _routines;
  List<Routine> get activeRoutines => _routines.where((r) => r.isActive).toList();
  List<Routine> get inactiveRoutines => _routines.where((r) => !r.isActive).toList();
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Generate Schedule objects from active routines and their completion logs.
  /// For each active routine, produces one Schedule per completion entry,
  /// plus an uncompleted Schedule for today if not yet done.
  List<Schedule> get schedules {
    final List<Schedule> result = [];
    final today = DateTime.now();
    final todayDate = DateTime(today.year, today.month, today.day);

    for (final routine in _routines.where((r) => r.isActive)) {
      bool hasToday = false;

      // Create a schedule for each completion log entry
      for (final log in routine.completionLog) {
        final logDate = DateTime(
          log.completedAt.year,
          log.completedAt.month,
          log.completedAt.day,
        );
        result.add(Schedule(
          id: log.id,
          routineId: routine.id,
          scheduledDate: logDate,
          completedAt: log.completedAt,
          notes: log.notes,
        ));
        if (logDate == todayDate) {
          hasToday = true;
        }
      }

      // If no completion for today, add an uncompleted schedule
      if (!hasToday) {
        result.add(Schedule(
          id: '${routine.id}_$todayDate',
          routineId: routine.id,
          scheduledDate: todayDate,
          completedAt: null,
        ));
      }
    }

    return result;
  }

  /// Load all routines from storage
  Future<void> loadRoutines() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _routines = await _repository.getAll();
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Add a new routine
  Future<void> addRoutine({
    required String name,
    required String nameEn,
    required RoutineFrequency frequency,
    String? reminderTime,
    int? targetCount,
    String? unit,
    bool isCounter = false,
  }) async {
    _error = null;
    
    try {
      final routine = await _repository.create(
        name: name,
        nameEn: nameEn,
        frequency: frequency,
        reminderTime: reminderTime,
        targetCount: targetCount,
        unit: unit,
        isCounter: isCounter,
      );
      if (routine.isActive && routine.reminderTime != null) {
        await _notificationService.scheduleRoutineReminder(routine);
      }
      _routines.add(routine);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Update an existing routine
  Future<void> updateRoutine(Routine routine) async {
    _error = null;
    
    try {
      final updated = await _repository.update(routine);
      if (updated != null) {
        // Update notification
        await _notificationService.cancelRoutineReminder(updated.id);
        if (updated.isActive && updated.reminderTime != null) {
          await _notificationService.scheduleRoutineReminder(updated);
        }

        final index = _routines.indexWhere((r) => r.id == routine.id);
        if (index != -1) {
          _routines[index] = updated;
          notifyListeners();
        }
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Delete a routine
  Future<void> deleteRoutine(String id) async {
    _error = null;
    
    try {
      await _repository.delete(id);
      await _notificationService.cancelRoutineReminder(id);
      _routines.removeWhere((r) => r.id == id);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Toggle routine active/paused status
  Future<void> toggleActive(String id) async {
    _error = null;
    
    try {
      final updated = await _repository.toggleActive(id);
      if (updated != null) {
        if (updated.isActive && updated.reminderTime != null) {
          await _notificationService.scheduleRoutineReminder(updated);
        } else {
          await _notificationService.cancelRoutineReminder(updated.id);
        }

        final index = _routines.indexWhere((r) => r.id == id);
        if (index != -1) {
          _routines[index] = updated;
          notifyListeners();
        }
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Mark a routine as complete for a specific date (defaults to today)
  Future<void> completeRoutine(String id, {DateTime? date, int? count, String? notes}) async {
    _error = null;
    
    try {
      final updated = await _repository.markComplete(id, date: date, count: count, notes: notes);
      if (updated != null) {
        final index = _routines.indexWhere((r) => r.id == id);
        if (index != -1) {
          _routines[index] = updated;
          notifyListeners();
        }
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Unmark completion for a specific date (defaults to today)
  Future<void> unmarkRoutine(String id, {DateTime? date}) async {
    _error = null;
    
    try {
      final updated = await _repository.unmarkComplete(id, date: date);
      if (updated != null) {
        final index = _routines.indexWhere((r) => r.id == id);
        if (index != -1) {
          _routines[index] = updated;
          notifyListeners();
        }
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Toggle completion for a specific date (defaults to today)
  Future<void> toggleComplete(String id, {DateTime? date}) async {
    final routine = _routines.firstWhere((r) => r.id == id);
    final targetDate = date ?? DateTime.now();
    if (routine.isCompletedOn(targetDate)) {
      await unmarkRoutine(id, date: targetDate);
    } else {
      await completeRoutine(id, date: targetDate);
    }
  }

  /// Update count for a specific date (for countable routines)
  Future<void> updateCount(String id, int count, {DateTime? date}) async {
    _error = null;
    
    try {
      final updated = await _repository.updateDateCount(id, count, date: date);
      if (updated != null) {
        final index = _routines.indexWhere((r) => r.id == id);
        if (index != -1) {
          _routines[index] = updated;
          notifyListeners();
        }
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  /// Get routine by ID
  Routine? getRoutineById(String id) {
    try {
      return _routines.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Get today's completion for a routine
  RoutineCompletion? getTodayCompletion(String routineId) {
    final routine = getRoutineById(routineId);
    return routine?.todayCompletion;
  }

  /// Get streak for a routine
  Future<int> getStreak(String routineId) async {
    return _repository.getStreak(routineId);
  }

  /// Get active routines for today
  List<Routine> getActiveRoutinesForToday() {
    return activeRoutines.where((r) => r.frequency == RoutineFrequency.daily).toList();
  }

  /// Sync all active routine reminders with the notification service
  Future<void> syncAllReminders() async {
    await _notificationService.cancelAll();
    for (final routine in _routines) {
      if (routine.isActive && routine.reminderTime != null) {
        await _notificationService.scheduleRoutineReminder(routine);
      }
    }
  }
}
