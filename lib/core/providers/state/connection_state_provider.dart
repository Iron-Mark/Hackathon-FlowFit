import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data_sources/watch_data_source_provider.dart';

/// Watch connection state provider
///
/// Tracks whether the phone is connected to the watch.
final watchConnectionStateProvider = StreamProvider<bool>((ref) {
  final watchBridge = ref.watch(watchDataSourceProvider);
  return watchBridge.connectionStateStream.map((state) {
    return state.isConnected;
  });
});

/// Connection status notifier
///
/// Manages manual connection/disconnection to the watch.
final connectionControlProvider =
    StateNotifierProvider<ConnectionControlNotifier, ConnectionState>((ref) {
      final watchBridge = ref.watch(watchDataSourceProvider);
      return ConnectionControlNotifier(watchBridge);
    });

/// Connection state
enum ConnectionState { disconnected, connecting, connected, error }

/// Notifier for connection control
class ConnectionControlNotifier extends StateNotifier<ConnectionState> {
  final dynamic watchBridge;

  ConnectionControlNotifier(this.watchBridge)
    : super(ConnectionState.disconnected);

  /// Connect to watch
  Future<void> connect() async {
    state = ConnectionState.connecting;
    try {
      await watchBridge.connectToWatch();
      state = ConnectionState.connected;
    } catch (e) {
      state = ConnectionState.error;
      rethrow;
    }
  }

  /// Disconnect from watch
  Future<void> disconnect() async {
    try {
      await watchBridge.disconnectFromWatch();
      state = ConnectionState.disconnected;
    } catch (e) {
      state = ConnectionState.error;
      rethrow;
    }
  }
}
