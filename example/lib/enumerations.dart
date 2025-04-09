import 'package:flutter/material.dart';

enum CalendarView {
  agenda("Agenda", Icons.list),
  day("Day", Icons.calendar_view_day_outlined),
  day3("3 days", Icons.view_column),
  draggableDay3("3 days with draggable events", Icons.view_column),
  day7("7 days (web)", Icons.calendar_view_week),
  multi_column("Multi columns", Icons.view_column_outlined),
  month("Month", Icons.calendar_month);

  const CalendarView(
    this.text,
    this.icon,
  );

  final String text;
  final IconData icon;
}
