/// Domain entity representing macronutrient information
class Macros {
  final double carbohydrates; // in grams
  final double protein; // in grams
  final double fat; // in grams

  const Macros({
    required this.carbohydrates,
    required this.protein,
    required this.fat,
  });

  /// Calculate total calories from macros
  /// Carbs: 4 cal/g, Protein: 4 cal/g, Fat: 9 cal/g
  int get totalCalories {
    return ((carbohydrates * 4) + (protein * 4) + (fat * 9)).round();
  }

  Macros copyWith({double? carbohydrates, double? protein, double? fat}) {
    return Macros(
      carbohydrates: carbohydrates ?? this.carbohydrates,
      protein: protein ?? this.protein,
      fat: fat ?? this.fat,
    );
  }

  /// Add two Macros together
  Macros operator +(Macros other) {
    return Macros(
      carbohydrates: carbohydrates + other.carbohydrates,
      protein: protein + other.protein,
      fat: fat + other.fat,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Macros &&
        other.carbohydrates == carbohydrates &&
        other.protein == protein &&
        other.fat == fat;
  }

  @override
  int get hashCode {
    return Object.hash(carbohydrates, protein, fat);
  }

  @override
  String toString() {
    return 'Macros(carbs: ${carbohydrates}g, protein: ${protein}g, fat: ${fat}g)';
  }
}
