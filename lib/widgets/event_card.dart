// lib/widgets/event_card.dart
// EventCard 위젯 정의
import 'package:flutter/material.dart';
import 'package:last_dear_us/models/event_model.dart';
import 'package:last_dear_us/utils/date_utils.dart' as custom_date_utils;

class EventCard extends StatelessWidget {
  final EventModel event;

  EventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(event.title),
        subtitle: Text(
            "${custom_date_utils.DateUtils.formatDate(event.startTime)} - ${custom_date_utils.DateUtils.formatDate(event.endTime)}" ),
      ),
    );
  }
}