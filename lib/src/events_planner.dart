import 'package:flutter/material.dart';
import 'package:sticky_infinite_list/models/alignments.dart';
import 'package:sticky_infinite_list/widget.dart';

import 'controller/events_controller.dart';
import 'events/event.dart';
import 'events/event_arranger.dart';
import 'events/side_events_arranger.dart';
import 'extension.dart';
import 'widgets/planner/day_widget.dart';
import 'widgets/planner/horizontal_days_indicator_widget.dart';
import 'widgets/planner/horizontal_full_day_events_widget.dart';
import 'widgets/planner/vertical_time_indicator_widget.dart';

class EventsPlanner extends StatefulWidget {
  const EventsPlanner({
    super.key,
    required this.controller,
    this.initialDate,
    this.daysShowed = 3,
    this.maxPreviousDays = 365,
    this.maxNextDays = 365,
    this.heightPerMinute = 0.9,
    this.daySeparationWidth = 3.0,
    this.dayEventsArranger = const SideEventArranger(),
    this.onDayChange,
    this.initialVerticalScrollOffset = 0,
    this.onVerticalScrollChange,
    this.horizontalScrollPhysics = const BouncingScrollPhysics(
      decelerationRate: ScrollDecelerationRate.fast,
    ),
    this.automaticAdjustHorizontalScrollToDay = true,
    this.onAutomaticAdjustHorizontalScroll,
    this.dayParam = const DayParam(),
    this.columnsParam = const ColumnsParam(),
    this.timesIndicatorsParam = const TimesIndicatorsParam(),
    this.daysHeaderParam = const DaysHeaderParam(),
    this.currentHourIndicatorParam = const CurrentHourIndicatorParam(),
    this.offTimesParam = const OffTimesParam(),
    this.pinchToZoomParam = const PinchToZoomParameters(),
    this.fullDayParam = const FullDayParam(),
  });

  /// data controller
  final EventsController controller;

  /// initial first day
  final DateTime? initialDate;

  /// Number of day showing in same time
  final int daysShowed;

  /// max horizontal previous days scroll
  /// Null for infinite
  final int? maxPreviousDays;

  /// max horizontal next days scroll
  /// /// Null for infinite
  final int? maxNextDays;

  /// Height per minute in day
  final double heightPerMinute;

  /// separation between two day
  final double daySeparationWidth;

  /// Arrange events position in day
  /// See SimpleEventArranger
  final EventArranger dayEventsArranger;

  /// Callback when first day (showed in planner) change during horizontal scroll
  final void Function(DateTime firstDay)? onDayChange;

  /// initial time scroll (vertical) : hour of day = heightPerMinute * $total_minutes
  final double initialVerticalScrollOffset;

  /// call when vertical scroll change
  final void Function(double offset)? onVerticalScrollChange;

  /// Horizontal day scroll physics
  final ScrollPhysics horizontalScrollPhysics;

  /// Automatic adjust horizontal scroll to nearest day and background
  final bool automaticAdjustHorizontalScrollToDay;

  /// Automatic adjust horizontal scroll to nearest day and background
  final void Function(DateTime day)? onAutomaticAdjustHorizontalScroll;

  /// day param : day builder, padding, colors...
  final DayParam dayParam;

  /// columns param : multi columns (multi agenda) per day
  final ColumnsParam columnsParam;

  /// left time indicator (hour) parameters
  final TimesIndicatorsParam timesIndicatorsParam;

  /// days in header parameters
  final DaysHeaderParam daysHeaderParam;

  /// hour indicator (line and text) param
  final CurrentHourIndicatorParam currentHourIndicatorParam;

  /// offTimes param
  final OffTimesParam offTimesParam;

  ///  pinchToZoom parameters
  final PinchToZoomParameters pinchToZoomParam;

  // full day parameters
  final FullDayParam fullDayParam;

  @override
  State createState() => EventsPlannerState();
}

class EventsPlannerState extends State<EventsPlanner> {
  final mainHorizontalController = ScrollController();
  final headersHorizontalController = ScrollController();
  late ScrollController mainVerticalController;
  late DateTime initialDate;
  late double dayWidth;
  late int currentIndex;
  late EventsController _controller;
  late VoidCallback automaticScrollAdjustListener;
  late double heightPerMinute;
  late double heightPerMinuteScaleStart;
  late double mainVerticalControllerOffsetScaleStart;
  bool listenHorizontalScrollDayChange = true;
  int _plannerPointerDownCount = 0;

