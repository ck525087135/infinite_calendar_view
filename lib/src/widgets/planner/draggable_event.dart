import 'package:flutter/material.dart';

import '../../events/event.dart';
import '../../events_planner.dart';
import '../../extension.dart';

class DraggableEventWidget extends StatelessWidget {
  const DraggableEventWidget({
    super.key,
    required this.event,
    required this.height,
    required this.width,
    required this.heightPerMinute,
    required this.onDragEnd,
    this.onSlotMinutesRound = 15,
    this.draggableFeedback,
    required this.child,
  });

  static double defaultDraggableOpacity = 0.7;

  /// event
  final Event event;

  /// event height
  final double height;

  /// event width
  final double width;

  /// current heightPerMinute
  final double heightPerMinute;

  /// event when end drag
  final void Function(
    DateTime exactStartDateTime,
    DateTime exactEndDateTime,
    DateTime roundStartDateTime,
    DateTime roundEndDateTime,
  ) onDragEnd;

  /// round date to nearest minutes date
  final int onSlotMinutesRound;

  /// event widget when drag
  final Widget? draggableFeedback;

  /// event widget
  final Widget child;

  @override
  Widget build(BuildContext context) {
    EventsPlannerState? plannerState;
    var oldPositionY = 0.0;

    return LongPressDraggable(
      feedback: draggableFeedback ?? getDefaultDraggableFeedback(),
      childWhenDragging: const SizedBox.shrink(),
      onDragStarted: () {
        plannerState = context.findAncestorStateOfType<EventsPlannerState>();
        var oldBox = context.findRenderObject() as RenderBox;
        var oldPosition = oldBox.localToGlobal(Offset.zero);
        oldPositionY = oldPosition.dy;
      },
      onDragUpdate: (details) {
        manageHorizontalScroll(
            plannerState?.mainHorizontalController, context, details);
      },
      onDragEnd: (details) {
        var difference = details.offset.dy - oldPositionY;
        var minutesDiff = event.endTime.difference(event.startTime).inMinutes;
        var minuteDiff = difference / heightPerMinute;

        // find day
        var scrollOffset = plannerState?.mainHorizontalController.offset ?? 0;
        var releaseOffset = scrollOffset + details.offset.dx;
        var index = (releaseOffset / (plannerState?.dayWidth ?? 0)).toInt();
        // adjust negative index, because current day begin 0 and negative begin -1
        var dayIndex = releaseOffset >= 0 ? index : index - 1;
        var currentDay = plannerState?.initialDate
                .add(Duration(days: dayIndex))
                .withoutTime ??
            event.startTime.withoutTime;

        // exact event time
        var exactStartDateTime = currentDay.add(
          Duration(
            minutes: event.startTime.totalMinutes + minuteDiff.toInt(),
          ),
        );
        var exactEndDateTime = exactStartDateTime.add(
          Duration(
            minutes: minutesDiff,
          ),
        );

        // round event time to nearest multiple of onSlotMinutesRound minutes
        var totalMinutes = exactStartDateTime.totalMinutes;
        var totalMinutesRound =
            onSlotMinutesRound * (totalMinutes / onSlotMinutesRound).round();
        var roundStartDateTime = currentDay.add(
          Duration(
            minutes: totalMinutesRound,
          ),
        );
        var roundEndDateTime = roundStartDateTime.add(
          Duration(
            minutes: minutesDiff,
          ),
        );

        onDragEnd.call(
          exactStartDateTime,
          exactEndDateTime,
          roundStartDateTime,
          roundEndDateTime,
        );
      },
      child: child,
    );
  }

  void manageHorizontalScroll(ScrollController? horizontalController,
      BuildContext context, DragUpdateDetails details) {
    if (horizontalController != null) {
      var screenWidth = MediaQuery.of(context).size.width;
      var dx = details.globalPosition.dx;
      if (dx > (0.9 * screenWidth)) {
        horizontalController.jumpTo(horizontalController.offset + 20);
      }
      if (dx < (0.1 * screenWidth)) {
        horizontalController.jumpTo(horizontalController.offset - 20);
      }
    }
  }

  SizedBox getDefaultDraggableFeedback() {
    return SizedBox(
      height: height,
      width: width,
      child: Opacity(
        opacity: defaultDraggableOpacity,
        child: child,
      ),
    );
  }
}
