import 'package:flutter/material.dart';

class Event {
  Event({
    this.columnIndex = 0,
    required this.startTime,
    required this.endTime,
    this.title,
    this.description,
    this.data,
    this.eventType = Event.defaultType,
    this.color = Colors.blue,
    this.textColor = Colors.white,
  });

  static const String defaultType = "default";

  final int columnIndex;
  final DateTime startTime;
  final DateTime endTime;
  final String? title;
  final String? description;
  final Color color;
  final Color textColor;
  final Object? data;
  final Object eventType;

  Event copyWith({
    final int? columnIndex,
    final DateTime? startTime,
    final DateTime? endTime,
    final String? title,
    final String? description,
    final Color? color,
    final Color? textColor,
    final Object? data,
    final Object? eventType,
  }) {
    return Event(
      columnIndex: columnIndex ?? this.columnIndex,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      title: title ?? this.title,
      description: description ?? this.description,
      color: color ?? this.color,
      textColor: textColor ?? this.textColor,
      data: data ?? this.data,
      eventType: eventType ?? this.eventType,
    );
  }
}

class FullDayEvent {
  FullDayEvent({
    this.columnIndex = 0,
    this.title,
    this.description,
    this.data,
    this.eventType = Event.defaultType,
    this.color = Colors.blue,
    this.textColor = Colors.white,
  });

  final int columnIndex;
  final String? title;
  final String? description;
  final Color color;
  final Color textColor;
  final Object? data;
  final Object eventType;
}
