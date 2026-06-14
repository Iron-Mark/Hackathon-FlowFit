import 'package:flutter_test/flutter_test.dart';
import 'package:flowfit/services/timer_service.dart';

void main() {
  group('TimerService', () {
    late TimerService timerService;

    setUp(() {
      timerService = TimerService();
    });

    tearDown(() {
      timerService.dispose();
    });

    group('Initial State', () {
      test('starts with zero elapsed seconds', () {
        expect(timerService.elapsedSeconds, equals(0));
      });

      test('is not running initially', () {
        expect(timerService.isRunning, isFalse);
      });

      test('is not paused initially', () {
        expect(timerService.isPaused, isFalse);
      });

      test('formatted time is 00:00 initially', () {
        expect(timerService.formattedTime, equals('00:00'));
      });
    });

    group('start', () {
      test('changes isRunning to true', () {
        timerService.start();
        expect(timerService.isRunning, isTrue);
      });

      test('does not start if already running', () {
        timerService.start();
        final firstStart = timerService.isRunning;
        timerService.start(); // Try to start again
        expect(firstStart, isTrue);
        expect(timerService.isRunning, isTrue);
      });

      test('emits elapsed seconds through stream', () async {
        final streamValues = <int>[];
        final subscription = timerService.timerStream.listen((value) {
          streamValues.add(value);
        });

        timerService.start();
        await Future.delayed(const Duration(milliseconds: 2100));
        timerService.stop();

        await subscription.cancel();
        expect(streamValues.length, greaterThanOrEqualTo(2));
        expect(streamValues, contains(1));
        expect(streamValues, contains(2));
      });

      test('increments elapsed seconds over time', () async {
        timerService.start();
        await Future.delayed(const Duration(milliseconds: 1100));
        final elapsed1 = timerService.elapsedSeconds;
        await Future.delayed(const Duration(milliseconds: 1000));
        final elapsed2 = timerService.elapsedSeconds;

        expect(elapsed1, greaterThanOrEqualTo(1));
        expect(elapsed2, greaterThan(elapsed1));
      });

      test('clears paused state when starting', () {
        timerService.start();
        timerService.pause();
        expect(timerService.isPaused, isTrue);
        timerService.resume();
        expect(timerService.isPaused, isFalse);
      });
    });

    group('pause', () {
      test('changes isRunning to false', () async {
        timerService.start();
        await Future.delayed(const Duration(milliseconds: 100));
        timerService.pause();
        expect(timerService.isRunning, isFalse);
      });

      test('sets isPaused to true', () async {
        timerService.start();
        await Future.delayed(const Duration(milliseconds: 100));
        timerService.pause();
        expect(timerService.isPaused, isTrue);
      });

      test('does not pause if not running', () {
        timerService.pause();
        expect(timerService.isPaused, isFalse);
      });

      test('does not pause if already paused', () async {
        timerService.start();
        await Future.delayed(const Duration(milliseconds: 100));
        timerService.pause();
        final wasPaused = timerService.isPaused;
        timerService.pause(); // Try to pause again
        expect(wasPaused, isTrue);
        expect(timerService.isPaused, isTrue);
      });

      test('preserves elapsed seconds', () async {
        timerService.start();
        await Future.delayed(const Duration(milliseconds: 1100));
        final elapsedBeforePause = timerService.elapsedSeconds;
        timerService.pause();
        await Future.delayed(const Duration(milliseconds: 1000));
        final elapsedAfterPause = timerService.elapsedSeconds;

        expect(elapsedBeforePause, greaterThanOrEqualTo(1));
        expect(elapsedAfterPause, equals(elapsedBeforePause));
      });
    });

    group('resume', () {
      test('resumes from paused state', () async {
        timerService.start();
        await Future.delayed(const Duration(milliseconds: 1100));
        timerService.pause();
        final elapsedAtPause = timerService.elapsedSeconds;
        timerService.resume();
        await Future.delayed(const Duration(milliseconds: 1100));
        final elapsedAfterResume = timerService.elapsedSeconds;

        expect(elapsedAfterResume, greaterThan(elapsedAtPause));
      });

      test('does not resume if not paused', () {
        timerService.resume();
        expect(timerService.isRunning, isFalse);
      });

      test('clears paused state', () async {
        timerService.start();
        await Future.delayed(const Duration(milliseconds: 100));
        timerService.pause();
        timerService.resume();
        expect(timerService.isPaused, isFalse);
        expect(timerService.isRunning, isTrue);
      });
    });

    group('stop', () {
      test('resets elapsed seconds to zero', () async {
        timerService.start();
        await Future.delayed(const Duration(milliseconds: 1100));
        timerService.stop();
        expect(timerService.elapsedSeconds, equals(0));
      });

      test('changes isRunning to false', () async {
        timerService.start();
        await Future.delayed(const Duration(milliseconds: 100));
        timerService.stop();
        expect(timerService.isRunning, isFalse);
      });

      test('clears paused state', () async {
        timerService.start();
        await Future.delayed(const Duration(milliseconds: 100));
        timerService.pause();
        timerService.stop();
        expect(timerService.isPaused, isFalse);
      });

      test('emits zero through stream', () async {
        final streamValues = <int>[];
        final subscription = timerService.timerStream.listen((value) {
          streamValues.add(value);
        });

        timerService.start();
        await Future.delayed(const Duration(milliseconds: 1100));
        timerService.stop();
        await Future.delayed(const Duration(milliseconds: 100));

        await subscription.cancel();
        expect(streamValues.last, equals(0));
      });
    });

    group('reset', () {
      test('resets elapsed seconds to zero without stopping', () async {
        timerService.start();
        await Future.delayed(const Duration(milliseconds: 1100));
        timerService.reset();
        expect(timerService.elapsedSeconds, equals(0));
      });

      test('keeps timer running if it was running', () async {
        timerService.start();
        await Future.delayed(const Duration(milliseconds: 1100));
        timerService.reset();
        await Future.delayed(const Duration(milliseconds: 1100));
        expect(timerService.elapsedSeconds, greaterThanOrEqualTo(1));
        expect(timerService.isRunning, isTrue);
      });
    });

    group('setElapsedSeconds', () {
      test('sets elapsed seconds to specified value', () {
        timerService.setElapsedSeconds(120);
        expect(timerService.elapsedSeconds, equals(120));
      });

      test('updates formatted time correctly', () {
        timerService.setElapsedSeconds(125);
        expect(timerService.formattedTime, equals('02:05'));
      });

      test('emits value through stream', () async {
        final streamValues = <int>[];
        final subscription = timerService.timerStream.listen((value) {
          streamValues.add(value);
        });

        timerService.setElapsedSeconds(60);
        await Future.delayed(const Duration(milliseconds: 100));

        await subscription.cancel();
        expect(streamValues, contains(60));
      });

      test('can restore state from saved value', () async {
        timerService.setElapsedSeconds(300);
        timerService.start();
        await Future.delayed(const Duration(milliseconds: 1100));
        expect(timerService.elapsedSeconds, greaterThanOrEqualTo(301));
      });
    });

    group('formattedTime', () {
      test('formats zero seconds correctly', () {
        expect(timerService.formattedTime, equals('00:00'));
      });

      test('formats single digit seconds correctly', () {
        timerService.setElapsedSeconds(5);
        expect(timerService.formattedTime, equals('00:05'));
      });

      test('formats double digit seconds correctly', () {
        timerService.setElapsedSeconds(45);
        expect(timerService.formattedTime, equals('00:45'));
      });

      test('formats minutes and seconds correctly', () {
        timerService.setElapsedSeconds(125);
        expect(timerService.formattedTime, equals('02:05'));
      });

      test('formats hours as minutes correctly', () {
        timerService.setElapsedSeconds(3665); // 1 hour, 1 minute, 5 seconds
        expect(timerService.formattedTime, equals('61:05'));
      });

      test('pads single digit minutes with zero', () {
        timerService.setElapsedSeconds(540); // 9 minutes
        expect(timerService.formattedTime, equals('09:00'));
      });

      test('formats large values correctly', () {
        timerService.setElapsedSeconds(7200); // 2 hours
        expect(timerService.formattedTime, equals('120:00'));
      });
    });

    group('dispose', () {
      test('cancels timer ticks when disposed', () async {
        timerService.start();
        await Future.delayed(const Duration(milliseconds: 1100));
        final elapsedBeforeDispose = timerService.elapsedSeconds;
        timerService.dispose();
        await Future.delayed(const Duration(milliseconds: 1100));
        expect(timerService.elapsedSeconds, elapsedBeforeDispose);
      });

      test('closes stream controller', () async {
        final streamDone = expectLater(timerService.timerStream, emitsDone);
        timerService.dispose();
        await streamDone;
      });
    });

    group('Edge Cases', () {
      test('handles rapid start/stop cycles', () async {
        for (int i = 0; i < 5; i++) {
          timerService.start();
          await Future.delayed(const Duration(milliseconds: 100));
          timerService.stop();
        }
        expect(timerService.elapsedSeconds, equals(0));
        expect(timerService.isRunning, isFalse);
      });

      test('handles pause/resume cycles', () async {
        timerService.start();
        for (int i = 0; i < 3; i++) {
          await Future.delayed(const Duration(milliseconds: 500));
          timerService.pause();
          await Future.delayed(const Duration(milliseconds: 200));
          timerService.resume();
        }
        timerService.stop();
        expect(timerService.isRunning, isFalse);
      });

      test('handles very large elapsed seconds', () {
        timerService.setElapsedSeconds(999999);
        expect(timerService.elapsedSeconds, equals(999999));
        expect(timerService.formattedTime.length, greaterThan(5));
      });
    });
  });

  group('CountdownTimerService', () {
    late CountdownTimerService countdownService;

    setUp(() {
      countdownService = CountdownTimerService();
    });

    tearDown(() {
      countdownService.dispose();
    });

    group('Initial State', () {
      test('starts with zero remaining seconds', () {
        expect(countdownService.remainingSeconds, equals(0));
      });

      test('is not running initially', () {
        expect(countdownService.isRunning, isFalse);
      });

      test('formatted time is 00:00 initially', () {
        expect(countdownService.formattedTime, equals('00:00'));
      });
    });

    group('start', () {
      test('sets remaining seconds to specified value', () {
        countdownService.start(60);
        expect(countdownService.remainingSeconds, equals(60));
      });

      test('changes isRunning to true', () {
        countdownService.start(30);
        expect(countdownService.isRunning, isTrue);
      });

      test('decrements remaining seconds over time', () async {
        countdownService.start(5);
        await Future.delayed(const Duration(milliseconds: 1100));
        final remaining1 = countdownService.remainingSeconds;
        await Future.delayed(const Duration(milliseconds: 1000));
        final remaining2 = countdownService.remainingSeconds;

        expect(remaining1, lessThan(5));
        expect(remaining2, lessThan(remaining1));
      });

      test('stops automatically when reaching zero', () async {
        countdownService.start(2);
        await Future.delayed(const Duration(milliseconds: 2500));
        expect(countdownService.isRunning, isFalse);
        expect(countdownService.remainingSeconds, equals(0));
      });

      test('does not start if already running', () {
        countdownService.start(60);
        final wasRunning = countdownService.isRunning;
        countdownService.start(30); // Try to start again
        expect(wasRunning, isTrue);
        expect(countdownService.isRunning, isTrue);
      });

      test('emits countdown values through stream', () async {
        final streamValues = <int>[];
        final subscription = countdownService.timerStream.listen((value) {
          streamValues.add(value);
        });

        countdownService.start(3);
        await Future.delayed(const Duration(milliseconds: 3500));

        await subscription.cancel();
        expect(streamValues, contains(3));
        expect(streamValues, contains(2));
        expect(streamValues, contains(1));
        expect(streamValues.last, equals(0));
      });
    });

    group('stop', () {
      test('stops countdown and resets to zero', () async {
        countdownService.start(30);
        await Future.delayed(const Duration(milliseconds: 1100));
        countdownService.stop();
        expect(countdownService.remainingSeconds, equals(0));
        expect(countdownService.isRunning, isFalse);
      });

      test('can be called multiple times safely', () {
        countdownService.stop();
        countdownService.stop();
        expect(countdownService.remainingSeconds, equals(0));
      });
    });

    group('skip', () {
      test('sets remaining seconds to zero', () async {
        countdownService.start(60);
        await Future.delayed(const Duration(milliseconds: 500));
        countdownService.skip();
        expect(countdownService.remainingSeconds, equals(0));
      });

      test('stops the countdown', () async {
        countdownService.start(60);
        await Future.delayed(const Duration(milliseconds: 500));
        countdownService.skip();
        expect(countdownService.isRunning, isFalse);
      });

      test('emits zero through stream', () async {
        final streamValues = <int>[];
        final subscription = countdownService.timerStream.listen((value) {
          streamValues.add(value);
        });

        countdownService.start(10);
        await Future.delayed(const Duration(milliseconds: 500));
        countdownService.skip();
        await Future.delayed(const Duration(milliseconds: 100));

        await subscription.cancel();
        expect(streamValues.last, equals(0));
      });
    });

    group('formattedTime', () {
      test('formats countdown time correctly', () {
        countdownService.start(125);
        expect(countdownService.formattedTime, equals('02:05'));
      });

      test('formats zero correctly', () {
        countdownService.start(0);
        expect(countdownService.formattedTime, equals('00:00'));
      });

      test('updates as countdown progresses', () async {
        countdownService.start(5);
        final format1 = countdownService.formattedTime;
        await Future.delayed(const Duration(milliseconds: 1100));
        final format2 = countdownService.formattedTime;
        expect(format1, isNot(equals(format2)));
      });
    });

    group('dispose', () {
      test('cancels countdown ticks when disposed', () async {
        countdownService.start(60);
        await Future.delayed(const Duration(milliseconds: 1100));
        final remainingBeforeDispose = countdownService.remainingSeconds;
        countdownService.dispose();
        await Future.delayed(const Duration(milliseconds: 1100));
        expect(countdownService.remainingSeconds, remainingBeforeDispose);
      });

      test('closes stream controller', () async {
        final streamDone = expectLater(countdownService.timerStream, emitsDone);
        countdownService.dispose();
        await streamDone;
      });
    });

    group('Edge Cases', () {
      test('handles countdown of 1 second', () async {
        countdownService.start(1);
        await Future.delayed(const Duration(milliseconds: 1500));
        expect(countdownService.remainingSeconds, equals(0));
        expect(countdownService.isRunning, isFalse);
      });

      test('handles very long countdown', () {
        countdownService.start(3600); // 1 hour
        expect(countdownService.remainingSeconds, equals(3600));
        expect(countdownService.formattedTime, equals('60:00'));
      });

      test('handles rapid start/stop cycles', () async {
        for (int i = 0; i < 5; i++) {
          countdownService.start(10);
          await Future.delayed(const Duration(milliseconds: 100));
          countdownService.stop();
        }
        expect(countdownService.remainingSeconds, equals(0));
        expect(countdownService.isRunning, isFalse);
      });
    });
  });
}
