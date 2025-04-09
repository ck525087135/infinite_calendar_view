import 'package:flutter/material.dart';
import 'package:infinite_calendar_view/infinite_calendar_view.dart';

class EventsMonthsView extends StatelessWidget {
  const EventsMonthsView({
    super.key,
    required this.controller,
  });

  final EventsController controller;

  @override
  Widget build(BuildContext context) {
    return EventsMonths(
      controller: controller,
      initialDate: DateTime.now(),
    );
  }
}
