import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flowfit/services/phone_data_listener.dart';
import 'package:flowfit/models/sensor_error.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PhoneDataListener', () {
    late PhoneDataListener service;
    const methodChannel = MethodChannel('com.flowfit.phone/data');
    const eventChannel = EventChannel('com.flowfit.phone/heartrate');
    const sensorBatchEventChannel = EventChannel(
      'com.flowfit.phone/sensor_data',
    );

    setUp(() {
      service = PhoneDataListener();
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(methodChannel, null);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockStreamHandler(eventChannel, null);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockStreamHandler(sensorBatchEventChannel, null);
      service.dispose();
    });

    group('heartRateStream', () {
      test(
        'emits HeartRateData when valid data is received from watch',
        () async {
          final testData = {
            'bpm': 72,
            'timestamp': DateTime.now().millisecondsSinceEpoch,
            'status': 'active',
            'ibiValues': [850, 845, 855],
          };

          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
              .setMockStreamHandler(
                eventChannel,
                MockStreamHandler.inline(
                  onListen: (arguments, events) {
                    events.success(testData);
                    return;
                  },
                ),
              );

          final stream = service.heartRateStream;
          final heartRateData = await stream.first;

          expect(heartRateData.bpm, 72);
          expect(heartRateData.status.name, 'active');
          expect(heartRateData.ibiValues.length, 3);
        },
      );

      test('emits multiple HeartRateData events from watch', () async {
        final testData1 = {
          'bpm': 70,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'status': 'active',
          'ibiValues': [],
        };
        final testData2 = {
          'bpm': 75,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'status': 'active',
          'ibiValues': [],
        };

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockStreamHandler(
              eventChannel,
              MockStreamHandler.inline(
                onListen: (arguments, events) {
                  events.success(testData1);
                  events.success(testData2);
                  return;
                },
              ),
            );

        final stream = service.heartRateStream;
        final heartRateList = await stream.take(2).toList();

        expect(heartRateList.length, 2);
        expect(heartRateList[0].bpm, 70);
        expect(heartRateList[1].bpm, 75);
      });

      test('throws SensorError when null event is received', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockStreamHandler(
              eventChannel,
              MockStreamHandler.inline(
                onListen: (arguments, events) {
                  events.success(null);
                  return;
                },
              ),
            );

        final stream = service.heartRateStream;

        expect(
          () => stream.first,
          throwsA(
            isA<SensorError>().having(
              (e) => e.message,
              'message',
              'Received null data from watch',
            ),
          ),
        );
      });

      test('throws SensorError when non-Map event is received', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockStreamHandler(
              eventChannel,
              MockStreamHandler.inline(
                onListen: (arguments, events) {
                  events.success('invalid string data');
                  return;
                },
              ),
            );

        final stream = service.heartRateStream;

        expect(
          () => stream.first,
          throwsA(
            isA<SensorError>().having(
              (e) => e.message,
              'message',
              'Invalid data format from watch',
            ),
          ),
        );
      });

      test(
        'throws SensorError when required field "timestamp" is missing',
        () async {
          final invalidData = {
            'bpm': 72,
            'status': 'active',
            // Missing 'timestamp'
          };

          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
              .setMockStreamHandler(
                eventChannel,
                MockStreamHandler.inline(
                  onListen: (arguments, events) {
                    events.success(invalidData);
                    return;
                  },
                ),
              );

          final stream = service.heartRateStream;

          expect(
            () => stream.first,
            throwsA(
              isA<SensorError>().having(
                (e) => e.message,
                'message',
                'Malformed JSON from watch',
              ),
            ),
          );
        },
      );

      test(
        'throws SensorError when required field "status" is missing',
        () async {
          final invalidData = {
            'bpm': 72,
            'timestamp': DateTime.now().millisecondsSinceEpoch,
            // Missing 'status'
          };

          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
              .setMockStreamHandler(
                eventChannel,
                MockStreamHandler.inline(
                  onListen: (arguments, events) {
                    events.success(invalidData);
                    return;
                  },
                ),
              );

          final stream = service.heartRateStream;

          expect(
            () => stream.first,
            throwsA(
              isA<SensorError>().having(
                (e) => e.message,
                'message',
                'Malformed JSON from watch',
              ),
            ),
          );
        },
      );

      test('throws SensorError when timestamp has invalid type', () async {
        final invalidData = {
          'bpm': 72,
          'timestamp': 'not an integer',
          'status': 'active',
        };

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockStreamHandler(
              eventChannel,
              MockStreamHandler.inline(
                onListen: (arguments, events) {
                  events.success(invalidData);
                  return;
                },
              ),
            );

        final stream = service.heartRateStream;

        expect(
          () => stream.first,
          throwsA(
            isA<SensorError>().having(
              (e) => e.message,
              'message',
              'Invalid timestamp field type',
            ),
          ),
        );
      });

      test('throws SensorError when status has invalid type', () async {
        final invalidData = {
          'bpm': 72,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'status': 123, // Should be string
        };

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockStreamHandler(
              eventChannel,
              MockStreamHandler.inline(
                onListen: (arguments, events) {
                  events.success(invalidData);
                  return;
                },
              ),
            );

        final stream = service.heartRateStream;

        expect(
          () => stream.first,
          throwsA(
            isA<SensorError>().having(
              (e) => e.message,
              'message',
              'Invalid status field type',
            ),
          ),
        );
      });

      test('throws SensorError when bpm has invalid type', () async {
        final invalidData = {
          'bpm': 'seventy-two', // Should be int or null
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'status': 'active',
        };

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockStreamHandler(
              eventChannel,
              MockStreamHandler.inline(
                onListen: (arguments, events) {
                  events.success(invalidData);
                  return;
                },
              ),
            );

        final stream = service.heartRateStream;

        expect(
          () => stream.first,
          throwsA(
            isA<SensorError>().having(
              (e) => e.message,
              'message',
              'Invalid bpm field type',
            ),
          ),
        );
      });

      test('throws SensorError when ibiValues has invalid type', () async {
        final invalidData = {
          'bpm': 72,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'status': 'active',
          'ibiValues': 'not a list',
        };

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockStreamHandler(
              eventChannel,
              MockStreamHandler.inline(
                onListen: (arguments, events) {
                  events.success(invalidData);
                  return;
                },
              ),
            );

        final stream = service.heartRateStream;

        expect(
          () => stream.first,
          throwsA(
            isA<SensorError>().having(
              (e) => e.message,
              'message',
              'Invalid ibiValues field type',
            ),
          ),
        );
      });

      test('accepts null bpm value', () async {
        final testData = {
          'bpm': null,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'status': 'active',
          'ibiValues': [],
        };

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockStreamHandler(
              eventChannel,
              MockStreamHandler.inline(
                onListen: (arguments, events) {
                  events.success(testData);
                  return;
                },
              ),
            );

        final stream = service.heartRateStream;
        final heartRateData = await stream.first;

        expect(heartRateData.bpm, isNull);
        expect(heartRateData.status.name, 'active');
      });

      test('handles error in JSON parsing', () async {
        final invalidData = {
          'bpm': 72,
          'timestamp': 'invalid',
          'status': 'active',
        };

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockStreamHandler(
              eventChannel,
              MockStreamHandler.inline(
                onListen: (arguments, events) {
                  events.success(invalidData);
                  return;
                },
              ),
            );

        final stream = service.heartRateStream;

        expect(() => stream.first, throwsA(isA<SensorError>()));
      });

      test('handles stream cancellation', () async {
        var cancelCalled = false;

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockStreamHandler(
              eventChannel,
              MockStreamHandler.inline(
                onListen: (arguments, events) {
                  return;
                },
                onCancel: (arguments) {
                  cancelCalled = true;
                  return;
                },
              ),
            );

        final stream = service.heartRateStream;
        final subscription = stream.listen((_) {});
        await subscription.cancel();

        expect(cancelCalled, true);
      });
    });

    group('startListening', () {
      test('returns true when listening starts successfully', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(methodChannel, (
              MethodCall methodCall,
            ) async {
              if (methodCall.method == 'startListening') {
                return true;
              }
              return null;
            });

        final result = await service.startListening();
        expect(result, true);
      });

      test('returns false when listening fails to start', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(methodChannel, (
              MethodCall methodCall,
            ) async {
              if (methodCall.method == 'startListening') {
                return false;
              }
              return null;
            });

        final result = await service.startListening();
        expect(result, false);
      });

      test('returns false on PlatformException', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(methodChannel, (
              MethodCall methodCall,
            ) async {
              if (methodCall.method == 'startListening') {
                throw PlatformException(
                  code: 'ERROR',
                  message: 'Failed to start',
                );
              }
              return null;
            });

        final result = await service.startListening();
        expect(result, false);
      });
    });

    group('stopListening', () {
      test('completes successfully', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(methodChannel, (
              MethodCall methodCall,
            ) async {
              if (methodCall.method == 'stopListening') {
                return null;
              }
              return null;
            });

        await expectLater(service.stopListening(), completes);
      });

      test('handles PlatformException gracefully', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(methodChannel, (
              MethodCall methodCall,
            ) async {
              if (methodCall.method == 'stopListening') {
                throw PlatformException(
                  code: 'ERROR',
                  message: 'Failed to stop',
                );
              }
              return null;
            });

        // Should not throw, just log the error
        await expectLater(service.stopListening(), completes);
      });
    });

    group('isWatchConnected', () {
      test('returns true when watch is connected', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(methodChannel, (
              MethodCall methodCall,
            ) async {
              if (methodCall.method == 'isWatchConnected') {
                return true;
              }
              return null;
            });

        final result = await service.isWatchConnected();
        expect(result, true);
      });

      test('returns false when watch is not connected', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(methodChannel, (
              MethodCall methodCall,
            ) async {
              if (methodCall.method == 'isWatchConnected') {
                return false;
              }
              return null;
            });

        final result = await service.isWatchConnected();
        expect(result, false);
      });

      test('returns false on PlatformException', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(methodChannel, (
              MethodCall methodCall,
            ) async {
              if (methodCall.method == 'isWatchConnected') {
                throw PlatformException(
                  code: 'ERROR',
                  message: 'Failed to check',
                );
              }
              return null;
            });

        final result = await service.isWatchConnected();
        expect(result, false);
      });
    });

    group('sensorBatchStream', () {
      test(
        'emits SensorBatch when valid data is received from watch',
        () async {
          final testData = {
            'type': 'sensor_batch',
            'timestamp': 1234567890,
            'bpm': 75,
            'sample_rate': 32,
            'count': 3,
            'accelerometer': [
              [0.12, -0.45, 9.81],
              [0.15, -0.42, 9.79],
              [0.13, -0.44, 9.80],
            ],
          };

          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
              .setMockStreamHandler(
                sensorBatchEventChannel,
                MockStreamHandler.inline(
                  onListen: (arguments, events) {
                    events.success(testData);
                    return;
                  },
                ),
              );

          final stream = service.sensorBatchStream;
          final sensorBatch = await stream.first;

          expect(sensorBatch.sampleCount, 3);
          expect(sensorBatch.timestamp, 1234567890);
          expect(sensorBatch.samples.length, 3);
          expect(sensorBatch.samples[0].length, 4); // [accX, accY, accZ, bpm]
          expect(sensorBatch.samples[0][3], 75.0); // BPM value
        },
      );

      test('constructs 4-feature vectors correctly', () async {
        final testData = {
          'type': 'sensor_batch',
          'timestamp': 1234567890,
          'bpm': 80,
          'sample_rate': 32,
          'count': 2,
          'accelerometer': [
            [1.0, 2.0, 3.0],
            [4.0, 5.0, 6.0],
          ],
        };

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockStreamHandler(
              sensorBatchEventChannel,
              MockStreamHandler.inline(
                onListen: (arguments, events) {
                  events.success(testData);
                  return;
                },
              ),
            );

        final stream = service.sensorBatchStream;
        final sensorBatch = await stream.first;

        // Verify first sample
        expect(sensorBatch.samples[0][0], 1.0); // accX
        expect(sensorBatch.samples[0][1], 2.0); // accY
        expect(sensorBatch.samples[0][2], 3.0); // accZ
        expect(sensorBatch.samples[0][3], 80.0); // bpm

        // Verify second sample
        expect(sensorBatch.samples[1][0], 4.0); // accX
        expect(sensorBatch.samples[1][1], 5.0); // accY
        expect(sensorBatch.samples[1][2], 6.0); // accZ
        expect(sensorBatch.samples[1][3], 80.0); // bpm
      });

      test('throws SensorError when null event is received', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockStreamHandler(
              sensorBatchEventChannel,
              MockStreamHandler.inline(
                onListen: (arguments, events) {
                  events.success(null);
                  return;
                },
              ),
            );

        final stream = service.sensorBatchStream;

        expect(
          () => stream.first,
          throwsA(
            isA<SensorError>().having(
              (e) => e.message,
              'message',
              'Received null data from watch',
            ),
          ),
        );
      });

      test('throws SensorError when non-Map event is received', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockStreamHandler(
              sensorBatchEventChannel,
              MockStreamHandler.inline(
                onListen: (arguments, events) {
                  events.success('invalid string data');
                  return;
                },
              ),
            );

        final stream = service.sensorBatchStream;

        expect(
          () => stream.first,
          throwsA(
            isA<SensorError>().having(
              (e) => e.message,
              'message',
              'Invalid data format from watch',
            ),
          ),
        );
      });

      test(
        'throws SensorError when required field "type" is missing',
        () async {
          final invalidData = {
            'timestamp': 1234567890,
            'bpm': 75,
            'sample_rate': 32,
            'count': 1,
            'accelerometer': [
              [0.1, 0.2, 0.3],
            ],
          };

          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
              .setMockStreamHandler(
                sensorBatchEventChannel,
                MockStreamHandler.inline(
                  onListen: (arguments, events) {
                    events.success(invalidData);
                    return;
                  },
                ),
              );

          final stream = service.sensorBatchStream;

          expect(
            () => stream.first,
            throwsA(
              isA<SensorError>().having(
                (e) => e.message,
                'message',
                'Malformed sensor batch JSON from watch',
              ),
            ),
          );
        },
      );

      test(
        'throws SensorError when required field "accelerometer" is missing',
        () async {
          final invalidData = {
            'type': 'sensor_batch',
            'timestamp': 1234567890,
            'bpm': 75,
            'sample_rate': 32,
            'count': 1,
          };

          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
              .setMockStreamHandler(
                sensorBatchEventChannel,
                MockStreamHandler.inline(
                  onListen: (arguments, events) {
                    events.success(invalidData);
                    return;
                  },
                ),
              );

          final stream = service.sensorBatchStream;

          expect(
            () => stream.first,
            throwsA(
              isA<SensorError>().having(
                (e) => e.message,
                'message',
                'Malformed sensor batch JSON from watch',
              ),
            ),
          );
        },
      );

      test(
        'throws SensorError when count does not match accelerometer array length',
        () async {
          final invalidData = {
            'type': 'sensor_batch',
            'timestamp': 1234567890,
            'bpm': 75,
            'sample_rate': 32,
            'count': 5, // Says 5 but only has 2
            'accelerometer': [
              [0.1, 0.2, 0.3],
              [0.4, 0.5, 0.6],
            ],
          };

          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
              .setMockStreamHandler(
                sensorBatchEventChannel,
                MockStreamHandler.inline(
                  onListen: (arguments, events) {
                    events.success(invalidData);
                    return;
                  },
                ),
              );

          final stream = service.sensorBatchStream;

          expect(
            () => stream.first,
            throwsA(
              isA<SensorError>().having(
                (e) => e.message,
                'message',
                'Count mismatch in sensor batch',
              ),
            ),
          );
        },
      );

      test('throws SensorError when bpm has invalid type', () async {
        final invalidData = {
          'type': 'sensor_batch',
          'timestamp': 1234567890,
          'bpm': 'seventy-five', // Should be int
          'sample_rate': 32,
          'count': 1,
          'accelerometer': [
            [0.1, 0.2, 0.3],
          ],
        };

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockStreamHandler(
              sensorBatchEventChannel,
              MockStreamHandler.inline(
                onListen: (arguments, events) {
                  events.success(invalidData);
                  return;
                },
              ),
            );

        final stream = service.sensorBatchStream;

        expect(
          () => stream.first,
          throwsA(
            isA<SensorError>().having(
              (e) => e.message,
              'message',
              'Invalid bpm field type',
            ),
          ),
        );
      });

      test('throws SensorError when accelerometer has invalid type', () async {
        final invalidData = {
          'type': 'sensor_batch',
          'timestamp': 1234567890,
          'bpm': 75,
          'sample_rate': 32,
          'count': 1,
          'accelerometer': 'not a list',
        };

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockStreamHandler(
              sensorBatchEventChannel,
              MockStreamHandler.inline(
                onListen: (arguments, events) {
                  events.success(invalidData);
                  return;
                },
              ),
            );

        final stream = service.sensorBatchStream;

        expect(
          () => stream.first,
          throwsA(
            isA<SensorError>().having(
              (e) => e.message,
              'message',
              'Invalid accelerometer field type',
            ),
          ),
        );
      });

      test('handles malformed JSON and continues listening', () async {
        final invalidData = {
          'type': 'sensor_batch',
          'timestamp': 'invalid', // Wrong type
          'bpm': 75,
          'sample_rate': 32,
          'count': 1,
          'accelerometer': [
            [0.1, 0.2, 0.3],
          ],
        };

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockStreamHandler(
              sensorBatchEventChannel,
              MockStreamHandler.inline(
                onListen: (arguments, events) {
                  events.success(invalidData);
                  return;
                },
              ),
            );

        final stream = service.sensorBatchStream;

        expect(() => stream.first, throwsA(isA<SensorError>()));
      });
    });

    group('dispose', () {
      test('disposes resources without error', () {
        final testService = PhoneDataListener();
        expect(() => testService.dispose(), returnsNormally);
      });
    });
  });
}
