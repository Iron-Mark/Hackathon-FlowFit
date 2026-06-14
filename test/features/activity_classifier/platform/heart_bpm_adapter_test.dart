import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flowfit/features/activity_classifier/platform/heart_bpm_adapter.dart';

void main() {
  group('HeartBpmAdapter', () {
    late HeartBpmAdapter adapter;

    setUp(() {
      adapter = HeartBpmAdapter();
    });

    tearDown(() {
      adapter.dispose();
    });

    test('setManualBpm updates currentBpm and emits on stream', () async {
      final values = <int?>[];
      final sub = adapter.bpmStream.listen(values.add);

      adapter.setManualBpm(75);
      await Future.delayed(const Duration(milliseconds: 10));

      expect(adapter.currentBpm, equals(75));
      expect(values.last, equals(75));

      await sub.cancel();
    });

    test(
      'connectExternalStream subscribes to external stream and publishes',
      () async {
        final controller = StreamController<int>();
        final values = <int?>[];
        final sub = adapter.bpmStream.listen(values.add);

        adapter.connectExternalStream(controller.stream);
        controller.add(60);
        controller.add(62);
        await Future.delayed(const Duration(milliseconds: 10));

        expect(adapter.currentBpm, equals(62));
        expect(values, containsAll([60, 62]));

        await controller.close();
        await sub.cancel();
      },
    );
  });
}
