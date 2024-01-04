class SharingSettingsModel {
  String id;
  String sharerId;
  String accepterId;
  String status;

  SharingSettingsModel({required this.id, required this.sharerId, required this.accepterId, required this.status});

  factory SharingSettingsModel.fromMap(Map<String, dynamic> map, String id) {
    return SharingSettingsModel(
      id: id,
      sharerId: map['sharerId'] ?? '',
      accepterId: map['accepterId'] ?? '',
      status: map['status'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'sharerId': sharerId,
      'accepterId': accepterId,
      'status': status,
    };
  }
}
