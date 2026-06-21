/// Represents the connection state between watch and phone
class ConnectionState {
  /// Whether the phone is connected to the watch
  final bool isConnected;

  /// Number of connected nodes
  final int nodeCount;

  /// Last successful sync timestamp
  final DateTime? lastSyncTime;

  /// Error message if connection failed
  final String? errorMessage;

  ConnectionState({
    required this.isConnected,
    this.nodeCount = 0,
    this.lastSyncTime,
    this.errorMessage,
  });

  /// Create a connected state
  factory ConnectionState.connected({
    int nodeCount = 1,
    DateTime? lastSyncTime,
  }) {
    return ConnectionState(
      isConnected: true,
      nodeCount: nodeCount,
      lastSyncTime: lastSyncTime,
    );
  }

  /// Create a disconnected state
  factory ConnectionState.disconnected({String? errorMessage}) {
    return ConnectionState(
      isConnected: false,
      nodeCount: 0,
      errorMessage: errorMessage,
    );
  }

  /// Create a copy with updated fields
  ConnectionState copyWith({
    bool? isConnected,
    int? nodeCount,
    DateTime? lastSyncTime,
    String? errorMessage,
  }) {
    return ConnectionState(
      isConnected: isConnected ?? this.isConnected,
      nodeCount: nodeCount ?? this.nodeCount,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  String toString() {
    return 'ConnectionState(isConnected: $isConnected, nodeCount: $nodeCount, '
        'lastSyncTime: $lastSyncTime, errorMessage: $errorMessage)';
  }
}