  @override
  void initState() {
    super.initState();
    heightPerMinute = widget.heightPerMinute;
    _controller = widget.controller;
    initialDate = widget.initialDate?.withoutTime ?? DateTime.now().withoutTime;
    currentIndex = 0;
    mainVerticalController = ScrollController(
      initialScrollOffset: widget.initialVerticalScrollOffset,
    );

    // synchronize horizontal scroll between days events / full day events / days header
    if (widget.daysHeaderParam.daysHeaderVisibility ||
        widget.fullDayParam.fullDayEventsBarVisibility) {
      mainHorizontalController.addListener(() {
        headersHorizontalController.jumpTo(mainHorizontalController.offset);
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // index calculation and first day showed
      if (widget.onDayChange != null) {
        initDayChangingListener();
      }

      // Automatic adjust horizontal scroll to nearest day
      if (widget.automaticAdjustHorizontalScrollToDay) {
        automaticScrollAdjustListener = getAutomaticScrollAdjustListener();
        mainHorizontalController.position.isScrollingNotifier
            .addListener(automaticScrollAdjustListener);
      }

      // init vertical scroll listener when scroll stop
      if (widget.onVerticalScrollChange != null) {
        mainVerticalController.position.isScrollingNotifier.addListener(() {
          if (!mainVerticalController.position.isScrollingNotifier.value) {
            widget.onVerticalScrollChange?.call(mainVerticalController.offset);
          }
        });
      }
    });
  }

  /// listen mainHorizontalController and call onFirstDayChange when day change
  void initDayChangingListener() {
    var halfDayWidth = (dayWidth / 2);
    var scroll = mainHorizontalController;
    scroll.addListener(() {
      if (listenHorizontalScrollDayChange) {
        var halfDay = scroll.offset >= 0 ? halfDayWidth : -halfDayWidth;
        var index = ((scroll.offset + halfDay) / dayWidth).toInt();
        // only when index has changed
        if (index != currentIndex) {
          currentIndex = index;
          var currentDay = initialDate.add(Duration(days: currentIndex));
          widget.onDayChange?.call(currentDay);
        }
      }
    });
  }

  /// listen mainHorizontalController scroll stop and adjust to nearest day
  /// call onAutomaticAdjustHorizontalScroll when end adjust
  VoidCallback getAutomaticScrollAdjustListener() {
    return () {
      // when scroll stopped
      var scroll = mainHorizontalController;
      var stopScroll = !scroll.position.isScrollingNotifier.value;
      if (listenHorizontalScrollDayChange && stopScroll) {
        // Round to nearest day
        var nearestDay = dayWidth * (scroll.offset / dayWidth).round();
        if (nearestDay != scroll.offset) {
          // adjust scroll
          Future.delayed(const Duration(milliseconds: 1), () {
            scroll.animateTo(nearestDay,
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeIn);

            // event
            var adjustedDay = initialDate
                .add(Duration(days: (nearestDay / dayWidth).toInt()));
            widget.onAutomaticAdjustHorizontalScroll?.call(adjustedDay);
          });
        }
      }
    };
  }

  @override
  Widget build(BuildContext context) {
    var dayParam = widget.dayParam;
    var plannerHeight = (heightPerMinute * 60 * 24) +
        dayParam.dayTopPadding +
        dayParam.dayBottomPadding;
    var daySeparationWidthPadding = widget.daySeparationWidth / 2;
    var todayColor = dayParam.todayColor ?? getDefaultTodayColor(context);
    var currentHourIndicatorColor =
        widget.currentHourIndicatorParam.currentHourIndicatorColor ??
            getDefaultHourIndicatorColor(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        var width = constraints.maxWidth;
        var leftWidget = widget.timesIndicatorsParam.timesIndicatorsWidth;
        dayWidth = (width - leftWidget) / widget.daysShowed;

        return Column(
          children: [
            // top days header
            if (widget.daysHeaderParam.daysHeaderVisibility ||
                widget.columnsParam.columns > 1)
              getHorizontalDaysIndicatorWidget(),

            // full day events
            if (widget.fullDayParam.fullDayEventsBarVisibility)
              getHorizontalFullDayEventsWidget(
                daySeparationWidthPadding,
                todayColor,
              ),

            // days content
            Expanded(
              child: getPlannerAndTimesWidget(
                plannerHeight,
                currentHourIndicatorColor,
                todayColor,
                daySeparationWidthPadding,
              ),
            ),
          ],
        );
      },
    );
  }

