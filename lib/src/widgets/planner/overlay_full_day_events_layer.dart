import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:infinite_calendar_view/infinite_calendar_view.dart';
import 'package:infinite_calendar_view/src/extension.dart';

class OverlayFullDayEventsLayer extends StatefulWidget {
  const OverlayFullDayEventsLayer({
    super.key,
    required this.controller,
    required this.dayHorizontalController, // Receives mainHorizontalController
    required this.initialDate,
    required this.dayWidth,
    required this.daySeparationWidthPadding,
    required this.fullDayParam,
    required this.maxPreviousDays,
    required this.maxNextDays,
    required this.barHeight,
    this.onEventTap,
  });

  final EventsController controller;
  final ScrollController dayHorizontalController;
  final DateTime initialDate;
  final double dayWidth;
  final double daySeparationWidthPadding;
  final FullDayParam fullDayParam;
  final int? maxPreviousDays;
  final int? maxNextDays;
  final double barHeight;
  final void Function(FullDayEvent event)? onEventTap;

  @override
  State<OverlayFullDayEventsLayer> createState() =>
      _OverlayFullDayEventsLayerState();
}

class _OverlayFullDayEventsLayerState extends State<OverlayFullDayEventsLayer> {
  List<_EventLayoutInfo> _eventLayouts = [];
  late VoidCallback _eventListener;
  final ScrollController _verticalScrollController = ScrollController();

  // Store unique events currently needing layout
  Set<FullDayEvent> _uniqueEventsToLayout = {};

