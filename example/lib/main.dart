import 'package:example/views/events_months_view.dart';
import 'package:example/views/events_planner_multi_columns_view.dart';
import 'package:example/views/events_planner_simple_view.dart';
import 'package:flutter/material.dart';
import 'package:infinite_calendar_view/infinite_calendar_view.dart';

import 'data.dart';
import 'enumerations.dart';
import 'views/events_list_view.dart';
import 'views/events_planner_draggable_events_view.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  EventsController controller = EventsController()
    ..updateCalendarData((calendarData) {
      calendarData.addEvents(events);
      calendarData.addFullDayEvents(DateTime.now(), fullDayEvents);
    });
  var calendarMode = CalendarView.day3;
  var darkMode = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Infinite Calendar View',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        primaryColor: Colors.blue,
        appBarTheme: AppBarTheme(backgroundColor: Colors.blue),
        colorScheme: ColorScheme.fromSeed(
          brightness: Brightness.light,
          seedColor: Colors.blue,
          primary: Colors.blue,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        appBarTheme: AppBarTheme(backgroundColor: Color(0xff2F2F2F)),
        colorScheme: ColorScheme.fromSeed(
          brightness: Brightness.dark,
          seedColor: Colors.blueAccent,
        ),
      ),
      themeMode: darkMode ? ThemeMode.dark : ThemeMode.light,
      home: Scaffold(
        appBar: getAppBar(context),
        body: switch (calendarMode) {
          CalendarView.agenda => EventsListView(
              controller: controller,
            ),
          CalendarView.day => EventsPlannerView(
              key: UniqueKey(),
              controller: controller,
              daysShowed: 1,
              isDarkMode: darkMode,
            ),
          CalendarView.day3 => EventsPlannerView(
              key: UniqueKey(),
              controller: controller,
              daysShowed: 3,
              isDarkMode: darkMode,
            ),
          CalendarView.draggableDay3 => EventsPlannerDraggableEventsView(
              key: UniqueKey(),
              controller: controller,
              daysShowed: 3,
              isDarkMode: darkMode,
            ),
          CalendarView.day7 => EventsPlannerDraggableEventsView(
              key: UniqueKey(),
              controller: controller,
              daysShowed: 7,
              isDarkMode: darkMode,
            ),
          CalendarView.multi_column => EventsPlannerMultiColumnView(
              key: UniqueKey(),
              isDarkMode: darkMode,
            ),
          CalendarView.month => EventsMonthsView(
              controller: controller,
            ),
        },
      ),
    );
  }

  AppBar getAppBar(BuildContext context) {
    return AppBar(
      title: Text(
        "Infinite Calendar View",
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Theme.of(context).colorScheme.onPrimary,
            ),
      ),
      scrolledUnderElevation: 0.0,
      toolbarOpacity: 1,
      elevation: 0,
      centerTitle: false,
      leading: Icon(
        Icons.rocket_launch,
        color: Theme.of(context).colorScheme.onPrimary,
      ),
      actions: [
        // change dark mode
        IconButton(
          onPressed: () => setState(() => darkMode = !darkMode),
          icon: Icon(
            Icons.dark_mode,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ),

        // change calendar mode
        PopupMenuButton(
          icon: Icon(calendarMode.icon),
          iconColor: Theme.of(context).colorScheme.onPrimary,
          onSelected: (value) => setState(() => calendarMode = value),
          itemBuilder: (BuildContext context) {
            return CalendarView.values.map((mode) {
              return PopupMenuItem(
                value: mode,
                child: ListTile(
                  leading: Icon(mode.icon),
                  title: Text(mode.text),
                ),
              );
            }).toList();
          },
        ),
      ],
    );
  }
}
