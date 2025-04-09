import 'package:example/data.dart';
import 'package:example/extension.dart';
import 'package:flutter/material.dart';
import 'package:infinite_calendar_view/infinite_calendar_view.dart';
import 'package:intl/intl.dart';

class EventsPlannerMultiColumnView extends StatelessWidget {
  const EventsPlannerMultiColumnView({
    super.key,
    required this.isDarkMode,
  });

  final bool isDarkMode;

  @override
  Widget build(BuildContext context) {
    var controller = EventsController()
      ..updateCalendarData((calendarData) {
        calendarData.addEvents(reservationsEvents);
      });

    var heightPerMinute = 1.0;
    var initialVerticalScrollOffset = heightPerMinute * 7 * 60;

    return EventsPlanner(
      controller: controller,
      daysShowed: 1,
      initialDate: DateTime.now(),
      heightPerMinute: heightPerMinute,
      initialVerticalScrollOffset: initialVerticalScrollOffset,
      daySeparationWidth: 10,
      columnsParam: ColumnsParam(
        columns: 3,
        columnsLabels: ["Tennis", "Foot", "Bad"],
        columnsWidthRatio: [1 / 3, 1 / 3, 1 / 3],
        columnsColors: [
          Colors.yellow.pastel,
          Colors.green.pastel,
          Colors.blueAccent.pastel,
        ],
      ),
      fullDayParam: FullDayParam(
        fullDayEventsBarVisibility: false,
      ),
      daysHeaderParam: DaysHeaderParam(
        daysHeaderHeight: 80,
        daysHeaderVisibility: true,
        daysHeaderColor: Theme.of(context).appBarTheme.backgroundColor,
        dayHeaderBuilder: (day, isToday) {
          return DefaultDayHeader(
            dayText: DateFormat("E d").format(day),
            isToday: isToday,
            foregroundColor:
                isDarkMode ? Theme.of(context).colorScheme.primary : null,
          );
        },
      ),
    );
  }
}
