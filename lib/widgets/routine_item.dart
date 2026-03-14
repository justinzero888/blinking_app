import 'package:flutter/material.dart';
import '../models/routine.dart';

/// Widget for displaying a routine item in the routine dashboard
class RoutineItem extends StatelessWidget {
  final Routine routine;
  final bool isCompletedToday;
  final int? todayValue; // For counter-type routines (e.g., steps, water)
  final VoidCallback? onComplete;
  final VoidCallback? onIncrement;
  final VoidCallback? onDecrement;
  final VoidCallback? onTap;
  final VoidCallback? onTogglePause;

  const RoutineItem({
    super.key,
    required this.routine,
    this.isCompletedToday = false,
    this.todayValue,
    this.onComplete,
    this.onIncrement,
    this.onDecrement,
    this.onTap,
    this.onTogglePause,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              _buildIcon(),
              const SizedBox(width: 12),
              Expanded(child: _buildInfo(context)),
              _buildAction(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon() {
    IconData iconData;
    switch (routine.icon) {
      case '💊':
        iconData = Icons.medication;
        break;
      case '🚶':
        iconData = Icons.directions_walk;
        break;
      case '💧':
        iconData = Icons.water_drop;
        break;
      case '📖':
        iconData = Icons.menu_book;
        break;
      case '😴':
        iconData = Icons.bedtime;
        break;
      case '🍜':
        iconData = Icons.restaurant;
        break;
      default:
        iconData = Icons.check_circle;
    }
    
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: routine.isActive 
            ? Colors.blue.withAlpha(25)
            : Colors.grey.withAlpha(25),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        iconData,
        color: routine.isActive ? Colors.blue : Colors.grey,
      ),
    );
  }

  Widget _buildInfo(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          routine.name,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w500,
                decoration: routine.isActive ? null : TextDecoration.lineThrough,
                color: routine.isActive ? null : Colors.grey,
              ),
        ),
        const SizedBox(height: 4),
        _buildSubtitle(context),
      ],
    );
  }

  Widget _buildSubtitle(BuildContext context) {
    if (!routine.isActive) {
      return Text(
        'Paused',
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[600],
        ),
      );
    }

    // For counter-type routines
    if (routine.targetCount != null && todayValue != null) {
      return Row(
        children: [
          Text(
            'Today: $todayValue',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
          Text(
            ' / ${routine.targetCount}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[400],
            ),
          ),
          if (todayValue! >= routine.targetCount!)
            const Padding(
              padding: EdgeInsets.only(left: 4),
              child: Icon(Icons.check_circle, size: 14, color: Colors.green),
            ),
        ],
      );
    }

    // For simple check-type routines
    return Row(
      children: [
        Text(
          routine.reminderTime != null
              ? routine.reminderTime! // Already HH:mm format
              : 'Daily',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        if (routine.streak > 0) ...[
          const SizedBox(width: 8),
          Text(
            '🔥 ${routine.streak} day streak',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.orange,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildAction() {
    if (!routine.isActive) {
      return IconButton(
        icon: const Icon(Icons.play_arrow, color: Colors.grey),
        onPressed: onTogglePause,
        tooltip: 'Resume',
      );
    }

    // For counter-type routines
    if (routine.targetCount != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.remove_circle_outline),
            onPressed: onDecrement,
            iconSize: 20,
            color: Colors.grey,
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: onIncrement,
            iconSize: 20,
            color: Colors.blue,
          ),
        ],
      );
    }

    // For simple check-type routines
    return IconButton(
      icon: Icon(
        isCompletedToday ? Icons.check_circle : Icons.radio_button_unchecked,
        color: isCompletedToday ? Colors.green : Colors.grey,
      ),
      onPressed: onComplete,
    );
  }
}

/// Section header for routine groups (Active / Paused)
class RoutineSectionHeader extends StatelessWidget {
  final String title;
  final int count;
  final Color? color;

  const RoutineSectionHeader({
    super.key,
    required this.title,
    required this.count,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color ?? Colors.green,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(width: 8),
          Text(
            '($count)',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey,
                ),
          ),
        ],
      ),
    );
  }
}