  @override
  void initState() {
    super.initState();
    _updateEventsToLayout(); // Initial calculation

    _eventListener = () {
      if (mounted) {
        _updateEventsToLayout();
      }
    };
    widget.controller.addListener(_eventListener);

    // No need to listen to scroll here, AnimatedBuilder handles it

    // Initial layout calculation after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _calculateAndSetLayouts();
      }
    });
  }

  @override
  void dispose() {
    widget.controller.removeListener(_eventListener);
    _verticalScrollController.dispose();
    super.dispose();
  }

  // Determine which unique events might be visible or relevant
  void _updateEventsToLayout() {
    final Set<FullDayEvent> newSet = {};
    // Access the internal map - consider adding a getter to EventsController
    final allEventsMap = widget.controller.calendarData.fullDayEvents;

    // OPTIMIZATION TODO: Only process days potentially visible
    // For now, process all days containing events
    allEventsMap.forEach((day, dayEvents) {
      newSet.addAll(dayEvents);
    });

    if (!setEquals(_uniqueEventsToLayout, newSet)) {
      setState(() {
        _uniqueEventsToLayout = newSet;
        _calculateAndSetLayouts(); // Recalculate layout when relevant events change
      });
    }
  }

  // Calculate layout based on the current set of unique events
  void _calculateAndSetLayouts() {
    if (!mounted || widget.dayWidth <= 0) return;

    final List<_EventLayoutInfo> newLayouts = [];
    final List<List<_OccupiedSpan>> occupiedLevels = [];

    // Sort events by start date, then duration
    List<FullDayEvent> sortedEvents = _uniqueEventsToLayout.toList();
    sortedEvents.sort((a, b) {
      int comp = a.startTime.compareTo(b.startTime);
      if (comp == 0) {
        comp = b.endTime.compareTo(a.endTime);
      }
      return comp;
    });

    for (final event in sortedEvents) {
      final startDate = event.startTime.withoutTime;
      final endDate = event.endTime.withoutTime;

      if (endDate.isBefore(startDate)) continue;

      final startIndex = startDate.difference(widget.initialDate).inDays;
      final endIndex = endDate.difference(widget.initialDate).inDays;
      final durationDays = endIndex - startIndex + 1;

      if (durationDays <= 0) continue;

      final eventStartOffset = startIndex * widget.dayWidth;
      final eventWidth = (durationDays * widget.dayWidth) -
          (widget.daySeparationWidthPadding * 2);

      // Find available vertical level
      int level = 0;
      bool placed = false;
      while (!placed) {
        // Remove level limit to allow more events
        if (level >= occupiedLevels.length) {
          occupiedLevels.add([]);
        }

        bool overlaps = false;
        for (final span in occupiedLevels[level]) {
          if (math.max(startIndex, span.startIndex) <=
              math.min(endIndex, span.endIndex)) {
            overlaps = true;
            break;
          }
        }

        if (!overlaps) {
          occupiedLevels[level]
              .add(_OccupiedSpan(startIndex: startIndex, endIndex: endIndex));
          placed = true;
        } else {
          level++;
        }
      }

      final double eventHeight = 20.0;
      final double verticalPadding = 2.0;
      final topOffset = level * (eventHeight + verticalPadding) + 4.0;

      // Add layout regardless of bar height since we now support scrolling
      newLayouts.add(_EventLayoutInfo(
        event: event,
        left: eventStartOffset + widget.daySeparationWidthPadding,
        top: topOffset,
        width: math.max(0, eventWidth),
        height: eventHeight,
      ));
    }

    if (!listEquals(_eventLayouts, newLayouts)) {
      setState(() {
        _eventLayouts = newLayouts;
      });
    }
  }

  // Add a method to count events per day
  Map<DateTime, int> _countEventsPerDay() {
    final Map<DateTime, int> counts = {};
    final allEventsMap = widget.controller.calendarData.fullDayEvents;

    allEventsMap.forEach((day, events) {
      counts[day] = events.length;
    });

    return counts;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.dayHorizontalController,
      builder: (context, child) {
        final bool hasClients = widget.dayHorizontalController.hasClients;
        final double scrollOffset =
            hasClients ? widget.dayHorizontalController.offset : 0.0;

        return ClipRect(
          child: GestureDetector(
            child: SingleChildScrollView(
              controller: _verticalScrollController,
              child: SizedBox(
                height: _calculateTotalHeight(),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: _eventLayouts.map((layout) {
                    if (widget.fullDayParam.fullDayEventsBuilder != null) {
                      return Positioned(
                        left: layout.left - scrollOffset,
                        top: layout.top,
                        width: layout.width,
                        height: layout.height,
                        child: GestureDetector(
                          onTap: () {
                            if (widget.fullDayParam.onEventTap != null) {
                              widget.fullDayParam.onEventTap!(layout.event);
                            }
                          },
                          child: widget.fullDayParam.fullDayEventsBuilder!.call(
                            [layout.event],
                            layout.width,
                            false,
                          ),
                        ),
                      );
                    } else {
                      return Positioned(
                        left: layout.left - scrollOffset,
                        top: layout.top,
                        width: layout.width,
                        height: layout.height,
                        child: GestureDetector(
                          onTap: () {
                            if (widget.fullDayParam.onEventTap != null) {
                              widget.fullDayParam.onEventTap!(layout.event);
                            }
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: layout.event.color,
                              borderRadius: BorderRadius.circular(3),
                            ),
                            padding:
                                const EdgeInsets.symmetric(horizontal: 4.0),
                            child: Text(
                              layout.event.title ?? '',
                              style: TextStyle(
                                  color: layout.event.textColor, fontSize: 10),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                              textAlign: TextAlign.left,
                            ),
                          ),
                        ),
                      );
                    }
                  }).toList(),
                ),
              ),
            ),
            onTapUp: (TapUpDetails details) {
              widget.fullDayParam.onFullLocationTap?.call(widget.initialDate
                  .add(Duration(
                      days: (widget.dayHorizontalController.offset /
                                  widget.dayWidth)
                              .toInt() +
                          (details.localPosition.dx / widget.dayWidth)
                              .toInt())));
            },
          ),
        );
      },
    );
  }

  double _calculateTotalHeight() {
    if (_eventLayouts.isEmpty) return widget.barHeight;

    double maxBottom = 0;
    for (var layout in _eventLayouts) {
      final bottom = layout.top + layout.height;
      if (bottom > maxBottom) {
        maxBottom = bottom;
      }
    }

    return math.max(
        maxBottom + 4.0, widget.barHeight); // Add some padding at the bottom
  }
}

// Helper class to store calculated layout information for an event
class _EventLayoutInfo {
  final FullDayEvent event;
  final double left;
  final double top;
  final double width;
  final double height;

  _EventLayoutInfo({
    required this.event,
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });

  // Equality operator for efficient state updates
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _EventLayoutInfo &&
          runtimeType == other.runtimeType &&
          event == other.event && // Relies on FullDayEvent equality
          left == other.left &&
          top == other.top &&
          width == other.width &&
          height == other.height;

  @override
  int get hashCode => Object.hash(event, left, top, width, height);
}

// Helper class for tracking horizontal spans in the stacking logic
class _OccupiedSpan {
  final int startIndex;
  final int endIndex;

  _OccupiedSpan({required this.startIndex, required this.endIndex});
}
