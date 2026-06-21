// Driver for the profile-mode canvas performance traces.
//
//   flutter drive --profile \
//     --driver=test_driver/perf_driver.dart \
//     --target=integration_test/perf_pan_test.dart -d macos
//
// For every timeline the target reports (one per `traceAction` reportKey), this
// writes build/perf/<key>.timeline.json (the full Chrome/Perfetto trace) and
// build/perf/<key>.timeline_summary.json (avg/worst frame build + rasterizer
// times, 90th/99th percentiles, and missed-frame-budget counts).

import 'package:flutter_driver/flutter_driver.dart';
import 'package:integration_test/integration_test_driver.dart';

Future<void> main() => integrationDriver(
      responseDataCallback: (data) async {
        if (data == null) return;
        for (final entry in data.entries) {
          final timeline =
              Timeline.fromJson(entry.value as Map<String, dynamic>);
          final summary = TimelineSummary.summarize(timeline);
          await summary.writeTimelineToFile(
            entry.key,
            destinationDirectory: 'build/perf',
            pretty: true,
            includeSummary: true,
          );
        }
      },
    );
