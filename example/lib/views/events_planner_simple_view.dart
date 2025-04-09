import 'package:flutter/material.dart';
import 'package:infinite_calendar_view/infinite_calendar_view.dart';
import 'package:intl/intl.dart';

class EventsPlannerView extends StatelessWidget {
  const EventsPlannerView({
    super.key,
    required this.controller,
    required this.daysShowed,
    required this.isDarkMode,
  });

  final EventsController controller;
  final int daysShowed;
  final bool isDarkMode;

  @override
  Widget build(BuildContext context) {
    var heightPerMinute = 1.0;
    var initialVerticalScrollOffset = heightPerMinute * 7 * 60;

    return EventsPlanner(
      controller: controller,
      daysShowed: daysShowed,
      initialDate: DateTime.now(),
      heightPerMinute: heightPerMinute,
      initialVerticalScrollOffset: initialVerticalScrollOffset,
      daysHeaderParam: DaysHeaderParam(
        daysHeaderVisibility: daysShowed != 1,
        dayHeaderTextBuilder: (day) => DateFormat("E d").format(day),
      ),
    );
  }
}
