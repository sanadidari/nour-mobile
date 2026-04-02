import 'package:uuid/uuid.dart';

class Mission {
  final String id;
  final String title;
  final String? description;
  final String status;
  final String? locationName;
  final DateTime createdAt;

  Mission({
    required this.id,
    required this.title,
    this.description,
    required this.status,
    this.locationName,
    required this.createdAt,
  });

  factory Mission.fromJson(Map<String, dynamic> json) {
    return Mission(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      status: json['status'],
      locationName: json['location_name'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'status': status,
      'location_name': locationName,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
