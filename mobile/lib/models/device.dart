class AppDevice {
  final int id;
  final String deviceIdentifier;
  final String platform;
  final String deviceName;
  final bool isActive;
  final DateTime lastSeen;

  AppDevice({
    required this.id,
    required this.deviceIdentifier,
    required this.platform,
    required this.deviceName,
    required this.isActive,
    required this.lastSeen,
  });

  factory AppDevice.fromJson(Map<String, dynamic> json) => AppDevice(
        id: json['id'],
        deviceIdentifier: json['device_identifier'] ?? '',
        platform: json['platform'] ?? '',
        deviceName: json['device_name'] ?? '',
        isActive: json['is_active'] ?? true,
        lastSeen: DateTime.tryParse(json['last_seen'] ?? '') ?? DateTime.now(),
      );
}
