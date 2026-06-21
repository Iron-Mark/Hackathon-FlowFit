import 'package:flowfit/models/mood_rating.dart';
import 'package:flowfit/widgets/mood_change_badge.dart';
import 'package:flowfit/widgets/mood_transformation_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('mood change badge hides when either mood is missing', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              MoodChangeBadge(preMood: _mood(2)),
              MoodChangeBadge(postMood: _mood(4)),
            ],
          ),
        ),
      ),
    );

    expect(find.byType(MoodChangeBadge), findsNWidgets(2));
    expect(find.byIcon(Icons.arrow_forward_rounded), findsNothing);
  });

  testWidgets('mood change badge shows pre to post mood', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MoodChangeBadge(preMood: _mood(2), postMood: _mood(5)),
        ),
      ),
    );

    expect(find.text('😕'), findsOneWidget);
    expect(find.text('💪'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_forward_rounded), findsOneWidget);
  });

  testWidgets('mood transformation card shows positive change copy', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MoodTransformationCard(
            preMood: _mood(2),
            postMood: _mood(5),
            moodChange: 3,
          ),
        ),
      ),
    );

    expect(find.text('Mood Transformation'), findsOneWidget);
    expect(find.text('+3 points improvement!'), findsOneWidget);
    expect(find.text('😕'), findsOneWidget);
    expect(find.text('💪'), findsOneWidget);
  });

  testWidgets('mood transformation card handles neutral and negative changes', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              MoodTransformationCard(
                preMood: _mood(4),
                postMood: _mood(4),
                moodChange: 0,
              ),
              MoodTransformationCard(
                preMood: _mood(5),
                postMood: _mood(3),
                moodChange: -2,
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Mood stayed consistent'), findsOneWidget);
    expect(find.text('-2 points change'), findsOneWidget);
  });
}

MoodRating _mood(int value) {
  const emojiMap = {1: '😢', 2: '😕', 3: '😐', 4: '🙂', 5: '💪'};

  return MoodRating(
    value: value,
    emoji: emojiMap[value]!,
    timestamp: DateTime.utc(2026),
  );
}
