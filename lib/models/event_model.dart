// Event 모델 정의
import 'package:cloud_firestore/cloud_firestore.dart';

class EventModel {
  final String eventId;
  final String title;
  final DateTime startTime;
  final DateTime endTime;
  final String userId;
  final String description;

  EventModel({
    required this.eventId,
    required this.title,
    required this.startTime,
    required this.endTime,
    required this.userId,
    required this.description,
  });

  factory EventModel.fromMap(Map<String, dynamic> data) {
    return EventModel(
      eventId: data['eventId'] ?? '',
      title: data['title'] ?? '',
      startTime: (data['startTime'] as Timestamp).toDate(),
      endTime: (data['endTime'] as Timestamp).toDate(),
      userId: data['userId'] ?? '',
      description: data['description'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'eventId': eventId,
      'title': title,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'userId': userId,
      'description': description,
    };
  }

  EventModel copyWith({
    String? eventId,
    String? title,
    DateTime? startTime,
    DateTime? endTime,
    String? userId,
    String? description,
  }) {
    return EventModel(
      eventId: eventId ?? this.eventId,
      title: title ?? this.title,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      userId: userId ?? this.userId,
      description: description ?? this.description,
    );
  }
}