  Color getDefaultTodayColor(BuildContext context) {
    return context.isDarkMode
        ? Theme.of(context).colorScheme.surface.lighten(0.03)
        : Theme.of(context).colorScheme.primaryContainer.lighten(0.04);
  }

  Color getDefaultHourIndicatorColor(BuildContext context) {
    return context.isDarkMode
        ? Theme.of(context).colorScheme.primary.lighten()
        : Theme.of(context).colorScheme.primary.darken();
  }

  GestureDetector getPlannerAndTimesWidget(
    double plannerHeight,
    Color currentHourIndicatorColor,
    Color todayColor,
    double daySeparationWidthPadding,
  ) {
    var zoom = widget.pinchToZoomParam;
    var isZoom = zoom.pinchToZoom;
    return GestureDetector(
      onScaleStart: isZoom ? zoom.onScaleStart ?? _onScaleStart : null,
      onScaleUpdate: isZoom ? zoom.onScaleUpdate ?? _onScaleUpdate : null,
      onScaleEnd: isZoom ? zoom.onScaleEnd ?? _onScaleEnd : null,
      child: Listener(
        onPointerDown: isZoom ? (event) => _onPointerDown() : null,
        onPointerCancel: isZoom ? (event) => _onPointerUp() : null,
        onPointerUp: isZoom ? (event) => _onPointerUp() : null,
        child: IgnorePointer(
          ignoring: isZoom ? _plannerPointerDownCount > 1 : false,
          child: CustomScrollView(
            physics: isZoom && _plannerPointerDownCount > 1
                ? const NeverScrollableScrollPhysics()
                : null,
            controller: mainVerticalController,
            slivers: [
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  childCount: 1,
                  (context, index) {
                    return SizedBox(
                      height: plannerHeight,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // left Timeline
                          getVerticalTimeIndicatorWidget(
                            currentHourIndicatorColor,
                          ),

                          // day planning infinite list
                          Expanded(
                            child: getPlannerWidget(
                              todayColor,
                              daySeparationWidthPadding,
                              plannerHeight,
                              currentHourIndicatorColor,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  InfiniteList getPlannerWidget(
    Color todayColor,
    double daySeparationWidthPadding,
    double plannerHeight,
    Color currentHourIndicatorColor,
  ) {
    var physics = _plannerPointerDownCount > 1
        ? const NeverScrollableScrollPhysics()
        : widget.horizontalScrollPhysics;

    return InfiniteList(
      physics: physics,
      controller: mainHorizontalController,
      scrollDirection: Axis.horizontal,
      direction: InfiniteListDirection.multi,
      negChildCount: widget.maxPreviousDays,
      posChildCount: widget.maxNextDays,
      builder: (context, index) {
        var day = initialDate.add(Duration(days: index));

        // notify day will be build
        Future(() => widget.dayParam.onDayBuild?.call(day));

        return InfiniteListItem(
          contentBuilder: (context) {
            return DayWidget(
              controller: _controller,
              day: day,
              todayColor: todayColor,
              daySeparationWidthPadding: daySeparationWidthPadding,
              plannerHeight: plannerHeight,
              heightPerMinute: heightPerMinute,
              dayWidth: dayWidth,
              dayEventsArranger: widget.dayEventsArranger,
              dayParam: widget.dayParam,
              columnsParam: widget.columnsParam,
              currentHourIndicatorParam: widget.currentHourIndicatorParam,
              currentHourIndicatorColor: currentHourIndicatorColor,
              offTimesParam: widget.offTimesParam,
            );
          },
        );
      },
    );
  }

  VerticalTimeIndicatorWidget getVerticalTimeIndicatorWidget(
    Color currentHourIndicatorColor,
  ) {
    return VerticalTimeIndicatorWidget(
      timesIndicatorsParam: widget.timesIndicatorsParam,
      heightPerMinute: heightPerMinute,
      currentHourIndicatorHourVisibility:
          widget.currentHourIndicatorParam.currentHourIndicatorHourVisibility,
      currentHourIndicatorColor: currentHourIndicatorColor,
    );
  }

  HorizontalFullDayEventsWidget getHorizontalFullDayEventsWidget(
    double daySeparationWidthPadding,
    Color todayColor,
  ) {
    return HorizontalFullDayEventsWidget(
      controller: _controller,
      fullDayParam: widget.fullDayParam,
      columnsParam: widget.columnsParam,
      daySeparationWidthPadding: daySeparationWidthPadding,
      dayHorizontalController: headersHorizontalController,
      maxPreviousDays: widget.maxPreviousDays,
      maxNextDays: widget.maxNextDays,
      initialDate: initialDate,
      dayWidth: dayWidth,
      todayColor: todayColor,
      timesIndicatorsWidth: widget.timesIndicatorsParam.timesIndicatorsWidth,
    );
  }

  HorizontalDaysIndicatorWidget getHorizontalDaysIndicatorWidget() {
    return HorizontalDaysIndicatorWidget(
      daysHeaderParam: widget.daysHeaderParam,
      columnsParam: widget.columnsParam,
      dayHorizontalController: headersHorizontalController,
      maxPreviousDays: widget.maxPreviousDays,
      maxNextDays: widget.maxNextDays,
      initialDate: initialDate,
      dayWidth: dayWidth,
      timesIndicatorsWidth: widget.timesIndicatorsParam.timesIndicatorsWidth,
    );
  }

  void _onScaleStart(ScaleStartDetails details) {
    if (details.pointerCount == 2) {
      heightPerMinuteScaleStart = heightPerMinute;
      mainVerticalControllerOffsetScaleStart = mainVerticalController.offset;
    }
  }

  void _onScaleUpdate(ScaleUpdateDetails details) {
    if (details.pointerCount == 2) {
      var speed = widget.pinchToZoomParam.pinchToZoomSpeed;
      var scale = (((details.scale - 1) * speed) + 1);
      var newHeightPerMinute = heightPerMinuteScaleStart * scale;
      var minZoom = widget.pinchToZoomParam.pinchToZoomMinHeightPerMinute;
      var maxZoom = widget.pinchToZoomParam.pinchToZoomMaxHeightPerMinute;
      if (minZoom <= newHeightPerMinute && newHeightPerMinute <= maxZoom) {
        setState(() {
          heightPerMinute = newHeightPerMinute;
          mainVerticalController
              .jumpTo(mainVerticalControllerOffsetScaleStart * scale);
        });
      }
    }
  }

  void _onScaleEnd(ScaleEndDetails details) {
    widget.controller.notifyListeners();
    widget.pinchToZoomParam.onZoomChange?.call(heightPerMinute);
  }

  void _onPointerDown() {
    setState(() {
      _plannerPointerDownCount++;
      if (_plannerPointerDownCount > 1 &&
          widget.automaticAdjustHorizontalScrollToDay) {
        mainHorizontalController.position.isScrollingNotifier
            .removeListener(automaticScrollAdjustListener);
      }
    });
  }

  void _onPointerUp() {
    setState(() {
      _plannerPointerDownCount--;
      if (_plannerPointerDownCount == 0 &&
          widget.automaticAdjustHorizontalScrollToDay) {
        mainHorizontalController.position.isScrollingNotifier
            .addListener(automaticScrollAdjustListener);
      }
    });
  }

  void updateHeightPerMinute(double heightPerMinute) {
    setState(() {
      this.heightPerMinute = heightPerMinute;
    });
  }

  void updateVerticalScrollOffset(verticalScrollOffset) {
    mainVerticalController.jumpTo(verticalScrollOffset);
  }

  void jumpToDate(DateTime date) {
    if (context.mounted) {
      // stop scroll listener for avoid change day listener
      listenHorizontalScrollDayChange = false;
      var index = date.withoutTime.getDayDifference(initialDate);
      mainHorizontalController.jumpTo(index * dayWidth);
      listenHorizontalScrollDayChange = true;
    }
  }
}

class FullDayParam {
  const FullDayParam({
    this.fullDayEventsBarVisibility = true,
    this.fullDayEventsBarHeight = 40,
    this.fullDayEventsBarLeftText = defaultFullDayEventsBarLeftText,
    this.fullDayEventsBarLeftWidget,
    this.fullDayEventsBarDecoration = const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.black12))),
    this.fullDayEventsBuilder,
    this.fullDayEventBuilder,
    this.fullDayBackgroundColor,
  });

  static const defaultFullDayEventsBarLeftText = 'All day';

  /// visibility of full days events
  final bool fullDayEventsBarVisibility;

  /// events days top bar height
  final double fullDayEventsBarHeight;

  /// events days top bar left widget
  final Widget? fullDayEventsBarLeftWidget;

  /// events days top bar left text
  final String fullDayEventsBarLeftText;

  /// events days top bar decoration
  final Decoration? fullDayEventsBarDecoration;

  /// full day events builder
  final Widget Function(List<FullDayEvent> events, double width)?
      fullDayEventsBuilder;

  /// full day event builder
  final Widget Function(FullDayEvent event, double width)? fullDayEventBuilder;

  /// color of background top bar
  final Color? fullDayBackgroundColor;
}

class PinchToZoomParameters {
  const PinchToZoomParameters({
    this.pinchToZoom = true,
    this.pinchToZoomSpeed = 1,
    this.pinchToZoomMinHeightPerMinute = 0.5,
    this.pinchToZoomMaxHeightPerMinute = 2.5,
    this.onZoomChange,
    this.onScaleStart,
    this.onScaleUpdate,
    this.onScaleEnd,
  });

  /// active pinchToZoom (scale) on planner
  /// update heightPerMinute when zoom
  final bool pinchToZoom;

  /// pinchToZoom : speed of scale
  final double pinchToZoomSpeed;

  /// pinchToZoom : max possible HeightPerMinute when scale
  final double pinchToZoomMinHeightPerMinute;

  /// pinchToZoom : min possible HeightPerMinute when scale
  final double pinchToZoomMaxHeightPerMinute;

  /// call when pinchToZoom finished. Return new heightPerMinute
  final void Function(double heightPerMinute)? onZoomChange;

  /// on scale start when scale is active
  final void Function(ScaleStartDetails details)? onScaleStart;

  /// on scale update when scale is active
  final void Function(ScaleUpdateDetails details)? onScaleUpdate;

  /// on scale end when scale is active
  final void Function(ScaleEndDetails details)? onScaleEnd;
}

class CurrentHourIndicatorParam {
  const CurrentHourIndicatorParam({
    this.currentHourIndicatorCustomPainter,
    this.currentHourIndicatorLineVisibility = true,
    this.currentHourIndicatorHourVisibility = true,
    this.currentHourIndicatorColor,
  });

  /// custom day painter for current hour
  final CustomPainter Function(double heightPerMinute, bool isToday)?
      currentHourIndicatorCustomPainter;

  /// show current hour line and text
  final bool currentHourIndicatorLineVisibility;

  /// show current hour line and text
  final bool currentHourIndicatorHourVisibility;

  final Color? currentHourIndicatorColor;
}

class OffTimesParam {
  const OffTimesParam({
    this.offTimesAllDaysRanges = defaultOffTimesAllDaysRange,
    this.offTimesDayRanges = const {},
    this.offTimesColor,
    this.offTimesAllDaysPainter,
    this.offTimesDayPainter,
  });

  static const defaultOffTimesAllDaysRange = [
    OffTimeRange(TimeOfDay(hour: 0, minute: 0), TimeOfDay(hour: 7, minute: 0)),
    OffTimeRange(TimeOfDay(hour: 18, minute: 0), TimeOfDay(hour: 24, minute: 0))
  ];

  /// off time range for all day
  final List<OffTimeRange> offTimesAllDaysRanges;

  /// off time range for particular day (holidays, public holiday...)
  final Map<DateTime, List<OffTimeRange>> offTimesDayRanges;

  /// off time color
  final Color? offTimesColor;

  /// off time custom painter
  final CustomPainter Function(bool isToday, double heightPerMinute,
      List<OffTimeRange> ranges, Color color)? offTimesAllDaysPainter;

  /// off time on day custom painter
  final CustomPainter Function(bool isToday, double heightPerMinute,
      List<OffTimeRange> ranges, Color color)? offTimesDayPainter;
}

class OffTimeRange {
  const OffTimeRange(this.start, this.end);

  final TimeOfDay start;
  final TimeOfDay end;
}

class DaysHeaderParam {
  const DaysHeaderParam({
    this.daysHeaderVisibility = true,
    this.daysHeaderHeight = 40.0,
    this.daysHeaderColor,
    this.daysHeaderForegroundColor,
    this.dayHeaderBuilder,
    this.dayHeaderTextBuilder,
  });

  /// visibility of days top bar
  final bool daysHeaderVisibility;

  /// days top bar height
  final double daysHeaderHeight;

  /// day top bar background color
  final Color? daysHeaderColor;

  /// day top bar foreground color
  final Color? daysHeaderForegroundColor;

  /// day builder in top bar
  final Widget Function(DateTime day, bool isToday)? dayHeaderBuilder;

  /// day text builder
  final String Function(DateTime day)? dayHeaderTextBuilder;
}

class TimesIndicatorsParam {
  const TimesIndicatorsParam({
    this.timesIndicatorsWidth = 60.0,
    this.timesIndicatorsHorizontalPadding = 4.0,
    this.timesIndicatorsCustomPainter,
  });

  /// width of left times bar
  final double timesIndicatorsWidth;

  /// horizontal padding of left times bar
  final double timesIndicatorsHorizontalPadding;

  /// custom times painter
  final CustomPainter Function(double heightPerMinute)?
      timesIndicatorsCustomPainter;
}

class ColumnsParam {
  const ColumnsParam({
    this.columns = 1,
    this.columnsLabels = const [],
    this.columnsColors = const [],
    this.columnsWidthRatio,
    this.columnHeaderBuilder,
    this.columnCustomPainter,
  });

  /// number of columns per day
  final int columns;

  /// label of column showed in header
  final List<String> columnsLabels;

  /// background color of column showed in header
  final List<Color> columnsColors;

  /// ratio of dayWidth of each column
  final List<double>? columnsWidthRatio;

  /// column custom builder in top bar
  final Widget Function(
    DateTime day,
    bool isToday,
    int columIndex,
    double columnWidth,
  )? columnHeaderBuilder;

  /// custom day painter for paint verticals lines
  final CustomPainter Function(double width, int colum)? columnCustomPainter;

  double getColumSize(double dayWidth, int columnIndex) {
    var columnWidthRatio = columnsWidthRatio?[columnIndex];
    return columnWidthRatio != null
        ? dayWidth * columnWidthRatio
        : dayWidth / columns;
  }
}

class DayParam {
  const DayParam({
    this.todayColor,
    this.dayColor,
    this.dayTopPadding = 10,
    this.dayBottomPadding = 15,
    this.dayCustomPainter,
    this.dayEventBuilder,
    this.onSlotMinutesRound = 15,
    this.onSlotTap,
    this.onSlotLongTap,
    this.onSlotDoubleTap,
    this.onDayBuild,
  });

  /// today day top padding (before scroll)
  final double dayTopPadding;

  /// today day bottom padding (after scroll)
  final double dayBottomPadding;

  /// event when horizontal scroll and day planner are build
  final void Function(DateTime day)? onDayBuild;

  /// today day color
  /// null for no color
  final Color? todayColor;

  /// day background color
  final Color? dayColor;

  /// custom day painter for paint horizontal lines
  final CustomPainter Function(double heightPerMinute, bool isToday)?
      dayCustomPainter;

  /// event builder
  /// for listening event tap, it's possible to add gesture detector to dayEventBuilder
  /// example : dayEventBuilder : (event, height, width) => GestureDetector(child: DefaultEventWidget(...));
  final Widget Function(
          Event event, double height, double width, double heightPerMinute)?
      dayEventBuilder;

  /// round date to nearest minutes date
  final int onSlotMinutesRound;

  /// event when tap on free slot on day
  final void Function(DateTime exactDateTime, DateTime roundDateTime)?
      onSlotTap;

  /// event when long tap on free slot on day
  final void Function(DateTime exactDateTime, DateTime roundDateTime)?
      onSlotLongTap;

  /// event when double tap on free slot on day
  final void Function(DateTime exactDateTime, DateTime roundDateTime)?
      onSlotDoubleTap;
}
