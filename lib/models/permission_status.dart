enum WatchPermissionStatus {
  granted,
  denied,
  notDetermined;

  String toJson() => name;

  static WatchPermissionStatus fromJson(String json) {
    return WatchPermissionStatus.values.firstWhere(
      (status) => status.name == json,
      orElse: () => WatchPermissionStatus.notDetermined,
    );
  }
}
