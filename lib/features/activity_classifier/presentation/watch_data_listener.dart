import 'package:flowfit/models/heart_rate_data.dart';
import 'package:flowfit/models/sensor_batch.dart';
import 'package:flowfit/services/sensors/phone_data_listener.dart';

enum BpmSource { simulation, plugin, watch }

enum AccelSource { phone, simulation, watch }

abstract class ActivityWatchDataListener {
  Future<bool> startListening();
  Stream<HeartRateData> get heartRateStream;
  Stream<SensorBatch> get sensorBatchStream;
}

class PhoneActivityWatchDataListener implements ActivityWatchDataListener {
  PhoneActivityWatchDataListener(this._phoneListener);

  final PhoneDataListener _phoneListener;

  @override
  Future<bool> startListening() => _phoneListener.startListening();

  @override
  Stream<HeartRateData> get heartRateStream => _phoneListener.heartRateStream;

  @override
  Stream<SensorBatch> get sensorBatchStream => _phoneListener.sensorBatchStream;
}
