import 'package:flutter/material.dart';
import 'package:infinite_calendar_view/src/events_months.dart';
import 'package:infinite_calendar_view/src/extension.dart';

class MonthHeader extends StatelessWidget {
  const MonthHeader({
    super.key,
    required this.weekParam,
  });

  final WeekParam weekParam;

  @override
  Widget build(BuildContext context) {
    var startOfWeek = weekParam.startOfWeekDay;

    return Container(
      height: weekParam.headerHeight,
      decoration: BoxDecoration(
        color: Theme.of(context).appBarTheme.backgroundColor,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: [
          for (var dayOfWeek = startOfWeek;
              dayOfWeek < startOfWeek + 7;
              dayOfWeek++)
            Expanded(
              child: weekParam.headerBuilder?.call(((dayOfWeek - 1) % 7) + 1) ??
                  getDefaultHeaderDay(context, (dayOfWeek - 1) % 7),
            )
        ],
      ),
    );
  }

  Widget getDefaultHeaderDay(BuildContext context, int dayOfWeek) {
    var defaultDaysText = ["M", "T", "W", "T", "F", "S", "S"];
    return Center(
      child: Text(
        weekParam.headerText?.call(dayOfWeek + 1) ?? defaultDaysText[dayOfWeek],
        style: weekParam.headerStyle ?? getDefaultTextStyle(context, dayOfWeek),
      ),
    );
  }

  TextStyle getDefaultTextStyle(BuildContext context, int dayOfWeek) {
    var defaultForegroundColor = context.isDarkMode
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.onPrimary;
    var textColor = weekParam.headerTextColor?.call(dayOfWeek + 1) ??
        defaultForegroundColor;
    return TextStyle().copyWith(
      color: (dayOfWeek >= 5) ? textColor.darken() : textColor,
      fontWeight: FontWeight.w700,
      fontSize: 13,
    );
  }
}
