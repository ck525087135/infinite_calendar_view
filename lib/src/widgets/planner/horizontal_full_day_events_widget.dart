import 'package:flutter/material.dart';

import '../../../infinite_calendar_view.dart';

// This widget now only provides the left label for the full-day bar.
// The background and event rendering are handled by the Stack and Overlay in EventsPlannerState.
class HorizontalFullDayEventsWidget extends StatelessWidget {
  const HorizontalFullDayEventsWidget({
    super.key,
    required this.fullDayParam,
    required this.timesIndicatorsWidth,
  });

  final FullDayParam fullDayParam;
  final double timesIndicatorsWidth;

  @override
  Widget build(BuildContext context) {
    // Returns only the left label part
    return SizedBox(
      width: timesIndicatorsWidth,
      height: fullDayParam.fullDayEventsBarHeight,
      child: fullDayParam.fullDayEventsBarLeftWidget ??
          Center(
            child: Text(
              fullDayParam.fullDayEventsBarLeftText,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.outline, fontSize: 12),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
    );
  }
}
