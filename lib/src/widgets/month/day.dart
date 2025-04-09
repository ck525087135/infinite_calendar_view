import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:infinite_calendar_view/src/controller/events_controller.dart';
import 'package:infinite_calendar_view/src/events/event.dart';
import 'package:infinite_calendar_view/src/events_months.dart';
import 'package:infinite_calendar_view/src/extension.dart';

class Day extends StatefulWidget {
  const Day({
    super.key,
    required this.controller,
    required this.daysParam,
    required this.day,
  });

  final DateTime day;
  final DaysParam daysParam;
  final EventsController controller;

  @override
  State<Day> createState() => _DayState();
}

class _DayState extends State<Day> {
  late VoidCallback eventListener;
  List<Event>? events;

  @override
  void initState() {
    super.initState();
    events = widget.controller.getFilteredDayEvents(widget.day);
    eventListener = () => updateEvents();
    widget.controller.addListener(eventListener);
  }

  @override
  void dispose() {
    super.dispose();
    widget.controller.removeListener(eventListener);
  }

  // update day events when change
  void updateEvents() {
    if (mounted) {
      var dayEvents = widget.controller.getFilteredDayEvents(widget.day);

      // no update if no change for current day
      if (listEquals(dayEvents, events) == false) {
        setState(() {
          events = dayEvents;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.daysParam.dayHeight,
      child: widget.daysParam.dayBuilder?.call(widget.day, events) ??
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              getHeaderWidget(widget.daysParam.headerHeight),
              SizedBox(height: widget.daysParam.beforeEventSpacing),
              widget.daysParam.dayEventsBuilder?.call(events) ??
                  getEventsCanBeShowedWidget(),
            ],
          ),
    );
  }

  Container getHeaderWidget(double headerHeight) {
    return Container(
      height: headerHeight,
      child: widget.daysParam.dayHeaderBuilder?.call(widget.day) ??
          DefaultDayHeader(
            text: widget.day.day.toString(),
            isToday: DateUtils.isSameDay(widget.day, DateTime.now()),
          ),
    );
  }

  Widget getEventsCanBeShowedWidget() {
    var dayParam = widget.daysParam;
    var dayHeight = dayParam.dayHeight;
    var headerHeight = dayParam.headerHeight;
    var eventHeight = dayParam.eventHeight;
    var space = dayParam.eventSpacing;
    var beforeEventSpacing = dayParam.beforeEventSpacing;
    var eventsLength = events?.length ?? 0;
    var maxPossibleEvents =
        ((dayHeight - headerHeight - beforeEventSpacing + space) /
                (eventHeight + space))
            .toInt();
    var maxEvents = min(maxPossibleEvents, eventsLength);
    var showedEvents = events?.sublist(0, maxEvents) ?? [];

    // remove last to show generic events "x more events"
    if (showedEvents.length < eventsLength) {
      showedEvents.removeLast();
    }
    var notShowedEventsCount = eventsLength - showedEvents.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var event in showedEvents) ...[
          Container(
            height: eventHeight,
            child: dayParam.dayEventBuilder?.call(event) ??
                DefaultDayEvent(event: event),
          ),
          if (event != showedEvents.last || notShowedEventsCount > 0)
            SizedBox(height: space),
        ],

        // show no showed events count
        if (notShowedEventsCount > 0)
          DefaultNotShowedEventsWidget(
            context: context,
            eventHeight: eventHeight,
            text: "$notShowedEventsCount others",
          ),
      ],
    );
  }
}

class DefaultDayHeader extends StatelessWidget {
  const DefaultDayHeader({
    super.key,
    required this.text,
    this.isToday = false,
    this.fontSize = 12,
    this.fontWeight = FontWeight.w500,
    this.textColor,
    this.todayTextColor,
    this.todayBackgroundColor,
  });

  final String text;
  final bool isToday;
  final double fontSize;
  final FontWeight fontWeight;
  final Color? textColor;
  final Color? todayTextColor;
  final Color? todayBackgroundColor;

  @override
  Widget build(BuildContext context) {
    var colorScheme = Theme.of(context).colorScheme;
    var todayBgColor = todayBackgroundColor ?? colorScheme.primary;
    var todayFgColor = todayTextColor ?? colorScheme.onPrimary;
    var fgColor = textColor ?? colorScheme.outline;
    return Center(
      child: Container(
        decoration: BoxDecoration(
          color: isToday ? todayBgColor : null,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Text(
            text,
            style: TextStyle().copyWith(
              fontSize: fontSize,
              fontWeight: fontWeight,
              color: isToday ? todayFgColor : fgColor,
            ),
          ),
        ),
      ),
    );
  }
}

class DefaultNotShowedEventsWidget extends StatelessWidget {
  const DefaultNotShowedEventsWidget({
    super.key,
    required this.context,
    required this.eventHeight,
    required this.text,
    this.textStyle,
    this.textPadding = const EdgeInsets.all(2),
    this.decoration,
  });

  final BuildContext context;
  final double eventHeight;
  final String text;
  final TextStyle? textStyle;
  final EdgeInsets textPadding;
  final BoxDecoration? decoration;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: eventHeight,
      decoration: decoration ??
          BoxDecoration(
            color: Theme.of(context).colorScheme.outlineVariant.lighten(0.1),
            borderRadius: BorderRadius.circular(3),
          ),
      child: Padding(
        padding: textPadding,
        child: Text(
          text,
          style: textStyle ?? TextStyle().copyWith(fontSize: 10),
        ),
      ),
    );
  }
}

/// default event showed
class DefaultDayEvent extends StatelessWidget {
  const DefaultDayEvent({
    super.key,
    required this.event,
  });

  final Event event;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: event.color,
        borderRadius: BorderRadius.circular(3),
      ),
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: Text(
          event.title ?? "",
          style: TextStyle().copyWith(
            fontSize: 10,
            color: event.textColor,
          ),
        ),
      ),
    );
  }
}
