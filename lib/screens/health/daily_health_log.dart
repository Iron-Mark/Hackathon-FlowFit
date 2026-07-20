import 'package:flutter/material.dart';

// Per-day health log backing the health screen (food, water, and sleep).
class DailyHealthLog {
  DailyHealthLog({
    required this.waterIntake,
    required this.foodItems,
    required this.bedTime,
    required this.wakeTime,
  });

  factory DailyHealthLog.seeded() {
    return DailyHealthLog(
      waterIntake: 1.5,
      foodItems: {
        'Breakfast': [
          {'name': 'Oatmeal with Berries', 'calories': '350 kcal'},
          {'name': 'Black Coffee', 'calories': '5 kcal'},
        ],
        'Lunch': [
          {'name': 'Grilled Chicken Salad', 'calories': '450 kcal'},
          {'name': 'Apple', 'calories': '80 kcal'},
        ],
        'Dinner': [
          {'name': 'Salmon with Veggies', 'calories': '550 kcal'},
        ],
        'Snacks': [
          {'name': 'Almonds', 'calories': '160 kcal'},
        ],
      },
      bedTime: const TimeOfDay(hour: 22, minute: 30),
      wakeTime: const TimeOfDay(hour: 6, minute: 0),
    );
  }

  factory DailyHealthLog.empty() {
    return DailyHealthLog(
      waterIntake: 0,
      foodItems: {'Breakfast': [], 'Lunch': [], 'Dinner': [], 'Snacks': []},
      bedTime: const TimeOfDay(hour: 22, minute: 30),
      wakeTime: const TimeOfDay(hour: 6, minute: 0),
    );
  }

  double waterIntake;
  Map<String, List<Map<String, String>>> foodItems;
  TimeOfDay bedTime;
  TimeOfDay wakeTime;
}
