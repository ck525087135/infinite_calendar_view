import 'package:flutter/material.dart';
import 'package:infinite_calendar_view/infinite_calendar_view.dart';
import 'package:intl/intl.dart';

class EventsListView extends StatelessWidget {
  const EventsListView({
    super.key,
    required this.controller,
  });

  final EventsController controller;

  @override
  Widget build(BuildContext context) {
    return EventsList(
      controller: controller,
      initialDate: DateTime.now(),
      dayEventsBuilder: (day, events) {
        return DefaultDayEvents(
          events: events,
          nullEventsWidget: DefaultDayEvents.defaultEmptyEventsWidget,
        );
      },
      dayHeaderBuilder: (day, isToday, events) => DefaultHeader(
        dayText: DateFormat.MMMMEEEEd().format(day).toUpperCase(),
      ),
    );
  }
}
