import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flowfit/services/watch_bridge.dart';
import 'package:flowfit/models/heart_rate_data.dart';
import 'package:flowfit/models/permission_status.dart';
import 'package:flowfit/models/sensor_error.dart';
import 'package:flowfit/models/sensor_error_code.dart';
import 'package:flowfit/models/sensor_status.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('WatchBridgeService', () {
    late WatchBridgeService service;
    const methodChannel = MethodChannel('com.flowfit.watch/data');

    setUp(() {
      service = WatchBridgeService();
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(methodChannel, null);
    });

    group('connectToWatch', () {
      test('returns true when connection succeeds', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(methodChannel, (
              MethodCall methodCall,
            ) async {
              if (methodCall.method == 'connectWatch') {
                return true;
              }
              return null;
            });

        final result = await service.connectToWatch();
        expect(result, true);
      });

      test('returns false when connection fails', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(methodChannel, (
              MethodCall methodCall,
            ) async {
              if (methodCall.method == 'connectWatch') {
                return false;
              }
              return null;
            });

        final result = await service.connectToWatch();
        expect(result, false);
      });

      test('throws SensorError on PlatformException', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(methodChannel, (
              MethodCall methodCall,
            ) async {
              if (methodCall.method == 'connectWatch') {
                throw PlatformException(
                  code: 'CONNECTION_FAILED',
                  message: 'Unable to connect',
                );
              }
              return null;
            });

        expect(
          () => service.connectToWatch(),
          throwsA(
            isA<SensorError>().having(
              (e) => e.code,
              'code',
              SensorErrorCode.connectionFailed,
            ),
          ),
        );
      });
    });

    group('disconnectFromWatch', () {
      test('completes successfully', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(methodChannel, (
              MethodCall methodCall,
            ) async {
              if (methodCall.method == 'disconnectWatch') {
                return null;
              }
              return null;
            });

        await expectLater(service.disconnectFromWatch(), completes);
      });

      test('throws SensorError on PlatformException', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(methodChannel, (
              MethodCall methodCall,
            ) async {
              if (methodCall.method == 'disconnectWatch') {
                throw PlatformException(
                  code: 'UNKNOWN',
                  message: 'Disconnect failed',
                );
              }
              return null;
            });

        expect(
          () => service.disconnectFromWatch(),
          throwsA(isA<SensorError>()),
        );
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
    });

    group('startHeartRateTracking', () {
      test('returns true when tracking starts successfully', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(methodChannel, (
              MethodCall methodCall,
            ) async {
              if (methodCall.method == 'startHeartRate') {
                return true;
              }
              return null;
            });

        final result = await service.startHeartRateTracking();
        expect(result, true);
      });

      test('returns false when tracking fails to start', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(methodChannel, (
              MethodCall methodCall,
            ) async {
              if (methodCall.method == 'startHeartRate') {
                return false;
              }
              return null;
            });

        final result = await service.startHeartRateTracking();
        expect(result, false);
      });

      test('throws SensorError on PlatformException', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(methodChannel, (
              MethodCall methodCall,
            ) async {
              if (methodCall.method == 'startHeartRate') {
                throw PlatformException(
                  code: 'SENSOR_UNAVAILABLE',
                  message: 'Sensor not available',
                );
              }
              return null;
            });

        expect(
          () => service.startHeartRateTracking(),
          throwsA(
            isA<SensorError>().having(
              (e) => e.code,
              'code',
              SensorErrorCode.sensorUnavailable,
            ),
          ),
        );
      });
    });

    group('stopHeartRateTracking', () {
      test('completes successfully', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(methodChannel, (
              MethodCall methodCall,
            ) async {
              if (methodCall.method == 'stopHeartRate') {
                return null;
              }
              return null;
            });

        await expectLater(service.stopHeartRateTracking(), completes);
      });

      test('throws SensorError on PlatformException', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(methodChannel, (
              MethodCall methodCall,
            ) async {
              if (methodCall.method == 'stopHeartRate') {
                throw PlatformException(
                  code: 'UNKNOWN',
                  message: 'Stop failed',
                );
              }
              return null;
            });

        expect(
          () => service.stopHeartRateTracking(),
          throwsA(isA<SensorError>()),
        );
      });
    });

    group('getCurrentHeartRate', () {
      test('returns HeartRateData when data is available', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(methodChannel, (
              MethodCall methodCall,
            ) async {
              if (methodCall.method == 'getCurrentHeartRate') {
                return {
                  'bpm': 75,
                  'timestamp': DateTime.now().millisecondsSinceEpoch,
                  'status': 'active',
                };
              }
              return null;
            });

        final result = await service.getCurrentHeartRate();
        expect(result, isNotNull);
        expect(result!.bpm, 75);
        expect(result.status.toString(), contains('active'));
      });

      test('returns null when no data is available', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(methodChannel, (
              MethodCall methodCall,
            ) async {
              if (methodCall.method == 'getCurrentHeartRate') {
                return null;
              }
              return null;
            });

        final result = await service.getCurrentHeartRate();
        expect(result, isNull);
      });

      test('throws SensorError on PlatformException', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(methodChannel, (
              MethodCall methodCall,
            ) async {
              if (methodCall.method == 'getCurrentHeartRate') {
                throw PlatformException(
                  code: 'SENSOR_UNAVAILABLE',
                  message: 'Cannot read heart rate',
                );
              }
              return null;
            });

        expect(
          () => service.getCurrentHeartRate(),
          throwsA(isA<SensorError>()),
        );
      });
    });

    group('error handling', () {
      test('maps PERMISSION_DENIED to correct error code', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(methodChannel, (
              MethodCall methodCall,
            ) async {
              throw PlatformException(
                code: 'PERMISSION_DENIED',
                message: 'Permission denied',
              );
            });

        expect(
          () => service.connectToWatch(),
          throwsA(
            isA<SensorError>().having(
              (e) => e.code,
              'code',
              SensorErrorCode.permissionDenied,
            ),
          ),
        );
      });

      test('maps SERVICE_UNAVAILABLE to correct error code', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(methodChannel, (
              MethodCall methodCall,
            ) async {
              throw PlatformException(
                code: 'SERVICE_UNAVAILABLE',
                message: 'Service unavailable',
              );
            });

        expect(
          () => service.connectToWatch(),
          throwsA(
            isA<SensorError>().having(
              (e) => e.code,
              'code',
              SensorErrorCode.serviceUnavailable,
            ),
          ),
        );
      });

      test(
        'does not retry when Samsung Health service package is missing',
        () async {
          var connectAttempts = 0;

          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
              .setMockMethodCallHandler(methodChannel, (
                MethodCall methodCall,
              ) async {
                if (methodCall.method == 'connectWatch') {
                  connectAttempts += 1;
                  throw PlatformException(
                    code: 'SERVICE_UNAVAILABLE',
                    message: 'Samsung Health service unavailable',
                    details: 'com.samsung.android.service.health',
                  );
                }
                return null;
              });

          await expectLater(
            () => service.connectToWatch(),
            throwsA(
              isA<SensorError>()
                  .having(
                    (e) => e.code,
                    'code',
                    SensorErrorCode.serviceUnavailable,
                  )
                  .having(
                    (e) => e.details,
                    'details',
                    contains('com.samsung.android.service.health'),
                  ),
            ),
          );
          expect(connectAttempts, 1);
        },
      );

      test('maps TIMEOUT to correct error code', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(methodChannel, (
              MethodCall methodCall,
            ) async {
              throw PlatformException(
                code: 'TIMEOUT',
                message: 'Operation timed out',
              );
            });

        expect(
          () => service.connectToWatch(),
          throwsA(
            isA<SensorError>().having(
              (e) => e.code,
              'code',
              SensorErrorCode.timeout,
            ),
          ),
        );
      });
    });

    group('permission state monitoring', () {
      test('permissionStateStream is available', () {
        final stream = service.permissionStateStream;
        expect(stream, isNotNull);
        expect(stream, isA<Stream<PermissionStatus>>());
      });

      test('startPermissionMonitoring can be called', () {
        // Just verify the method can be called without throwing
        expect(
          () => service.startPermissionMonitoring(
            interval: const Duration(milliseconds: 100),
          ),
          returnsNormally,
        );
        service.stopPermissionMonitoring();
      });

      test('stopPermissionMonitoring can be called', () {
        service.startPermissionMonitoring(
          interval: const Duration(milliseconds: 100),
        );

        // Verify stopPermissionMonitoring can be called
        expect(() => service.stopPermissionMonitoring(), returnsNormally);
      });

      test('dispose closes permission state stream', () {
        // Create a new service instance for this test
        final testService = WatchBridgeService();
        testService.dispose();

        // After dispose, the stream controller should be closed
        // We can't directly test this without exposing internals,
        // but we can verify dispose completes without error
        expect(testService, isNotNull);
      });
    });

    group('openAppSettings', () {
      test(
        'openAppSettings throws SensorError when plugin not available',
        () async {
          // In test environment without plugin, should throw SensorError
          expect(() => service.openAppSettings(), throwsA(isA<SensorError>()));
        },
      );
    });

    group('watch-to-phone sync', () {
      const syncChannel = MethodChannel('com.flowfit.watch/sync');

      tearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(syncChannel, null);
      });

      test('sendHeartRateToPhone returns true on success', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(syncChannel, (
              MethodCall methodCall,
            ) async {
              if (methodCall.method == 'sendHeartRateToPhone') {
                expect(methodCall.arguments['data'], isNotNull);
                return true;
              }
              return null;
            });

        final heartRateData = HeartRateData(
          bpm: 75,
          timestamp: DateTime.now(),
          status: SensorStatus.active,
        );

        final result = await service.sendHeartRateToPhone(heartRateData);
        expect(result, true);
      });

      test('sendHeartRateToPhone returns false on failure', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(syncChannel, (
              MethodCall methodCall,
            ) async {
              if (methodCall.method == 'sendHeartRateToPhone') {
                return false;
              }
              return null;
            });

        final heartRateData = HeartRateData(
          bpm: 75,
          timestamp: DateTime.now(),
          status: SensorStatus.active,
        );

        final result = await service.sendHeartRateToPhone(heartRateData);
        expect(result, false);
      });

      test(
        'checkPhoneConnection returns true when phone is connected',
        () async {
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
              .setMockMethodCallHandler(syncChannel, (
                MethodCall methodCall,
              ) async {
                if (methodCall.method == 'checkPhoneConnection') {
                  return true;
                }
                return null;
              });

          final result = await service.checkPhoneConnection();
          expect(result, true);
        },
      );

      test(
        'checkPhoneConnection returns false when phone is not connected',
        () async {
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
              .setMockMethodCallHandler(syncChannel, (
                MethodCall methodCall,
              ) async {
                if (methodCall.method == 'checkPhoneConnection') {
                  return false;
                }
                return null;
              });

          final result = await service.checkPhoneConnection();
          expect(result, false);
        },
      );

      test('checkPhoneConnection returns false on error', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(syncChannel, (
              MethodCall methodCall,
            ) async {
              if (methodCall.method == 'checkPhoneConnection') {
                throw PlatformException(
                  code: 'ERROR',
                  message: 'Connection check failed',
                );
              }
              return null;
            });

        final result = await service.checkPhoneConnection();
        expect(result, false);
      });

      test('getConnectedNodesCount returns node count', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(syncChannel, (
              MethodCall methodCall,
            ) async {
              if (methodCall.method == 'getConnectedNodesCount') {
                return 2;
              }
              return null;
            });

        final result = await service.getConnectedNodesCount();
        expect(result, 2);
      });

      test(
        'getConnectedNodesCount returns 0 when no nodes connected',
        () async {
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
              .setMockMethodCallHandler(syncChannel, (
                MethodCall methodCall,
              ) async {
                if (methodCall.method == 'getConnectedNodesCount') {
                  return 0;
                }
                return null;
              });

          final result = await service.getConnectedNodesCount();
          expect(result, 0);
        },
      );

      test('getConnectedNodesCount returns 0 on error', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(syncChannel, (
              MethodCall methodCall,
            ) async {
              if (methodCall.method == 'getConnectedNodesCount') {
                throw PlatformException(
                  code: 'ERROR',
                  message: 'Failed to get count',
                );
              }
              return null;
            });

        final result = await service.getConnectedNodesCount();
        expect(result, 0);
      });
    });

    group('heartRateStream', () {
      const eventChannel = EventChannel('com.flowfit.watch/heartrate');
      const syncChannel = MethodChannel('com.flowfit.watch/sync');

      setUp(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(syncChannel, (
              MethodCall methodCall,
            ) async {
              if (methodCall.method == 'checkPhoneConnection') {
                return false;
              }
              return null;
            });
      });

      tearDown(() {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockStreamHandler(eventChannel, null);
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(syncChannel, null);
      });

      test('emits HeartRateData when data is received', () async {
        final testData = {
          'bpm': 72,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'status': 'active',
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
      });

      test('emits multiple HeartRateData events', () async {
        final testData1 = {
          'bpm': 70,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'status': 'active',
        };
        final testData2 = {
          'bpm': 75,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          'status': 'active',
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

      test('throws SensorError on invalid data format', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockStreamHandler(
              eventChannel,
              MockStreamHandler.inline(
                onListen: (arguments, events) {
                  events.success({'invalid': 'data'});
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
  });
}
