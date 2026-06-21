class DailyMood {
  final int stressMinutes;
  final int calmMinutes;
  final double stressScore; // 0..1 where 1 = all stress

  DailyMood({required this.stressMinutes, required this.calmMinutes})
    : stressScore = (stressMinutes + calmMinutes) == 0
          ? 0.0
          : (stressMinutes / (stressMinutes + calmMinutes));

  bool get moreStressedThanCalm => stressMinutes > calmMinutes;

  Map<String, dynamic> toJson() => {
    'stressMinutes': stressMinutes,
    'calmMinutes': calmMinutes,
    'stressScore': stressScore,
  };

  factory DailyMood.fromJson(Map<String, dynamic> json) => DailyMood(
    stressMinutes: json['stressMinutes'] as int? ?? 0,
    calmMinutes: json['calmMinutes'] as int? ?? 0,
  );
}
