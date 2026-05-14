import 'routine.dart';

/// Default routines for the app
class DefaultRoutines {
  static List<Routine> get defaults => [
        Routine(
          id: 'routine_vitamin',
          name: '维生素',
          nameEn: 'Vitamin',
          icon: '💊',
          frequency: RoutineFrequency.daily,
          reminderTime: '08:00',
          isActive: true,
          targetCount: 1,
          currentCount: 0,
          isCounter: false,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        Routine(
          id: 'routine_steps',
          name: '5000步',
          nameEn: '5000 Steps',
          icon: '🚶',
          frequency: RoutineFrequency.daily,
          reminderTime: '21:00',
          isActive: true,
          targetCount: 5000,
          currentCount: 0,
          isCounter: true,
          unit: '步',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        Routine(
          id: 'routine_water',
          name: '喝水',
          nameEn: 'Water',
          icon: '💧',
          frequency: RoutineFrequency.daily,
          reminderTime: '21:00',
          isActive: true,
          targetCount: 1500,
          currentCount: 0,
          isCounter: true,
          unit: 'ml',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];
}
